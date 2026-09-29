import 'package:flutter/material.dart';

import '../../features/home/domain/social_worker_case.dart';
import '../theme/app_spacing.dart';

/// شارة حالة الحالة (Case Work Status) — نص + لون معًا، أبدًا لون وحده.
class CaseStatusBadge extends StatelessWidget {
  final CaseWorkStatus status;

  const CaseStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: status.color,
        ),
      ),
    );
  }
}
