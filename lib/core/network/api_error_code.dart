/// كتالوج أكواد الخطأ — FLUTTER_API_DOCUMENTATION §8.
///
/// الكود هو ما يُعتمد عليه في المنطق، لا رسالة الخادم ولا كود HTTP.
library;

enum ApiErrorCode {
  // مصادقة وصلاحيات
  unauthorized('UNAUTHORIZED'),
  forbidden('FORBIDDEN'),
  invalidCredentials('INVALID_CREDENTIALS'),
  accountLocked('ACCOUNT_LOCKED'),
  platformNotAllowed('PLATFORM_NOT_ALLOWED'),
  socialWorkerWebBlocked('SOCIAL_WORKER_WEB_BLOCKED'),

  // دورة حياة التوكن
  tokenExpired('TOKEN_EXPIRED'),
  tokenRevoked('TOKEN_REVOKED'),
  tokenInvalid('TOKEN_INVALID'),

  // تحقق وبيانات
  validationError('VALIDATION_ERROR'),
  notFound('NOT_FOUND'),
  caseNotFound('CASE_NOT_FOUND'),
  duplicateResource('DUPLICATE_RESOURCE'),
  duplicateNationalId('DUPLICATE_NATIONAL_ID'),
  deleteConflict('DELETE_CONFLICT'),

  // تزامن وسير عمل
  concurrencyConflict('CONCURRENCY_CONFLICT'),
  invalidStatusTransition('INVALID_STATUS_TRANSITION'),
  opinionSlotLocked('OPINION_SLOT_LOCKED'),
  missingWorkerOpinion('MISSING_WORKER_OPINION'),
  caseAlreadyApproved('CASE_ALREADY_APPROVED'),
  idempotencyKeyRequired('IDEMPOTENCY_KEY_REQUIRED'),

  // مرفقات
  fileTooLarge('FILE_TOO_LARGE'),
  unsupportedFileType('UNSUPPORTED_FILE_TYPE'),
  storageUnavailable('STORAGE_UNAVAILABLE'),

  // عام
  rateLimited('RATE_LIMITED'),
  internalError('INTERNAL_ERROR'),

  /// الجهاز بلا اتصال — كود محلي، لا يأتي من الخادم أبدًا.
  offline('OFFLINE'),

  /// انتهت المهلة — كود محلي.
  timeout('TIMEOUT'),

  /// استجابة لم نستطع تفسيرها — كود محلي.
  unknown('UNKNOWN');

  const ApiErrorCode(this.wireValue);

  final String wireValue;

  static ApiErrorCode fromWire(String? value) {
    if (value == null) return ApiErrorCode.unknown;
    for (final code in ApiErrorCode.values) {
      if (code.wireValue == value) return code;
    }
    return ApiErrorCode.unknown;
  }

  /// هل يُحَل هذا الخطأ بإعادة المحاولة لاحقًا؟
  ///
  /// مهم لمحرّك المزامنة: خطأ غير قابل لإعادة المحاولة لا يُترك في الطابور
  /// يستهلك محاولات بلا طائل.
  bool get isRetryable => switch (this) {
    ApiErrorCode.offline ||
    ApiErrorCode.timeout ||
    ApiErrorCode.internalError ||
    ApiErrorCode.storageUnavailable ||
    ApiErrorCode.rateLimited => true,
    _ => false,
  };

  /// هل يعني هذا الخطأ أن الحالة تغيّرت على الخادم بينما كنّا أوفلاين؟
  ///
  /// عند مواجهته يتوقف تفريغ باقي طابور هذه الحالة ويُعرض تعارض
  /// (§14.4 — "لا تُكمل الإعادة على افتراض قديم").
  bool get isConflict => switch (this) {
    ApiErrorCode.concurrencyConflict ||
    ApiErrorCode.invalidStatusTransition ||
    ApiErrorCode.opinionSlotLocked ||
    ApiErrorCode.caseAlreadyApproved ||
    ApiErrorCode.forbidden => true,
    _ => false,
  };

  /// هل يستوجب تسجيل خروج فوري؟
  bool get requiresReauth => switch (this) {
    ApiErrorCode.tokenExpired ||
    ApiErrorCode.tokenRevoked ||
    ApiErrorCode.tokenInvalid ||
    ApiErrorCode.unauthorized => true,
    _ => false,
  };
}
