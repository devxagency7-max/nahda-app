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
      'لا يوجد اتصال بالإنترنت. تم حفظ عملك على الجهاز وسيُرفَع تلقائيًا عند عودة الاتصال.',
    ApiErrorCode.timeout =>
      'انتهت مهلة الاتصال. تحقق من الشبكة وحاول مرة أخرى.',
    ApiErrorCode.invalidCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
    ApiErrorCode.accountLocked =>
      'تم قفل الحساب مؤقتًا بعد عدة محاولات خاطئة. حاول بعد ١٥ دقيقة.',
    ApiErrorCode.platformNotAllowed =>
      'هذا التطبيق مخصص للأخصائيين الاجتماعيين فقط.',
    ApiErrorCode.socialWorkerWebBlocked =>
      'لا يمكن تنفيذ هذا الإجراء من خارج تطبيق الموبايل.',
    ApiErrorCode.rateLimited =>
      'عدد المحاولات كبير. انتظر قليلًا ثم حاول مرة أخرى.',
    ApiErrorCode.forbidden => 'ليس لديك صلاحية لتنفيذ هذا الإجراء.',
    ApiErrorCode.caseNotFound => 'الحالة غير موجودة.',
    ApiErrorCode.notFound => 'العنصر المطلوب غير موجود.',
    ApiErrorCode.concurrencyConflict =>
      'تم تعديل هذه الحالة من جهة أخرى. راجع التعديلات قبل الحفظ.',
    ApiErrorCode.invalidStatusTransition =>
      'لم يعد هذا الإجراء متاحًا — تغيّرت حالة الملف.',
    ApiErrorCode.opinionSlotLocked => 'تم إرسال الرأي مسبقًا ولا يمكن تعديله.',
    ApiErrorCode.caseAlreadyApproved => 'تم اعتماد هذه الحالة نهائيًا.',
    ApiErrorCode.validationError => 'يوجد خطأ في البيانات المُدخَلة.',
    ApiErrorCode.duplicateNationalId => 'يوجد حالة مسجلة بالفعل بهذا الرقم القومي.',
    ApiErrorCode.duplicateResource => 'هذا العنصر مسجل بالفعل.',
    ApiErrorCode.fileTooLarge => 'حجم الملف يتجاوز ١٠ ميجابايت.',
    ApiErrorCode.unsupportedFileType => 'نوع الملف غير مدعوم.',
    ApiErrorCode.storageUnavailable =>
      'خدمة رفع الملفات غير متاحة حاليًا. سيُعاد المحاولة تلقائيًا.',
    ApiErrorCode.internalError => 'حدث خطأ في الخادم. حاول مرة أخرى.',
    ApiErrorCode.idempotencyKeyRequired => 'خطأ فني في الطلب.',
    _ => 'حدث خطأ غير متوقع. حاول مرة أخرى.',
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
