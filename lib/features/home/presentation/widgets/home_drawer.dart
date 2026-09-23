import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/data_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../case_acceptance/presentation/case_acceptance_screen.dart';
import '../../../case_list/presentation/case_list_filter.dart';
import '../../../case_list/presentation/case_list_screen.dart';
import '../../../profile/presentation/user_profile_provider.dart';
import '../../../profile/presentation/user_profile_screen.dart';
import '../../../profile/presentation/widgets/user_avatar.dart';
import '../../../sync/presentation/sync_status_screen.dart';
import '../../../returned_cases/presentation/returned_cases_screen.dart';
import '../../domain/home_summary.dart';

class HomeDrawer extends ConsumerWidget {
  final HomeData data;

  const HomeDrawer({super.key, required this.data});

  void _navigateToFilter(BuildContext context, CaseListFilter filter) {
    Navigator.of(context).pop(); // إغلاق الـ Drawer
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CaseListScreen(data: data, initialFilter: filter),
      ),
    );
  }

  void _openProfile(BuildContext context) {
    Navigator.of(context).pop();
    UserProfileScreen.open(context);
  }

  void _openCaseAcceptance(BuildContext context) {
    Navigator.of(context).pop();
    CaseAcceptanceScreen.open(context);
  }

  void _openReturnedCases(BuildContext context) {
    Navigator.of(context).pop();
    ReturnedCasesScreen.open(context, data);
  }

  /// تسجيل خروج محروس.
  ///
  /// الخروج يمسح التوكنات، وطابور المزامنة لا يستطيع التفريغ بدونها — فالخروج
  /// بعمل غير مرفوع يعني **فقدًا فعليًا لعمل يوم ميداني**. لذا نحذّر برقم
  /// صريح ونجعل المتابعة قرارًا واعيًا.
  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final pending = ref.read(pendingSyncCountProvider).valueOrNull ?? 0;
    final photos = ref.read(pendingAttachmentCountProvider).valueOrNull ?? 0;
    final total = pending + photos;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(total > 0 ? 'لديك عمل لم يُرفَع' : 'تسجيل الخروج'),
        content: Text(
          total > 0
              ? 'يوجد $total تغيير محفوظ على الجهاز ولم يصل إلى الخادم بعد.\n\n'
                    'يُفضَّل الاتصال بالإنترنت وانتظار اكتمال المزامنة قبل '
                    'الخروج، وإلا فقد يتعذّر رفع هذا العمل لاحقًا.'
              : 'هل تريد تسجيل الخروج من التطبيق؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(total > 0 ? 'البقاء ومتابعة المزامنة' : 'إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // لا تنقّل يدوي: جذر التطبيق يراقب حالة المصادقة ويعرض شاشة الدخول.
    await ref.read(authControllerProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final displayName = profile.name.isNotEmpty ? profile.name : data.socialWorkerName;

    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header (Clickable to open profile)
            InkWell(
              onTap: () => _openProfile(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    bottom: BorderSide(color: AppColors.border),
                  ),
                ),
                child: Column(
                  children: [
                    UserAvatar(
                      radius: 36,
                      imagePath: profile.imagePath,
                      avatarEmoji: profile.avatarEmoji,
                      name: displayName,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'أخصائي اجتماعي ميداني',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                children: [
                  _DrawerTile(
                    icon: Icons.home_outlined,
                    title: 'الرئيسية',
                    isSelected: true,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  _DrawerTile(
                    icon: Icons.person_outline,
                    title: 'البروفايل (الملف الشخصي)',
                    onTap: () => _openProfile(context),
                  ),
                  const Divider(height: 20, color: AppColors.border),
                  _DrawerTile(
                    icon: Icons.assignment_turned_in_outlined,
                    title: 'قبول الحالات',
                    badge: '2 جديدة',
                    badgeColor: AppColors.primary,
                    onTap: () => _openCaseAcceptance(context),
                  ),
                  _DrawerTile(
                    icon: Icons.folder_outlined,
                    title: 'كل حالاتي',
                    badge: '${data.counters.allCases}',
                    onTap: () => _navigateToFilter(context, CaseListFilter.allCases),
                  ),
                  _DrawerTile(
                    icon: Icons.bookmark_outline,
                    title: 'الحالات المحفوظة',
                    badge: '${data.counters.savedCases}',
                    onTap: () => _navigateToFilter(context, CaseListFilter.saved),
                  ),
                  _DrawerTile(
                    icon: Icons.assignment_return_outlined,
                    title: 'الحالات المرتجعة',
                    badge: '${data.counters.returnedCases}',
                    badgeColor: data.counters.returnedCases > 0 ? AppColors.warning : null,
                    onTap: () => _openReturnedCases(context),
                  ),
                  Consumer(
                    builder: (context, ref, _) {
                      final pending =
                          ref.watch(pendingSyncCountProvider).valueOrNull ?? 0;
                      final photos =
                          ref
                              .watch(pendingAttachmentCountProvider)
                              .valueOrNull ??
                          0;
                      final total = pending + photos;

                      return _DrawerTile(
                        icon: Icons.sync,
                        title: 'حالة المزامنة',
                        badge: total > 0 ? '$total' : null,
                        badgeColor: total > 0 ? AppColors.warning : null,
                        onTap: () {
                          Navigator.of(context).pop();
                          SyncStatusScreen.open(context);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Consumer(
                builder: (context, ref, _) => _DrawerTile(
                  icon: Icons.logout,
                  title: 'تسجيل الخروج',
                  textColor: AppColors.danger,
                  iconColor: AppColors.danger,
                  onTap: () => _confirmLogout(context, ref),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? badge;
  final Color? badgeColor;
  final Color? textColor;
  final Color? iconColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.title,
    this.badge,
    this.badgeColor,
    this.textColor,
    this.iconColor,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
      leading: Icon(
        icon,
        color: iconColor ?? (isSelected ? AppColors.primary : AppColors.textPrimary),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          color: textColor ?? (isSelected ? AppColors.primary : AppColors.textPrimary),
        ),
      ),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (badgeColor ?? AppColors.primary).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: badgeColor ?? AppColors.primary,
                ),
              ),
            )
          : null,
    );
  }
}
