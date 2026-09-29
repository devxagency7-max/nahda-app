import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers/data_providers.dart';
import '../../../core/storage/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_background.dart';

/// يحوّل مفتاح `icon` النصّي من الخادم لأيقونة — العقد لا يفرض قائمة ثابتة
/// لقيمه (`icon: string?` حر)، فهذه مطابقة استرشادية بأفضل تخمين مع رمز
/// افتراضي آمن لأي مفتاح غير معروف.
IconData _iconFor(String? key) => switch (key) {
  'case_assigned' => Icons.assignment_ind_outlined,
  'case_returned' => Icons.assignment_return_outlined,
  'case_approved' || 'support_approved' => Icons.check_circle_outline,
  'field_visit' => Icons.calendar_today_outlined,
  'case_updated' => Icons.update_outlined,
  _ => Icons.notifications_outlined,
};

/// وقت نسبي بالعربي — بلا اعتماد جديد، فروق خشنة تكفي لقائمة إشعارات.
String _timeAgo(DateTime createdAtUtc) {
  final diff = DateTime.now().toUtc().difference(createdAtUtc);
  if (diff.inMinutes < 1) return 'الآن';
  if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
  if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
  if (diff.inDays == 1) return 'أمس';
  if (diff.inDays < 30) return 'منذ ${diff.inDays} يوم';
  return 'منذ ${(diff.inDays / 30).floor()} شهر';
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // تحديث فوري عند الفتح؛ لا يمنع عرض الكاش المحلي (Stream يظهر فورًا
    // بصرف النظر عن نتيجة هذا التحديث).
    ref.read(notificationsRepositoryProvider).refresh();
  }

  Future<void> _markAllAsRead() async {
    try {
      await ref.read(notificationsRepositoryProvider).markAllRead();
    } on ApiException catch (e) {
      _showError(e.displayMessage);
    }
  }

  Future<void> _handleTap(CachedNotificationRow item) async {
    if (item.isRead) return;
    try {
      await ref.read(notificationsRepositoryProvider).markRead(item.id);
    } on ApiException catch (e) {
      _showError(e.displayMessage);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('الإشعارات والتنبيهات'),
          elevation: 0,
          actions: [
            notificationsAsync.maybeWhen(
              data: (items) {
                final hasUnread = items.any((n) => !n.isRead);
                if (!hasUnread) return const SizedBox.shrink();
                return TextButton(
                  onPressed: _markAllAsRead,
                  child: const Text(
                    'قراءة الكل',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => ref.read(notificationsRepositoryProvider).refresh(),
          child: notificationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => const Center(
              child: Text(
                'تعذّر تحميل الإشعارات',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: const Center(
                        child: Text(
                          'لا توجد إشعارات حالياً',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isUnread = !item.isRead;

                  return InkWell(
                    onTap: () => _handleTap(item),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isUnread
                            ? AppColors.primaryLight.withValues(alpha: 0.4)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(
                          color: isUnread
                              ? AppColors.primary.withValues(alpha: 0.3)
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isUnread
                                  ? AppColors.primary.withValues(alpha: 0.12)
                                  : AppColors.surfaceMuted,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _iconFor(item.icon),
                              size: 20,
                              color: isUnread
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isUnread
                                              ? FontWeight.w800
                                              : FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _timeAgo(item.createdAtUtc),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                if ((item.subtitle ?? '').isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    item.subtitle!,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
