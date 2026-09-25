import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/localized_number_parser.dart';
import '../../domain/sections/agricultural_holding_form.dart';
import '../widgets/editable_dropdown.dart';
import '../widgets/editable_text_field.dart';
import '../widgets/section_card.dart';
import '../widgets/tab_progress_bar.dart';

const _landTypes = ['تمليك', 'إيجار'];
const _otherOption = 'أخرى';
const _livestockOptions = [
  'بقرة',
  'عجلة',
  'جاموسة',
  'أغنام / ماعز',
  'حمير / خيول',
  'دواجن',
  _otherOption,
];

/// سؤال نعم/لا صريح بدل SwitchListTile — المفتاح كان بيبدأ `false` فيبان
/// إن المستخدم جاوب بالنفي وهو لسه ماجاوبش أصلًا.
class _YesNoQuestion extends StatelessWidget {
  final String question;
  final HoldingAnswer value;
  final ValueChanged<HoldingAnswer> onChanged;
  final bool showError;

  const _YesNoQuestion({
    required this.question,
    required this.value,
    required this.onChanged,
    this.showError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                question,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: showError ? AppColors.danger : null,
                ),
              ),
            ),
            const Text(
              '*',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: 8,
          children: [
            for (final entry in const {
              HoldingAnswer.yes: 'نعم',
              HoldingAnswer.no: 'لا',
            }.entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: value == entry.key,
                onSelected: (_) => onChanged(entry.key),
                side: showError
                    ? const BorderSide(color: AppColors.danger)
                    : null,
              ),
          ],
        ),
      ],
    );
  }
}

/// تاب الحيازة والأصول — يوثّق أي أرض/ماشية تملكها الأسرة كمصدر دخل أو أصل عيني.
class AgriculturalHoldingTab extends StatefulWidget {
  final AgriculturalHoldingFormData initialData;
  final ValueChanged<AgriculturalHoldingFormData> onChanged;

  const AgriculturalHoldingTab({
    super.key,
    required this.initialData,
    required this.onChanged,
  });

  @override
  AgriculturalHoldingTabState createState() => AgriculturalHoldingTabState();
}

class AgriculturalHoldingTabState extends State<AgriculturalHoldingTab> {
  late final AgriculturalHoldingFormData _data = widget.initialData;

  late final _areaCtrl = TextEditingController(
    text: _data.landAreaFeddan?.toString() ?? '',
  );
  late final _rentCtrl = TextEditingController(
    text: _data.landRentAmount?.toString() ?? '',
  );
  late final _annualIncomeCtrl = TextEditingController(
    text: _data.annualLandIncome?.toString() ?? '',
  );
  late final _cropCtrl = TextEditingController(text: _data.cropType ?? '');
  late final _livestockOtherCtrl = TextEditingController(
    text: _data.livestockOther ?? '',
  );
  late final _livestockCtrl = TextEditingController(
    text: _data.livestockDetails ?? '',
  );
  late final _notesCtrl = TextEditingController(text: _data.notes ?? '');

