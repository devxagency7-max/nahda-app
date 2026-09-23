import 'package:dio/dio.dart';

import '../config/app_config.dart';
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
/// **قاعدة معمارية:** هذا الصنف يُستخدم من `*_api.dart` (طبقة remote) فقط،
/// ويستدعيها `SyncEngine` وحده. الـ repositories لا تلمس الشبكة مباشرة —
/// تكتب في Drift وتضيف للطابور. راجع §2.2 من خطة الربط.
class ApiClient {
  ApiClient._(this._dio);

  final Dio _dio;

  Dio get raw => _dio;

  factory ApiClient.create({
    required SecureTokenStore tokenStore,
    required Future<void> Function() onSessionExpired,
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

    return ApiClient._(dio);
  }

  Future<T> get<T>(
    String path,
    T Function(Object? data) parser, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) => _send(
    parser,
    () => _dio.get<dynamic>(
      path,
      queryParameters: _clean(query),
      cancelToken: cancelToken,
    ),
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
    () => _dio.post<dynamic>(
      path,
      data: body,
      queryParameters: _clean(query),
      cancelToken: cancelToken,
      options: _withIdempotency(idempotencyKey),
    ),
  );

  Future<T> put<T>(
    String path,
    T Function(Object? data) parser, {
    Object? body,
    String? idempotencyKey,
    CancelToken? cancelToken,
  }) => _send(
    parser,
    () => _dio.put<dynamic>(
      path,
      data: body,
      cancelToken: cancelToken,
      options: _withIdempotency(idempotencyKey),
    ),
  );

  Future<T> delete<T>(
    String path,
    T Function(Object? data) parser, {
    Object? body,
    CancelToken? cancelToken,
  }) => _send(
    parser,
    () => _dio.delete<dynamic>(path, data: body, cancelToken: cancelToken),
  );

  /// إرسال الترويسات الخاصة بالمصادقة (`X-Client-Type`) — §2.1.
  ///
  /// مقصورة على login/refresh/logout؛ لا تُرسَل مع المسارات المحمية.
  Future<T> postAuth<T>(
    String path,
    T Function(Object? data) parser, {
    Object? body,
  }) => _send(
    parser,
    () => _dio.post<dynamic>(
      path,
      data: body,
      options: Options(
        headers: {'X-Client-Type': AppConfig.clientType},
        extra: {kSkipAuthRefresh: true},
      ),
    ),
  );

  Future<T> _send<T>(
    T Function(Object? data) parser,
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final response = await request();
      return ApiEnvelope.parse<T>(
        response.data,
        parser,
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
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
