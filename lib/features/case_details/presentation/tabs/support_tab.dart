import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/sections/support_form.dart';
import '../../domain/sections/support_section.dart';
import '../widgets/detail_row.dart';
import '../widgets/section_card.dart';
import '../widgets/tab_progress_bar.dart';

const Map<String, List<String>> _supportOptionsMap = {
  'لحوم': ['نص كيلو', 'كيلو'],
  'كرتونة مواد غذائية': [],
  'زي مدرسي ومصروفات دراسية': [],
  'دعم طبي': ['علاج', 'عمليات', 'طرف صناعي', 'كرسي متحرك', 'سماعة', 'منح'],
  'جهاز عرايس': [],
  'منح دراسية': [],
  'دعم المرافق': ['وصلة مية', 'وصلة كهرباء', 'حمام', 'سقف', 'صرف صحي', 'بناء'],
  'دعم أجهزة منزلية وأثاث منزلي': [],
  'مرشح بنك الطعام': [],
};

/// تاب الدعم — المقترح (اختيارات متعددة) من صلاحية الأخصائي (القسم 20).
class SupportTab extends StatefulWidget {
  final SupportRecommendationFormData initialData;
  final ValueChanged<SupportRecommendationFormData> onChanged;
  final ApprovedSupportSection? approved;

  const SupportTab({
    super.key,
    required this.initialData,
    required this.onChanged,
    this.approved,
  });

  @override
  State<SupportTab> createState() => _SupportTabState();
}

class _SupportTabState extends State<SupportTab> {
  late final SupportRecommendationFormData _data = widget.initialData;

  void _notify() => widget.onChanged(_data);

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d/M/yyyy', 'ar');

    return Column(
      children: [
        TabProgressBar(progress: _data.progress),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            children: [
              SectionCard(
                title: 'أنواع الدعم المقترحة (اختيارات متعددة)',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'اختر الدعم المطلوبة للحالة (يمكن اختيار أكثر من نوع):',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    for (final entry in _supportOptionsMap.entries) ...[
                      _SupportTypeTile(
                        title: entry.key,
                        subOptions: entry.value,
                        isSelected: _data.selectedSupportTypes.contains(entry.key),
                        selectedSubTypes: _data.selectedSubTypes,
                        onToggleCategory: (selected) {
                          setState(() {
                            if (selected) {
                              _data.selectedSupportTypes.add(entry.key);
                            } else {
                              _data.selectedSupportTypes.remove(entry.key);
                              for (final sub in entry.value) {
                                _data.selectedSubTypes.remove(sub);
                              }
                            }
                          });
                          _notify();
                        },
                        onToggleSubOption: (sub, selected) {
                          setState(() {
                            if (selected) {
                              if (!_data.selectedSupportTypes.contains(entry.key)) {
                                _data.selectedSupportTypes.add(entry.key);
                              }
                              _data.selectedSubTypes.add(sub);
                            } else {
                              _data.selectedSubTypes.remove(sub);
                            }
                          });
                          _notify();
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (widget.approved != null)
                SectionCard(
                  title: 'الدعم المعتمد',
                  child: Column(
                    children: [
                      DetailRow(
                        label: 'نوع الدعم المعتمد',
                        value: widget.approved!.approvedSupportType,
                      ),
                      DetailRow(
                        label: 'القيمة المعتمدة',
                        value:
                            '${widget.approved!.approvedAmount.toStringAsFixed(0)} جنيه',
                      ),
                      DetailRow(
                        label: 'المستفيد',
                        value: widget.approved!.beneficiary,
                      ),
                      DetailRow(
                        label: 'تاريخ الاعتماد',
                        value: df.format(widget.approved!.approvedAt),
                      ),
                      DetailRow(
                        label: 'ملاحظات الاعتماد',
                        value: widget.approved!.approvalNotes,
                      ),
                    ],
                  ),
                )
              else
                const SectionCard(
                  child: Text(
                    'لم يتم اتخاذ القرار بعد — في انتظار المراجع',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SupportTypeTile extends StatelessWidget {
  final String title;
  final List<String> subOptions;
  final bool isSelected;
  final List<String> selectedSubTypes;
  final ValueChanged<bool> onToggleCategory;
  final Function(String sub, bool selected) onToggleSubOption;

  const _SupportTypeTile({
    required this.title,
    required this.subOptions,
    required this.isSelected,
    required this.selectedSubTypes,
    required this.onToggleCategory,
    required this.onToggleSubOption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryLight.withValues(alpha: 0.4) : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          CheckboxListTile(
            value: isSelected,
            onChanged: (v) => onToggleCategory(v ?? false),
            title: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.primary,
          ),
          if (isSelected && subOptions.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
              child: Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final sub in subOptions)
                      FilterChip(
                        label: Text(sub),
                        selected: selectedSubTypes.contains(sub),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: selectedSubTypes.contains(sub) ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        onSelected: (sel) => onToggleSubOption(sub, sel),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
