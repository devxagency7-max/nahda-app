import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/egyptian_national_id_parser.dart';
import '../../../../core/utils/localized_number_parser.dart';
import '../../domain/sections/basic_info_family_form.dart';
import '../widgets/editable_dropdown.dart';
import '../widgets/editable_text_field.dart';
import '../widgets/section_card.dart';
import '../widgets/tab_progress_bar.dart';

const _relations = [
  'الزوج',
  'الزوجة',
  'الابن',
  'الابنة',
  'الحفيد',
  'الحفيدة',
  'الجد',
  'الجدة',
  'أخرى',
];

const _educationStages = [
  'حضانة',
  'ابتدائي',
  'إعدادي',
  'ثانوي',
  'كلية / جامعة',
  'أخرى',
];

const _nonStudentEducationLevels = [
  'مؤهل عالي / كلية (جامعي)',
  'معهد عالي (4 سنوات)',
  'معهد متوسط / فوق متوسط (سنتين)',
  'دبلوم فني / مؤهل متوسط',
  'ثانوية عامة / أزهرية',
  'إعدادية',
  'ابتدائية',
  'يجيد القراءة والكتابة',
  'أمي (بدون مؤهل)',
  'أخرى',
];

const _genders = ['ذكر', 'أنثى'];
const _religions = ['مسلم', 'مسيحي'];

const Map<String, List<String>> _gradeOptionsForStage = {
  'حضانة': ['KG1', 'KG2'],
  'ابتدائي': [
    'الصف الأول الابتدائي',
    'الصف الثاني الابتدائي',
    'الصف الثالث الابتدائي',
    'الصف الرابع الابتدائي',
    'الصف الخامس الابتدائي',
    'الصف السادس الابتدائي',
  ],
  'إعدادي': [
    'الصف الأول الإعدادي',
    'الصف الثاني الإعدادي',
    'الصف الثالث الإعدادي',
  ],
  'ثانوي': [
    'الصف الأول الثانوي',
    'الصف الثاني الثانوي',
    'الصف الثالث الثانوي',
  ],
};

/// تاب الأفراد التابعين للأسرة — مستقل بذاته (SECTION 4 في الويب)،
/// مطابق لفورم "إضافة فرد" هناك بالكامل.
class FamilyMembersTab extends StatefulWidget {
  final FamilyMembersFormData initialData;
  final ValueChanged<FamilyMembersFormData> onChanged;

  const FamilyMembersTab({
    super.key,
    required this.initialData,
    required this.onChanged,
  });

  @override
  State<FamilyMembersTab> createState() => _FamilyMembersTabState();
}

class _FamilyMembersTabState extends State<FamilyMembersTab> {
  late final FamilyMembersFormData _data = widget.initialData;
  bool _showAddMemberForm = false;
  int? _editingIndex;

