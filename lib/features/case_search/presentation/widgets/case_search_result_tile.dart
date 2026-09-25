import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/priority_badge.dart';
import '../../domain/case_search_result.dart';

class CaseSearchResultTile extends StatelessWidget {
  final CaseSearchResult result;
  final VoidCallback onTap;

  const CaseSearchResultTile({
    super.key,
    required this.result,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          result.personName,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        result.displayId,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                PriorityBadge(priority: result.priority),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  result.statusLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                if (result.village != null) ...[
                  const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                  Text(
                    result.village!,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
            if (result.charity != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.apartment_outlined, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      result.charity!,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (result.isAssignedToCurrentWorker == false) ...[
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 13,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      result.assignedWorkerName != null
                          ? 'هذه الحالة مسندة إلى ${result.assignedWorkerName}'
                          : 'هذه الحالة موجودة ولم تُسند لأخصائي بعد',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (result.isAssignedToCurrentWorker == true) ...[
              const Text(
                'مسندة إليك',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ],
            // isAssignedToCurrentWorker == null: مصدر البيانات (البحث
            // الحقيقي) لا يرجّع معلومة الإسناد — لا نعرض قسم الإسناد بدل ما
            // نفترض حالة غير معروفة.
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Icon(
                result.charity != null ? Icons.access_time_rounded : Icons.done_all,
                size: 16,
                color: result.charity != null ? AppColors.warning : Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
