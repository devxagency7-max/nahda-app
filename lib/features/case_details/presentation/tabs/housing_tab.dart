import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/sections/housing_form.dart';
import '../widgets/multi_select_chip_field.dart';
import '../widgets/tab_progress_bar.dart';

/// تاب السكن — مطابق لتصميم صفحة السكن في الويب: كل حقل بطاقة اختيار
/// متعدد (Multi-select Chips) بعداد اختيارات، ودعم "أخرى" بنص حر.
class HousingTab extends StatefulWidget {
  final HousingFormData initialData;
  final ValueChanged<HousingFormData> onChanged;

  const HousingTab({
    super.key,
    required this.initialData,
    required this.onChanged,
  });

  @override
  State<HousingTab> createState() => _HousingTabState();
}

class _HousingTabState extends State<HousingTab> {
  late final HousingFormData _data = widget.initialData;
  late final _descCtrl = TextEditingController(
    text: _data.housingDescription ?? '',
  );

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  void _notify() => setState(() => widget.onChanged(_data));

  @override
  Widget build(BuildContext context) {
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
              // 1. Dynamic Multiline Housing Description Card at top
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.home_work_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'وصف السكن',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _descCtrl,
                      maxLines: null,
                      minLines: 3,
                      keyboardType: TextInputType.multiline,
                      onChanged: (v) {
                        _data.housingDescription = v;
                        _notify();
                      },
                      decoration: const InputDecoration(
                        hintText: 'اكتب وصف حالة السكن والملاحظات تفصيلياً هنا...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              MultiSelectChipField(
                label: 'طبيعة السكن',
                field: _data.housingType,
                options: const ['خاص', 'إيجار', 'منزل عائلة'],
                onChanged: _notify,
              ),
              const SizedBox(height: AppSpacing.md),
              MultiSelectChipField(
                label: 'الحوائط',
                field: _data.walls,
                options: const ['طوب احمر', 'بلوك', 'محارة', 'دهان', 'طوب لبن'],
                onChanged: _notify,
              ),
              const SizedBox(height: AppSpacing.md),
              MultiSelectChipField(
                label: 'السقف',
                field: _data.roof,
                options: const ['بدون', 'مسلح', 'خشب', 'سعف', 'جريد'],
                onChanged: _notify,
              ),
              const SizedBox(height: AppSpacing.md),
              MultiSelectChipField(
                label: 'الأرضية',
                field: _data.floor,
                options: const ['تراب', 'أسمنت', 'بلاط', 'سيراميك'],
                onChanged: _notify,
              ),
              const SizedBox(height: AppSpacing.md),
              MultiSelectChipField(
                label: 'المدخل',
                field: _data.entrance,
                options: const ['تراب', 'أسمنت', 'بلاط', 'سيراميك', 'رخام'],
                onChanged: _notify,
              ),
              const SizedBox(height: AppSpacing.md),
              MultiSelectChipField(
                label: 'حالة دورات المياه',
                field: _data.bathroomCondition,
                options: const ['ادمي', 'غير ادمي'],
                onChanged: _notify,
              ),
              const SizedBox(height: AppSpacing.md),
              MultiSelectChipField(
                label: 'الكهرباء',
                field: _data.electricity,
                options: const ['عداد', 'ممارسة'],
                onChanged: _notify,
              ),
              const SizedBox(height: AppSpacing.md),
              MultiSelectChipField(
                label: 'عداد المياه',
                field: _data.waterMeter,
                options: const ['عداد', 'ممارسة'],
                onChanged: _notify,
              ),
              const SizedBox(height: AppSpacing.md),
              MultiSelectChipField(
                label: 'موتور مياه',
                field: _data.waterMotor,
                options: const ['يوجد', 'لا يوجد'],
                onChanged: _notify,
              ),
              const SizedBox(height: AppSpacing.md),
              MultiSelectChipField(
                label: 'الثلاجة',
                field: _data.fridge,
                options: const ['يوجد', 'لا يوجد'],
                onChanged: _notify,
              ),
              const SizedBox(height: AppSpacing.md),
              MultiSelectChipField(
                label: 'الغسالة',
                field: _data.washer,
                options: const ['لا يوجد', 'عادية', 'هاف اوتوماتيك'],
                onChanged: _notify,
              ),
              const SizedBox(height: AppSpacing.md),
              MultiSelectChipField(
                label: 'فرن خبيز',
                field: _data.oven,
                options: const ['يوجد', 'لا يوجد'],
                onChanged: _notify,
              ),
              const SizedBox(height: AppSpacing.md),
              MultiSelectChipField(
                label: 'أجهزة الطبخ',
                field: _data.cookingAppliances,
                options: const ['شعلة', 'بوتوجاز', 'لا يوجد'],
                onChanged: _notify,
              ),
              const SizedBox(height: AppSpacing.md),
              MultiSelectChipField(
                label: 'حاسب آلي',
                field: _data.computer,
                options: const ['للتعليم', 'للتسلية', 'لا يوجد'],
                onChanged: _notify,
              ),
              const SizedBox(height: AppSpacing.md),
              MultiSelectChipField(
                label: 'التلفاز',
                field: _data.tv,
                options: const ['تلفاز', 'شاشة', 'لا يوجد'],
                onChanged: _notify,
              ),
              const SizedBox(height: AppSpacing.md),
              MultiSelectChipField(
                label: 'ديب فريزر',
                field: _data.freezer,
                options: const ['يوجد', 'لا يوجد'],
                onChanged: _notify,
              ),
              const SizedBox(height: AppSpacing.md),
              MultiSelectChipField(
                label: 'وسيلة مواصلات',
                field: _data.transportation,
                options: const ['سيارة', 'موتوسيكل', 'توك توك'],
                onChanged: _notify,
              ),
              const SizedBox(height: AppSpacing.md),
              MultiSelectChipField(
                label: 'إنترنت',
                field: _data.internet,
                options: const ['يوجد', 'لا يوجد'],
                onChanged: _notify,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
