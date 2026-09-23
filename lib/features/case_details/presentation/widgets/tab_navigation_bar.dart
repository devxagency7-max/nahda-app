import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// أزرار تنقل عائمة (بدون نص) — سهم "السابق" أسفل يمين، سهم "التالي"
/// أسفل شمال. في آخر تاب يتحول زر "التالي" إلى زر إرسال للمراجع.
///
/// اتجاه الأسهم بصريًا (بصرف النظر عن RTL/LTR للنص):
/// - "السابق" (يرجع لتاب قبله) → سهم يشاور يمين (→ في نظام إحداثيات الشاشة).
/// - "التالي" (يقدّم لتاب بعده) → سهم يشاور شمال (← في نظام إحداثيات الشاشة).
/// نستخدم TextDirection.ltr صراحة على الأيقونتين لتثبيت اتجاههما البصري
/// ومنع أي auto-mirroring من الـ Directionality المحيطة (RTL للتطبيق).
class TabNavigationBar extends StatelessWidget {
  final bool isFirstTab;
  final bool isLastTab;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  const TabNavigationBar({
    super.key,
    required this.isFirstTab,
    required this.isLastTab,
    required this.onPrevious,
    required this.onNext,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // أسفل يمين — سهم يشاور يمين الشاشة (رجوع للسابق)
          _NavCircleButton(
            icon: Icons.arrow_forward_ios_rounded,
            onPressed: isFirstTab ? null : onPrevious,
          ),
          // أسفل شمال — سهم يشاور شمال الشاشة (تقدّم للتالي) أو إرسال
          isLastTab
              ? _NavCircleButton(
                  icon: Icons.send_rounded,
                  onPressed: onSubmit,
                  filled: true,
                )
              : _NavCircleButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onPressed: onNext,
                ),
        ],
      ),
    );
  }
}

class _NavCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool filled;

  const _NavCircleButton({
    required this.icon,
    required this.onPressed,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;

    return Material(
      color: disabled
          ? AppColors.surfaceMuted
          : (filled ? AppColors.primary : AppColors.surface),
      shape: const CircleBorder(),
      elevation: disabled ? 0 : 3,
      shadowColor: AppColors.textPrimary.withValues(alpha: 0.2),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 52,
          height: 52,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Icon(
              icon,
              size: 20,
              color: disabled
                  ? AppColors.textMuted
                  : (filled ? AppColors.textInverse : AppColors.primary),
            ),
          ),
        ),
      ),
    );
  }
}
