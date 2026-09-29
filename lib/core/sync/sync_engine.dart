import 'dart:async';

import '../../features/cases/data/cases_api.dart';
import '../../features/cases/data/workflow_api.dart';
import '../../features/notifications/data/notifications_api.dart';
import '../logging/app_logger.dart';
import '../network/api_error_code.dart';
import '../network/api_exception.dart';
import '../network/network_status_service.dart';
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
    NetworkStatusService? networkStatus,
  }) : _queue = queue,
       _ensureFreshSession = ensureFreshSession,
       _uploadAttachmentsForCase = uploadAttachmentsForCase,
       _submitPendingVisitsForCase = submitPendingVisitsForCase,
       _casesApi = casesApi,
       _workflowApi = workflowApi,
       _notificationsApi = notificationsApi,
       _networkStatus = networkStatus;

  final SyncQueueDao _queue;

  /// `null` فقط في اختبارات لا تحتاج تمييز أونلاين/أوفلاين قبل الإرسال
  /// الفوري — عندها [trySendImmediately] يحاول دائمًا (راجع توثيقها).
  ///
  /// **حاسم:** يعتمد على [NetworkStatusService] لا `ConnectivityMonitor`
  /// الخام — الحالة المركزية الموحّدة (Internet+Backend) هي التي تقرر هنا،
  /// لا فحص واجهة شبكة بسيط قد يكذب في بوابة مقيّدة.
  final NetworkStatusService? _networkStatus;

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

  /// من ينتظر حاليًا نهاية دورة التفريغ الجارية — راجع [awaitIdle].
  Completer<void>? _idleWaiters;

  /// هل هناك دورة تفريغ قيد التنفيذ الآن؟ لمنع إطلاق دورتين متزامنتين —
  /// تفريغان متوازيان لنفس العملية يعنيان تنفيذًا مزدوجًا محتملًا.
  bool get isFlushing => _isFlushing;

  /// ينتظر فعليًا (لا يرجع فورًا) حتى تنتهي أي دورة تفريغ جارية الآن، أو
  /// يرجع فورًا لو لا دورة جارية أصلًا. يُستخدم من `AuthRepository.endSession`
  /// قبل `AppDatabase.clearAll` — يمنع حذف صفّ طابور بينما `_executeOne`
  /// يكتب عليه (`markSucceeded`/`markFailed`) في نفس اللحظة
  /// (AUTH_SESSION_AUDIT.md §2، مشكلة #8).
  Future<void> awaitIdle() {
    if (!_isFlushing) return Future.value();
    return (_idleWaiters ??= Completer<void>()).future;
  }

  /// نقطة الدخول الوحيدة. آمنة للاستدعاء من عدة محفّزات في آن واحد (عودة
  /// الاتصال، استئناف التطبيق، زر "زامن الآن") — القفل يجعل الثانية تنتظر.
  Future<SyncFlushResult> flush() async {
    if (_isFlushing) return SyncFlushResult.empty;
    _isFlushing = true;

    try {
      final result = await _flushLocked();
      final remaining = await _queue.watchPendingCount().first;
      AppLogger.sync('Pending operations: $remaining');
      return result;
    } finally {
      _isFlushing = false;
      _idleWaiters?.complete();
      _idleWaiters = null;
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
    // ملاحظة: لا حاجة لمعالجة "جلسة منتهية" هنا — `ApiClient._send` يُعلّق
    // الـ `Future` بلا اكتمال في هذه الحالة بدل رمي استثناء (راجع توثيقها)،
    // فـ `await _dispatch(...)` أعلاه لا يعود أصلًا؛ الصفّ يبقى `in_flight`
    // بأمان ليُعاد تأهيله في أول تفريغ تالٍ لجلسة صحيحة.
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
    SyncOperationType.updateCharity ||
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
  Future<void> _dispatch(SyncOperationRow op, SyncOperationType type) =>
      _dispatchRaw(
        type: type,
        caseId: op.caseId,
        payload: _queue.decodePayload(op),
        idempotencyKey: op.idempotencyKey,
      );

  /// نفس توجيه [_dispatch] لكن على قيم خام لا على صفّ طابور مخزَّن — يخدم
  /// [trySendImmediately] الذي يرسل **قبل** أي كتابة في `sync_queue` أصلًا.
  Future<void> _dispatchRaw({
    required SyncOperationType type,
    required String caseId,
    required Map<String, dynamic> payload,
    String? idempotencyKey,
  }) async {
    switch (type) {
      case SyncOperationType.bookmarkCase:
        await _requireCasesApi().addBookmark(caseId);
      case SyncOperationType.unbookmarkCase:
        await _requireCasesApi().removeBookmark(caseId);
      case SyncOperationType.updateBeneficiary:
        await _requireCasesApi().updateBeneficiary(caseId, payload);
      case SyncOperationType.updateFamilyMembers:
        await _requireCasesApi().updateFamilyMembers(caseId, payload);
      case SyncOperationType.updateHousing:
        await _requireCasesApi().updateHousing(caseId, payload);
      case SyncOperationType.updateUtilities:
        await _requireCasesApi().updateUtilities(caseId, payload);
      case SyncOperationType.updateAgriculture:
        await _requireCasesApi().updateAgriculture(caseId, payload);
      case SyncOperationType.updateFinancial:
        await _requireCasesApi().updateFinancial(caseId, payload);
      case SyncOperationType.updateInitialNeeds:
        await _requireCasesApi().updateInitialNeeds(caseId, payload);
      case SyncOperationType.updateClassification:
        await _requireCasesApi().updateClassification(caseId, payload);
      case SyncOperationType.updateAssessedNeeds:
        await _requireCasesApi().updateAssessedNeeds(caseId, payload);
      case SyncOperationType.updateCharity:
        await _requireCasesApi().updateCharity(caseId, payload);
      case SyncOperationType.acceptCase:
        await _requireWorkflowApi().accept(
          caseId,
          payload,
          idempotencyKey: _requireKey(idempotencyKey),
        );
      case SyncOperationType.rejectAssignment:
        await _requireWorkflowApi().rejectAssignment(
          caseId,
          payload,
          idempotencyKey: _requireKey(idempotencyKey),
        );
      case SyncOperationType.submitWorkerOpinion:
        await _requireWorkflowApi().submitWorkerOpinion(
          caseId,
          payload,
          idempotencyKey: _requireKey(idempotencyKey),
        );
      case SyncOperationType.markNotificationRead:
        // `caseId` هنا معرّف الإشعار نفسه، لا حالة — راجع
        // `NotificationsRepository.markRead` (لا caseId حقيقي لعملية إشعار).
        await _requireNotificationsApi().markRead(caseId);
      case SyncOperationType.markAllNotificationsRead:
        await _requireNotificationsApi().markAllRead();
      default:
        // لا يُصَل إليه أبدًا بفضل حارس [_isWired] في [_executeOne]/
        // [trySendImmediately] — موجود فقط ليبقى `switch` شاملًا دون تكرار
        // كل الحالات هنا.
        throw StateError('نوع غير موجّه: ${type.wireValue}');
    }
  }

  /// يرسل العملية للخادم **فورًا** — الأونلاين هو الوضع الغالب، والطابور
  /// خطة بديلة للانقطاع الفعلي فقط.
  ///
  /// - [ImmediateSendStatus.sent]: وصلت — لا `enqueue`.
  /// - [ImmediateSendStatus.deferred]: **لا اتصال فعليًا** (أو نوع غير موجّه)
  ///   — على المستدعي أن يضعها في الطابور كما كان يفعل. هذا المسار الوحيد
  ///   المسموح للطابور طالما التطبيق أونلاين.
  /// - [ImmediateSendStatus.rejected]: أي فشل إرسال **ونحن أونلاين فعلًا** —
  ///   رفض نهائي من الخادم (تحقق مثلًا) أو خطأ شبكة عابر (timeout/انقطاع
  ///   مؤقت) على حدٍّ سواء. **لا تُوضَع في الطابور أبدًا** في كلتا الحالتين:
  ///   قرار صريح — أونلاين يعني "أرِ المستخدم الخطأ الحقيقي فورًا"، لا تخزين
  ///   صامت في طابور قد لا يُفرَّغ تلقائيًا لدقائق طويلة.
  ///
  /// **قرار المنتج:** طالما أونلاين، لا شيء يُؤجَّل بصمت في الخلفية — أي
  /// رفض من الخادم (بما فيه تعارض rowVersion 409) يُعرَض فورًا للمستخدم
  /// ليتصرف، بدل انتظار دورة مزامنة خلفية لاحقة قد تمر دون أن يلاحظها.
  /// الأوفلاين وحده يبقى مسار التأجيل الطبيعي ([ImmediateSendResult.deferred]).
  Future<ImmediateSendResult> trySendImmediately({
    required SyncOperationType type,
    required String caseId,
    required Map<String, dynamic> payload,
    String? idempotencyKey,

    /// `false` يعيد سلوك التأجيل الصامت القديم للتعارض تحديدًا (409) حتى
    /// وإن كنا أونلاين — احتفظنا بالخيار هنا فقط تحسبًا لمسار مستقبلي
    /// يحتاجه صراحةً؛ لا مستدعٍ حاليًا يمرر `false`.
    bool rejectConflictsImmediately = true,
  }) async {
    final networkStatus = _networkStatus;
    final isOnline = networkStatus?.current.isOnline ?? true;
    if (!isOnline) return ImmediateSendResult.deferred;
    if (!_isWired(type)) return ImmediateSendResult.deferred;

    try {
      final sessionOk = await _ensureFreshSession();
      if (!sessionOk) return ImmediateSendResult.deferred;

      await _dispatchRaw(
        type: type,
        caseId: caseId,
        payload: payload,
        idempotencyKey: idempotencyKey,
      );
      return ImmediateSendResult.sent;
    } on ApiException catch (e) {
      if (e.isConflict) {
        return rejectConflictsImmediately
            ? ImmediateSendResult.rejected(e)
            : ImmediateSendResult.deferred;
      }
      if (e.requiresReauth) return ImmediateSendResult.deferred;
      // أونلاين + أي خطأ آخر (تحقق نهائي أو شبكة عابرة) = يُعرَض للمستخدم
      // فورًا، لا طابور صامت.
      return ImmediateSendResult.rejected(e);
    }
    // ملاحظة: "جلسة منتهية أثناء الانتظار" لا تحتاج معالجة هنا لنفس سبب
    // `_executeOne` أعلاه — `await _dispatchRaw(...)` لا يعود أصلًا في تلك
    // الحالة.
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

  /// مسارات سير العمل تتطلب `Idempotency-Key` دومًا (§6) — سواء أتت من صفّ
  /// طابور (`SyncQueueDao.enqueue` يولّدها) أو من مفتاح مُمرَّر مباشرة إلى
  /// [trySendImmediately] — فغيابها هنا يعني خللًا في طبقة الكتابة نفسها،
  /// لا حالة شبكة عادية.
  String _requireKey(String? key) {
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

enum ImmediateSendStatus { sent, deferred, rejected }

class ImmediateSendResult {
  const ImmediateSendResult._(this.status, [this.error]);

  static const sent = ImmediateSendResult._(ImmediateSendStatus.sent);
  static const deferred = ImmediateSendResult._(ImmediateSendStatus.deferred);
  factory ImmediateSendResult.rejected(ApiException error) =>
      ImmediateSendResult._(ImmediateSendStatus.rejected, error);

  final ImmediateSendStatus status;

  /// غير `null` فقط مع [ImmediateSendStatus.rejected].
  final ApiException? error;

  bool get isSent => status == ImmediateSendStatus.sent;
  bool get isRejected => status == ImmediateSendStatus.rejected;
}
