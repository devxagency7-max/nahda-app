import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../case_list/presentation/case_list_filter.dart';
import '../../domain/home_summary.dart';

/// أرقام سريعة — Social Worker Spec §5.3: "لا يجب أن تتحول إلى Analytics ثقيلة."
/// كل كارت قابل للضغط ويفتح صفحة الحالات على القسم المطابق.
class HomeCountersRow extends StatelessWidget {
  final HomeCounters counters;
  final void Function(CaseListFilter filter) onTapFilter;

  const HomeCountersRow({
    super.key,
    required this.counters,
    required this.onTapFilter,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _CounterItem(
        CaseListFilter.allCases,
        counters.allCases,
        Icons.folder_outlined,
        AppColors.primary,
      ),
      _CounterItem(
        CaseListFilter.saved,
        counters.savedCases,
        Icons.bookmark_outline,
        const Color(0xFF2563EB),
      ),
      _CounterItem(
        CaseListFilter.returned,
        counters.returnedCases,
        Icons.assignment_return_outlined,
        counters.returnedCases > 0 ? AppColors.warning : AppColors.textMuted,
      ),
    ];

    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _CounterCard(
              item: items[i],
              onTap: () => onTapFilter(items[i].filter),
            ),
          ),
        ],
      ],
    );
  }
}

class _CounterItem {
  final CaseListFilter filter;
  final int value;
  final IconData icon;
  final Color color;

  _CounterItem(this.filter, this.value, this.icon, this.color);

  String get label => filter.label;
}

class _CounterCard extends StatelessWidget {
  final _CounterItem item;
  final VoidCallback onTap;

  const _CounterCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.sm,
      ),
      child: Column(
        children: [
          Icon(item.icon, color: item.color, size: 20),
          const SizedBox(height: 8),
          Text(
            '${item.value}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: item.color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
