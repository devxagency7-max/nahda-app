import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/sections/opinions_form.dart';
import '../widgets/editable_dropdown.dart';
import '../widgets/tab_progress_bar.dart';

const _socialWorkerOpinions = ['مقبول', 'مرفوض', 'لم يتم البدء'];
const _finalDecisions = ['اعتماد', 'رفض'];

/// تاب الرأي — 3 كروت جنب بعض: رأي الأخصائي (قابل للتعديل بـ مقبول/مرفوض/لم يتم البدء)،
/// رأي المراجع، رأي مدير التنمية (View-only للأخصائي).
class OpinionsTab extends StatefulWidget {
  final OpinionsFormData initialData;
  final ValueChanged<OpinionsFormData> onChanged;

  const OpinionsTab({
    super.key,
    required this.initialData,
    required this.onChanged,
  });

  @override
  State<OpinionsTab> createState() => _OpinionsTabState();
}

class _OpinionsTabState extends State<OpinionsTab> {
  late final OpinionsFormData _data = widget.initialData;

  late final _reportCtrl = TextEditingController(
    text: _data.socialWorker.detailedReport ?? '',
  );

  void _notify() => setState(() => widget.onChanged(_data));

  @override
  void dispose() {
    _reportCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabProgressBar(progress: _data.progress),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              final cards = [
                _OpinionCard(
                  title: 'رأي الأخصائي',
                  icon: Icons.badge_outlined,
                  color: AppColors.primary,
                  editable: true,
                  briefValue: _data.socialWorker.briefOpinion,
                  briefOptions: _socialWorkerOpinions,
                  onBriefChanged: (v) {
                    _data.socialWorker.briefOpinion = v;
                    _notify();
                  },
                  reportController: _reportCtrl,
                  reportHint: 'التقرير التفصيلي...',
                  onReportChanged: (v) {
                    _data.socialWorker.detailedReport = v;
                    _notify();
                  },
                ),
                _OpinionCard(
                  title: 'رأي المراجع',
                  icon: Icons.search,
                  color: AppColors.warning,
                  editable: false,
                  briefValue: _data.reviewer?.briefOpinion,
                  briefPlaceholder: 'لم تتم المراجعة بعد',
                  reportPlaceholder:
                      _data.reviewer?.notes ?? 'ملاحظات المراجعة...',
                ),
                _OpinionCard(
                  title: 'رأي مدير التنمية',
                  icon: Icons.verified_outlined,
                  color: AppColors.success,
                  editable: false,
                  briefValue: _data.director?.finalDecision,
                  briefPlaceholder: 'اختر القرار...',
                  reportPlaceholder:
                      _data.director?.approvalOrRejectionNote ??
                      'التعليق النهائي للمدير...',
                ),
              ];

              final content = isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < cards.length; i++) ...[
                          if (i > 0) const SizedBox(width: AppSpacing.md),
                          Expanded(child: cards[i]),
                        ],
                      ],
                    )
                  : Column(
                      children: [
                        for (int i = 0; i < cards.length; i++) ...[
                          if (i > 0) const SizedBox(height: AppSpacing.md),
                          cards[i],
                        ],
                      ],
                    );

              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: content,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _OpinionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool editable;
  final String? briefValue;
  final List<String>? briefOptions;
  final ValueChanged<String?>? onBriefChanged;
  final String? briefPlaceholder;
  final TextEditingController? reportController;
  final String? reportHint;
  final String? reportPlaceholder;
  final ValueChanged<String>? onReportChanged;

  const _OpinionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.editable,
    this.briefValue,
    this.briefOptions,
    this.onBriefChanged,
    this.briefPlaceholder,
    this.reportController,
    this.reportHint,
    this.reportPlaceholder,
    this.onReportChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'الرأي المختصر',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          if (editable)
            EditableDropdown(
              label: '',
              value: briefValue,
              options: briefOptions ?? _finalDecisions,
              onChanged: onBriefChanged!,
            )
          else
            _ReadOnlyField(
              value: briefValue,
              placeholder: briefPlaceholder ?? '—',
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            editable ? 'التقرير التفصيلي' : 'ملاحظات',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          if (editable)
            TextField(
              controller: reportController,
              maxLines: 4,
              decoration: InputDecoration(hintText: reportHint),
              onChanged: onReportChanged,
            )
          else
            _ReadOnlyField(
              value: null,
              placeholder: reportPlaceholder ?? '—',
              minHeight: 90,
            ),
        ],
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String? value;
  final String placeholder;
  final double minHeight;

  const _ReadOnlyField({
    this.value,
    required this.placeholder,
    this.minHeight = 44,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      alignment: Alignment.topRight,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        hasValue ? value! : placeholder,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: hasValue ? AppColors.textPrimary : AppColors.textMuted,
        ),
      ),
    );
  }
}
