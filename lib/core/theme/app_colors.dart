import 'package:flutter/material.dart';

/// Design tokens نُقلت من هوية النهضة في الويب (web/css/base.css)
/// خلفية سماوية + كروت بيضاء صلبة بظل بارز — واضح تحت الشمس وسريع
/// على أجهزة متوسطة (Social Worker Spec §59، §58).
class AppColors {
  AppColors._();

  // Primary & accent — نفس قيم الويب بالظبط
  static const Color primary = Color(0xFF1D4ED8);
  static const Color primaryHover = Color(0xFF1E40AF);
  static const Color primaryLight = Color(0xFFE8EEFC);

  static const Color success = Color(0xFF047857);
  static const Color successBg = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFB45309);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerBg = Color(0xFFFEE2E2);

  // خلفية التطبيق — تدرج سماوي ثابت (Gradient، بدون صورة)
  static const Color background = Color(0xFFF3F8FE);
  static const Color backgroundGradientStart = Color(0xFFEAF3FF);
  static const Color backgroundGradientEnd = Color(0xFFF7FBFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF6F9FC);

  // نص
  static const Color textPrimary = Color(0xFF000000);
  static const Color textBody = Color(0xFF09090B);
  static const Color textSecondary = Color(0xFF334155);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textInverse = Color(0xFFFFFFFF);

  // حدود
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);
}