  void _notify() => widget.onChanged(_data);

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'أفراد الأسرة التابعين — عدد الأفراد: ${_data.members.length}',
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => setState(() {
                            _editingIndex = null;
                            _showAddMemberForm = !_showAddMemberForm;
                          }),
                          icon: Icon(
                            _showAddMemberForm ? Icons.close : Icons.add,
                            size: 18,
                          ),
                          label: Text(
                            _showAddMemberForm ? 'إلغاء' : 'إضافة فرد',
                          ),
                        ),
                      ],
                    ),
                    if (_showAddMemberForm) ...[
                      const SizedBox(height: AppSpacing.md),
                      _AddFamilyMemberForm(
                        onSave: (member) {
                          setState(() {
                            _data.members.add(member);
                            _showAddMemberForm = false;
                          });
                          _notify();
                        },
                        onCancel: () =>
                            setState(() => _showAddMemberForm = false),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    if (_data.members.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: Text(
                          'لم يتم إضافة أفراد أسرة بعد. اضغط على زر "إضافة فرد" للبدء في التسجيل.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      )
                    else
                      for (int i = 0; i < _data.members.length; i++) ...[
                        if (_editingIndex == i) ...[
                          _AddFamilyMemberForm(
                            initialMember: _data.members[i],
                            onSave: (updated) {
                              setState(() {
                                _data.members[i] = updated;
                                _editingIndex = null;
                              });
                              _notify();
                            },
                            onCancel: () =>
                                setState(() => _editingIndex = null),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ] else ...[
                          _FamilyMemberTile(
                            member: _data.members[i],
                            onEdit: () => setState(() {
                              _showAddMemberForm = false;
                              _editingIndex = i;
                            }),
                            onDelete: () {
                              setState(() => _data.members.removeAt(i));
                              _notify();
                            },
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                      ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FamilyMemberTile extends StatelessWidget {
  final FamilyMemberFormData member;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FamilyMemberTile({
    required this.member,
    required this.onEdit,
    required this.onDelete,
  });

  void _showMemberDetailsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    member.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(),
              _buildDetailRow('صلة القرابة', member.relation),
              if (member.nationalId != null && member.nationalId!.isNotEmpty)
                _buildDetailRow('الرقم القومي', member.nationalId!),
              if (member.age != null)
                _buildDetailRow('السن', '${member.age} سنة'),
              if (member.gender != null && member.gender!.isNotEmpty)
                _buildDetailRow('النوع', member.gender!),
              if (member.religion != null && member.religion!.isNotEmpty)
                _buildDetailRow('الديانة', member.religion!),
              _buildDetailRow(
                'حالة التعليم',
                member.isStudent ? 'طالب ملتحق بالتعليم' : 'غير ملتحق بالتعليم',
              ),
              if (member.isStudent && member.educationStage != null)
                _buildDetailRow('المرحلة التعليمية', member.educationStage!),
              if (member.isStudent &&
                  member.educationGrade != null &&
                  member.educationGrade!.isNotEmpty)
                _buildDetailRow('الصف / المستوى الدراسي', member.educationGrade!),
              if (!member.isStudent &&
                  member.nonStudentEducation != null &&
                  member.nonStudentEducation!.isNotEmpty)
                _buildDetailRow('المؤهل الدراسي / المستوى التعليمي', member.nonStudentEducation!),
              if (member.job != null && member.job!.isNotEmpty)
                _buildDetailRow('الوظيفة / العمل', member.job!),
              if (member.monthlyIncome != null)
                _buildDetailRow('الدخل الشهري', '${member.monthlyIncome} جنيه'),
              _buildDetailRow(
                'تكافل وكرامة',
                member.takafulKarama ? 'مستفيد' : 'غير مستفيد',
              ),
              if (member.takafulKarama && member.takafulKaramaAmount != null)
                _buildDetailRow(
                  'مبلغ تكافل وكرامة',
                  '${member.takafulKaramaAmount} جنيه',
                ),
              if (member.notes != null && member.notes!.isNotEmpty)
                _buildDetailRow('ملاحظات', member.notes!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showMemberDetailsModal(context),
      borderRadius: BorderRadius.circular(AppRadius.input),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.input),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              child: const Icon(
                Icons.person,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (member.nationalId != null && member.nationalId!.isNotEmpty)
                    Text(
                      'الرقم القومي: ${member.nationalId}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  Text(
                    member.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    children: [
                      Text(
                        member.relation,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                      if (member.age != null) ...[
                        const Text('·', style: TextStyle(color: AppColors.textMuted)),
                        Text(
                          '${member.age} سنة',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                      if (member.isStudent && member.educationStage != null) ...[
                        const Text('·', style: TextStyle(color: AppColors.textMuted)),
                        Text(
                          '${member.educationStage}${member.educationGrade != null ? " (${member.educationGrade})" : ""}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ] else if (!member.isStudent &&
                          member.nonStudentEducation != null &&
                          member.nonStudentEducation!.isNotEmpty) ...[
                        const Text('·', style: TextStyle(color: AppColors.textMuted)),
                        Text(
                          member.nonStudentEducation!,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onEdit,
              icon: const Icon(
                Icons.edit_outlined,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.danger,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddFamilyMemberForm extends StatefulWidget {
  final FamilyMemberFormData? initialMember;
  final ValueChanged<FamilyMemberFormData> onSave;
  final VoidCallback onCancel;

  const _AddFamilyMemberForm({
    this.initialMember,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<_AddFamilyMemberForm> createState() => _AddFamilyMemberFormState();
}

class _AddFamilyMemberFormState extends State<_AddFamilyMemberForm> {
  late final _member = widget.initialMember ?? FamilyMemberFormData();
  late final _nameCtrl = TextEditingController(text: _member.name);
  late final _idCtrl = TextEditingController(text: _member.nationalId ?? '');
  late final _ageCtrl = TextEditingController(
    text: _member.age?.toString() ?? '',
  );
  late final _jobCtrl = TextEditingController(text: _member.job ?? '');
  late final _incomeCtrl = TextEditingController(
    text: _member.monthlyIncome?.toString() ?? '',
  );
  late final _takafulKaramaAmountCtrl = TextEditingController(
    text: _member.takafulKaramaAmount?.toString() ?? '',
  );
  late final _notesCtrl = TextEditingController(text: _member.notes ?? '');
  late final _universityCtrl = TextEditingController(
    text: _member.universityName ?? '',
  );
  late final _otherGradeCtrl = TextEditingController(
    text: _member.educationGrade ?? '',
  );

  @override
  void dispose() {
    _nameCtrl.dispose();
    _idCtrl.dispose();
    _ageCtrl.dispose();
    _jobCtrl.dispose();
    _incomeCtrl.dispose();
    _takafulKaramaAmountCtrl.dispose();
    _notesCtrl.dispose();
    _universityCtrl.dispose();
    _otherGradeCtrl.dispose();
    super.dispose();
  }

  void _onNationalIdChanged(String v) {
    _member.nationalId = v;
    final parsed = parseEgyptianNationalId(v);
    if (parsed.valid) {
      setState(() {
        _member.age = parsed.age;
        _ageCtrl.text = parsed.age.toString();
        _member.gender = parsed.genderAr;
        if (_member.religion == null || _member.religion!.isEmpty) {
          _member.religion = parsed.religionAr ?? 'مسلم';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          EditableTextField(
            label: 'اسم الفرد التابع الرباعي',
            required: true,
            controller: _nameCtrl,
            onChanged: (v) => setState(() => _member.name = v),
          ),
          EditableDropdown(
            label: 'صلة القرابة برب الأسرة',
            required: true,
            value: _member.relation.isEmpty ? null : _member.relation,
            options: _relations,
            onChanged: (v) => setState(() => _member.relation = v ?? ''),
          ),
          EditableTextField(
            label: 'الرقم القومي (14 رقم)',
            controller: _idCtrl,
            keyboardType: TextInputType.number,
            maxLength: 14,
            onChanged: _onNationalIdChanged,
          ),
          EditableTextField(
            label: 'السن الحالي (يُحسب تلقائياً من الرقم القومي)',
            controller: _ageCtrl,
            keyboardType: TextInputType.number,
            onChanged: (v) => _member.age = parseLocalizedInt(v),
          ),
          EditableDropdown(
            label: 'النوع',
            value: _member.gender,
            options: _genders,
            onChanged: (v) => setState(() => _member.gender = v),
          ),
          EditableDropdown(
            label: 'الديانة',
            value: _member.religion,
            options: _religions,
            onChanged: (v) => setState(() => _member.religion = v),
          ),
          CheckboxListTile(
            value: _member.isStudent,
            onChanged: (v) {
              setState(() {
                _member.isStudent = v ?? false;
                if (_member.isStudent) {
                  _member.nonStudentEducation = null;
                } else {
                  _member.educationStage = null;
                  _member.educationGrade = null;
                  _member.universityName = null;
                  _universityCtrl.clear();
                  _otherGradeCtrl.clear();
                }
              });
            },
            title: const Text(
              '🎓 هل الفرد طالب ملتحق بالتعليم؟',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          if (_member.isStudent) ...[
            EditableDropdown(
              label: 'المرحلة التعليمية',
              value: _member.educationStage,
              options: _educationStages,
              onChanged: (v) {
                setState(() {
                  _member.educationStage = v;
                  _member.educationGrade = null;
                  _member.universityName = null;
                  _universityCtrl.clear();
                  _otherGradeCtrl.clear();
                });
              },
            ),
            if (_member.educationStage != null &&
                _gradeOptionsForStage.containsKey(_member.educationStage)) ...[
              EditableDropdown(
                label: 'الصف / المستوى الدراسي (${_member.educationStage})',
                value: _member.educationGrade,
                options: _gradeOptionsForStage[_member.educationStage!]!,
                onChanged: (v) => setState(() => _member.educationGrade = v),
              ),
            ] else if (_member.educationStage == 'كلية / جامعة') ...[
              EditableTextField(
                label: 'اسم الكلية / الجامعة والفرقة',
                controller: _universityCtrl,
                onChanged: (v) {
                  _member.universityName = v;
                  _member.educationGrade = v;
                },
              ),
            ] else if (_member.educationStage == 'أخرى') ...[
              EditableTextField(
                label: 'تفاصيل المرحلة والصف الدراسي',
                controller: _otherGradeCtrl,
                onChanged: (v) => _member.educationGrade = v,
              ),
            ],
          ] else ...[
            EditableDropdown(
              label: 'المؤهل الدراسي / المستوى التعليمي',
              value: _member.nonStudentEducation,
              options: _nonStudentEducationLevels,
              onChanged: (v) {
                setState(() {
                  _member.nonStudentEducation = v;
                });
              },
            ),
          ],
          EditableTextField(
            label: 'الوظيفة / العمل',
            controller: _jobCtrl,
            onChanged: (v) => _member.job = v,
          ),
          EditableTextField(
            label: 'الدخل الشهري للفرد (جنيه)',
            controller: _incomeCtrl,
            keyboardType: TextInputType.number,
            onChanged: (v) => _member.monthlyIncome = parseLocalizedDouble(v),
          ),
          CheckboxListTile(
            value: _member.takafulKarama,
            onChanged: (v) {
              setState(() {
                _member.takafulKarama = v ?? false;
                if (!_member.takafulKarama) {
                  _member.takafulKaramaAmount = null;
                  _takafulKaramaAmountCtrl.clear();
                }
              });
            },
            title: const Text(
              'مستفيد من تكافل وكرامة',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.primary,
          ),
          if (_member.takafulKarama)
            EditableTextField(
              label: 'مبلغ تكافل وكرامة (جنيه)',
              controller: _takafulKaramaAmountCtrl,
              keyboardType: TextInputType.number,
              onChanged: (v) =>
                  _member.takafulKaramaAmount = parseLocalizedDouble(v),
            ),
          EditableTextField(
            label: 'ملاحظات',
            controller: _notesCtrl,
            onChanged: (v) => _member.notes = v,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onCancel,
                child: const Text('إلغاء'),
              ),
              const SizedBox(width: AppSpacing.sm),
              ElevatedButton(
                onPressed: _member.isComplete
                    ? () => widget.onSave(_member)
                    : null,
                child: Text(
                  widget.initialMember != null
                      ? 'تحديث بيانات الفرد'
                      : 'تأكيد إضافة الفرد التابع',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
