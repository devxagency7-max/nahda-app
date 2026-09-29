import 'dart:async';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../session/session_registry.dart';
import '../storage/secure_token_store.dart';
import 'api_envelope.dart';
import 'api_exception.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/idempotency_interceptor.dart';

/// عميل HTTP للـ API.
///
/// كل دوالّه ترمي [ApiException] فقط — لا `DioException` يعبر هذه الطبقة.
///
/// **نتيجة تخص جلسة منتهية (logout/تبديل حساب حدث أثناء انتظار الرد) لا
/// تُرمى كاستثناء إطلاقًا** — الطلبات الجارية تُلغى فعليًا عبر
/// `SessionRegistry.cancelToken` عند إنهاء الجلسة (`DioException.cancel`
/// العادي، معالَج ضمن `on DioException` كأي إلغاء آخر)، وفي النافذة
/// الضيقة النادرة التي يصل فيها الرد قبل معالجة الإلغاء، يُترَك `Future`
/// الاستدعاء **معلَّقًا بلا اكتمال أبدًا** بدل رمي نوع استثناء جديد كل طبقة
/// (شاشات، repositories) يجب أن تتعلّم توقّعه وتجاهله. هذا آمن لأن نفس
/// `cancelToken` (المُلغى بالفعل) هو ما يُغلق دورة حياة ذلك الانتظار — أي
/// `catchError`/`whenComplete` مرتبط بدورة حياة widget يُنظَّف مع تخلّصه
/// عادةً، ولا كود بعد نقطة الانتظار هذه ينفَّذ أبدًا لبيانات لا تخص أي
/// جلسة نشطة حاليًا.
///
/// **قاعدة معمارية:** هذا الصنف يُستخدم من `*_api.dart` (طبقة remote) فقط،
/// ويستدعيها `SyncEngine` وحده. الـ repositories لا تلمس الشبكة مباشرة —
/// تكتب في Drift وتضيف للطابور. راجع §2.2 من خطة الربط.
class ApiClient {
  ApiClient._(this._dio, this._session);

  final Dio _dio;
  final SessionRegistry? _session;

  Dio get raw => _dio;

