import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/sections/timeline_section.dart';
import '../widgets/section_card.dart';

class TimelineTab extends StatelessWidget {
  final CaseTimelineSection data;

  const TimelineTab({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.events.isEmpty) {
      return const SectionEmptyState(message: 'لا يوجد سجل أحداث بعد');
    }

    final df = DateFormat('d/M/yyyy — h:mm a', 'ar');

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        for (int i = 0; i < data.events.length; i++)
          _TimelineTile(
            event: data.events[i],
            df: df,
            isLast: i == data.events.length - 1,
          ),
      ],
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final TimelineEvent event;
  final DateFormat df;
  final bool isLast;

  const _TimelineTile({
    required this.event,
    required this.df,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                const Expanded(
                  child: VerticalDivider(color: AppColors.border, width: 2),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.label,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    df.format(event.at),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  if (event.actorName != null)
                    Text(
                      event.actorName!,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
