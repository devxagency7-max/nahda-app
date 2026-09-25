import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/api_error_code.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/sync/sync_operation.dart';
import '../../attachments/data/attachment_uploader.dart';
import 'field_visits_api.dart';

const _uuid = Uuid();

/// نتيجة محاولة إرسال زيارة.
sealed class VisitSubmitResult {
  const VisitSubmitResult();
}

class VisitSubmitted extends VisitSubmitResult {
  const VisitSubmitted(this.serverId);
  final String serverId;
}

/// حُفِظت محليًا وستُرسَل حين تعود الشبكة.
class VisitQueued extends VisitSubmitResult {
  const VisitQueued(this.localId);
  final String localId;
}

class VisitFailed extends VisitSubmitResult {
  const VisitFailed(this.error);
  final ApiException error;
}

/// مستودع الزيارات الميدانية.
///
/// ⚠️ **يحمل أثقل ضمان في التطبيق: إرسال الزيارة مرة واحدة بالضبط.**
///
/// `POST /field-visits` يقبل `Idempotency-Key` اختياريًا الآن (`BACKEND_
/// CHANGE_RESPONSE.md`، طلب 4) — حماية خادمية حقيقية بالإضافة للحماية
/// المحلية، لا بديلًا عنها: هي وحدها لا تكفي (لو مات التطبيق قبل حفظ
/// `inFlight` أصلًا، أو أُعيد تثبيته فقد `dedupId` المحلي). السيناريو القاتل
/// يبقى واردًا: الأخصائي يضغط حفظ، الطلب يصل، الردّ يضيع. أي قرار أعمى
/// بعدها خاطئ — إعادة الإرسال بلا مفتاح تُنشئ زيارة مكررة، وعدم الإرسال
/// يفقد الزيارة.
///
/// الحماية رباعية الآن:
/// 1. `dedupId` دائم يُولَّد مرة واحدة عند الإنشاء، ويُرسَل كـ
///    `Idempotency-Key` — الخادم نفسه يمنع التكرار عند نفس المفتاح.
/// 2. تعليم `inFlight` **قبل** الإرسال ويُحفَظ في القرص.
/// 3. عند الإقلاع، أي زيارة عالقة تُطابَق مع زيارات الخادم قبل أي قرار.
/// 4. (دفاع أخير) حتى بلا (1)، مطابقة (3) تبقى خط الدفاع لو تغيّر الجهاز.
class FieldVisitsRepository {
  FieldVisitsRepository({
    required FieldVisitsApi api,
    required AppDatabase db,
    required AttachmentUploader uploader,
  }) : _api = api,
       _db = db,
       _uploader = uploader;

  final FieldVisitsApi _api;
  final AppDatabase _db;
  final AttachmentUploader _uploader;

  // ───────────────────────── الإنشاء ─────────────────────────