  factory ApiClient.create({
    required SecureTokenStore tokenStore,
    required Future<void> Function() onSessionExpired,
    SessionRegistry? session,
    String? baseUrl,
  }) {
    final resolvedBase = baseUrl ?? AppConfig.apiBaseUrl;

    BaseOptions buildOptions() => BaseOptions(
      baseUrl: resolvedBase,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      // نستقبل كل الأكواد ونفكّ الغلاف بأنفسنا — العقد ينصّ أن حتى 404 و 429
      // ترجع نفس شكل الغلاف (§3).
      validateStatus: (status) => status != null && status < 500,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    // عميل منفصل للـ refresh وإعادة المحاولة — بلا AuthInterceptor
    // تجنّبًا للتكرار اللانهائي.
    final refreshClient = Dio(buildOptions())
      ..interceptors.add(const ErrorInterceptor());

    final dio = Dio(buildOptions());
    dio.interceptors.addAll([
      const IdempotencyInterceptor(),
      AuthInterceptor(
        tokenStore: tokenStore,
        refreshClient: refreshClient,
        onSessionExpired: onSessionExpired,
      ),
      const ErrorInterceptor(),
      if (AppConfig.enableNetworkLogging)
        LogInterceptor(
          requestBody: true,
          // لا نطبع أجسام الاستجابات: تحتوي بيانات مستفيدين حقيقية.
          responseBody: false,
          requestHeader: false,
        ),
    ]);

    return ApiClient._(dio, session);
  }

  Future<T> get<T>(
    String path,
    T Function(Object? data) parser, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) => _send(
    parser,
    (token) => _dio.get<dynamic>(
      path,
      queryParameters: _clean(query),
      cancelToken: token,
    ),
    cancelToken,
  );

  Future<T> post<T>(
    String path,
    T Function(Object? data) parser, {
    Object? body,
    String? idempotencyKey,
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) => _send(
    parser,
    (token) => _dio.post<dynamic>(
      path,
      data: body,
      queryParameters: _clean(query),
      cancelToken: token,
      options: _withIdempotency(idempotencyKey),
    ),
    cancelToken,
  );

  Future<T> put<T>(
    String path,
    T Function(Object? data) parser, {
    Object? body,
    String? idempotencyKey,
    CancelToken? cancelToken,
  }) => _send(
    parser,
    (token) => _dio.put<dynamic>(
      path,
      data: body,
      cancelToken: token,
      options: _withIdempotency(idempotencyKey),
    ),
    cancelToken,
  );

  Future<T> delete<T>(
    String path,
    T Function(Object? data) parser, {
    Object? body,
    CancelToken? cancelToken,
  }) => _send(
    parser,
    (token) => _dio.delete<dynamic>(path, data: body, cancelToken: token),
    cancelToken,
  );

  /// إرسال الترويسات الخاصة بالمصادقة (`X-Client-Type`) — §2.1.
  ///
  /// مقصورة على login/refresh/logout؛ لا تُرسَل مع المسارات المحمية.
  ///
  /// **لا تُمرَّر `cancelToken` الجلسة هنا** — `login()` نفسه يُستدعى *قبل*
  /// وجود جلسة، و`logout()` يُستدعى أثناء إنهائها (بعد إلغاء الـ token
  /// القديم بالفعل)؛ ربطهما بالـ CancelToken كان يعني إلغاء طلب الدخول نفسه.
  Future<T> postAuth<T>(
    String path,
    T Function(Object? data) parser, {
    Object? body,
  }) => _send(
    parser,
    (_) => _dio.post<dynamic>(
      path,
      data: body,
      options: Options(
        headers: {'X-Client-Type': AppConfig.clientType},
        extra: {kSkipAuthRefresh: true},
      ),
    ),
    null,
    trackSession: false,
  );

  Future<T> _send<T>(
    T Function(Object? data) parser,
    Future<Response<dynamic>> Function(CancelToken?) request,
    CancelToken? explicitCancelToken, {
    bool trackSession = true,
  }) async {
    final session = trackSession ? _session : null;
    final capturedGeneration = session?.generation;
    final token = explicitCancelToken ?? session?.cancelToken;

    // الجلسة التي أطلقت هذا الطلب لم تعد الجلسة النشطة الآن — لا داعي حتى
    // لإطلاق الطلب فعليًا. `Completer` بلا `complete` أبدًا: انتظار بلا
    // نتيجة، لا استثناء يتوجّب على كل طبقة أعلى توقّعه.
    if (session != null &&
        capturedGeneration != null &&
        !session.isCurrent(capturedGeneration)) {
      return Completer<T>().future;
    }

    try {
      final response = await request(token);

      // الجيل تغيّر أثناء انتظار الرد تحديدًا (logout/login آخر وقع بين
      // إطلاق الطلب واستلام الرد) — النتيجة لا تخص أي جلسة نشطة الآن.
      if (session != null && capturedGeneration != null && !session.isCurrent(capturedGeneration)) {
        return Completer<T>().future;
      }

      return ApiEnvelope.parse<T>(
        response.data,
        parser,
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      if (session != null &&
          capturedGeneration != null &&
          !session.isCurrent(capturedGeneration)) {
        // يشمل `DioExceptionType.cancel` الناتج عن `cancelToken.cancel()`
        // في `SessionRegistry.endSession` — المسار المتوقَّع الشائع.
        return Completer<T>().future;
      }
      final error = e.error;
      if (error is ApiException) throw error;
      throw ApiEnvelope.parseError(
        e.response?.data,
        statusCode: e.response?.statusCode,
      );
    }
  }

  Options? _withIdempotency(String? key) => key == null || key.isEmpty
      ? null
      : Options(extra: {kIdempotencyKey: key});

  /// يحذف المفاتيح ذات القيم الفارغة حتى لا تُرسَل كـ `?x=null`.
  Map<String, dynamic>? _clean(Map<String, dynamic>? query) {
    if (query == null) return null;
    final cleaned = <String, dynamic>{};
    query.forEach((key, value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      cleaned[key] = value;
    });
    return cleaned.isEmpty ? null : cleaned;
  }
}

/// مُحلّلات جاهزة للاستجابات الشائعة.
class Parse {
  const Parse._();

  /// `data: null` — للمسارات التي لا ترجع محتوى.
  static void empty(Object? _) {}

  static Map<String, dynamic> object(Object? data) =>
      data is Map<String, dynamic> ? data : const {};

  static List<Map<String, dynamic>> list(Object? data) => data is List
      ? data.whereType<Map<String, dynamic>>().toList(growable: false)
      : const [];
}
