import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../home_providers.dart';

/// شريط حالة المزامنة أعلى الشاشة.
///
/// يظهر **فقط** حين يعني شيئًا للأخصائي: بلا اتصال، أو عمل محفوظ لم يُرفَع.
/// حين يكون كل شيء متزامنًا يختفي تمامًا — شريط دائم يصبح ضوضاء تُتجاهَل.
///
/// الرسالة تطمئن لا تُنذر: "محفوظ على الجهاز" لا "فشل الحفظ". العمل **لم
/// يضِع**، هو فقط ينتظر شبكة.
class SyncBannerBar extends ConsumerWidget {
  const SyncBannerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banner = ref.watch(syncBannerProvider);

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: banner.isVisible
          ? _Bar(banner: banner)
          : const SizedBox(width: double.infinity),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.banner});

  final SyncBanner banner;

  @override
  Widget build(BuildContext context) {
    final offline = banner.isOffline;

    // الأوفلاين حالة عادية للعمل الميداني لا خطأ — لونه محايد لا أحمر.
    final background = offline ? AppColors.surfaceMuted : AppColors.primaryLight;
    final foreground = offline ? AppColors.textSecondary : AppColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      color: background,
      child: Row(
        children: [
          if (offline)
            Icon(Icons.cloud_off_outlined, size: 16, color: foreground)
          else
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(foreground),
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              banner.message,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
