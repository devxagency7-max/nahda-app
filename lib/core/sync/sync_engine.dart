import 'dart:async';

import '../../features/cases/data/cases_api.dart';
import '../../features/cases/data/workflow_api.dart';
import '../../features/notifications/data/notifications_api.dart';
import '../network/api_error_code.dart';
import '../network/api_exception.dart';
import '../storage/app_database.dart' show SyncOperationRow;
import 'sync_operation.dart';
import 'sync_queue.dart';

/// نتيجة دورة تفريغ واحدة — لعرضها في شاشة حالة المزامنة أو للتسجيل.
class SyncFlushResult {
  const SyncFlushResult({
    required this.succeeded,
    required this.failed,
    required this.conflicted,
    this.authError,
  });

  final int succeeded;
  final int failed;
  final int conflicted;

  /// غير `null` حين توقّف التفريغ بالكامل لأن الجلسة انتهت — لا فائدة من
  /// محاولة أي عملية أخرى قبل إعادة الدخول (§14.4).
  final ApiException? authError;

  bool get stoppedForAuth => authError != null;

  static const empty = SyncFlushResult(succeeded: 0, failed: 0, conflicted: 0);
}

/// محرّك المزامنة — الجهة الوحيدة التي تُفرّغ [SyncQueueDao] وتستدعي طبقات
/// الشبكة (`*_api.dart`) نيابةً عن الكتابات المؤجَّلة.
///
/// **لماذا هو منفصل عن الـ repositories:** الـ repositories تكتب في Drift
/// وتضع عملية في الطابور فتستجيب الواجهة فورًا؛ هذا الصنف وحده يقرر متى
/// ولماذا تُرسَل تلك العملية فعليًا للخادم، وهو ما يجعل تتبّع كل قواعد
/// العقد (§14) في مكان واحد بدل توزيعها بين كل شاشة.
///
/// **الترتيب الحاكم لكل دورة تفريغ:**
/// 1. التحقق من صلاحية الجلسة **مرة واحدة قبل البدء** — لا لكل عملية (§14.4).
/// 2. تجميع العمليات الجاهزة حسب الحالة (`caseId`).
/// 3. لكل حالة: تخطّيها بالكامل إن كان لديها عملية متوقّفة (`conflict`/
///    `dead_lettered`) — تعارض حالة لا يوقف غيرها (§2.3، القاعدة ١)،
///    لكنه يوقف تفريغ *باقي طابور تلك الحالة نفسها* حتى يُحسَم.
/// 4. داخل الحالة الواحدة: بترتيب `flushPriority` ثم تسلسل الإنشاء —
///    المرفقات (تُدار خارج هذا الطابور، انظر ملاحظة أدناه) ← القبول/الرفض
///    ← الزيارات ← الأقسام ← الرأي أخيرًا.
///
/// **ملاحظة معمارية مهمة:** رفع المرفقات (`AttachmentUploader`) وإرسال
/// الزيارات الميدانية (`FieldVisitsRepository.submit`) لهما منطق تعافٍ خاص
/// بهما أعقد من نمط "أرسل وسجّل النتيجة" العام هنا (مطابقة مع الخادم عند
/// الشك، لا إعادة إرسال أعمى — §14.2). لذلك **لا يُفرّغهما هذا المحرّك
/// مباشرة**؛ [flush] يستدعيهما كخطوة منفصلة قبل تفريغ الطابور العام، فيبقى
/// الترتيب الشامل صحيحًا دون تكرار منطقهما الخاص هنا.
class SyncEngine {
  SyncEngine({
    required SyncQueueDao queue,
    required Future<bool> Function() ensureFreshSession,
    required Future<void> Function(String caseId) uploadAttachmentsForCase,
    required Future<void> Function(String caseId) submitPendingVisitsForCase,
    CasesApi? casesApi,
    WorkflowApi? workflowApi,
    NotificationsApi? notificationsApi,
  }) : _queue = queue,
       _ensureFreshSession = ensureFreshSession,
       _uploadAttachmentsForCase = uploadAttachmentsForCase,
       _submitPendingVisitsForCase = submitPendingVisitsForCase,
       _casesApi = casesApi,
       _workflowApi = workflowApi,
       _notificationsApi = notificationsApi;

