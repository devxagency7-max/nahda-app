import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_background.dart';
import '../../auth/presentation/login_screen.dart';
import 'user_profile_provider.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const UserProfileScreen(),
      ),
    );
  }

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  final List<String> _sampleAvatars = [
    '👨‍💼',
    '👨‍🦱',
    '🧔',
    '👨',
    '🧑',
    '👩‍💼',
  ];

  void _showChangePhotoModal() {
    final profileNotifier = ref.read(userProfileProvider.notifier);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'تغيير الصورة الشخصية',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Action Options: Gallery & Camera
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      final success = await profileNotifier.pickImageFromGallery();
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم اختيار وتحديث الصورة الشخصية من المعرض بنجاح'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('معرض الصور'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      final success = await profileNotifier.pickImageFromCamera();
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم التقات الصورة من الكاميرا وتحديث البروفايل'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: const Text('الكاميرا'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),
            const Text(
              'أو اختر أيقونة شخصية جاهزة:',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.md),

            // Sample Emoji Avatars
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_sampleAvatars.length, (index) {
                final emoji = _sampleAvatars[index];
                return InkWell(
                  onTap: () {
                    profileNotifier.updateEmoji(emoji);
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم تحديث الصورة الشخصية بنجاح'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  void _showEditFieldDialog({
    required String title,
    required String initialValue,
    required void Function(String val) onSave,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.edit, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'تعديل $title',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: 'أدخل $title الجديد...',
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final newValue = controller.text.trim();
              if (newValue.isNotEmpty) {
                onSave(newValue);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم تعديل $title بنجاح'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('حفظ التعديل'),
          ),
        ],
      ),
    );
  }

  void _showEditGenderDialog(String currentGender) {
    final notifier = ref.read(userProfileProvider.notifier);
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'اختر النوع',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        children: [
          SimpleDialogOption(
            onPressed: () {
              notifier.updateGender('ذكر');
              Navigator.of(ctx).pop();
            },
            child: const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text(
                '👨 ذكر',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const Divider(height: 1),
          SimpleDialogOption(
            onPressed: () {
              notifier.updateGender('أنثى');
              Navigator.of(ctx).pop();
            },
            child: const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text(
                '👩 أنثى',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final profileNotifier = ref.read(userProfileProvider.notifier);

    Widget avatarWidget;
    if (profile.imagePath != null &&
        profile.imagePath!.isNotEmpty &&
        !kIsWeb &&
        File(profile.imagePath!).existsSync()) {
      avatarWidget = CircleAvatar(
        radius: 46,
        backgroundImage: FileImage(File(profile.imagePath!)),
      );
    } else if (profile.avatarEmoji.isNotEmpty && profile.avatarEmoji != '👨‍💼') {
      avatarWidget = CircleAvatar(
        radius: 46,
        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
        child: Text(
          profile.avatarEmoji,
          style: const TextStyle(fontSize: 42),
        ),
      );
    } else {
      avatarWidget = CircleAvatar(
        radius: 46,
        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
        child: Text(
          profile.name.isEmpty ? 'م' : profile.name.substring(0, 1),
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      );
    }

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('الملف الشخصي'),
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // User Header Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Avatar with Camera Icon Badge (Clickable to change photo)
                  Stack(
                    children: [
                      avatarWidget,
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _showChangePhotoModal,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: _showChangePhotoModal,
                    icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                    label: const Text(
                      'تغيير الصورة الشخصية',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Name Row with Edit Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        profile.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _showEditFieldDialog(
                          title: 'الاسم',
                          initialValue: profile.name,
                          onSave: profileNotifier.updateName,
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                        tooltip: 'تعديل الاسم',
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'أخصائي اجتماعي ميداني معتمد',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Profile Details Section (All Editable)
            Row(
              children: [
                const Text(
                  'بيانات الحساب والتواصل',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                const Text(
                  'اضغط على أي خانة للتعديل',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildEditableProfileTile(
                    icon: Icons.email_outlined,
                    label: 'البريد الإلكتروني',
                    value: profile.email,
                    onTap: () => _showEditFieldDialog(
                      title: 'البريد الإلكتروني',
                      initialValue: profile.email,
                      keyboardType: TextInputType.emailAddress,
                      onSave: profileNotifier.updateEmail,
                    ),
                  ),
                  const Divider(height: 18, color: AppColors.border),
                  _buildEditableProfileTile(
                    icon: Icons.wc_outlined,
                    label: 'النوع',
                    value: profile.gender,
                    onTap: () => _showEditGenderDialog(profile.gender),
                  ),
                  const Divider(height: 18, color: AppColors.border),
                  _buildEditableProfileTile(
                    icon: Icons.location_on_outlined,
                    label: 'المنطقة الجغرافية المسندة',
                    value: profile.region,
                    onTap: () => _showEditFieldDialog(
                      title: 'المنطقة الجغرافية',
                      initialValue: profile.region,
                      onSave: profileNotifier.updateRegion,
                    ),
                  ),
                  const Divider(height: 18, color: AppColors.border),
                  _buildEditableProfileTile(
                    icon: Icons.phone_outlined,
                    label: 'رقم الهاتف المسجل',
                    value: profile.phone,
                    onTap: () => _showEditFieldDialog(
                      title: 'رقم الهاتف',
                      initialValue: profile.phone,
                      keyboardType: TextInputType.phone,
                      onSave: profileNotifier.updatePhone,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Logout Button
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout, color: AppColors.danger, size: 18),
              label: const Text(
                'تسجيل الخروج من الحساب',
                style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.danger),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableProfileTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_outlined, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
