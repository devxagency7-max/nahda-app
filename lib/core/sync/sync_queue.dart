import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../network/api_exception.dart';
import '../storage/app_database.dart';
import 'sync_operation.dart';

const _uuid = Uuid();

/// طابور عمليات المزامنة.
///
/// كل كتابة يقوم بها الأخصائي تمرّ من هنا. الـ repositories تكتب في Drift
/// وتضيف عملية هنا؛ `SyncEngine` وحده يقرأ ويُفرّغ.
class SyncQueueDao {
  SyncQueueDao(this._db);

  final AppDatabase _db;

  /// يضيف عملية للطابور.
  ///
  /// سلوك الدمج (§2.3، القاعدة ٤): تعديلان على **نفس القسم** لنفس الحالة قبل
  /// المزامنة يُدمجان في عملية واحدة. بدون هذا، التعديل الثاني سيحمل
  /// `rowVersion` أصبح قديمًا بفعل الأول، فيفشل بـ 409 حتميًا — تعارض نصنعه
  /// بأنفسنا لا تعارض حقيقي مع مستخدم آخر.
  Future<String> enqueue({
    required SyncOperationType type,
    required String caseId,
    required Map<String, dynamic> payload,
    int? rowVersion,
    String? dedupId,
    String? idempotencyKey,
  }) async {
    return _db.transaction(() async {
      if (type.isSectionUpdate) {
        final merged = await _tryMergeSectionUpdate(
          type: type,
          caseId: caseId,
          payload: payload,
          rowVersion: rowVersion,
        );
        if (merged != null) return merged;
      }

      // حارس التكرار: عملية بنفس dedupId موجودة بالفعل — لا نضيف ثانية.
      if (dedupId != null) {
        final existing = await (_db.select(_db.syncQueue)
              ..where((t) => t.dedupId.equals(dedupId))
              ..limit(1))
            .getSingleOrNull();
        if (existing != null) return existing.id;
      }

      final now = DateTime.now();
      final id = _uuid.v4();

      await _db.into(_db.syncQueue).insert(
        SyncQueueCompanion.insert(
          id: id,
          type: type.wireValue,
          caseId: caseId,
          sequence: await _nextSequence(caseId),
          payload: jsonEncode(payload),
          idempotencyKey: Value(
            // يُستخدَم المفتاح المُمرَّر إن وُجد — تولَّد لمحاولة إرسال فورية
            // سبقت هذا الاستدعاء ([SyncEngine.trySendImmediately]) وفشلت،
            // فيجب أن يصل الخادم بنفس المفتاح لا بمفتاح جديد (§15.3). وإلا
            // يُولَّد هنا مرة واحدة ولا يتغيّر أبدًا بعدها.
            idempotencyKey ??
                (type.requiresIdempotencyKey ? _uuid.v4() : null),
          ),
          dedupId: Value(dedupId ?? (type.needsLocalDedup ? _uuid.v4() : null)),
          rowVersion: Value(rowVersion),
          createdAt: now,
          updatedAt: now,
        ),
      );

      return id;
    });
  }