  final SyncQueueDao _queue;

  /// يتحقق من صلاحية التوكن ويُجدّده عند الحاجة، ويرجع `false` إن تعذّر ذلك
  /// (الجلسة تحتاج دخولًا جديدًا) — يُمرَّر من الخارج بدل أن يعتمد هذا الصنف
  /// على `AuthController` مباشرة، تجنّبًا لاعتماد دائري بين طبقتَي المزامنة
  /// والمصادقة.
  final Future<bool> Function() _ensureFreshSession;

  final Future<void> Function(String caseId) _uploadAttachmentsForCase;
  final Future<void> Function(String caseId) _submitPendingVisitsForCase;

  /// `null` فقط عند عدم تمرير عميل حقيقي (اختبارات لا تحتاج مسارات الحالات).
  final CasesApi? _casesApi;

  /// `null` فقط عند عدم تمرير عميل حقيقي (اختبارات لا تحتاج سير العمل).
  final WorkflowApi? _workflowApi;

  /// `null` فقط عند عدم تمرير عميل حقيقي (اختبارات لا تحتاج الإشعارات).
  final NotificationsApi? _notificationsApi;

  bool _isFlushing = false;

  /// هل هناك دورة تفريغ قيد التنفيذ الآن؟ لمنع إطلاق دورتين متزامنتين —
  /// تفريغان متوازيان لنفس العملية يعنيان تنفيذًا مزدوجًا محتملًا.
  bool get isFlushing => _isFlushing;

  /// نقطة الدخول الوحيدة. آمنة للاستدعاء من عدة محفّزات في آن واحد (عودة
  /// الاتصال، استئناف التطبيق، زر "زامن الآن") — القفل يجعل الثانية تنتظر.
  Future<SyncFlushResult> flush() async {
    if (_isFlushing) return SyncFlushResult.empty;
    _isFlushing = true;

    try {
      return await _flushLocked();
    } finally {
      _isFlushing = false;
    }
  }

