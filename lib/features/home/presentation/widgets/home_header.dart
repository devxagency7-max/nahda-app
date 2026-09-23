import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../profile/presentation/user_profile_provider.dart';
import '../../../profile/presentation/user_profile_screen.dart';
import '../../../profile/presentation/widgets/user_avatar.dart';

class HomeHeader extends ConsumerWidget {
  final String fallbackName;
  final int unreadNotifications;
  final VoidCallback onNotificationsTap;
  final VoidCallback? onMenuTap;

  const HomeHeader({
    super.key,
    required this.fallbackName,
    required this.unreadNotifications,
    required this.onNotificationsTap,
    this.onMenuTap,
  });

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'صباح الخير';
    }
    return 'مساء الخير';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final displayName = profile.name.isNotEmpty ? profile.name : fallbackName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Top App Bar Row
        Row(
          children: [
            if (onMenuTap != null)
              InkWell(
                onTap: onMenuTap,
                borderRadius: BorderRadius.circular(AppRadius.button),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(
                    Icons.menu,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            const Spacer(),
            _NotificationBell(
              count: unreadNotifications,
              onTap: onNotificationsTap,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // 2. Greeting Welcome Card with User Avatar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              UserAvatar(
                radius: 26,
                imagePath: profile.imagePath,
                avatarEmoji: profile.avatarEmoji,
                name: displayName,
                onTap: () => UserProfileScreen.open(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$_greeting، $displayName',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(width: 6),
                        const Text('👋', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'مرحباً بك مجدداً، نتمنى لك يوماً موفقاً ومثمراً في الميدان ✨',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotificationBell extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _NotificationBell({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(color: AppColors.border),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.notifications_outlined,
              color: AppColors.textPrimary,
              size: 20,
            ),
            if (count > 0)
              Positioned(
                top: 6,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
