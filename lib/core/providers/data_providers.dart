import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/attachments/data/attachment_uploader.dart';
import '../../features/attachments/data/attachments_api.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/cases/data/cases_api.dart';
import '../../features/cases/data/cases_repository.dart';
import '../../features/cases/data/workflow_api.dart';
import '../../features/field_visits/data/field_visits_api.dart';
import '../../features/field_visits/data/field_visits_repository.dart';
import '../../features/notifications/data/notifications_api.dart';
import '../../features/notifications/data/notifications_repository.dart';
import '../../features/reference/data/reference_api.dart';
import '../../features/reference/data/reference_repository.dart';
import '../storage/app_database.dart';
import '../sync/startup_service.dart';
import '../sync/sync_engine.dart';
import 'app_providers.dart';

/// مزوّدات طبقة البيانات.
///
/// تُبنى فوق [apiClientProvider] و [appDatabaseProvider] في `app_providers.dart`.

// ───────────────────────── الحالات ─────────────────────────

final casesApiProvider = Provider<CasesApi>(
  (ref) => CasesApi(ref.watch(apiClientProvider)),
);

final workflowApiProvider = Provider<WorkflowApi>(
  (ref) => WorkflowApi(ref.watch(apiClientProvider)),
);

final casesRepositoryProvider = Provider<CasesRepository>(
  (ref) => CasesRepository(
    api: ref.watch(casesApiProvider),
    db: ref.watch(appDatabaseProvider),
    queue: ref.watch(syncQueueProvider),
    syncEngine: ref.watch(syncEngineProvider),
    networkStatus: ref.watch(networkStatusServiceProvider),
  ),
);

/// طابور عمل الأخصائي — Online-First: يجلب من الخادم مباشرة عند توفّر
/// الاتصال، ويقع على الكاش المحلي فقط عند الأوفلاين أو فشل الشبكة.
final workQueueProvider = FutureProvider<List<CachedCaseRow>>(
  (ref) => ref.watch(casesRepositoryProvider).getWorkQueue(),
);

final bookmarkedCasesProvider = StreamProvider<List<CachedCaseRow>>(
  (ref) => ref.watch(casesRepositoryProvider).watchBookmarked(),
);

final returnedCasesProvider = StreamProvider<List<CachedCaseRow>>(
  (ref) => ref.watch(casesRepositoryProvider).watchReturned(),
);

final caseByIdProvider = StreamProvider.family<CachedCaseRow?, String>(
  (ref, caseId) => ref.watch(casesRepositoryProvider).watchCase(caseId),
);

// ───────────────────────── البيانات المرجعية ─────────────────────────

final referenceApiProvider = Provider<ReferenceApi>(
  (ref) => ReferenceApi(ref.watch(apiClientProvider)),
);

final referenceRepositoryProvider = Provider<ReferenceRepository>(
  (ref) => ReferenceRepository(
    api: ref.watch(referenceApiProvider),
    db: ref.watch(appDatabaseProvider),
    networkStatus: ref.watch(networkStatusServiceProvider),
  ),
);

/// هل البيانات المرجعية جاهزة للعمل أوفلاين؟
///
/// بدونها لا يستطيع الأخصائي ملء أي نموذج في الميدان.
final offlineReadyProvider = FutureProvider<bool>(
  (ref) => ref.watch(referenceRepositoryProvider).isReadyForOfflineWork(),
);

// ───────────────────────── المرفقات ─────────────────────────

final attachmentsApiProvider = Provider<AttachmentsApi>(
  (ref) => AttachmentsApi(ref.watch(apiClientProvider)),
);

final attachmentUploaderProvider = Provider<AttachmentUploader>(
  (ref) => AttachmentUploader(
    api: ref.watch(attachmentsApiProvider),
    db: ref.watch(appDatabaseProvider),
  ),
);

final pendingAttachmentsProvider =
    StreamProvider.family<List<PendingAttachmentRow>, String>(
      (ref, caseId) =>
          ref.watch(attachmentUploaderProvider).watchForCase(caseId),
    );

/// عدد المرفقات التي لم تُرفَع — تُعرَض منفصلة لأن الصور أثقل ما يُرفَع.
final pendingAttachmentCountProvider = StreamProvider<int>(
  (ref) => ref.watch(attachmentUploaderProvider).watchPendingCount(),
);

// ───────────────────────── الزيارات الميدانية ─────────────────────────

final fieldVisitsApiProvider = Provider<FieldVisitsApi>(
  (ref) => FieldVisitsApi(ref.watch(apiClientProvider)),
);

