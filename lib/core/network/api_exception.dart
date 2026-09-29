import 'api_error_code.dart';

/// خطأ موحّد من طبقة الشبكة.
///
/// كل فشل — من الخادم أو محلي — يصل للطبقات الأعلى بهذا الشكل فقط.
/// لا تسرّب لـ DioException خارج `lib/core/network/`.
class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.details,
    this.cause,
  });

  final ApiErrorCode code;

  /// رسالة الخادم بالعربية. قد تكون فارغة، لذا استخدم [displayMessage] للعرض.
  final String message;

  final int? statusCode;

  /// أخطاء الحقول من FluentValidation: `{ "nationalId": ["..."] }`.
  ///
  /// **غائب** (لا فارغ) عند عدم وجود أخطاء حقول — §3 من العقد.
  final Map<String, List<String>>? details;

  final Object? cause;

  bool get isRetryable => code.isRetryable;
  bool get isConflict => code.isConflict;
  bool get requiresReauth => code.requiresReauth;

  /// أول رسالة خطأ لحقل معيّن — لعرضها تحت حقل النموذج.
  ///
  /// ملاحظة: مسار البحث يرجع مفاتيح PascalCase (`NationalId`) بينما بقية
  /// المسارات camelCase — لذا المطابقة هنا غير حسّاسة لحالة الأحرف (§21).
  String? fieldError(String field) {
    final map = details;
    if (map == null || map.isEmpty) return null;

    final exact = map[field];
    if (exact != null && exact.isNotEmpty) return exact.first;

    final lower = field.toLowerCase();
    for (final entry in map.entries) {
      if (entry.key.toLowerCase() == lower && entry.value.isNotEmpty) {
        return entry.value.first;
      }
    }
    return null;
  }

  /// رسالة صالحة للعرض للمستخدم بالعربية.
  ///
  /// تُفضَّل رسالة الخادم لأنها الأدق سياقًا؛ وإلا نصّ افتراضي واضح.
  String get displayMessage {
    if (message.trim().isNotEmpty) return message;
    return _fallbackMessage;
  }

  String get _fallbackMessage => switch (code) {
    ApiErrorCode.offline =>
      'يظهر إن النت مقطوع عندك دلوقتي، بس متقلقش — شغلك محفوظ على جهازك وهيتبعت لوحده أول ما النت يرجع.',
    ApiErrorCode.timeout =>
      'النت بطيء شوية ومقدرناش نكمل الطلب. جرّب تاني.',
    ApiErrorCode.invalidCredentials =>
      'الإيميل أو الباسورد مش مظبوط، جرّب تاني.',
    ApiErrorCode.accountLocked =>
      'الحساب اتقفل مؤقتًا بعد كذا محاولة غلط. استنى ربع ساعة وجرّب تاني.',
    ApiErrorCode.platformNotAllowed =>
      'التطبيق ده مخصوص للأخصائيين الاجتماعيين بس.',
    ApiErrorCode.socialWorkerWebBlocked =>
      'الإجراء ده متاح بس من تطبيق الموبايل.',
    ApiErrorCode.rateLimited =>
      'حاولت كذا مرة على طول، استنى شوية وجرّب تاني.',
    ApiErrorCode.forbidden => 'معندكش صلاحية تعمل الإجراء ده.',
    ApiErrorCode.caseNotFound => 'الحالة دي مش موجودة.',
    ApiErrorCode.notFound => 'اللي بتدور عليه مش موجود.',
    ApiErrorCode.concurrencyConflict =>
      'حد تاني عدّل في الحالة دي قبلك. راجع التعديلات قبل ما تحفظ.',
    ApiErrorCode.invalidStatusTransition =>
      'الإجراء ده بقى مش متاح — حالة الملف اتغيّرت.',
    ApiErrorCode.opinionSlotLocked => 'الرأي اتبعت خلاص ومينفعش يتعدّل.',
    ApiErrorCode.caseAlreadyApproved => 'الحالة دي اتاعتمدت خلاص بشكل نهائي.',
    ApiErrorCode.validationError => 'في حاجة غلط في البيانات اللي دخلتها.',
    ApiErrorCode.duplicateNationalId => 'في حالة مسجّلة خلاص بنفس الرقم القومي ده.',
    ApiErrorCode.duplicateResource => 'العنصر ده مسجّل خلاص.',
    ApiErrorCode.fileTooLarge => 'حجم الملف أكبر من ١٠ ميجا، صغّره وجرّب تاني.',
    ApiErrorCode.unsupportedFileType => 'نوع الملف ده مش مدعوم.',
    ApiErrorCode.storageUnavailable =>
      'خدمة رفع الملفات مش شغالة دلوقتي. هنعيد المحاولة لوحدنا.',
    ApiErrorCode.internalError => 'حصلت مشكلة من عندنا، جرّب تاني كمان شوية.',
    ApiErrorCode.idempotencyKeyRequired => 'في مشكلة فنية بسيطة في الطلب.',
    _ => 'حصل خطأ مش متوقع، جرّب تاني.',
  };

  ApiException copyWith({ApiErrorCode? code, String? message}) => ApiException(
    code: code ?? this.code,
    message: message ?? this.message,
    statusCode: statusCode,
    details: details,
    cause: cause,
  );

  @override
  String toString() =>
      'ApiException(${code.wireValue}, http=$statusCode, message="$message"'
      '${details != null ? ', details=$details' : ''})';
}