  /// ينشئ زيارة **محليًا فقط**. لا شبكة إطلاقًا.
  ///
  /// ينجح دائمًا — الأخصائي في الميدان لا يُمنَع من تسجيل زيارة لانقطاع الشبكة.
  Future<String> createLocal({
    required String caseId,
    required DateTime visitDate,
    required String outcome,
    DateTime? startTime,
    DateTime? endTime,
    double? latitude,
    double? longitude,
    String? locationDescription,
    String? status,
    String? notes,
    String? description,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    // الإحداثيات معًا أو لا شيء — نُسقِط الناقص هنا لا عند الإرسال (§15.10).
    final hasBoth = latitude != null && longitude != null;

    await _db
        .into(_db.localFieldVisits)
        .insert(
          LocalFieldVisitsCompanion.insert(
            id: id,
            caseId: caseId,
            // يُولَّد مرة واحدة ولا يتغيّر مدى حياة الزيارة.
            dedupId: _uuid.v4(),
            visitDate: _formatDate(visitDate),
            startTimeUtc: Value(startTime?.toUtc()),
            endTimeUtc: Value(endTime?.toUtc()),
            latitude: Value(hasBoth ? latitude : null),
            longitude: Value(hasBoth ? longitude : null),
            locationDescription: Value(locationDescription),
            outcome: outcome,
            visitStatus: Value(status),
            notes: Value(notes),
            description: Value(description),
            createdAt: now,
            updatedAt: now,
          ),
        );

    return id;
  }

  /// يحدّث حقول زيارة **لم تُرفَع للخادم بعد** (لا `serverId`).
  ///
  /// يُستخدَم من نموذج الزيارة عند تعديل مسوَّدة قبل الحفظ النهائي. لا يمسّ
  /// زيارة أُرسِلت بنجاح أصلًا — تعديل زيارة مرفوعة يتطلّب `PUT
  /// /field-visits/{id}` عبر [FieldVisitsApi.update]، غير مربوط بعد بواجهة
  /// (راجع طلب الباك إند الجديد حول قيد `SocialWorkerId` على التعديل).
  Future<void> updateLocalFields(
    String id, {
    DateTime? visitDate,
    String? outcome,
    DateTime? startTime,
    DateTime? endTime,
    double? latitude,
    double? longitude,
    String? locationDescription,
    String? status,
    String? notes,
    String? description,
  }) async {
    final visit = await _read(id);
    if (visit == null || visit.serverId != null) return;

    final hasBoth = latitude != null && longitude != null;

    await _update(
      id,
      LocalFieldVisitsCompanion(
        visitDate: visitDate != null
            ? Value(_formatDate(visitDate))
            : const Value.absent(),
        outcome: outcome != null ? Value(outcome) : const Value.absent(),
        startTimeUtc: startTime != null
            ? Value(startTime.toUtc())
            : const Value.absent(),
        endTimeUtc: endTime != null
            ? Value(endTime.toUtc())
            : const Value.absent(),
        latitude: Value(hasBoth ? latitude : null),
        longitude: Value(hasBoth ? longitude : null),
        locationDescription: Value(locationDescription),
        visitStatus: status != null ? Value(status) : const Value.absent(),
        notes: Value(notes),
        description: Value(description),
      ),
    );
  }

  /// يربط مرفقًا ملتقطًا بزيارة.
  Future<void> attachPhoto(String visitLocalId, String attachmentLocalId) async {
    final visit = await _read(visitLocalId);
    if (visit == null) return;

    final ids = _decodeIds(visit.localAttachmentIdsJson);
    if (ids.contains(attachmentLocalId)) return;

    await _update(
      visitLocalId,
      LocalFieldVisitsCompanion(
        localAttachmentIdsJson: Value(jsonEncode([...ids, attachmentLocalId])),
      ),
    );
  }

  // ───────────────────────── الإرسال ─────────────────────────

  /// يرسل زيارة للخادم بضمان المرة الواحدة.
  ///
  /// يرفع الصور أولًا لأن `photoAttachmentIds` يقبل المُثبَّت فقط.
  Future<VisitSubmitResult> submit(String localId) async {
    final visit = await _read(localId);
    if (visit == null) {
      return const VisitFailed(
        ApiException(code: ApiErrorCode.notFound, message: 'الزيارة غير موجودة.'),
      );
    }

    // أُرسِلت من قبل — لا إرسال ثانٍ.
    if (visit.serverId != null) return VisitSubmitted(visit.serverId!);

    // عالقة من محاولة سابقة ماتت — نتحقق من الخادم قبل أي قرار.
    if (visit.syncState == SyncState.syncing.name) {
      final recovered = await _recoverStuckVisit(visit);
      if (recovered != null) return VisitSubmitted(recovered);
    }

    // الصور قبل الزيارة: الخادم يرفض معرّفات مرفقات غير مُثبَّتة.
    final photosReady = await _uploader.uploadAllForCase(visit.caseId);
    if (!photosReady) {
      await _markState(localId, SyncState.pendingSync);
      return VisitQueued(localId);
    }

    final photoIds = await _uploader.committedIdsForVisit(localId);

    // نُعلِّم قبل الإرسال ونحفظ فورًا — هذه العلامة هي ما يُنقذنا لو مات
    // التطبيق في السطر التالي.
    await _markState(localId, SyncState.syncing);

    try {
      final response = await _api.create(
        caseId: visit.caseId,
        visitDate: visit.visitDate,
        outcome: visit.outcome,
        startTimeUtc: visit.startTimeUtc,
        endTimeUtc: visit.endTimeUtc,
        latitude: visit.latitude,
        longitude: visit.longitude,
        locationDescription: visit.locationDescription,
        status: visit.visitStatus,
        notes: visit.notes,
        description: visit.description,
        photoAttachmentIds: photoIds,
        // §BACKEND_CHANGE_RESPONSE.md طلب 4: مفتاح واحد يُولَّد وقت إنشاء
        // الزيارة (`dedupId`) ويُعاد استخدامه حرفيًا في كل محاولة — توليد
        // مفتاح جديد لكل محاولة يُبطل الحماية من أساسها.
        idempotencyKey: visit.dedupId,
      );

      final serverId = response['id'] as String?;
      await _update(
        localId,
        LocalFieldVisitsCompanion(
          serverId: Value(serverId),
          rowVersion: Value(_int(response['rowVersion'])),
          syncState: Value(SyncState.synced.name),
        ),
      );

      return VisitSubmitted(serverId ?? '');
    } on ApiException catch (e) {
      // فشل شبكة: النتيجة **مجهولة**، لا فاشلة. نُبقيها `syncing` حتى يتحقق
      // مسار التعافي من الخادم — إعادة الإرسال أعمى هنا هي مصدر التكرار.
      if (e.isRetryable) {
        return VisitQueued(localId);
      }

      // رفض صريح من الخادم: لم تُنشأ زيارة، آمن أن نعيدها للانتظار.
      await _markState(
        localId,
        e.isConflict ? SyncState.conflict : SyncState.failed,
      );
      return VisitFailed(e);
    }
  }

  /// يتعافى من زيارة عالقة: هل وصلت للخادم أم لا؟
  ///
  /// يرجع معرّف الخادم إن ثبت وصولها، و`null` إن لم تصل (فيصحّ الإرسال).
  Future<String?> _recoverStuckVisit(FieldVisitRow visit) async {
    try {
      final remote = await _api.listForCase(visit.caseId);

      // لا معرّف مشترك نطابق به (الخادم لا يعرف `dedupId`)، فنطابق بالسمات:
      // نفس التاريخ + نفس النتيجة = الزيارة نفسها بدرجة ثقة عالية.
      for (final item in remote) {
        if (item['visitDate'] == visit.visitDate &&
            item['outcome'] == visit.outcome) {
          final serverId = item['id'] as String?;
          if (serverId == null) continue;

          await _update(
            visit.id,
            LocalFieldVisitsCompanion(
              serverId: Value(serverId),
              rowVersion: Value(_int(item['rowVersion'])),
              syncState: Value(SyncState.synced.name),
            ),
          );
          return serverId;
        }
      }

      // لم نجدها — لم تصل، فالإرسال آمن.
      return null;
    } on ApiException {
      // تعذّر التحقق: **لا نرسل**. زيارة متأخرة أهون من زيارة مكررة في سجل رسمي.
      return null;
    }
  }

  /// يفحص الزيارات العالقة عند إقلاع التطبيق.
  ///
  /// يُستدعى مرة واحدة بعد استعادة الجلسة وقبل أي تفريغ للطابور.
  Future<void> reconcileStuckVisits() async {
    final stuck =
        await (_db.select(_db.localFieldVisits)..where(
              (t) =>
                  t.syncState.equals(SyncState.syncing.name) &
                  t.serverId.isNull(),
            ))
            .get();

    for (final visit in stuck) {
      final serverId = await _recoverStuckVisit(visit);
      if (serverId == null) {
        // لم تصل ولم نتمكّن من التأكد — تعود للانتظار لتُرسَل بوعي لاحقًا.
        await _markState(visit.id, SyncState.pendingSync);
      }
    }
  }

  // ───────────────────────── القراءة ─────────────────────────

  Stream<List<FieldVisitRow>> watchForCase(String caseId) =>
      (_db.select(_db.localFieldVisits)
            ..where((t) => t.caseId.equals(caseId))
            ..orderBy([(t) => OrderingTerm.desc(t.visitDate)]))
          .watch();

  Future<List<FieldVisitRow>> pendingVisits() =>
      (_db.select(_db.localFieldVisits)..where(
            (t) => t.syncState.isNotIn([SyncState.synced.name]),
          ))
          .get();

  /// زيارات في حالة `conflict` — تحتاج قرار المستخدم عبر شاشة التعارض
  /// (§14.3). **لا** تمرّ بـ `sync_queue`؛ لهذا مصدر مستقل هنا.
  Stream<List<FieldVisitRow>> watchConflicted() =>
      (_db.select(_db.localFieldVisits)
            ..where((t) => t.syncState.equals(SyncState.conflict.name))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();

  /// يعيد زيارة متعارضة لحالة `pendingSync` — بعد أن يقرّر المستخدم
  /// "احتفظ بقيمتي" في شاشة التعارض. لا `rowVersion` جديدًا هنا لأن
  /// `POST /field-visits` لا يحمل `rowVersion` أصلًا (إنشاء، لا تعديل).
  Future<void> retryAfterResolution(String id) =>
      _markState(id, SyncState.pendingSync);

  /// يتخلّى عن زيارة محلية لم تصل للخادم — المسار الوحيد المسموح به لحذف
  /// عمل غير مرفوع (نمط `SyncQueueDao.discard`). يُستخدَم عند اختيار
  /// "خذ قيمة الخادم" في شاشة التعارض.
  Future<void> discard(String id) =>
      (_db.delete(_db.localFieldVisits)..where((t) => t.id.equals(id))).go();

  Future<FieldVisitRow?> _read(String id) =>
      (_db.select(_db.localFieldVisits)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  // ───────────────────────── مساعدات ─────────────────────────

  Future<void> _update(String id, LocalFieldVisitsCompanion changes) =>
      (_db.update(_db.localFieldVisits)..where((t) => t.id.equals(id))).write(
        changes.copyWith(updatedAt: Value(DateTime.now())),
      );

  Future<void> _markState(String id, SyncState state) =>
      _update(id, LocalFieldVisitsCompanion(syncState: Value(state.name)));

  List<String> _decodeIds(String json) {
    final decoded = jsonDecode(json);
    return decoded is List
        ? decoded.whereType<String>().toList(growable: false)
        : const [];
  }

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static int? _int(Object? v) => switch (v) {
    final int i => i,
    final num n => n.toInt(),
    _ => null,
  };
}
