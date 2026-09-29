import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers/app_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/profile_api.dart';
import '../data/profile_dto.dart';
import '../data/profile_repository.dart';

final profileApiProvider = Provider<ProfileApi>(
  (ref) => ProfileApi(ref.watch(apiClientProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(api: ref.watch(profileApiProvider)),
);

/// حالة شاشة البروفايل — **أونلاين فقط**، لا كاش محلي (راجع توثيق
/// [ProfileRepository]). الفشل يُترجَم إلى [AsyncError] فتعرضه الشاشة
/// صراحةً، لا بيانات قديمة صامتة.
final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, ProfileDto>(
      UserProfileNotifier.new,
    );

class UserProfileNotifier extends AsyncNotifier<ProfileDto> {
  @override
  Future<ProfileDto> build() {
    // `ref.watch` لا `ref.read` هنا عمدًا — يجعل هذا الـ Notifier auth-aware:
    // أي تغيّر في هوية المستخدم الحالي (logout ثم login بحساب آخر) يعيد
    // بناء `build()` من الصفر بدل الاحتفاظ بملف الحساب السابق معلَّقًا في
    // الذاكرة (AUTH_SESSION_AUDIT.md، مشكلة #5 CRITICAL). القيمة نفسها غير
    // مستخدَمة — الغرض فقط ربط دورة حياة هذا الـ Provider بحالة المصادقة.
    ref.watch(currentUserProvider);
    return _repo.fetch();
  }

  ProfileRepository get _repo => ref.read(profileRepositoryProvider);

  /// يعيد الجلب من الخادم — يُستخدَم لأخذ `rowVersion` طازج قبل [update]
  /// إن كانت الشاشة مفتوحة منذ فترة.
  Future<void> refresh() async {
    state = const AsyncLoading<ProfileDto>().copyWithPrevious(state);
    state = await AsyncValue.guard(_repo.fetch);
  }

  /// يرمي [ApiException] عند الرفض — الشاشة تعرض رسالة الخادم بدل ابتلاعها.
  Future<void> updateField({
    String? fullName,
    String? phone,
    String? gender,
    String? region,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final previous = state;
    // نجلب نسخة طازجة أولًا: `rowVersion` المعروض قد يكون قديمًا لو مضى
    // وقت منذ فتح الشاشة (تعديل من جهاز آخر، أو من نفس الحساب سابقًا).
    final fresh = await _repo.fetch();

    state = const AsyncLoading<ProfileDto>().copyWithPrevious(previous);
    try {
      final updated = await _repo.update(
        fullName: fullName ?? fresh.fullName,
        phone: phone ?? fresh.phone,
        gender: gender ?? fresh.gender,
        region: region ?? fresh.region,
        rowVersion: fresh.rowVersion,
      );
      state = AsyncData(updated);
    } on ApiException {
      state = AsyncData(fresh);
      rethrow;
    }
  }

  /// يلتقط صورة (معرض/كاميرا)، يرفعها، ويحدّث الحالة بالبروفايل الناتج —
  /// **`rowVersion` الجديد يحل محل القديم تلقائيًا** (هو ناتج نفس استدعاء
  /// الرفع)، فلا حاجة لجلب إضافي بعده مباشرة.
  Future<void> pickAndUploadAvatar(ImageSource source) async {
    final previous = state;
    final XFile? picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;

    state = const AsyncLoading<ProfileDto>().copyWithPrevious(previous);
    state = await AsyncValue.guard(() => _repo.uploadAvatar(File(picked.path)));
  }

  Future<void> deleteAvatar() async {
    final previous = state;
    state = const AsyncLoading<ProfileDto>().copyWithPrevious(previous);
    state = await AsyncValue.guard(_repo.deleteAvatar);
  }
}
