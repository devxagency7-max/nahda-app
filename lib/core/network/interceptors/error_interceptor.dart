import 'package:dio/dio.dart';

import '../api_error_code.dart';
import '../api_envelope.dart';
import '../api_exception.dart';

/// يحوّل كل فشل إلى [ApiException] قبل أن يغادر طبقة الشبكة.
///
/// بعد هذا الـ interceptor لا يرى أي كود في التطبيق `DioException` إطلاقًا.
class ErrorInterceptor extends Interceptor {
  const ErrorInterceptor();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // خطأ سبق تحويله (مثلًا رفض من AuthInterceptor) — يُمرَّر كما هو.
    if (err.error is ApiException) {
      return handler.next(err);
    }

    final apiError = switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => const ApiException(
        code: ApiErrorCode.timeout,
        message: '',
      ),

      DioExceptionType.connectionError => const ApiException(
        code: ApiErrorCode.offline,
        message: '',
      ),

      DioExceptionType.cancel => const ApiException(
        code: ApiErrorCode.unknown,
        message: 'تم إلغاء الطلب.',
      ),

      // badResponse وغيرها: الخادم ردّ فعليًا — نفكّ الغلاف.
      _ => ApiEnvelope.parseError(
        err.response?.data,
        statusCode: err.response?.statusCode,
      ),
    };

    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: apiError,
        stackTrace: err.stackTrace,
      ),
    );
  }
}
