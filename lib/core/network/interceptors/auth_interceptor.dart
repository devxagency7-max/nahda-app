import 'dart:async';

import 'package:dio/dio.dart';

import '../../storage/secure_token_store.dart';
import '../api_error_code.dart';
import '../api_envelope.dart';
import '../api_exception.dart';

/// مسارات لا تحمل `Authorization` أبدًا.
const _publicPaths = {'/auth/login', '/auth/refresh'};

/// علامة داخلية: لا تحاول تحديث التوكن لهذا الطلب (يُستخدم لطلب الـ refresh نفسه).
const kSkipAuthRefresh = 'skipAuthRefresh';

/// يضيف `Bearer` ويدير تحديث التوكن.
///
/// عقد مهم (§2.5): أي `401` → محاولة **واحدة** لـ `/auth/refresh`؛ فشلها يعني
/// مسح الجلسة وتسجيل خروج. و`403` **لا يُعالَج بـ refresh إطلاقًا** — معناه
/// "ممنوع" لا "منتهي الصلاحية".
///
/// قيد حرج (§2.3): الخادم يدوّر الـ refresh token ويكتشف إعادة الاستخدام.
/// استدعاءان متزامنان بنفس التوكن → أحدهما يفوز والآخر **يُبطل عائلة التوكنات
/// كلها**. لذا كل تحديث يمرّ عبر `Future` واحد مشترك.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required SecureTokenStore tokenStore,
    required Dio refreshClient,
    required Future<void> Function() onSessionExpired,
  }) : _tokenStore = tokenStore,
       _refreshClient = refreshClient,
       _onSessionExpired = onSessionExpired;

  final SecureTokenStore _tokenStore;

  /// عميل منفصل بلا هذا الـ interceptor — وإلا لدخلنا في تكرار لا نهائي.
  final Dio _refreshClient;

  final Future<void> Function() _onSessionExpired;

  /// الـ future الوحيد المسموح به للتحديث في أي لحظة.
  Future<AuthSession?>? _refreshInFlight;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isPublic(options)) {
      return handler.next(options);
    }

    var session = await _tokenStore.read();
    if (session == null) {
      return handler.reject(
        DioException(
          requestOptions: options,
          error: const ApiException(
            code: ApiErrorCode.unauthorized,
            message: '',
          ),
          type: DioExceptionType.cancel,
        ),
      );
    }

    // تحديث استباقي: أرخص بكثير من ترك الطلب يفشل بـ 401 ثم إعادته،
    // وأهم من ذلك أنه يتجنّب تفريغ طابور كامل بتوكن منتهٍ.
    if (session.isAccessTokenExpired) {
      session = await _refreshSession();
      if (session == null) {
        return handler.reject(
          DioException(
            requestOptions: options,
            error: const ApiException(
              code: ApiErrorCode.tokenExpired,
              message: '',
            ),
            type: DioExceptionType.cancel,
          ),
        );
      }
    }

    options.headers['Authorization'] = 'Bearer ${session.accessToken}';
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final options = err.requestOptions;

    // 403 ليس مشكلة توكن — لا تحديث ولا إعادة محاولة (§15.9).
    if (status != 401 || _isPublic(options) || _shouldSkipRefresh(options)) {
      return handler.next(err);
    }

    final session = await _refreshSession();
    if (session == null) {
      return handler.next(err);
    }

    // محاولة واحدة فقط بالتوكن الجديد.
    options.headers['Authorization'] = 'Bearer ${session.accessToken}';
    options.extra[kSkipAuthRefresh] = true;

    try {
      final response = await _refreshClient.fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  /// تحديث مُسلسَل: أول من يطلب ينشئ الـ future، والبقية ينتظرونه.
  Future<AuthSession?> _refreshSession() {
    final existing = _refreshInFlight;
    if (existing != null) return existing;

    final future = _performRefresh();
    _refreshInFlight = future;

    return future.whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<AuthSession?> _performRefresh() async {
    final current = await _tokenStore.read();
    if (current == null) return null;

    // الـ refresh token نفسه منتهٍ (طابور أقدم من ٧ أيام) — لا فائدة من المحاولة.
    if (current.isRefreshTokenExpired) {
      await _expireSession();
      return null;
    }

    try {
      final response = await _refreshClient.post<dynamic>(
        '/auth/refresh',
        data: {'refreshToken': current.refreshToken},
        options: Options(extra: {kSkipAuthRefresh: true}),
      );

      final session = ApiEnvelope.parse<AuthSession?>(
        response.data,
        _sessionFromJson,
        statusCode: response.statusCode,
      );

      if (session == null) {
        await _expireSession();
        return null;
      }

      await _tokenStore.write(session);
      return session;
    } on DioException catch (e) {
      final status = e.response?.statusCode;

      // انقطاع شبكة لا يعني جلسة باطلة — نحتفظ بالتوكن للمحاولة لاحقًا.
      // مسحه هنا يعني طرد أخصائي في الميدان بسبب ضعف الإشارة.
      if (status == null) return null;

      if (status == 401 || status == 403) {
        await _expireSession();
      }
      return null;
    } on ApiException catch (e) {
      if (e.requiresReauth) await _expireSession();
      return null;
    }
  }

  Future<void> _expireSession() async {
    await _tokenStore.clear();
    await _onSessionExpired();
  }

  static AuthSession? _sessionFromJson(Object? data) {
    if (data is! Map<String, dynamic>) return null;

    final access = data['accessToken'];
    final refresh = data['refreshToken'];
    if (access is! String || refresh is! String) return null;

    final expiresIn = data['expiresIn'];
    final seconds = expiresIn is num ? expiresIn.toInt() : 900;
    final now = DateTime.now().toUtc();

    return AuthSession(
      accessToken: access,
      refreshToken: refresh,
      accessTokenExpiresAt: now.add(Duration(seconds: seconds)),
      // الخادم لا يرسل انتهاء الـ refresh token؛ العقد يثبّته على ٧ أيام (§2.4).
      refreshTokenExpiresAt: now.add(const Duration(days: 7)),
    );
  }

  bool _isPublic(RequestOptions options) =>
      _publicPaths.any((p) => options.path.endsWith(p));

  bool _shouldSkipRefresh(RequestOptions options) =>
      options.extra[kSkipAuthRefresh] == true;
}
