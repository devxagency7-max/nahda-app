import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// جلسة المستخدم المخزَّنة.
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresAt,
    required this.refreshTokenExpiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime accessTokenExpiresAt;

  /// الـ refresh token عمره ٧ أيام (§2.4). نحسب انتهاءه وقت الإصدار
  /// لأن الطابور الأوفلاين يحتاج معرفة متى يصبح التفريغ مستحيلًا بلا دخول جديد.
  final DateTime refreshTokenExpiresAt;

  /// هل انتهت صلاحية التوكن؟ مع هامش ٦٠ ثانية.
  ///
  /// سماحية انحراف الساعة عند الخادم ٣٠ ثانية فقط (§2.4)، والهامش الأكبر
  /// هنا يحمي من جهاز ساعته منحرفة قليلًا.
  bool get isAccessTokenExpired =>
      DateTime.now().toUtc().isAfter(
        accessTokenExpiresAt.subtract(const Duration(seconds: 60)),
      );

  bool get isRefreshTokenExpired =>
      DateTime.now().toUtc().isAfter(refreshTokenExpiresAt);

  /// المدة المتبقية قبل أن يصبح تسجيل الدخول إجباريًا.
  ///
  /// تُستخدم لتحذير الأخصائي قبل خروجه للميدان بطابور غير مُفرَّغ.
  Duration get timeUntilReauthRequired {
    final remaining = refreshTokenExpiresAt.difference(DateTime.now().toUtc());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'accessTokenExpiresAt': accessTokenExpiresAt.toIso8601String(),
    'refreshTokenExpiresAt': refreshTokenExpiresAt.toIso8601String(),
  };

  static AuthSession? fromJson(Map<String, dynamic> json) {
    final access = json['accessToken'];
    final refresh = json['refreshToken'];
    if (access is! String || refresh is! String) return null;
    if (access.isEmpty || refresh.isEmpty) return null;

    final accessExp = DateTime.tryParse('${json['accessTokenExpiresAt']}');
    final refreshExp = DateTime.tryParse('${json['refreshTokenExpiresAt']}');
    if (accessExp == null || refreshExp == null) return null;

    return AuthSession(
      accessToken: access,
      refreshToken: refresh,
      accessTokenExpiresAt: accessExp.toUtc(),
      refreshTokenExpiresAt: refreshExp.toUtc(),
    );
  }
}

/// تخزين التوكنات في Keychain (iOS) / Keystore (Android).
///
/// **لا SharedPreferences إطلاقًا** — §17 من العقد.
///
/// قاعدة حرجة (§2.3): يُخزَّن **التوكن الأحدث فقط**. الخادم يدوّر الـ refresh
/// token في كل استدعاء ويكتشف إعادة الاستخدام — وإعادة إرسال توكن مُدوَّر
/// تُبطل عائلة التوكنات كلها وتطرد المستخدم. فلا نحتفظ بنسخة "قديمة" أبدًا.
class SecureTokenStore {
  SecureTokenStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            // `first_unlock` لا `first_unlock_this_device_only`: التطبيق يحتاج
            // العمل بعد إعادة التشغيل دون فتح الجهاز يدويًا أولًا.
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  final FlutterSecureStorage _storage;

  static const _sessionKey = 'nahda.auth.session';
  static const _userKey = 'nahda.auth.user';

  /// كاش في الذاكرة — الـ interceptor يقرأ الجلسة في كل طلب، والقراءة من
  /// Keychain في كل مرة بطيئة بلا داعٍ.
  AuthSession? _cached;
  bool _loaded = false;

  Future<AuthSession?> read() async {
    if (_loaded) return _cached;

    final raw = await _storage.read(key: _sessionKey);
    _loaded = true;

    if (raw == null || raw.isEmpty) {
      _cached = null;
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      _cached = decoded is Map<String, dynamic>
          ? AuthSession.fromJson(decoded)
          : null;
    } on FormatException {
      // تخزين تالف — نعامله كعدم وجود جلسة بدل الانهيار عند الإقلاع.
      _cached = null;
    }

    return _cached;
  }

  Future<void> write(AuthSession session) async {
    _cached = session;
    _loaded = true;
    await _storage.write(key: _sessionKey, value: jsonEncode(session.toJson()));
  }

  Future<void> clear() async {
    _cached = null;
    _loaded = true;
    await _storage.delete(key: _sessionKey);
    await _storage.delete(key: _userKey);
  }

  /// بيانات المستخدم المخزَّنة — تسمح بفتح التطبيق أوفلاين دون `/auth/me`.
  Future<Map<String, dynamic>?> readUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> writeUser(Map<String, dynamic> user) =>
      _storage.write(key: _userKey, value: jsonEncode(user));

  /// هل تفريغ طابور المزامنة ممكن الآن؟
  ///
  /// **لا يُجدّد التوكن هنا** — `AuthInterceptor` يتولّى ذلك شفافيًا مع أول
  /// طلب فعلي. الفحص هنا أضيق: هل الـ refresh token نفسه ما زال حيًّا؟
  /// طابور تراكم على مدى أيام (§14.4) قد يجد الـ refresh token منتهيًا
  /// (٧ أيام) رغم أن آخر access token كان صالحًا وقت الإغلاق — عندها لا
  /// فائدة من إرسال أي عملية: أول طلب سيفشل بـ `401` نهائي ويستهلك محاولة
  /// من كل عملية في الطابور بلا طائل. أفضل أن يتوقف `SyncEngine` هنا مرة
  /// واحدة قبل البدء ويطلب دخولًا جديدًا.
  ///
  /// معرَّفة هنا لا في `AuthRepository` عمدًا — `SyncEngine` يحتاجها ضمن
  /// `syncEngineProvider`، الذي تعتمد عليه `AuthRepository.endSession` نفسها
  /// (`awaitSyncIdle`)؛ إبقاؤها في `AuthRepository` كان يُنشئ اعتمادًا
  /// دائريًا بين `authRepositoryProvider` و`syncEngineProvider`.
  Future<bool> canFlushSyncQueue() async {
    final session = await read();
    if (session == null) return false;
    return !session.isRefreshTokenExpired;
  }
}