  Future<SyncFlushResult> _flushLocked() async {
    // خطوة صفر: زيارات/مرفقات عالقة من موت سابق للتطبيق — تُطابَق مع الخادم
    // لا تُعاد إرسالًا أعمى (§14.2). يجب أن تسبق أي شيء آخر.
    await _reconcileStuckAttachmentsAndVisits();

    // خطوة واحدة قبل أي شيء يلمس الشبكة: هل الجلسة صالحة؟
    //
    // طابور تراكم على مدى أيام قد يحمل refresh token منتهيًا (٧ أيام،
    // §14.4) — نكتشف ذلك مرة واحدة هنا، لا بعد إهدار محاولات على كل عملية.
    final sessionOk = await _ensureFreshSession();
    if (!sessionOk) {
      return const SyncFlushResult(
        succeeded: 0,
        failed: 0,
        conflicted: 0,
        authError: ApiException(
          code: ApiErrorCode.tokenExpired,
          message: 'انتهت الجلسة. سجّل الدخول لمتابعة رفع التغييرات المعلّقة.',
        ),
      );
    }

    var succeeded = 0;
    var failed = 0;
    var conflicted = 0;

    // الرفع أولًا على مستوى كل الحالات: زيارة تشير لصور غير مُثبَّتة تُرفَض
    // بـ 422 مهما كان ترتيبها داخل طابورها هي.
    final caseIds = await _distinctCaseIdsWithWork();
    for (final caseId in caseIds) {
      await _uploadAttachmentsForCase(caseId);
      await _submitPendingVisitsForCase(caseId);
    }

    // التفريغ العام: كل ما تبقّى في `sync_queue` (أقسام، سير عمل، مفضّلة...).
    // نُعيد القراءة بعد كل عملية بدل تحميل دفعة واحدة، لأن `enqueue` قد
    // يُدمَج مع عملية أخرى أثناء التفريغ (المستخدم يعدّل وهو يتزامن).
    while (true) {
      final batch = await _queue.readyOperations(limit: 50);
      if (batch.isEmpty) break;

      // نجمع حسب الحالة فنحترم "تعارض حالة لا يوقف حالة أخرى" (§2.3)،
      // مع الحفاظ على ترتيب `flushPriority` + تسلسل الإنشاء داخل كل حالة
      // (وهو الترتيب الذي يرجعه `readyOperations` أصلًا).
      final byCase = <String, List<SyncOperationRow>>{};
      for (final op in batch) {
        byCase.putIfAbsent(op.caseId, () => []).add(op);
      }

      var madeProgress = false;

      for (final entry in byCase.entries) {
        final caseId = entry.key;
        final ops = entry.value..sort(_byPriorityThenSequence);

        if (await _queue.hasBlockingOperation(caseId)) continue;

        for (final op in ops) {
          final outcome = await _executeOne(op);

          switch (outcome) {
            case _Outcome.succeeded:
              succeeded++;
              madeProgress = true;
            case _Outcome.conflicted:
              conflicted++;
              madeProgress = true;
            case _Outcome.failed:
              failed++;
              madeProgress = true;
            case _Outcome.skipped:
              // لا تُحتسَب تقدّمًا — نوع بلا مسار تنفيذ سيبقى بنفس الحالة
              // في كل دورة، فاحتسابها كتقدّم يعني حلقة لا نهائية (§ أدناه).
              break;
          }

          // أي نتيجة غير النجاح توقف باقي عمليات *نفس* الحالة فقط —
          // ترتيب flushPriority يفرض ذلك (لا نُرسِل الرأي قبل قسم أقدم لم
          // يُرسَل بعد)، والحالات الأخرى تكمل تفريغها بلا تأثر.
          if (outcome != _Outcome.succeeded) break;
        }
      }

      // دورة كاملة بلا أي تقدّم فعلي (كل الحالات محظورة، فارغة، أو أول
      // عملية فيها من نوع غير موجّه بعد) تعني توقّفًا حقيقيًا لا عابرًا —
      // نخرج بدل حلقة لا نهائية تعيد قراءة نفس العمليات غير المنفَّذة.
      if (!madeProgress) break;
    }

    return SyncFlushResult(
      succeeded: succeeded,
      failed: failed,
      conflicted: conflicted,
    );
  }

  Future<void> _reconcileStuckAttachmentsAndVisits() async {
    final stuckOps = await _queue.stuckInFlight();
    // عمليات الطابور العام العالقة تعود لـ pending بأمان: كلها إمّا محروسة
    // بـ Idempotency-Key (إعادة الإرسال آمنة) أو نتيجتها معروفة عبر
    // rowVersion. الزيارات/المرفقات لها تعافيها الخاص خارج هذا الطابور.
    for (final op in stuckOps) {
      await _queue.retryAfterResolution(op.id, newRowVersion: op.rowVersion);
    }
  }

  Future<List<String>> _distinctCaseIdsWithWork() async {
    final ops = await _queue.readyOperations(limit: 500);
    return ops.map((o) => o.caseId).toSet().toList(growable: false);
  }

  int _byPriorityThenSequence(SyncOperationRow a, SyncOperationRow b) {
    final pa = SyncOperationType.fromWire(a.type).flushPriority;
    final pb = SyncOperationType.fromWire(b.type).flushPriority;
    if (pa != pb) return pa.compareTo(pb);
    return a.sequence.compareTo(b.sequence);
  }

