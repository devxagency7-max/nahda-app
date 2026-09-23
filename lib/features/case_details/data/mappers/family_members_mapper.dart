import '../../domain/sections/basic_info_family_form.dart';

/// يحوّل [FamilyMembersFormData] من/إلى شكل التخزين المحلي وشكل
/// `PUT /cases/{id}/family-members` (§19) — استبدال كامل، `caseRowVersion`.
class FamilyMembersMapper {
  const FamilyMembersMapper._();

  static Map<String, dynamic> toCacheJson(FamilyMembersFormData form) => {
    'members': [
      for (final m in form.members)
        {
          'name': m.name,
          'relation': m.relation,
          'nationalId': m.nationalId,
          'age': m.age,
          'gender': m.gender,
          'religion': m.religion,
          'isStudent': m.isStudent,
          'educationStage': m.educationStage,
          'educationGrade': m.educationGrade,
          'universityName': m.universityName,
          'nonStudentEducation': m.nonStudentEducation,
          'job': m.job,
          'monthlyIncome': m.monthlyIncome,
          'takafulKarama': m.takafulKarama,
          'takafulKaramaAmount': m.takafulKaramaAmount,
          'notes': m.notes,
        },
    ],
  };

  /// شكل جسم `PUT /family-members` — [caseRowVersion] نسخة **الحالة** لا
  /// نسخة فرد. `sortOrder` يُشتَق من ترتيب القائمة نفسها (§19 لا يفرض شكلًا
  /// آخر). المرحلة التعليمية غير الطلابية (`nonStudentEducation`) لا حقل
  /// مطابق لها في العقد — الخادم يخزّن `education` عامًا للفرد غير الطالب،
  /// فنمرّره كذلك.
  static Map<String, dynamic> toApiPayload(
    FamilyMembersFormData form, {
    required int caseRowVersion,
  }) => {
    'members': [
      for (var i = 0; i < form.members.length; i++)
        () {
          final m = form.members[i];
          return {
            'name': m.name,
            'relation': m.relation,
            'nationalId': m.nationalId,
            'age': m.age,
            'gender': m.gender,
            'isStudent': m.isStudent,
            'educationStage': m.isStudent ? m.educationStage : null,
            'grade': m.isStudent ? m.educationGrade : null,
            'university': m.isStudent ? m.universityName : null,
            'education': m.isStudent ? null : m.nonStudentEducation,
            'job': m.job,
            'monthlyIncome': m.monthlyIncome,
            'takafulBeneficiary': m.takafulKarama,
            'takafulAmount': m.takafulKaramaAmount,
            'notes': m.notes,
            'sortOrder': i + 1,
          };
        }(),
    ],
    'caseRowVersion': caseRowVersion,
  };
}
