import 'package:workmanager/workmanager.dart';

import '../../features/attachments/data/attachment_uploader.dart';
import '../../features/attachments/data/attachments_api.dart';
import '../../features/auth/data/auth_api.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/cases/data/cases_api.dart';
import '../../features/cases/data/workflow_api.dart';
import '../../features/field_visits/data/field_visits_api.dart';
import '../../features/field_visits/data/field_visits_repository.dart';
import '../../features/notifications/data/notifications_api.dart';
import '../network/api_client.dart';
import '../storage/app_database.dart';
import '../storage/secure_token_store.dart';
import 'sync_engine.dart';
import 'sync_queue.dart';

/// اسم المهمة الدورية الوحيد — يُستخدَم للتسجيل والإلغاء معًا.
const backgroundSyncTaskName = 'nahda.background_sync';

/// التباعد المطلوب. Android يقرّبه تلقائيًا لأقرب ١٥ دقيقة لو أقل من ذلك؛
/// iOS يتجاهله كليًا (راجع تعليق [registerBackgroundSync]).
const backgroundSyncFrequency = Duration(minutes: 15);

/// نقطة الدخول التي يستدعيها نظام التشغيل في Isolate/Engine منفصل تمامًا عن
/// شجرة الواجهة — **بلا** أي وصول لمزوّدات Riverpod الحالية. كل تبعية هنا
/// تُبنى يدويًا من الصفر، بنفس تركيبها في `app_providers.dart`/
/// `data_providers.dart` لكن بمعزل تام عنهما (لا `ProviderScope` هنا أصلًا).
///
/// `@pragma('vm:entry-point')` إلزامي — بدونه الـ tree shaking في وضع
/// release يحذف الدالة فيفشل استدعاء نظام التشغيل لها بصمت.
@pragma('vm:entry-point')
void backgroundSyncDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != backgroundSyncTaskName) return true;

    final db = AppDatabase();
    try {
      final tokenStore = SecureTokenStore();

      // لا جلسة محفوظة أصلًا — لا داعي لأي اتصال شبكة، نجاح فوري.
      if (await tokenStore.read() == null) return true;

      final apiClient = ApiClient.create(
        tokenStore: tokenStore,
        // لا واجهة تستمع لإشارة "انتهت الجلسة" داخل isolate خلفي؛
        // AuthRepository.canFlushSyncQueue أدناه يكفي لإيقاف التفريغ بأمان
        // لو الجلسة فعلًا منتهية، بلا حاجة لتفاعل واجهة هنا.
        onSessionExpired: () async {},
      );

      final queue = SyncQueueDao(db);
      final authRepository = AuthRepository(
        api: AuthApi(apiClient),
        tokenStore: tokenStore,
      );
      final attachmentUploader = AttachmentUploader(
        api: AttachmentsApi(apiClient),
        db: db,
      );
      final fieldVisitsRepository = FieldVisitsRepository(
        api: FieldVisitsApi(apiClient),
        db: db,
        uploader: attachmentUploader,
      );

      final syncEngine = SyncEngine(
        queue: queue,
        casesApi: CasesApi(apiClient),
        workflowApi: WorkflowApi(apiClient),
        notificationsApi: NotificationsApi(apiClient),
        ensureFreshSession: authRepository.canFlushSyncQueue,
        uploadAttachmentsForCase: attachmentUploader.uploadAllForCase,
        submitPendingVisitsForCase: (caseId) async {
          final pending = await fieldVisitsRepository.pendingVisits();
          for (final visit in pending) {
            if (visit.caseId != caseId) continue;
            await fieldVisitsRepository.submit(visit.id);
          }
        },
      );

      final result = await syncEngine.flush();
      return result.authError == null;
    } catch (_) {
      // فشل غير متوقع (شبكة/قاعدة بيانات) — نرجع false فيعيد النظام
      // جدولة المحاولة بسياسة التراجع الافتراضية؛ لا نُسقط الاستثناء لأن
      // isolate خلفي بلا معالج أخطاء يعني تعطّل صامت للمهمة كلها.
      return false;
    } finally {
      await db.close();
    }
  });
}

/// يُستدعى مرة عند إقلاع التطبيق (`main()`) — يُهيّئ Workmanager ويسجّل
/// المهمة الدورية. آمن للاستدعاء المتكرر: [ExistingPeriodicWorkPolicy.keep]
/// يُبقي التسجيل القائم كما هو بدل إعادة ضبط مؤقّته من الصفر في كل إقلاع.
///
/// **قيد iOS معروف:** `frequency` هنا مجرد تلميح — iOS يقرر التوقيت الفعلي
/// حسب نمط استخدام المستخدم للتطبيق وحالة البطارية، وقد لا يُشغّل المهمة
/// لساعات. Android أقرب للموثوقية. **كلا النظامين لا يضمن التشغيل إطلاقًا**
/// لو المستخدم أوقف التطبيق يدويًا (force-stop) أو عطّل تحسين البطارية
/// بشكل صارم — حد نظام تشغيل لا يمكن تجاوزه من التطبيق، والمزامنة عند فتح
/// التطبيق (`StartupService`) تبقى خط الدفاع الأساسي دائمًا، هذا تحسين فوقها.
Future<void> registerBackgroundSync() async {
  await Workmanager().initialize(backgroundSyncDispatcher);
  await Workmanager().registerPeriodicTask(
    backgroundSyncTaskName,
    backgroundSyncTaskName,
    frequency: backgroundSyncFrequency,
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}