  Future<_Outcome> _executeOne(SyncOperationRow op) async {
    final type = SyncOperationType.fromWire(op.type);

    // **لا تُمَسّ** — لا `markInFlight` ولا `markFailed`. هذا ليس فشلًا:
    // هو غياب كود التنفيذ نفسه (المرحلة ٢ من خطة الربط لم تُنجَز بعد).
    // توجيهها عبر `markFailed` كان سيُصنَّفها `dead_lettered` (خطأ محلي غير
    // قابل لإعادة المحاولة وفق `ApiErrorCode.internalError.isRetryable`)
    // فتُحبَط بصفة نهائية عملية أخصائي صالحة تمامًا لمجرد أن الكود الذي
    // يرسلها لم يُكتَب بعد — وهي بالضبط الفئة التي لا يجوز أن تُحذَف تلقائيًا.
    if (!_isWired(type)) return _Outcome.skipped;

    await _queue.markInFlight(op.id);

    try {
      await _dispatch(op, type);
      await _queue.markSucceeded(op.id);
      return _Outcome.succeeded;
    } on ApiException catch (e) {
      final status = await _queue.markFailed(op.id, e);
      return status == SyncOperationStatus.conflict
          ? _Outcome.conflicted
          : _Outcome.failed;
    }
  }

  /// هل يملك هذا النوع اليوم دالة شبكة فعلية يستدعيها [_dispatch]؟
  ///
  /// المفضّلة (منذ المرحلة ١)، وأقسام الحالة التسعة + سير العمل الثلاثي
  /// المتاح لـ `social_worker` (منذ المرحلة ٢)، وإشعارَي القراءة (منذ إكمال
  /// شاشة الإشعارات) — كلها لها دالة في `CasesApi`/`WorkflowApi`/
  /// `NotificationsApi` الآن. المرفقات والزيارات الميدانية **لا** تمرّ من
  /// هنا أصلًا (تُدار خارج هذا الطابور، انظر تعليق الصنف)، وباقي سير العمل
  /// (assign, opinions/reviewer, …) لا يصله هذا الدور فلم يُدرَج هنا.
  bool _isWired(SyncOperationType type) => switch (type) {
    SyncOperationType.bookmarkCase ||
    SyncOperationType.unbookmarkCase ||
    SyncOperationType.updateBeneficiary ||
    SyncOperationType.updateFamilyMembers ||
    SyncOperationType.updateHousing ||
    SyncOperationType.updateUtilities ||
    SyncOperationType.updateAgriculture ||
    SyncOperationType.updateFinancial ||
    SyncOperationType.updateInitialNeeds ||
    SyncOperationType.updateClassification ||
    SyncOperationType.updateAssessedNeeds ||
    SyncOperationType.acceptCase ||
    SyncOperationType.rejectAssignment ||
    SyncOperationType.submitWorkerOpinion ||
    SyncOperationType.markNotificationRead ||
    SyncOperationType.markAllNotificationsRead => true,
    _ => false,
  };

