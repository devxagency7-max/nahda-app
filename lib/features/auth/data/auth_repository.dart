import '../../../core/network/api_error_code.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/session/session_registry.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/secure_token_store.dart';
import '../domain/auth_user.dart';
import 'auth_api.dart';

/// سبب انتهاء الجلسة — يُستهلَك فقط لاختيار رسالة العرض في الواجهة؛ مسار
/// [AuthRepository.endSession] نفسه واحد بصرف النظر عن السبب.
enum SessionEndReason {
  /// المستخدم ضغط "تسجيل خروج" صراحة.
  userInitiated,

  /// الخادم رفض التوكن ولم يُفلح التجديد (`AuthInterceptor._expireSession`).
  expired,
}

/// منطق المصادقة فوق [AuthApi] و [SecureTokenStore].
class AuthRepository {
  AuthRepository({
    required AuthApi api,
    required SecureTokenStore tokenStore,
    required AppDatabase database,
    required SessionRegistry session,
    Future<void> Function()? awaitSyncIdle,
  }) : _api = api,
       _tokenStore = tokenStore,
       _database = database,
       _session = session,
       _awaitSyncIdle = awaitSyncIdle;

  final AuthApi _api;
  final SecureTokenStore _tokenStore;
  final AppDatabase _database;
  final SessionRegistry _session;

  /// ينتظر توقّف أي دورة تفريغ جارية لـ `SyncEngine` قبل `clearAll()` —
  /// يمنع تصادم قراءة/كتابة بين حذف الجداول وتحديث صفّ طابور في نفس اللحظة
  /// (AUTH_SESSION_AUDIT.md §2، مشكلة #8). `null` في الاختبارات وفي
  /// `background_sync.dart` (لا `SyncEngine` مشترك يستحق الانتظار هناك).
  final Future<void> Function()? _awaitSyncIdle;

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final result = await _api.login(email: email, password: password);

    // دفاع في العمق: الخادم يفرض قفل المنصّة أصلًا، لكن استجابة بدور آخر
    // تعني خللًا يجب ألّا يمرّ صامتًا.
    if (!result.user.isSocialWorker) {
      throw const ApiException(
        code: ApiErrorCode.platformNotAllowed,
        message: 'هذا التطبيق مخصص للأخصائيين الاجتماعيين فقط.',
      );
    }