  /// يدمج تعديل قسم مع عملية معلّقة سابقة لنفس القسم، إن وُجدت.
  ///
  /// يرجع معرّف العملية المدموجة، أو `null` إن لم يكن هناك ما يُدمَج.
  Future<String?> _tryMergeSectionUpdate({
    required SyncOperationType type,
    required String caseId,
    required Map<String, dynamic> payload,
    int? rowVersion,
  }) async {
    final pending =
        await (_db.select(_db.syncQueue)
              ..where(
                (t) =>
                    t.caseId.equals(caseId) &
                    t.type.equals(type.wireValue) &
                    // عملية قيد الإرسال لا تُدمَج — نتيجتها مجهولة.
                    t.status.isIn(['pending', 'failed']),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.sequence)])
              ..limit(1))
            .getSingleOrNull();

    if (pending == null) return null;

    await (_db.update(_db.syncQueue)..where((t) => t.id.equals(pending.id)))
        .write(
          SyncQueueCompanion(
            payload: Value(jsonEncode(payload)),
            // نحتفظ بأقدم rowVersion: هو الذي يمثّل الحالة التي بنى عليها
            // المستخدم أول تعديل، والخادم سيرفض لو تغيّرت فعلًا من جهة أخرى.
            rowVersion: Value(pending.rowVersion ?? rowVersion),
            status: const Value('pending'),
            attempts: const Value(0),
            lastErrorCode: const Value(null),
            lastErrorMessage: const Value(null),
            nextAttemptAt: const Value(null),
            updatedAt: Value(DateTime.now()),
          ),
        );

    return pending.id;
  }

  Future<int> _nextSequence(String caseId) async {
    final query = _db.selectOnly(_db.syncQueue)
      ..addColumns([_db.syncQueue.sequence.max()])
      ..where(_db.syncQueue.caseId.equals(caseId));
    final row = await query.getSingleOrNull();
    return (row?.read(_db.syncQueue.sequence.max()) ?? 0) + 1;
  }

  /// العمليات الجاهزة للتفريغ، مرتّبة كما يفرضها العقد.
  ///
  /// الترتيب: الحالة (بأقدم عملية) ← الأولوية داخل الحالة ← تسلسل الإنشاء.
  Future<List<SyncOperationRow>> readyOperations({int limit = 50}) {
    final now = DateTime.now();
    return (_db.select(_db.syncQueue)
          ..where(
            (t) =>
                t.status.isIn(['pending', 'failed']) &
                (t.nextAttemptAt.isNull() |
                    t.nextAttemptAt.isSmallerOrEqualValue(now)),
          )
          ..orderBy([
            (t) => OrderingTerm.asc(t.createdAt),
            (t) => OrderingTerm.asc(t.sequence),
          ])
          ..limit(limit))
        .get();
  }

  /// عمليات عالقة في `inFlight` — دليل على موت التطبيق أثناء الإرسال.
  ///
  /// **لا تُعاد إرسالًا أعمى**؛ `SyncEngine` يتحقق من الخادم أولًا، خصوصًا
  /// للزيارات الميدانية التي لا يحرسها أي مفتاح (§14.2).
  Future<List<SyncOperationRow>> stuckInFlight() {
    // مهلة سخية: طلب بطيء على شبكة ضعيفة ليس طلبًا ميتًا.
    final cutoff = DateTime.now().subtract(const Duration(minutes: 10));
    return (_db.select(_db.syncQueue)
          ..where(
            (t) =>
                t.status.equals('in_flight') &
                (t.sentAt.isNull() | t.sentAt.isSmallerThanValue(cutoff)),
          ))
        .get();
  }

  Future<void> markInFlight(String id) =>
      (_db.update(_db.syncQueue)..where((t) => t.id.equals(id))).write(
        SyncQueueCompanion(
          status: const Value('in_flight'),
          sentAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> markSucceeded(String id) =>
      (_db.delete(_db.syncQueue)..where((t) => t.id.equals(id))).go();

  /// يسجّل فشلًا ويقرّر المصير حسب نوع الخطأ.
  ///
  /// - تعارض ← `conflict`، ويتوقّف تفريغ باقي طابور هذه الحالة
  /// - غير قابل لإعادة المحاولة ← `deadLettered`، **لا يُحذَف أبدًا**
  /// - غير ذلك ← `failed` بتباعد أسّي
  Future<SyncOperationStatus> markFailed(
    String id,
    ApiException error,
  ) async {
    final row = await (_db.select(_db.syncQueue)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return SyncOperationStatus.deadLettered;

    final attempts = row.attempts + 1;

    final status = switch (error) {
      _ when error.isConflict => SyncOperationStatus.conflict,
      _ when !error.isRetryable => SyncOperationStatus.deadLettered,
      _ => SyncOperationStatus.failed,
    };

    await (_db.update(_db.syncQueue)..where((t) => t.id.equals(id))).write(
      SyncQueueCompanion(
        status: Value(status.wireValue),
        attempts: Value(attempts),
        lastErrorCode: Value(error.code.wireValue),
        lastErrorMessage: Value(error.displayMessage),
        nextAttemptAt: Value(
          status == SyncOperationStatus.failed
              ? DateTime.now().add(retryBackoff(attempts))
              : null,
        ),
        sentAt: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );

    return status;
  }

  /// هل لهذه الحالة عملية متوقّفة تمنع تفريغ الباقي؟
  ///
  /// تعارض في حالة **لا يوقف** مزامنة حالة أخرى (§2.3، القاعدة ١).
  Future<bool> hasBlockingOperation(String caseId) async {
    final row = await (_db.select(_db.syncQueue)
          ..where(
            (t) =>
                t.caseId.equals(caseId) &
                t.status.isIn(['conflict', 'dead_lettered']),
          )
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }

  Future<List<SyncOperationRow>> operationsForCase(String caseId) =>
      (_db.select(_db.syncQueue)
            ..where((t) => t.caseId.equals(caseId))
            ..orderBy([(t) => OrderingTerm.asc(t.sequence)]))
          .get();

  /// يقرأ عملية واحدة بمعرّفها — تُستخدَم في شاشة حلّ التعارض التي تصل
  /// إليها فقط بمعرّف العملية، لا معرّف الحالة (`watchNeedingAttention`
  /// يفتحها بزر يحمل [SyncOperationRow] كاملة بالفعل).
  Future<SyncOperationRow?> operationById(String id) =>
      (_db.select(_db.syncQueue)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  /// العمليات التي تحتاج تدخّل المستخدم — تغذّي شاشة حالة المزامنة.
  Stream<List<SyncOperationRow>> watchNeedingAttention() =>
      (_db.select(_db.syncQueue)
            ..where((t) => t.status.isIn(['conflict', 'dead_lettered']))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();

  /// ما زال في طريقه للخادم فعلًا — بلا المتوقّف (`conflict`/`dead_lettered`)
  /// الذي لن يُرسَل تلقائيًا أبدًا؛ عدّه هنا كان يُبقي شريط "جارٍ الرفع"
  /// ظاهرًا للأبد رغم الاتصال.
  Stream<int> watchPendingCount() => _watchCount(['pending', 'in_flight', 'failed']);

  Stream<int> watchNeedingAttentionCount() =>
      _watchCount(['conflict', 'dead_lettered']);

  Stream<int> _watchCount(List<String> statuses) {
    final query = _db.selectOnly(_db.syncQueue)
      ..addColumns([_db.syncQueue.id.count()])
      ..where(_db.syncQueue.status.isIn(statuses));
    return query
        .watchSingle()
        .map((row) => row.read(_db.syncQueue.id.count()) ?? 0);
  }

  /// إعادة محاولة عملية متعارضة بعد أن يحلّها المستخدم.
  Future<void> retryAfterResolution(String id, {int? newRowVersion}) =>
      (_db.update(_db.syncQueue)..where((t) => t.id.equals(id))).write(
        SyncQueueCompanion(
          status: const Value('pending'),
          attempts: const Value(0),
          rowVersion: Value(newRowVersion),
          lastErrorCode: const Value(null),
          lastErrorMessage: const Value(null),
          nextAttemptAt: const Value(null),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// يتخلّى عن عملية بناءً على قرار صريح من المستخدم.
  ///
  /// المسار الوحيد المسموح به لحذف عمل غير مُرفَع.
  Future<void> discard(String id) =>
      (_db.delete(_db.syncQueue)..where((t) => t.id.equals(id))).go();

  Map<String, dynamic> decodePayload(SyncOperationRow row) {
    final decoded = jsonDecode(row.payload);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }
}