  /// يوجّه عملية طابور واحدة **مدعومة بالفعل** لاستدعاء الشبكة المطابق لها.
  ///
  /// يُستدعى بعد أن يتأكد [_executeOne] من [_isWired] — الأنواع غير
  /// المدعومة لا تصل هنا إطلاقًا، فلا حاجة لحالة "افتراضي" ترمي خطأ.
  Future<void> _dispatch(SyncOperationRow op, SyncOperationType type) async {
    final payload = _queue.decodePayload(op);

    switch (type) {
      case SyncOperationType.bookmarkCase:
        await _requireCasesApi().addBookmark(op.caseId);
      case SyncOperationType.unbookmarkCase:
        await _requireCasesApi().removeBookmark(op.caseId);
      case SyncOperationType.updateBeneficiary:
        await _requireCasesApi().updateBeneficiary(op.caseId, payload);
      case SyncOperationType.updateFamilyMembers:
        await _requireCasesApi().updateFamilyMembers(op.caseId, payload);
      case SyncOperationType.updateHousing:
        await _requireCasesApi().updateHousing(op.caseId, payload);
      case SyncOperationType.updateUtilities:
        await _requireCasesApi().updateUtilities(op.caseId, payload);
      case SyncOperationType.updateAgriculture:
        await _requireCasesApi().updateAgriculture(op.caseId, payload);
      case SyncOperationType.updateFinancial:
        await _requireCasesApi().updateFinancial(op.caseId, payload);
      case SyncOperationType.updateInitialNeeds:
        await _requireCasesApi().updateInitialNeeds(op.caseId, payload);
      case SyncOperationType.updateClassification:
        await _requireCasesApi().updateClassification(op.caseId, payload);
      case SyncOperationType.updateAssessedNeeds:
        await _requireCasesApi().updateAssessedNeeds(op.caseId, payload);
      case SyncOperationType.acceptCase:
        await _requireWorkflowApi().accept(
          op.caseId,
          payload,
          idempotencyKey: _requireIdempotencyKey(op),
        );
      case SyncOperationType.rejectAssignment:
        await _requireWorkflowApi().rejectAssignment(
          op.caseId,
          payload,
          idempotencyKey: _requireIdempotencyKey(op),
        );
      case SyncOperationType.submitWorkerOpinion:
        await _requireWorkflowApi().submitWorkerOpinion(
          op.caseId,
          payload,
          idempotencyKey: _requireIdempotencyKey(op),
        );
      case SyncOperationType.markNotificationRead:
        // `op.caseId` هنا معرّف الإشعار نفسه، لا حالة — راجع
        // `NotificationsRepository.markRead` (لا caseId حقيقي لعملية إشعار).
        await _requireNotificationsApi().markRead(op.caseId);
      case SyncOperationType.markAllNotificationsRead:
        await _requireNotificationsApi().markAllRead();
      default:
        // لا يُصَل إليه أبدًا بفضل حارس [_isWired] في [_executeOne] —
        // موجود فقط ليبقى `switch` شاملًا دون تكرار كل الحالات هنا.
        throw StateError('نوع غير موجّه: ${type.wireValue}');
    }
  }

  CasesApi _requireCasesApi() {
    final api = _casesApi;
    if (api == null) {
      throw const ApiException(
        code: ApiErrorCode.internalError,
        message: 'خطأ إعداد داخلي: CasesApi غير متاح لمحرّك المزامنة.',
      );
    }
    return api;
  }

  WorkflowApi _requireWorkflowApi() {
    final api = _workflowApi;
    if (api == null) {
      throw const ApiException(
        code: ApiErrorCode.internalError,
        message: 'خطأ إعداد داخلي: WorkflowApi غير متاح لمحرّك المزامنة.',
      );
    }
    return api;
  }

  NotificationsApi _requireNotificationsApi() {
    final api = _notificationsApi;
    if (api == null) {
      throw const ApiException(
        code: ApiErrorCode.internalError,
        message: 'خطأ إعداد داخلي: NotificationsApi غير متاح لمحرّك المزامنة.',
      );
    }
    return api;
  }

  /// مسارات سير العمل تتطلب `Idempotency-Key` دومًا (§6) — [SyncQueueDao]
  /// يولّده عند `enqueue` لكل نوع `requiresIdempotencyKey`، فغيابه هنا يعني
  /// خللًا في طبقة الكتابة نفسها، لا حالة شبكة عادية.
  String _requireIdempotencyKey(SyncOperationRow op) {
    final key = op.idempotencyKey;
    if (key == null || key.isEmpty) {
      throw const ApiException(
        code: ApiErrorCode.internalError,
        message: 'خطأ إعداد داخلي: عملية سير عمل بلا Idempotency-Key.',
      );
    }
    return key;
  }

  /// يُستدعى مرة عند الإقلاع، بعد التعافي من الزيارات العالقة وقبل أي
  /// تفريغ — لا يفعل شيئًا اليوم غير التأكد من عدم وجود قفل معلّق من جلسة
  /// سابقة (الذاكرة لا تُخزَّن، فهذا فعليًا ضمان توثيقي).
  void resetForNewSession() {
    _isFlushing = false;
  }
}

enum _Outcome { succeeded, failed, conflicted, skipped }
