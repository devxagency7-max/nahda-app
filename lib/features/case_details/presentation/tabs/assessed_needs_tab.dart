import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/sections/assessed_needs_form.dart';
import '../widgets/editable_dropdown.dart';
import '../widgets/editable_text_field.dart';
import '../widgets/section_card.dart';
import '../widgets/tab_progress_bar.dart';

const _priorityLevels = ['low', 'medium', 'high'];
const _sources = ['confirmed_from_initial', 'new_from_field_visit'];
const _statuses = ['pending', 'approved'];

/// تاب الاحتياجات المُقيَّمة (القسم 17) — أُضيف في المرحلة ٣ لتغطية قسم
/// مدعوم بالكامل في العقد (`PUT /assessed-needs`) لم يكن له تاب من قبل.
/// منفصل تمامًا عن الاحتياج الأولي (§19) — قد يؤكد/يعدّل/يضيف عليه.
class AssessedNeedsTab extends StatefulWidget {
  final AssessedNeedsFormData initialData;
  final ValueChanged<AssessedNeedsFormData> onChanged;

  const AssessedNeedsTab({
    super.key,
    required this.initialData,
    required this.onChanged,
  });

  @override
  State<AssessedNeedsTab> createState() => _AssessedNeedsTabState();
}

class _AssessedNeedsTabState extends State<AssessedNeedsTab> {
  late final AssessedNeedsFormData _data = widget.initialData;

  void _notify() => setState(() => widget.onChanged(_data));

  void _addNeed() {
    setState(() => _data.needs.add(AssessedNeedFormData()));
  }

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الاحتياجات المُقيَّمة — العدد: ${_data.needs.length}',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addNeed,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('إضافة احتياج'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (_data.needs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Text(
                    'لا احتياجات مُقيَّمة مسجَّلة بعد.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                )
              else
                for (var i = 0; i < _data.needs.length; i++) ...[
                  _AssessedNeedCard(
                    need: _data.needs[i],
                    onChanged: _notify,
                    onDelete: () {
                      setState(() => _data.needs.removeAt(i));
                      _notify();
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AssessedNeedCard extends StatefulWidget {
  final AssessedNeedFormData need;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  const _AssessedNeedCard({
    required this.need,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<_AssessedNeedCard> createState() => _AssessedNeedCardState();
}

class _AssessedNeedCardState extends State<_AssessedNeedCard> {
  late final _needTypeCtrl = TextEditingController(text: widget.need.needType);
  late final _categoryCtrl = TextEditingController(
    text: widget.need.category ?? '',
  );
  late final _descriptionCtrl = TextEditingController(
    text: widget.need.description ?? '',
  );
  late final _reasonCtrl = TextEditingController(text: widget.need.reason ?? '');
  late final _notesCtrl = TextEditingController(text: widget.need.notes ?? '');

  @override
  void dispose() {
    _needTypeCtrl.dispose();
    _categoryCtrl.dispose();
    _descriptionCtrl.dispose();
    _reasonCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: EditableTextField(
                  label: 'نوع الاحتياج',
                  required: true,
                  controller: _needTypeCtrl,
                  onChanged: (v) {
                    widget.need.needType = v;
                    widget.onChanged();
                  },
                ),
              ),
              IconButton(
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              ),
            ],
          ),
          EditableTextField(
            label: 'الفئة',
            controller: _categoryCtrl,
            onChanged: (v) {
              widget.need.category = v;
              widget.onChanged();
            },
          ),
          EditableTextField(
            label: 'الوصف',
            controller: _descriptionCtrl,
            onChanged: (v) {
              widget.need.description = v;
              widget.onChanged();
            },
          ),
          EditableDropdown(
            label: 'الأولوية',
            required: true,
            value: widget.need.priorityLevel.isEmpty
                ? null
                : widget.need.priorityLevel,
            options: _priorityLevels,
            onChanged: (v) {
              widget.need.priorityLevel = v ?? '';
              widget.onChanged();
            },
          ),
          EditableTextField(
            label: 'سبب الاحتياج',
            controller: _reasonCtrl,
            onChanged: (v) {
              widget.need.reason = v;
              widget.onChanged();
            },
          ),
          EditableDropdown(
            label: 'المصدر',
            required: true,
            value: widget.need.source.isEmpty ? null : widget.need.source,
            options: _sources,
            onChanged: (v) {
              widget.need.source = v ?? '';
              widget.onChanged();
            },
          ),
          EditableDropdown(
            label: 'الحالة',
            required: true,
            value: widget.need.status.isEmpty ? null : widget.need.status,
            options: _statuses,
            onChanged: (v) {
              widget.need.status = v ?? '';
              widget.onChanged();
            },
          ),
          EditableTextField(
            label: 'ملاحظات',
            controller: _notesCtrl,
            onChanged: (v) {
              widget.need.notes = v;
              widget.onChanged();
            },
          ),
        ],
      ),
    );
  }
}
