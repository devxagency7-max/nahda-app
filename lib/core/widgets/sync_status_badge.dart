import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// مكون شارة حالة المزامنة/الكاش لكروت الحالات:
/// - علامة الساعة 🕒 باللون البرتقالي: الحالة محفوظة في الكاش محليًا (لم تُرسل بعد).
/// - علامة الصحين الأزرق 🍿 (Icons.done_all باللون الأزرق كالواتساب): الحالة مزمونة ومرفوعة للباك إند.
class SyncStatusBadge extends StatelessWidget {
  final bool isSynced;
  final bool showLabel;

  const SyncStatusBadge({
    super.key,
    required this.isSynced,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSynced ? Colors.blue : AppColors.warning;
    final bgColor = isSynced
        ? Colors.blue.withValues(alpha: 0.12)
        : AppColors.warningBg.withValues(alpha: 0.6);
    final icon = isSynced ? Icons.done_all : Icons.access_time_rounded;
    final label = isSynced ? 'مخزنة بالباك إند' : 'محفوظة بالكاش محلياً';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
