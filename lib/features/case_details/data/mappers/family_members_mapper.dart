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

  /// يعيد بناء [FamilyMembersFormData] من شكل التخزين المحلي (`toCacheJson`)
  /// — بلا فقد. يُستخدَم عند إعادة فتح تاب أفراد الأسرة لعرض ما حفظه
  /// الأخصائي فعليًا بدل فورم فاضٍ.
  static FamilyMembersFormData fromCacheJson(Map<String, dynamic> json) {
    final rawMembers = json['members'] as List? ?? const [];
    return FamilyMembersFormData(
      members: [
        for (final m in rawMembers.whereType<Map<String, dynamic>>())
          FamilyMemberFormData(
            name: m['name'] as String? ?? '',
            relation: m['relation'] as String? ?? '',
            nationalId: m['nationalId'] as String?,
            age: m['age'] as int?,
            gender: m['gender'] as String?,
            religion: m['religion'] as String?,
            isStudent: m['isStudent'] as bool? ?? false,
            educationStage: m['educationStage'] as String?,
            educationGrade: m['educationGrade'] as String?,
            universityName: m['universityName'] as String?,
            nonStudentEducation: m['nonStudentEducation'] as String?,
            job: m['job'] as String?,
            monthlyIncome: (m['monthlyIncome'] as num?)?.toDouble(),
            takafulKarama: m['takafulKarama'] as bool? ?? false,
            takafulKaramaAmount: (m['takafulKaramaAmount'] as num?)
                ?.toDouble(),
            notes: m['notes'] as String?,
          ),
      ],
    );
  }

  /// يبني [FamilyMembersFormData] من استجابة `PUT`/`GET /family-members`
  /// الفعلية من الخادم (§19) — أسماء حقول مختلفة عن [toCacheJson]/
  /// [fromCacheJson] (`grade` لا `educationGrade`, `university` لا
  /// `universityName`, `education` لا `nonStudentEducation`,
  /// `takafulBeneficiary`/`takafulAmount` لا `takafulKarama`/
  /// `takafulKaramaAmount`). نقرأ `relationship` كبديل احتياطي لو اختلفت
  /// تسمية الخادم (نفس احتياط `CasesRepository.refreshFamilyMembers`).
  static FamilyMembersFormData fromApiResponse(Map<String, dynamic> json) {
    final rawMembers = json['members'] as List? ?? const [];
    return FamilyMembersFormData(
      members: [
        for (final m in rawMembers.whereType<Map<String, dynamic>>())
          FamilyMemberFormData(
            name: m['name'] as String? ?? '',
            relation: (m['relation'] ?? m['relationship']) as String? ?? '',
            nationalId: m['nationalId'] as String?,
            age: m['age'] as int?,
            gender: m['gender'] as String?,
            isStudent: m['isStudent'] as bool? ?? false,
            educationStage: m['educationStage'] as String?,
            educationGrade: m['grade'] as String?,
            universityName: m['university'] as String?,
            nonStudentEducation: m['education'] as String?,
            job: m['job'] as String?,
            monthlyIncome: (m['monthlyIncome'] as num?)?.toDouble(),
            takafulKarama: m['takafulBeneficiary'] as bool? ?? false,
            takafulKaramaAmount: (m['takafulAmount'] as num?)?.toDouble(),
            notes: m['notes'] as String?,
          ),
      ],
    );
  }
}
