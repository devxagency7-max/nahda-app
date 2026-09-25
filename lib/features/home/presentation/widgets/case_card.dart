import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/priority_badge.dart';
import '../../domain/social_worker_case.dart';

/// كارت الحالة — Social Worker Spec §44 (Case Card).
class CaseCard extends StatelessWidget {
  final SocialWorkerCase caseItem;
  final VoidCallback onTap;

  /// إن كانت الحالة لسه بانتظار قبول الأخصائي (`CaseWorkStatus.assigned`)
  /// وتم تمرير هذا الـ callback، يظهر زرار "قبول واستلام الحالة" بدل شريط
  /// التقدم — نفس الزرار الموجود في شاشة "قبول الحالات" بالظبط.
  final VoidCallback? onAccept;

  const CaseCard({
    super.key,
    required this.caseItem,
    required this.onTap,
    this.onAccept,
  });

  bool get _isPendingAcceptance =>
      onAccept != null && caseItem.status == CaseWorkStatus.assigned;

  String? get _visitLabel {
    final visitAt = caseItem.scheduledVisitAt;
    if (visitAt == null) return null;
    final now = DateTime.now();
    final isToday =
        visitAt.year == now.year &&
        visitAt.month == now.month &&
        visitAt.day == now.day;
    final time = DateFormat('h:mm a', 'ar').format(visitAt);
    return isToday
        ? 'زيارة اليوم $time'
        : DateFormat('d/M', 'ar').format(visitAt);
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      caseItem.personName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      caseItem.displayId,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              PriorityBadge(priority: caseItem.priority),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              if (_visitLabel != null) ...[
                const Icon(
                  Icons.access_time,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  _visitLabel!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              if (caseItem.village != null) ...[
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    caseItem.village!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          if (_isPendingAcceptance) ...[
            const SizedBox(height: AppSpacing.md),
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
          ] else ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: caseItem.progress,
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceMuted,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${(caseItem.progress * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _SyncStatusRow(hasUnsyncedChanges: caseItem.hasUnsyncedChanges),
          ],
        ],
      ),
    );
  }
}

class _SyncStatusRow extends StatelessWidget {
  final bool hasUnsyncedChanges;

  const _SyncStatusRow({required this.hasUnsyncedChanges});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Icon(
          hasUnsyncedChanges ? Icons.access_time_rounded : Icons.done_all,
          size: 18,
          color: hasUnsyncedChanges ? AppColors.warning : Colors.blue,
        ),
      ),
    );
  }
}
