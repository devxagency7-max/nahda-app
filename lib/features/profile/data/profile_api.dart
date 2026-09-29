import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error_code.dart';
import '../../../core/network/api_exception.dart';
import 'profile_dto.dart';

/// نتيجة `/profile/avatar/init`.
class InitAvatarUploadResult {
  const InitAvatarUploadResult({required this.uploadUrl, required this.mimeType});

  final String uploadUrl;
  final String mimeType;

  static InitAvatarUploadResult fromJson(Object? data) {
    final json = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    return InitAvatarUploadResult(
      uploadUrl: json['uploadUrl'] as String? ?? '',
      mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
    );
  }
}

/// مسارات البروفايل — `GET/PUT /profile` وصورة الحساب.
///
/// **أونلاين فقط** — بخلاف بيانات الحالات، بيانات الحساب لا تُخزَّن في طابور
/// مزامنة ولا كاش محلي: تعديلها نادر، ولا معنى لعرض نسخة قديمة منها أوفلاين.
class ProfileApi {
  ProfileApi(this._client) : _storageDio = Dio();

  final ApiClient _client;

  /// عميل منفصل للرفع المباشر إلى R2 — بلا `Authorization` (نفس نمط
  /// [AttachmentsApi]: التوقيع داخل الرابط نفسه).
  final Dio _storageDio;

  Future<ProfileDto> get() =>
      _client.get<ProfileDto>('/profile', ProfileDto.fromJson);

  /// `PUT /profile` — [rowVersion] يجب أن يكون أحدث نسخة معروفة (راجع
  /// توثيق [ProfileDto.rowVersion]).
  Future<ProfileDto> update({
    required String fullName,
    required String phone,
    required String gender,
    required String region,
    required int rowVersion,
  }) => _client.put<ProfileDto>(
    '/profile',
    ProfileDto.fromJson,
    body: {
      'fullName': fullName,
      'phone': phone,
      'gender': gender,
      'region': region,
      'rowVersion': rowVersion,
    },
  );

  Future<InitAvatarUploadResult> initAvatarUpload({
    required String fileName,
    required String mimeType,
    required int fileSize,
  }) => _client.post<InitAvatarUploadResult>(
    '/profile/avatar/init',
    InitAvatarUploadResult.fromJson,
    body: {'fileName': fileName, 'mimeType': mimeType, 'fileSize': fileSize},
  );

  Future<void> uploadAvatarBytes({
    required String uploadUrl,
    required File file,
    required String mimeType,
  }) async {
    final length = await file.length();
    try {
      await _storageDio.put<void>(
        uploadUrl,
        data: file.openRead(),
        options: Options(
          headers: {
            Headers.contentTypeHeader: mimeType,
            Headers.contentLengthHeader: length,
          },
        ),
      );
    } on DioException catch (e) {
      throw _storageError(e);
    }
  }

  Future<ProfileDto> confirmAvatarUpload() =>
      _client.post<ProfileDto>('/profile/avatar/confirm', ProfileDto.fromJson);

  Future<ProfileDto> deleteAvatar() =>
      _client.delete<ProfileDto>('/profile/avatar', ProfileDto.fromJson);

  ApiException _storageError(DioException e) {
    if (e.type == DioExceptionType.connectionError) {
      return const ApiException(code: ApiErrorCode.offline, message: '');
    }
    if (e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionTimeout) {
      return const ApiException(code: ApiErrorCode.timeout, message: '');
    }
    return ApiException(
      code: ApiErrorCode.storageUnavailable,
      message: 'تعذّر رفع الصورة. حاول مرة أخرى.',
      statusCode: e.response?.statusCode,
      cause: e,
    );
  }
}
