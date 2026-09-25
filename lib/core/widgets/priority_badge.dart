import 'package:flutter/material.dart';

import '../../features/home/domain/case_priority.dart';
import '../theme/app_spacing.dart';

/// شارة الأولوية — دائمًا نص + لون معًا، أبدًا لون وحده (UX Rule: لا تعتمد على اللون فقط).
class PriorityBadge extends StatelessWidget {
  final CasePriority priority;

  const PriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: priority.backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: priority.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            priority.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: priority.color,
            ),
          ),
        ],
      ),
    );
  }
}
