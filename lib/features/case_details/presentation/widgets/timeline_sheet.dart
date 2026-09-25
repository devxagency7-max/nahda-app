import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/sections/timeline_section.dart';
import '../tabs/timeline_tab.dart';

/// سجل التغييرات — Bottom Sheet يُفتح من زر في الـ Header بدل تاب منفصل.
class TimelineSheet extends StatelessWidget {
  final CaseTimelineSection data;

  const TimelineSheet({super.key, required this.data});

  static void show(BuildContext context, CaseTimelineSection data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TimelineSheet(data: data),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.md),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderStrong,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'سجل التغييرات',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(child: TimelineTab(data: data)),
        ],
      ),
    );
  }
}