    await _tokenStore.write(result.session);
    await _tokenStore.writeUser(result.user.toJson());
    // يبدأ جيلًا جديدًا **بعد** كتابة التوكن — أي طلب كان قيد التنفيذ قبل
    // هذه اللحظة (نظريًا مستحيل هنا، لا جلسة سابقة نشطة قبل أول login) لن
    // يُعتبر تابعًا للجلسة الجديدة.
    _session.beginSession(result.user.id);
    return result.user;
  }

  /// يستعيد الجلسة عند إقلاع التطبيق.
  ///
  /// **يعمل أوفلاين عن قصد** (§2 من الخطة): وجود توكن صالح يكفي لفتح التطبيق.
  /// فشل `/auth/me` بسبب الشبكة **لا يُنهي الجلسة** — إنهاؤها يعني طرد أخصائي
  /// في الميدان لأن الإشارة ضعيفة، وقد يحمل جهازه عمل يوم كامل غير مُرفَع.
  Future<AuthUser?> restoreSession() async {
    final session = await _tokenStore.read();
    if (session == null) return null;

    if (session.isRefreshTokenExpired) {
      // مسار تلقائي بلا واجهة تنتظر تأكيدًا — `force: true` إلزامي هنا،
      // وإلا `PendingSyncOperationsException` كانت ستمنع الإقلاع بالكامل.
      await endSession(
        reason: SessionEndReason.expired,
        notifyServer: false,
        force: true,
      );
      return null;
    }

    final cached = AuthUser.fromJson(await _tokenStore.readUser());

    try {
      final fresh = await _api.me();
      if (fresh != null) {
        await _tokenStore.writeUser(fresh.toJson());
        _session.beginSession(fresh.id);
        return fresh;
      }
      if (cached != null) _session.beginSession(cached.id);
      return cached;
    } on ApiException catch (e) {
      // رفض صريح من الخادم ← الجلسة باطلة فعلًا.
      if (e.requiresReauth || e.code == ApiErrorCode.forbidden) {
        await endSession(
          reason: SessionEndReason.expired,
          notifyServer: false,
          force: true,
        );
        return null;
      }
      // شبكة/مهلة/خطأ خادم ← نكمل بالبيانات المخزَّنة.
      if (cached != null) _session.beginSession(cached.id);
      return cached;
    }
  }

  /// نقطة الإنهاء الموحّدة الوحيدة لأي جلسة — تُستدعى من زر تسجيل الخروج
  /// اليدوي، ومن `AuthController.onSessionExpired` (توكن مرفوض/تجديد فاشل)،
  /// ومن `restoreSession` (جلسة باطلة عند الإقلاع). **لا مسار آخر يجوز أن
  /// يمسح التوكن أو القاعدة المحلية مباشرة** — أي مسار جديد لإنهاء الجلسة
  /// يجب أن يمر من هنا (راجع AUTH_SESSION_AUDIT.md §3، مشكلة #3).
  ///
  /// الترتيب حاسم:
  /// 1. [SessionRegistry.endSession] فورًا — يُبطل الجيل الحالي (فتُتجاهَل أي
  ///    ردود API قيد الوصول من هذه اللحظة) ويُلغي طلبات Dio الجارية عبر
  ///    `CancelToken`.
  /// 2. إخطار الخادم (best-effort) — يُستخدم التوكن الحالي **قبل** مسحه.
  /// 3. انتظار توقّف أي دورة تفريغ جارية لـ `SyncEngine` — يمنع حذف صفّ
  ///    طابور بينما `markSucceeded`/`markFailed` يكتب عليه في نفس اللحظة.
  /// 4. مسح التوكن ثم قاعدة البيانات المحلية.
  ///
  /// [force]: `false` (الافتراضي) يرفض المسح المحلي بـ
  /// [PendingSyncOperationsException] لو بقيت عمليات لم تُرفَع — **الجلسة
  /// نفسها تنتهي دومًا** (توكن يُمسح، جيل يُبطل) بصرف النظر عن هذا الفشل؛
  /// الاستثناء يخص قاعدة البيانات المحلية فقط، ويعني عمليًا "تنبّه: بيانات
  /// الحساب السابق لا تزال على الجهاز". المتصل الذي راجع الأمر فعلًا مع
  /// المستخدم (تحذير `home_drawer.dart`) أو مسار تلقائي بلا واجهة تنتظر
  /// (`onSessionExpired`, `restoreSession`) يمرّر `force: true` صراحة.
  Future<void> endSession({
    required SessionEndReason reason,
    bool notifyServer = true,
    bool force = false,
  }) async {
    _session.endSession();

    if (notifyServer) {
      final session = await _tokenStore.read();
      if (session != null) {
        try {
          // `AuthApi.logout` يستخدم `ApiClient.postAuth` (`trackSession:
          // false`) — غير مرتبط بجيل [_session] المُبطَل للتو أعلاه، وإلا
          // كان هذا الاستدعاء نفسه سيُعلَّق بلا نتيجة أبدًا.
          await _api.logout(session.refreshToken);
        } on ApiException {
          // فشل إبطال الجلسة على الخادم لا يمنع الخروج محليًا.
        }
      }
    }

    await _tokenStore.clear();
    await _awaitSyncIdle?.call();
    await _database.clearAll(force: force);
  }

  Future<AuthSession?> currentSession() => _tokenStore.read();

  /// هل يقترب انتهاء صلاحية الجلسة؟ لتحذير الأخصائي قبل خروجه للميدان.
  Future<bool> isReauthSoon({
    Duration threshold = const Duration(days: 2),
  }) async {
    final session = await _tokenStore.read();
    if (session == null) return false;
    return session.timeUntilReauthRequired <= threshold;
  }
}
