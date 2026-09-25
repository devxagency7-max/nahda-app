import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// خلفية التطبيق — تدرج سماوي ثابت (Gradient، بدون صورة).
/// ده اللي بيدي للـ GlassCard "حاجة" تبيّن البلور فوقها من غير أي تكلفة
/// أداء إضافية (عكس صورة + Blur في نسخة الويب).
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.backgroundGradientStart,
            AppColors.backgroundGradientEnd,
          ],
        ),
      ),
      child: child,
    );
  }
}
