import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// شريط تقدم أعلى كل تاب — يوضح نسبة اكتمال بيانات هذا القسم تحديدًا،
/// حتى يعرف المستخدم من أول نظرة هل التاب مكتمل أم لا.
class TabProgressBar extends StatelessWidget {
  final double progress; // 0.0 - 1.0

  const TabProgressBar({super.key, required this.progress});

  Color get _color {
    if (progress >= 1.0) return AppColors.success;
    if (progress >= 0.5) return AppColors.primary;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    final percent = (progress.clamp(0.0, 1.0) * 100).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 7,
                backgroundColor: AppColors.surfaceMuted,
                valueColor: AlwaysStoppedAnimation(_color),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 38,
            child: Text(
              '$percent%',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: _color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
