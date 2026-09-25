import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_error_code.dart';
import '../../../core/network/api_exception.dart';

/// نتيجة `/attachments/init`.
class InitUploadResult {
  const InitUploadResult({
    required this.attachmentId,
    required this.uploadUrl,
    required this.mimeType,
    required this.expiresAtUtc,
  });

  final String attachmentId;
  final String uploadUrl;

  /// **يُرسَل حرفيًا** كـ `Content-Type` في خطوة الرفع.
  final String mimeType;

  final DateTime? expiresAtUtc;

  bool get isExpired =>
      expiresAtUtc != null && DateTime.now().toUtc().isAfter(expiresAtUtc!);

  static InitUploadResult fromJson(Object? data) {
    final json = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    return InitUploadResult(
      attachmentId: json['attachmentId'] as String? ?? '',
      uploadUrl: json['uploadUrl'] as String? ?? '',
      mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
      expiresAtUtc: json['uploadUrlExpiresAtUtc'] is String
          ? DateTime.tryParse(json['uploadUrlExpiresAtUtc'] as String)?.toUtc()
          : null,
    );
  }
}

/// نتيجة `/attachments/{id}/commit`.
class CommitResult {
  const CommitResult({required this.alreadyComplete});

  /// `true` حين كان المرفق مُثبَّتًا أصلًا — دليل نجاح محاولة سابقة ضاع ردّها.
  final bool alreadyComplete;

  static CommitResult fromJson(Object? data) {
    final json = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    return CommitResult(alreadyComplete: json['alreadyComplete'] == true);
  }
}

/// مسارات المرفقات — §13 و §21.
class AttachmentsApi {
  AttachmentsApi(this._client) : _storageDio = Dio();

  final ApiClient _client;

  /// عميل منفصل للرفع المباشر إلى التخزين.
  ///
  /// الرفع **لا يمرّ عبر واجهة نهضة** ولا يحمل `Authorization` — التوقيع داخل
  /// الرابط نفسه، وإرسال التوكن لطرف ثالث تسريب.
  final Dio _storageDio;

  /// الخطوة ١: حجز مرفق والحصول على رابط رفع موقّع.
  ///
  /// **غير idempotent** — كل استدعاء يُنشئ `attachmentId` جديدًا ومرفقًا يتيمًا
  /// إن لم يُستكمَل. لا يُستدعى إلا والجهاز متصل ومستعد للرفع فورًا (§14.2).
  Future<InitUploadResult> init({
    required String caseId,
    required String documentType,
    required String fileName,
    required String mimeType,
    required int fileSize,
    String? description,
  }) => _client.post<InitUploadResult>(
    '/attachments/init',
    InitUploadResult.fromJson,
    body: {
      'caseId': caseId,
      'documentType': documentType,
      'fileName': fileName,
      'mimeType': mimeType,
      'fileSize': fileSize,
      'description': description,
    },
  );

  /// الخطوة ٢: رفع البايتات مباشرة للتخزين.
  ///
  /// `Content-Type` يطابق `mimeType` المُرجَع من `/init` **حرفيًا**.
  Future<void> uploadBytes({
    required String uploadUrl,
    required File file,
    required String mimeType,
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final length = await file.length();

    try {
      await _storageDio.put<void>(
        uploadUrl,
        data: file.openRead(),
        cancelToken: cancelToken,
        onSendProgress: onProgress,
        options: Options(
          headers: {
            Headers.contentTypeHeader: mimeType,
            Headers.contentLengthHeader: length,
          },
          sendTimeout: AppConfig.uploadTimeout,
          receiveTimeout: AppConfig.uploadTimeout,
        ),
      );
    } on DioException catch (e) {
      throw _storageError(e);
    }
  }

  /// الخطوة ٣: تثبيت المرفق.
  ///
  /// **الكتابة الوحيدة في النظام الآمنة لإعادة المحاولة بلا مفتاح** (§14.1):
  /// استدعاؤها على مرفق مُثبَّت يرجع `200` بـ `alreadyComplete: true` دون أثر
  /// جانبي. نستند إليها حين يضيع ردّ محاولة سابقة.
  ///
  /// `checksum` اختياري — الخادم يتحقق من الوجود والحجم والنوع الحقيقي بدونه.
  Future<CommitResult> commit(String attachmentId, {String? checksum}) =>
      _client.post<CommitResult>(
        '/attachments/$attachmentId/commit',
        CommitResult.fromJson,
        body: {if (checksum != null) 'checksum': checksum},
      );

  /// `GET /attachments/{id}/download` — رابط جديد صالح ١٥ دقيقة كل مرة.
  ///
  /// **لا يُخزَّن ولا يُعاد استخدامه** عبر الجلسات (§15.6).
  Future<String> downloadUrl(String attachmentId) => _client.get<String>(
    '/attachments/$attachmentId/download',
    (data) => data is Map<String, dynamic>
        ? (data['downloadUrl'] as String? ?? '')
        : '',
  );

  Future<void> delete(String attachmentId) =>
      _client.delete<void>('/attachments/$attachmentId', Parse.empty);

  /// `GET /cases/{id}/attachments` — بيانات وصفية بلا روابط تحميل.
  Future<Paged<Map<String, dynamic>>> listForCase(
    String caseId, {
    int page = 1,
    int limit = 20,
  }) => _client.get<Paged<Map<String, dynamic>>>(
    '/cases/$caseId/attachments',
    (data) => Paged.fromJson(data, (item) => item),
    query: {'page': page, 'limit': limit},
  );

  /// أخطاء التخزين لا تتبع غلاف نهضة — نحوّلها يدويًا.
  ApiException _storageError(DioException e) {
    final status = e.response?.statusCode;

    if (e.type == DioExceptionType.connectionError) {
      return const ApiException(code: ApiErrorCode.offline, message: '');
    }
    if (e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionTimeout) {
      return const ApiException(code: ApiErrorCode.timeout, message: '');
    }

    // 403 من التخزين يعني رابطًا موقّعًا منتهيًا — قابل للحل بـ /init جديد،
    // لا "ممنوع" بالمعنى المعتاد.
    if (status == 403) {
      return const ApiException(
        code: ApiErrorCode.storageUnavailable,
        message: 'انتهت صلاحية رابط الرفع. سيُعاد المحاولة تلقائيًا.',
        statusCode: 403,
      );
    }

    return ApiException(
      code: ApiErrorCode.storageUnavailable,
      message: 'تعذّر رفع الملف. سيُعاد المحاولة تلقائيًا.',
      statusCode: status,
      cause: e,
    );
  }
}
