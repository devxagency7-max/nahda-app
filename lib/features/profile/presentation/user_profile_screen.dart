import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_background.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/login_screen.dart';
import '../data/profile_dto.dart';
import 'user_profile_provider.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const UserProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('الملف الشخصي'), elevation: 0),
        body: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ProfileErrorState(
            error: error,
            onRetry: () => ref.read(userProfileProvider.notifier).refresh(),
          ),
          data: (profile) => _ProfileBody(profile: profile),
        ),
      ),
    );
  }
}

class _ProfileErrorState extends StatelessWidget {
  const _ProfileErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = error is ApiException
        ? (error as ApiException).displayMessage
        : 'تعذّر تحميل الملف الشخصي.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 40, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
          ],
        ),
      ),
    );
  }
}

class _ProfileBody extends ConsumerStatefulWidget {
  const _ProfileBody({required this.profile});

  final ProfileDto profile;

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody> {
  bool _busy = false;

  Future<void> _runGuarded(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
    } on ApiException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(e.displayMessage), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showChangePhotoModal() {
    final notifier = ref.read(userProfileProvider.notifier);

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
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _runGuarded(() => notifier.pickAndUploadAvatar(ImageSource.gallery));
                    },
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('معرض الصور'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _runGuarded(() => notifier.pickAndUploadAvatar(ImageSource.camera));
                    },
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: const Text('الكاميرا'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            if (widget.profile.avatarUrl != null) ...[
              const SizedBox(height: AppSpacing.md),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _runGuarded(notifier.deleteAvatar);
                },
                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                label: const Text('حذف الصورة الحالية', style: TextStyle(color: AppColors.danger)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEditFieldDialog({
    required String title,
    required String initialValue,
    required Future<void> Function(String value) onSave,
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
            Text('تعديل $title', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
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
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final newValue = controller.text.trim();
              if (newValue.isEmpty) return;
              Navigator.of(ctx).pop();
              _runGuarded(() => onSave(newValue));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('حفظ التعديل'),
          ),
        ],
      ),
    );
  }

  void _showEditGenderDialog() {
    final notifier = ref.read(userProfileProvider.notifier);
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('اختر النوع', textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.of(ctx).pop();
              _runGuarded(() => notifier.updateField(gender: 'ذكر'));
            },
            child: const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text('👨 ذكر', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const Divider(height: 1),
          SimpleDialogOption(
            onPressed: () {
              Navigator.of(ctx).pop();
              _runGuarded(() => notifier.updateField(gender: 'أنثى'));
            },
            child: const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text('👩 أنثى', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final notifier = ref.read(userProfileProvider.notifier);

    Widget avatarWidget = profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
        ? CircleAvatar(radius: 46, backgroundImage: NetworkImage(profile.avatarUrl!))
        : CircleAvatar(
            radius: 46,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              profile.fullName.isEmpty ? 'م' : profile.fullName.substring(0, 1),
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          );

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      avatarWidget,
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _busy ? null : _showChangePhotoModal,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, size: 15, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: _busy ? null : _showChangePhotoModal,
                    icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                    label: const Text('تغيير الصورة الشخصية', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        profile.fullName,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _busy
                            ? null
                            : () => _showEditFieldDialog(
                                title: 'الاسم',
                                initialValue: profile.fullName,
                                onSave: (v) => notifier.updateField(fullName: v),
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
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
                    child: const Text(
                      'أخصائي اجتماعي ميداني معتمد',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                const Text('بيانات الحساب والتواصل', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const Spacer(),
                const Text('اضغط على أي خانة للتعديل', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
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
                  _buildProfileTile(
                    icon: Icons.email_outlined,
                    label: 'البريد الإلكتروني',
                    value: profile.email,
                    onTap: null, // البريد معرّف تسجيل الدخول — لا يُعدَّل من هنا.
                  ),
                  const Divider(height: 18, color: AppColors.border),
                  _buildProfileTile(
                    icon: Icons.wc_outlined,
                    label: 'النوع',
                    value: profile.gender,
                    onTap: _busy ? null : _showEditGenderDialog,
                  ),
                  const Divider(height: 18, color: AppColors.border),
                  _buildProfileTile(
                    icon: Icons.location_on_outlined,
                    label: 'المنطقة الجغرافية المسندة',
                    value: profile.region,
                    onTap: _busy
                        ? null
                        : () => _showEditFieldDialog(
                            title: 'المنطقة الجغرافية',
                            initialValue: profile.region,
                            onSave: (v) => notifier.updateField(region: v),
                          ),
                  ),
                  const Divider(height: 18, color: AppColors.border),
                  _buildProfileTile(
                    icon: Icons.phone_outlined,
                    label: 'رقم الهاتف المسجل',
                    value: profile.phone,
                    onTap: _busy
                        ? null
                        : () => _showEditFieldDialog(
                            title: 'رقم الهاتف',
                            initialValue: profile.phone,
                            keyboardType: TextInputType.phone,
                            onSave: (v) => notifier.updateField(phone: v),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).logout();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout, color: AppColors.danger, size: 18),
              label: const Text('تسجيل الخروج من الحساب', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.danger),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
        if (_busy)
          Container(
            color: Colors.black.withValues(alpha: 0.05),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback? onTap,
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
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                  const SizedBox(height: 2),
                  Text(
                    value.isEmpty ? '—' : value,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            if (onTap != null) const Icon(Icons.edit_outlined, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
