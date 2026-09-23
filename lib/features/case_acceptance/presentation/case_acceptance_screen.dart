import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/data_providers.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/priority_badge.dart';
import '../../home/domain/case_priority.dart';

/// شاشة "قبول الحالات" — الحالات المُسندة للأخصائي والمنتظرة تأكيد استلامه.
///
/// **من الكاش المحلي دائمًا**، زي باقي شاشات التطبيق (`watchWorkQueue`) —
/// تظهر فورًا حتى بلا اتصال، وتُصفّى هنا لحالة `assigned` تحديدًا (المُسندة
/// المنتظرة قبولًا)؛ `in_research`/`returned_to_worker` قُبلت بالفعل وتظهر في
/// "كل حالاتي" بدلًا من هنا. القبول نفسه ([CasesRepository.acceptAssignment])
/// يكتب محليًا فورًا ويضع العملية في طابور المزامنة — لا ننتظر الخادم لنحدّث
/// الواجهة.
class CaseAcceptanceScreen extends ConsumerWidget {
  const CaseAcceptanceScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CaseAcceptanceScreen()),
    );
  }

  Future<void> _acceptCase(
    BuildContext context,
    WidgetRef ref,
    CachedCaseRow row,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(casesRepositoryProvider).acceptAssignment(row.id);
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'تم قبول واستلام حالة (${row.beneficiaryFullName}) بنجاح وإضافتها لقائمة مهامك',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      // محاولة رفع فورية إن كان هناك اتصال — القبول يظل صحيحًا محليًا حتى
      // لو فشلت (الطابور يعيد المحاولة تلقائيًا لاحقًا).
      unawaited(ref.read(runSyncProvider)());
    } catch (_) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('تعذّر حفظ القبول محليًا — حاول مرة أخرى'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workQueue = ref.watch(workQueueProvider);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('قبول واستلام الحالات'),
          elevation: 0,
        ),
        body: RefreshIndicator(
          onRefresh: () => ref.read(casesRepositoryProvider).refreshWorkQueue(),
          child: workQueue.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _ErrorState(
              onRetry: () =>
                  ref.read(casesRepositoryProvider).refreshWorkQueue(),
            ),
            data: (rows) {
              final pending = rows.where((r) => r.status == 'assigned').toList()
                ..sort((a, b) => b.fetchedAt.compareTo(a.fetchedAt));

              return ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'الحالات المعلقة التي تم إسنادها لمنطقتك وتنتظر تأكيد استلامك للبدء في النزول الميداني.',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (pending.isEmpty)
                    const _EmptyState()
                  else
                    for (final row in pending) ...[
                      _PendingCaseCard(
                        row: row,
                        onAccept: () => _acceptCase(context, ref, row),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          children: [
            _EmptyIcon(),
            SizedBox(height: AppSpacing.lg),
            Text(
              'تم قبول جميع الحالات المسندة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'لا توجد حالات جديدة معلقة للإسناد حالياً',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyIcon extends StatelessWidget {
  const _EmptyIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check_circle_outline,
        size: 48,
        color: AppColors.success,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SizedBox(height: 60),
        const Icon(Icons.wifi_off, size: 48, color: AppColors.textMuted),
        const SizedBox(height: AppSpacing.md),
        const Center(
          child: Text(
            'تعذّر تحديث القائمة من الخادم — القائمة المعروضة هي آخر نسخة محفوظة على الجهاز',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ),
      ],
    );
  }
}

class _PendingCaseCard extends StatelessWidget {
  final CachedCaseRow row;
  final VoidCallback onAccept;

  const _PendingCaseCard({required this.row, required this.onAccept});

  String get _assignedLabel {
    final at = row.serverUpdatedAt ?? row.fetchedAt;
    final now = DateTime.now();
    final isToday =
        at.year == now.year && at.month == now.month && at.day == now.day;
    final time = DateFormat('h:mm a', 'ar').format(at);
    return isToday ? 'اليوم، $time' : DateFormat('d/M، h:mm a', 'ar').format(at);
  }

  CasePriority get _priority => switch (row.priority) {
    'urgent' => CasePriority.urgent,
    'high' => CasePriority.high,
    'low' => CasePriority.low,
    _ => CasePriority.medium,
  };

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.beneficiaryFullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              PriorityBadge(priority: _priority),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#${row.displayId}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.access_time,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                'أُسندت إليك: $_assignedLabel',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              if (row.nextVisitLocation != null) ...[
                const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    row.nextVisitLocation!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          if (row.hasFullDetails) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'نسبة اكتمال بيانات الحالة: ${row.completionPercentage.round()}٪',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onAccept,
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text(
              'قبول واستلام الحالة',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
