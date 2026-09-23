import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/domain/auth_user.dart';
import '../../auth/presentation/auth_controller.dart';

class UserProfileData {
  final String name;
  final String email;
  final String gender;
  final String phone;
  final String region;
  final String? imagePath;
  final String avatarEmoji;

  const UserProfileData({
    required this.name,
    required this.email,
    required this.gender,
    required this.phone,
    required this.region,
    this.imagePath,
    this.avatarEmoji = '👨‍💼',
  });

  UserProfileData copyWith({
    String? name,
    String? email,
    String? gender,
    String? phone,
    String? region,
    String? imagePath,
    String? avatarEmoji,
  }) {
    return UserProfileData(
      name: name ?? this.name,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      region: region ?? this.region,
      imagePath: imagePath ?? this.imagePath,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
    );
  }
}

class UserProfileNotifier extends StateNotifier<UserProfileData> {
  UserProfileNotifier({AuthUser? user})
      : super(
          UserProfileData(
            name: user?.fullName ?? '',
            email: user?.email ?? '',
            gender: '',
            phone: '',
            region: '',
          ),
        );

  void updateName(String newName) {
    if (newName.trim().isNotEmpty) {
      state = state.copyWith(name: newName.trim());
    }
  }

  void updateEmail(String newEmail) {
    if (newEmail.trim().isNotEmpty) {
      state = state.copyWith(email: newEmail.trim());
    }
  }

  void updateGender(String newGender) {
    if (newGender.trim().isNotEmpty) {
      state = state.copyWith(gender: newGender.trim());
    }
  }

  void updatePhone(String newPhone) {
    if (newPhone.trim().isNotEmpty) {
      state = state.copyWith(phone: newPhone.trim());
    }
  }

  void updateRegion(String newRegion) {
    if (newRegion.trim().isNotEmpty) {
      state = state.copyWith(region: newRegion.trim());
    }
  }

  void updateEmoji(String emoji) {
    state = state.copyWith(avatarEmoji: emoji, imagePath: null);
  }

  Future<bool> pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        state = state.copyWith(imagePath: pickedFile.path);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> pickImageFromCamera() async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        state = state.copyWith(imagePath: pickedFile.path);
        return true;
      }
    } catch (_) {}
    return false;
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfileData>((ref) {
  final user = ref.watch(currentUserProvider);
  return UserProfileNotifier(user: user);
});
