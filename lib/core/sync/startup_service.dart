import '../../features/cases/data/cases_repository.dart';
import '../../features/field_visits/data/field_visits_repository.dart';
import '../../features/reference/data/reference_repository.dart';
import '../network/network_status_service.dart';
import '../storage/app_database.dart';
import 'sync_engine.dart';

/// نتيجة تهيئة بدء التشغيل.
class StartupResult {
  const StartupResult({
    required this.isOfflineReady,
    required this.pendingOperations,
    required this.wasOffline,
  });

  /// هل البيانات المرجعية موجودة؟ بدونها لا يعمل أي نموذج أوفلاين.
  final bool isOfflineReady;

  final int pendingOperations;

  /// هل بدأنا بلا اتصال؟ يُغيّر ما نعرضه للمستخدم.
  final bool wasOffline;

  bool get hasPendingWork => pendingOperations > 0;
}

/// يُشغّل ما يجب أن يحدث بعد تسجيل الدخول وعند عودة التطبيق للمقدّمة.
///
/// **الترتيب مقصود ومُلزَم:**
/// 1. التعافي من الزيارات العالقة — **قبل أي شيء يلمس الشبكة**، وإلا خاطرنا
///    بإرسال زيارة وصلت أصلًا فتتكرّر في سجل رسمي.
/// 2. البيانات المرجعية — بدونها لا يستطيع الأخصائي ملء نموذجًا في الميدان.
/// 3. طابور العمل — ليرى حالاته فورًا.
class StartupService {
  StartupService({
    required FieldVisitsRepository fieldVisits,
    required ReferenceRepository reference,
    required CasesRepository cases,
    required NetworkStatusService networkStatus,
    required AppDatabase db,
    required Future<SyncFlushResult> Function() runSync,
  }) : _fieldVisits = fieldVisits,
       _reference = reference,
       _cases = cases,
       _networkStatus = networkStatus,
       _db = db,
       _runSync = runSync;

  final FieldVisitsRepository _fieldVisits;
  final ReferenceRepository _reference;
  final CasesRepository _cases;
  final NetworkStatusService _networkStatus;
  final AppDatabase _db;

  /// يُفرّغ `sync_queue` عبر `SyncEngine` — مُمرَّر من الخارج (لا يُبنى
  /// `SyncEngine` هنا مباشرة) تجنّبًا لاعتماد دائري بين مزوّدات المصادقة
  /// وطبقة المزامنة في `data_providers.dart`.
  final Future<SyncFlushResult> Function() _runSync;

  /// يُستدعى مرة بعد استعادة الجلسة أو تسجيل الدخول.
  ///
  /// **حاسم:** يعتمد على فحص فوري طازج ([NetworkStatusService.checkNow]) لا
  /// على آخر حالة معروفة فقط — لحظة فتح التطبيق هي اللحظة التي يُبنى عليها
  /// قرار "أونلاين أم أوفلاين" لكامل الجلسة، فوجود واجهة شبكة بلا إنترنت
  /// فعلي (بوابة مقيّدة، شبكة بلا خدمة) لا يجوز أن يُعامَل كأونلاين.
  Future<StartupResult> run() async {
    final online = (await _networkStatus.checkNow()).isOnline;

    if (online) {
      // أولًا وقبل كل شيء: هل هناك زيارة لا نعرف إن وصلت؟
      await _fieldVisits.reconcileStuckVisits();

      // تفريغ العمل المعلَّق **قبل** جلب حالة جديدة من الخادم — إرسال
      // تعديلات الأخصائي أولًا يعني أن ما نجلبه بعدها يعكس عمله فعلًا،
      // لا نسخة قديمة قد تُخفي تعارضًا كان يجب أن يظهر له.
      await _runSync();

      // البيانات المرجعية أولًا لأن غيابها يُعطّل العمل الميداني كليًا،
      // بينما غياب طابور العمل يعني قائمة فارغة فقط.
      await _reference.refreshIfStale();
      await _cases.refreshWorkQueue();
    }

    return StartupResult(
      isOfflineReady: await _reference.isReadyForOfflineWork(),
      pendingOperations: await _db.pendingOperationCount(),
      wasOffline: !online,
    );
  }

  /// يُستدعى عند عودة التطبيق للمقدّمة.
  ///
  /// أخفّ من [run]: لا يُعيد جلب البيانات المرجعية إلا إن قدُمت.
  Future<void> onResume() async {
    if (!(await _networkStatus.checkNow()).isOnline) return;

    await _fieldVisits.reconcileStuckVisits();
    await _runSync();
    await _reference.refreshIfStale();
    await _cases.refreshWorkQueue();
  }

  /// تحضير كامل قبل الخروج للميدان — بطلب صريح من المستخدم.
  ///
  /// يسحب تفاصيل كل حالة كاملة لا العناوين فقط، لأن الأخصائي قد يقضي اليوم
  /// بلا تغطية.
  Future<StartupResult> prepareForFieldWork({
    void Function(String step, int done, int total)? onProgress,
  }) async {
    final online = (await _networkStatus.checkNow()).isOnline;
    if (!online) {
      return StartupResult(
        isOfflineReady: await _reference.isReadyForOfflineWork(),
        pendingOperations: await _db.pendingOperationCount(),
        wasOffline: true,
      );
    }

    onProgress?.call('القوائم والبيانات المرجعية', 0, 2);
    await _reference.refreshAll();

    onProgress?.call('تفاصيل الحالات', 1, 2);
    await _cases.prefetchForFieldWork(
      onProgress: (done, total) =>
          onProgress?.call('تفاصيل الحالات', done, total),
    );

    return StartupResult(
      isOfflineReady: await _reference.isReadyForOfflineWork(),
      pendingOperations: await _db.pendingOperationCount(),
      wasOffline: false,
    );
  }
}