final fieldVisitsRepositoryProvider = Provider<FieldVisitsRepository>(
  (ref) => FieldVisitsRepository(
    api: ref.watch(fieldVisitsApiProvider),
    db: ref.watch(appDatabaseProvider),
    uploader: ref.watch(attachmentUploaderProvider),
  ),
);

final fieldVisitsForCaseProvider =
    StreamProvider.family<List<FieldVisitRow>, String>(
      (ref, caseId) =>
          ref.watch(fieldVisitsRepositoryProvider).watchForCase(caseId),
    );

/// زيارات ميدانية في حالة تعارض — تحتاج قرار المستخدم (المرحلة ٤).
final conflictedFieldVisitsProvider = StreamProvider<List<FieldVisitRow>>(
  (ref) => ref.watch(fieldVisitsRepositoryProvider).watchConflicted(),
);

// ───────────────────────── الإشعارات ─────────────────────────

final notificationsApiProvider = Provider<NotificationsApi>(
  (ref) => NotificationsApi(ref.watch(apiClientProvider)),
);

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(
    api: ref.watch(notificationsApiProvider),
    db: ref.watch(appDatabaseProvider),
    queue: ref.watch(syncQueueProvider),
    syncEngine: ref.watch(syncEngineProvider),
    networkStatus: ref.watch(networkStatusServiceProvider),
  ),
);

final notificationsProvider = StreamProvider<List<CachedNotificationRow>>(
  (ref) => ref.watch(notificationsRepositoryProvider).watchAll(),
);

final unreadNotificationsCountProvider = StreamProvider<int>(
  (ref) => ref.watch(notificationsRepositoryProvider).watchUnreadCount(),
);

// ───────────────────────── محرّك المزامنة ─────────────────────────

/// الجهة الوحيدة التي تُفرّغ [syncQueueProvider] فعليًا — راجع
/// `lib/core/sync/sync_engine.dart` للتوثيق الكامل.
final syncEngineProvider = Provider<SyncEngine>((ref) {
  return SyncEngine(
    queue: ref.watch(syncQueueProvider),
    casesApi: ref.watch(casesApiProvider),
    workflowApi: ref.watch(workflowApiProvider),
    notificationsApi: ref.watch(notificationsApiProvider),
    networkStatus: ref.watch(networkStatusServiceProvider),
    ensureFreshSession: () =>
        ref.read(authRepositoryProvider).canFlushSyncQueue(),
    uploadAttachmentsForCase: (caseId) =>
        ref.watch(attachmentUploaderProvider).uploadAllForCase(caseId),
    submitPendingVisitsForCase: (caseId) async {
      final repo = ref.watch(fieldVisitsRepositoryProvider);
      final pending = await repo.pendingVisits();
      for (final visit in pending) {
        if (visit.caseId != caseId) continue;
        await repo.submit(visit.id);
      }
    },
  );
});

/// نتيجة آخر دورة تفريغ — لعرضها في شاشة حالة المزامنة.
final lastSyncResultProvider = StateProvider<SyncFlushResult?>((ref) => null);

/// نقطة الاستدعاء الموحّدة لتشغيل المزامنة من أي محفّز (عودة اتصال، استئناف
/// التطبيق، زر "زامن الآن"). تُحدّث [lastSyncResultProvider] بالنتيجة.
final runSyncProvider = Provider<Future<SyncFlushResult> Function()>((ref) {
  return () async {
    final result = await ref.read(syncEngineProvider).flush();
    ref.read(lastSyncResultProvider.notifier).state = result;
    return result;
  };
});

/// يشترك في عودة الاتصال ويُطلق مزامنة تلقائية عند كل عودة.
///
/// **يُقرأ مرة واحدة** (عبر `ref.watch` في نقطة تهيئة، مثل `AppRoot`) حتى
/// يُبنى ويبدأ الاستماع؛ لا يُستخدَم ناتجه مباشرة. منفصل عن [runSyncProvider]
/// نفسه لأن محفّز "عودة الاتصال" منطق مستقل عن تنفيذ التفريغ ذاته.
final autoSyncOnReconnectProvider = Provider<void>((ref) {
  final subscription = ref
      .watch(networkStatusServiceProvider)
      .onRestored
      .listen((_) {
        ref.read(runSyncProvider)();
      });
  ref.onDispose(subscription.cancel);
});

// ───────────────────────── بدء التشغيل ─────────────────────────

final startupServiceProvider = Provider<StartupService>(
  (ref) => StartupService(
    fieldVisits: ref.watch(fieldVisitsRepositoryProvider),
    reference: ref.watch(referenceRepositoryProvider),
    cases: ref.watch(casesRepositoryProvider),
    networkStatus: ref.watch(networkStatusServiceProvider),
    db: ref.watch(appDatabaseProvider),
    runSync: ref.watch(runSyncProvider),
  ),
);
