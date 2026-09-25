import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/sections/classification_form.dart';
import '../widgets/editable_dropdown.dart';
import '../widgets/editable_text_field.dart';
import '../widgets/section_card.dart';
import '../widgets/tab_progress_bar.dart';

const _mainClassificationOptions = [
  'فقر',
  'إعاقة',
  'يتيم',
  'مسنّ',
  'مريض مزمن',
  'أسرة بلا معيل',
];
const _levels = ['low', 'medium', 'high'];

/// تاب التصنيف الاجتماعي (القسم 16) — أُضيف في المرحلة ٣ لتغطية قسم مدعوم
/// بالكامل في العقد (`PUT /classification`) لم يكن له تاب من قبل.
class ClassificationTab extends StatefulWidget {
  final ClassificationFormData initialData;
  final ValueChanged<ClassificationFormData> onChanged;

  const ClassificationTab({
    super.key,
    required this.initialData,
    required this.onChanged,
  });

  @override
  State<ClassificationTab> createState() => _ClassificationTabState();
}

class _ClassificationTabState extends State<ClassificationTab> {
  late final ClassificationFormData _data = widget.initialData;
  late final _subCtrl = TextEditingController(
    text: _data.subClassification ?? '',
  );
  late final _notesCtrl = TextEditingController(text: _data.notes ?? '');

  @override
  void dispose() {
    _subCtrl.dispose();
    _notesCtrl.dispose();
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
              SectionCard(
                title: 'التصنيف الرئيسي (اختيارات متعددة)',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in _mainClassificationOptions)
                      FilterChip(
                        label: Text(option),
                        selected: _data.mainClassifications.contains(option),
                        onSelected: (selected) {
                          if (selected) {
                            _data.mainClassifications.add(option);
                          } else {
                            _data.mainClassifications.remove(option);
                          }
                          _notify();
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              EditableTextField(
                label: 'التصنيف الفرعي',
                controller: _subCtrl,
                onChanged: (v) {
                  _data.subClassification = v;
                  _notify();
                },
              ),
              EditableDropdown(
                label: 'مستوى الاحتياج',
                required: true,
                value: _data.needLevel.isEmpty ? null : _data.needLevel,
                options: _levels,
                onChanged: (v) {
                  _data.needLevel = v ?? '';
                  _notify();
                },
              ),
              EditableDropdown(
                label: 'الأولوية',
                required: true,
                value: _data.priorityLevel.isEmpty ? null : _data.priorityLevel,
                options: _levels,
                onChanged: (v) {
                  _data.priorityLevel = v ?? '';
                  _notify();
                },
              ),
              EditableDropdown(
                label: 'مستوى الهشاشة',
                value: _data.vulnerabilityLevel,
                options: _levels,
                onChanged: (v) {
                  _data.vulnerabilityLevel = v;
                  _notify();
                },
              ),
              EditableTextField(
                label: 'ملاحظات',
                controller: _notesCtrl,
                onChanged: (v) {
                  _data.notes = v;
                  _notify();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
