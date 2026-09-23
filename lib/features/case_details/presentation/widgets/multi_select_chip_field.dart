import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/sections/housing_form.dart';

/// بطاقة حقل اختيار متعدد (Multi-select Chips) — مطابقة لتصميم الويب:
/// عنوان + عداد "X اختيار" + Chips، ولو "أخرى" محددة يظهر حقل نص حر.
class MultiSelectChipField extends StatefulWidget {
  final String label;
  final MultiSelectField field;
  final List<String> options; // بدون "أخرى" — تُضاف تلقائيًا في النهاية
  final VoidCallback onChanged;

  const MultiSelectChipField({
    super.key,
    required this.label,
    required this.field,
    required this.options,
    required this.onChanged,
  });

  @override
  State<MultiSelectChipField> createState() => _MultiSelectChipFieldState();
}

class _MultiSelectChipFieldState extends State<MultiSelectChipField> {
  late final _otherCtrl = TextEditingController(
    text: widget.field.freeTextValue ?? '',
  );

  @override
  void dispose() {
    _otherCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allOptions = [...widget.options, MultiSelectField.otherOption];
    final count = widget.field.selected.length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: count > 0
                      ? AppColors.primaryLight
                      : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Text(
                  '$count اختيار',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: count > 0 ? AppColors.primary : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in allOptions)
                FilterChip(
                  label: Text(option),
                  selected: widget.field.selected.contains(option),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        widget.field.selected.add(option);
                      } else {
                        widget.field.selected.remove(option);
                        if (option == MultiSelectField.otherOption) {
                          widget.field.freeTextValue = null;
                          _otherCtrl.clear();
                        }
                      }
                    });
                    widget.onChanged();
                  },
                ),
            ],
          ),
          if (widget.field.hasOther) ...[
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _otherCtrl,
              decoration: const InputDecoration(hintText: 'اكتب هنا...'),
              onChanged: (v) {
                widget.field.freeTextValue = v;
                widget.onChanged();
              },
            ),
          ],
        ],
      ),
    );
  }
}