  /// يظهر تمييز الحقول الناقصة بعد أول محاولة مغادرة فاشلة فقط، عشان
  /// ما نستقبلش المستخدم بشاشة حمرا من أول ثانية.
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    // فتح التاب نفسه هو "الزيارة" — من هنا تبدأ نسبته تُحسب فعليًا.
    if (!_data.visited) {
      _data.visited = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onChanged(_data);
      });
    }
  }

  void _notify() => setState(() => widget.onChanged(_data));

  /// يُستدعى من الشاشة الأم قبل السماح بمغادرة التاب للأمام.
  void showValidationErrors() => setState(() => _showErrors = true);

  void _syncTenureControllers() {
    if (_data.landType != 'إيجار') _rentCtrl.clear();
    if (_data.landType != 'تمليك') _annualIncomeCtrl.clear();
  }

  void _clearLandControllers() {
    _areaCtrl.clear();
    _rentCtrl.clear();
    _annualIncomeCtrl.clear();
    _cropCtrl.clear();
  }

  void _clearLivestockControllers() {
    _livestockOtherCtrl.clear();
    _livestockCtrl.clear();
  }

  @override
  void dispose() {
    _areaCtrl.dispose();
    _rentCtrl.dispose();
    _annualIncomeCtrl.dispose();
    _cropCtrl.dispose();
    _livestockOtherCtrl.dispose();
    _livestockCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final missing = _data.missingFields;
    final landUnanswered = _data.landAnswer == HoldingAnswer.unanswered;
    final livestockUnanswered =
        _data.livestockAnswer == HoldingAnswer.unanswered;

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
              if (_showErrors && missing.isNotEmpty) ...[
                _ValidationBanner(messages: missing),
                const SizedBox(height: AppSpacing.lg),
              ],
              SectionCard(
                title: 'الأرض الزراعية',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _YesNoQuestion(
                      question: 'هل تملك/تستأجر الأسرة أرضًا زراعية؟',
                      value: _data.landAnswer,
                      showError: _showErrors && landUnanswered,
                      onChanged: (v) {
                        _data.landAnswer = v;
                        // الحقول المخفية تُمسح فعليًا — لا بيانات شبح.
                        _data.clearLandDetailsIfDenied();
                        if (v != HoldingAnswer.yes) _clearLandControllers();
                        _notify();
                      },
                    ),
                    if (_data.hasLand) ...[
                      EditableDropdown(
                        label: 'طبيعة حيازة الأرض',
                        value: _data.landType,
                        options: _landTypes,
                        onChanged: (v) {
                          _data.landType = v;
                          _data.clearIrrelevantTenureField();
                          _syncTenureControllers();
                          _notify();
                        },
                      ),
                      EditableTextField(
                        label: 'المساحة (فدان)',
                        controller: _areaCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: (v) {
                          final parsed = parseLocalizedDouble(v);
                          // القيم السالبة مرفوضة بدل ما تعدّي في الحساب.
                          _data.landAreaFeddan =
                              (parsed != null && parsed < 0) ? null : parsed;
                          _notify();
                        },
                      ),
                      if (_data.landType == 'إيجار') ...[
                        EditableTextField(
                          label: 'سعر إيجار الأرض (جنيه)',
                          controller: _rentCtrl,
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            final parsed = parseLocalizedDouble(v);
                            _data.landRentAmount =
                                (parsed != null && parsed < 0) ? null : parsed;
                            _notify();
                          },
                        ),
                      ] else if (_data.landType == 'تمليك') ...[
                        EditableTextField(
                          label:
                              'الدخل السنوي للأرض (جنيه/سنة - يُقسم على 12 في الدخل)',
                          controller: _annualIncomeCtrl,
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            final parsed = parseLocalizedDouble(v);
                            _data.annualLandIncome =
                                (parsed != null && parsed < 0) ? null : parsed;
                            _notify();
                          },
                        ),
                      ],
                      EditableTextField(
                        label: 'نوع الزراعة',
                        controller: _cropCtrl,
                        onChanged: (v) {
                          _data.cropType = v;
                          _notify();
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SectionCard(
                title: 'المواشي والأصول الحيوانية',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _YesNoQuestion(
                      question: 'هل تمتلك الأسرة مواشي أو أصول حيوانية؟',
                      value: _data.livestockAnswer,
                      showError: _showErrors && livestockUnanswered,
                      onChanged: (v) {
                        _data.livestockAnswer = v;
                        _data.clearLivestockDetailsIfDenied();
                        if (v != HoldingAnswer.yes) _clearLivestockControllers();
                        _notify();
                      },
                    ),
                    if (_data.hasLivestock) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'اختر أنواع المواشي والأصول:',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _showErrors && _data.selectedLivestock.isEmpty
                              ? AppColors.danger
                              : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final option in _livestockOptions)
                            FilterChip(
                              label: Text(option),
                              selected: _data.selectedLivestock.contains(option),
                              onSelected: (selected) {
                                if (selected) {
                                  _data.selectedLivestock.add(option);
                                } else {
                                  _data.selectedLivestock.remove(option);
                                  if (option == _otherOption) {
                                    _data.livestockOther = null;
                                    _livestockOtherCtrl.clear();
                                  }
                                }
                                _notify();
                              },
                            ),
                        ],
                      ),
                      // حقل "أخرى" — لو الخيار متحدد لازم نصه يتكتب.
                      if (_data.selectedLivestock.contains(_otherOption)) ...[
                        const SizedBox(height: AppSpacing.sm),
                        EditableTextField(
                          label: 'اكتب نوع المواشي الأخرى',
                          controller: _livestockOtherCtrl,
                          onChanged: (v) {
                            _data.livestockOther = v;
                            _notify();
                          },
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      EditableTextField(
                        label: 'تفاصيل إضافية والعدد',
                        controller: _livestockCtrl,
                        onChanged: (v) {
                          _data.livestockDetails = v;
                          _notify();
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SectionCard(
                child: EditableTextField(
                  label: 'ملاحظات وتفاصيل الأصول',
                  controller: _notesCtrl,
                  onChanged: (v) {
                    _data.notes = v;
                    _notify();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// شريط تنبيه بالحقول الناقصة قبل مغادرة التاب.
class _ValidationBanner extends StatelessWidget {
  final List<String> messages;

  const _ValidationBanner({required this.messages});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: AppColors.danger, size: 18),
              SizedBox(width: 6),
              Text(
                'أكمل الحقول المطلوبة قبل الانتقال',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final m in messages)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '• $m',
                style: const TextStyle(fontSize: 12.5, color: AppColors.danger),
              ),
            ),
        ],
      ),
    );
  }
}
