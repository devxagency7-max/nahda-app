import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/glass_card.dart';

/// كارت قسم واحد داخل تاب — نفس هوية GlassCard المستخدمة في باقي التطبيق.
class SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;

  const SectionCard({super.key, this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          child,
        ],
      ),
    );
  }
}

/// حالة عدم توفر بيانات القسم بعد (الحالة لم تصل لهذه المرحلة في الـ Workflow).
class SectionEmptyState extends StatelessWidget {
  final String message;

  const SectionEmptyState({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
