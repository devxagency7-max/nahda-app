import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../core/network/api_error_code.dart';
import '../../../core/network/api_exception.dart';
import '../../attachments/domain/upload_stage.dart';
import 'profile_api.dart';
import 'profile_dto.dart';

/// مستودع البروفايل — طبقة رفيعة فوق [ProfileApi] تضمن الالتزام بترتيب
/// العقد: أي `PUT /profile` يحمل **أحدث** `rowVersion` معروف، لا نسخة
/// مخزَّنة من شاشة سابقة (راجع توثيق [ProfileDto.rowVersion]).
class ProfileRepository {
  ProfileRepository({required ProfileApi api}) : _api = api;

  final ProfileApi _api;

  Future<ProfileDto> fetch() => _api.get();

  /// [rowVersion] **يجب** أن يأتي من [fetch] استُدعيت في نفس الجلسة —
  /// لا يُقبل ممرَّرًا من حالة قديمة (§ ملاحظة الباك إند).
  Future<ProfileDto> update({
    required String fullName,
    required String phone,
    required String gender,
    required String region,
    required int rowVersion,
  }) => _api.update(
    fullName: fullName,
    phone: phone,
    gender: gender,
    region: region,
    rowVersion: rowVersion,
  );

  /// يرفع صورة شخصية جديدة كاملة (init → رفع → confirm) ويرجع البروفايل
  /// المُحدَّث — **يحمل `rowVersion` جديدًا** لأن رفع الصورة نفسه يغيّره؛
  /// المستدعي يجب أن يستبدل أي `rowVersion` محفوظ لديه بهذا الناتج قبل أي
  /// `update` تالٍ.
  Future<ProfileDto> uploadAvatar(File file) async {
    final fileName = p.basename(file.path);
    final mimeType = AttachmentPolicy.mimeFor(fileName);
    if (mimeType == null) {
      throw const ApiException(
        code: ApiErrorCode.unsupportedFileType,
        message: 'نوع الصورة غير مدعوم.',
      );
    }

    final size = await file.length();
    final rejection = AttachmentPolicy.validate(fileName: fileName, sizeBytes: size);
    if (rejection != null) {
      throw ApiException(
        code: size > AttachmentPolicy.maxFileSizeBytes
            ? ApiErrorCode.fileTooLarge
            : ApiErrorCode.unsupportedFileType,
        message: rejection,
      );
    }

    final init = await _api.initAvatarUpload(
      fileName: fileName,
      mimeType: mimeType,
      fileSize: size,
    );
    await _api.uploadAvatarBytes(
      uploadUrl: init.uploadUrl,
      file: file,
      mimeType: init.mimeType,
    );
    return _api.confirmAvatarUpload();
  }

  /// يحذف الصورة الشخصية ويرجع البروفايل المُحدَّث (بـ `rowVersion` جديد).
  Future<ProfileDto> deleteAvatar() => _api.deleteAvatar();
}
