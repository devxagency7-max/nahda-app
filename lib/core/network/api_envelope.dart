import 'api_error_code.dart';
import 'api_exception.dart';

/// غلاف الاستجابة الموحّد — FLUTTER_API_DOCUMENTATION §3.
///
/// نجاح: `{ "success": true, "data": {...}, "message": null }`
/// خطأ:  `{ "success": false, "error": { "code", "message", "details" } }`
///
/// **كل** استجابة تمرّ من هنا، بما فيها 404 و 429 — العقد ينصّ أن المسارات
/// غير المطابقة وحدود المعدّل ترجع بنفس الشكل، فأي عميل يعامل الـ 404
/// كصفحة HTML سينكسر.
class ApiEnvelope {
  const ApiEnvelope._();

  /// يفكّ غلاف النجاح ويرجع `data` بعد تمريره على [parser].
  ///
  /// يرمي [ApiException] إذا كان الغلاف غلاف خطأ أو غير مفهوم.
  static T parse<T>(
    Object? body,
    T Function(Object? data) parser, {
    int? statusCode,
  }) {
    if (body is! Map<String, dynamic>) {
      throw ApiException(
        code: ApiErrorCode.unknown,
        message: '',
        statusCode: statusCode,
        cause: body,
      );
    }

    if (body['success'] == true) {
      return parser(body['data']);
    }

    throw parseError(body, statusCode: statusCode);
  }

  /// يفكّ غلاف الخطأ. يُستدعى من `ErrorInterceptor` ومن [parse].
  static ApiException parseError(Object? body, {int? statusCode}) {
    if (body is! Map<String, dynamic>) {
      return ApiException(
        code: _codeFromStatus(statusCode),
        message: '',
        statusCode: statusCode,
        cause: body,
      );
    }

    final error = body['error'];
    if (error is! Map<String, dynamic>) {
      return ApiException(
        code: _codeFromStatus(statusCode),
        message: _asString(body['message']) ?? '',
        statusCode: statusCode,
        cause: body,
      );
    }

    return ApiException(
      code: ApiErrorCode.fromWire(_asString(error['code'])),
      message: _asString(error['message']) ?? '',
      statusCode: statusCode,
      details: _parseDetails(error['details']),
    );
  }

  /// `details` — خريطة حقل ← قائمة أسباب.
  ///
  /// الشكل المتوقّع `{"field": ["reason"]}`، لكن نتسامح مع قيمة نصّية مفردة
  /// حتى لا ينهار العميل على شكل غير متوقّع.
  static Map<String, List<String>>? _parseDetails(Object? raw) {
    if (raw is! Map) return null;

    final result = <String, List<String>>{};
    raw.forEach((key, value) {
      final field = key.toString();
      if (value is List) {
        final reasons = value
            .map((e) => e?.toString())
            .whereType<String>()
            .where((e) => e.isNotEmpty)
            .toList();
        if (reasons.isNotEmpty) result[field] = reasons;
      } else if (value != null) {
        final single = value.toString();
        if (single.isNotEmpty) result[field] = [single];
      }
    });

    return result.isEmpty ? null : result;
  }

  /// كود احتياطي حين لا يرسل الخادم غلافًا مفهومًا.
  static ApiErrorCode _codeFromStatus(int? status) => switch (status) {
    401 => ApiErrorCode.unauthorized,
    403 => ApiErrorCode.forbidden,
    404 => ApiErrorCode.notFound,
    409 => ApiErrorCode.concurrencyConflict,
    422 => ApiErrorCode.validationError,
    423 => ApiErrorCode.accountLocked,
    429 => ApiErrorCode.rateLimited,
    503 => ApiErrorCode.storageUnavailable,
    _ when status != null && status >= 500 => ApiErrorCode.internalError,
    _ => ApiErrorCode.unknown,
  };

  static String? _asString(Object? value) =>
      value is String && value.isNotEmpty ? value : null;
}

/// نتيجة مُصفَّحة — FLUTTER_API_DOCUMENTATION §4.
class Paged<T> {
  const Paged({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  final List<T> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  static Paged<T> fromJson<T>(
    Object? data,
    T Function(Map<String, dynamic> item) itemParser,
  ) {
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final rawItems = map['items'];

    return Paged<T>(
      items: rawItems is List
          ? rawItems
                .whereType<Map<String, dynamic>>()
                .map(itemParser)
                .toList(growable: false)
          : const [],
      page: _int(map['page'], 1),
      limit: _int(map['limit'], 20),
      total: _int(map['total'], 0),
      totalPages: _int(map['totalPages'], 0),
      hasNext: map['hasNext'] == true,
      hasPrev: map['hasPrev'] == true,
    );
  }

  static int _int(Object? value, int fallback) => switch (value) {
    final int v => v,
    final num v => v.toInt(),
    final String v => int.tryParse(v) ?? fallback,
    _ => fallback,
  };

  Paged<R> map<R>(R Function(T item) transform) => Paged<R>(
    items: items.map(transform).toList(growable: false),
    page: page,
    limit: limit,
    total: total,
    totalPages: totalPages,
    hasNext: hasNext,
    hasPrev: hasPrev,
  );

  bool get isEmpty => items.isEmpty;
}
