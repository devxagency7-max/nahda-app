import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// أولوية الحالة — Social Worker Spec §27.
/// يجب ألا تعتمد الأولوية على اللون وحده؛ دائمًا نص + لون معًا.
enum CasePriority { low, medium, high, urgent }

extension CasePriorityX on CasePriority {
  String get label => switch (this) {
    CasePriority.low => 'منخفضة',
    CasePriority.medium => 'متوسطة',
    CasePriority.high => 'عالية',
    CasePriority.urgent => 'عاجلة',
  };

  Color get color => switch (this) {
    CasePriority.low => AppColors.textMuted,
    CasePriority.medium => AppColors.primary,
    CasePriority.high => AppColors.warning,
    CasePriority.urgent => AppColors.danger,
  };

  Color get backgroundColor => switch (this) {
    CasePriority.low => AppColors.surfaceMuted,
    CasePriority.medium => AppColors.primaryLight,
    CasePriority.high => AppColors.warningBg,
    CasePriority.urgent => AppColors.dangerBg,
  };
}
