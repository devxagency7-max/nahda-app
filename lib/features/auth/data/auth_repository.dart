import '../../../core/network/api_error_code.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/secure_token_store.dart';
import '../domain/auth_user.dart';
import 'auth_api.dart';

/// منطق المصادقة فوق [AuthApi] و [SecureTokenStore].
class AuthRepository {
  AuthRepository({required AuthApi api, required SecureTokenStore tokenStore})
    : _api = api,
      _tokenStore = tokenStore;

  final AuthApi _api;
  final SecureTokenStore _tokenStore;

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
      await _tokenStore.clear();
      return null;
    }

    final cached = AuthUser.fromJson(await _tokenStore.readUser());

    try {
      final fresh = await _api.me();
      if (fresh != null) {
        await _tokenStore.writeUser(fresh.toJson());
        return fresh;
      }
      return cached;
    } on ApiException catch (e) {
      // رفض صريح من الخادم ← الجلسة باطلة فعلًا.
      if (e.requiresReauth || e.code == ApiErrorCode.forbidden) {
        await _tokenStore.clear();
        return null;
      }
      // شبكة/مهلة/خطأ خادم ← نكمل بالبيانات المخزَّنة.
      return cached;
    }
  }

  /// تسجيل الخروج.
  ///
  /// **المتصل مسؤول عن التحقق من فراغ طابور المزامنة أولًا** — الخروج بطابور
  /// ممتلئ يفقد عمل الأخصائي.
  Future<void> logout() async {
    final session = await _tokenStore.read();

    if (session != null) {
      try {
        await _api.logout(session.refreshToken);
      } on ApiException {
        // فشل إبطال الجلسة على الخادم لا يمنع الخروج محليًا.
      }
    }

    await _tokenStore.clear();
  }

  Future<AuthSession?> currentSession() => _tokenStore.read();

  /// هل تفريغ طابور المزامنة ممكن الآن؟
  ///
  /// **لا يُجدّد التوكن هنا** — `AuthInterceptor` يتولّى ذلك شفافيًا مع أول
  /// طلب فعلي. الفحص هنا أضيق: هل الـ refresh token نفسه ما زال حيًّا؟
  /// طابور تراكم على مدى أيام (§14.4) قد يجد الـ refresh token منتهيًا
  /// (٧ أيام) رغم أن آخر access token كان صالحًا وقت الإغلاق — عندها لا
  /// فائدة من إرسال أي عملية: أول طلب سيفشل بـ `401` نهائي ويستهلك محاولة
  /// من كل عملية في الطابور بلا طائل. أفضل أن يتوقف `SyncEngine` هنا مرة
  /// واحدة قبل البدء ويطلب دخولًا جديدًا.
  Future<bool> canFlushSyncQueue() async {
    final session = await _tokenStore.read();
    if (session == null) return false;
    return !session.isRefreshTokenExpired;
  }

  /// هل يقترب انتهاء صلاحية الجلسة؟ لتحذير الأخصائي قبل خروجه للميدان.
  Future<bool> isReauthSoon({
    Duration threshold = const Duration(days: 2),
  }) async {
    final session = await _tokenStore.read();
    if (session == null) return false;
    return session.timeUntilReauthRequired <= threshold;
  }
}
