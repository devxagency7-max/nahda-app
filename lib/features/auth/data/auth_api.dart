import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_token_store.dart';
import '../domain/auth_user.dart';

/// نتيجة تسجيل الدخول: الجلسة + المستخدم.
class LoginResult {
  const LoginResult({required this.session, required this.user});

  final AuthSession session;
  final AuthUser user;
}

/// استدعاءات مسارات المصادقة — §2.3 من العقد.
class AuthApi {
  const AuthApi(this._client);

  final ApiClient _client;

  /// `POST /auth/login` — يتطلب `X-Client-Type: mobile`.
  ///
  /// أخطاء متوقّعة: `401 INVALID_CREDENTIALS` (عامّة عمدًا، لا تميّز بين بريد
  /// مجهول وكلمة مرور خاطئة)، `423 ACCOUNT_LOCKED` (٥ محاولات ← قفل ١٥ دقيقة)،
  /// `403 PLATFORM_NOT_ALLOWED` (دور غير الأخصائي)، `429 RATE_LIMITED`.
  Future<LoginResult> login({
    required String email,
    required String password,
  }) => _client.postAuth<LoginResult>(
    '/auth/login',
    _parseLogin,
    body: {'email': email, 'password': password},
  );

  /// `POST /auth/logout` — يُبطل جلسة هذا الجهاز وحده. دائمًا `200`.
  ///
  /// ملاحظة: **لا يُلغي تسجيل توكن الإشعارات** — لا يوجد مسار لذلك (§12).
  Future<void> logout(String refreshToken) => _client.postAuth<void>(
    '/auth/logout',
    Parse.empty,
    body: {'refreshToken': refreshToken},
  );

  /// `GET /auth/me` — يقرأ المستخدم من قاعدة البيانات لا من الـ JWT،
  /// فيكشف إيقاف الحساب خلال استدعاء واحد لا عند انتهاء التوكن.
  Future<AuthUser?> me() => _client.get<AuthUser?>('/auth/me', AuthUser.fromJson);

  static LoginResult _parseLogin(Object? data) {
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};

    final access = map['accessToken'];
    final refresh = map['refreshToken'];
    if (access is! String || refresh is! String) {
      throw const FormatException('استجابة تسجيل دخول غير مكتملة');
    }

    final expiresIn = map['expiresIn'];
    final seconds = expiresIn is num ? expiresIn.toInt() : 900;
    final now = DateTime.now().toUtc();

    final user = AuthUser.fromJson(map['user']);
    if (user == null) {
      throw const FormatException('بيانات المستخدم غير مكتملة');
    }

    return LoginResult(
      session: AuthSession(
        accessToken: access,
        refreshToken: refresh,
        accessTokenExpiresAt: now.add(Duration(seconds: seconds)),
        // العقد يثبّت عمر الـ refresh token على ٧ أيام (§2.4)؛ الخادم لا يرسله.
        refreshTokenExpiresAt: now.add(const Duration(days: 7)),
      ),
      user: user,
    );
  }
}
