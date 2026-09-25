import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// نافذة تأكيد الإرسال رغم نقص البيانات — استثناء صريح بموافقة صاحب
/// المنتج (يخالف Social Worker Spec §38 الذي يمنع الإرسال بالكامل عند
/// النقص). يسمح بالإرسال لكن بعد تحذير واضح لا يمكن تفويته بالخطأ.
class IncompleteSubmitDialog extends StatelessWidget {
  final List<String> missingSections;

  const IncompleteSubmitDialog({super.key, required this.missingSections});

  static Future<bool> show(
    BuildContext context,
    List<String> missingSections,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => IncompleteSubmitDialog(missingSections: missingSections),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(
        Icons.warning_amber_rounded,
        color: AppColors.warning,
        size: 32,
      ),
      title: const Text(
        'البيانات غير مكتملة',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الأقسام التالية غير مكتملة، وقد يعيد المراجع الحالة إليك لاستكمالها:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final section in missingSections)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 6, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Text(
                    section,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('رجوع لاستكمال البيانات'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
          child: const Text('إرسال رغم النقص'),
        ),
      ],
    );
  }
}
