import '../../domain/sections/basic_info_family_form.dart';

/// يحوّل [BasicInfoFormData] من/إلى شكل التخزين المحلي وشكل
/// `PUT /cases/{id}/beneficiary` (§19).
///
/// **عدم تطابق مكتشف:** `caseName` (اسم الحالة، يظهر في الشاشة) لا يقابله
/// `fullName` في العقد إلا اسميًا — العقد لا يعرض `nationalId` ضمن هذا الـ
/// PUT إطلاقًا (ثابت من الإنشاء)، فحقل `nationalId` في الشاشة **لا يُرسَل**.
/// حقول أخرى (`religion`, `workType`, `socialInsurance`, `takafulKarama`,
/// `referralDistrict`, `referralVillage`, `charity`) لا تطابق العقد مباشرة —
/// بعضها له نظير قريب (`religion` مطابق، `takafulKarama`/`takafulKaramaAmount`
/// مطابقان)، والباقي محفوظ محليًا فقط.
class BeneficiaryMapper {
  const BeneficiaryMapper._();

  static Map<String, dynamic> toCacheJson(BasicInfoFormData form) => {
    'caseName': form.caseName,
    'nationalId': form.nationalId,
    'educationLevel': form.educationLevel,
    'age': form.age,
    'gender': form.gender,
    'religion': form.religion,
    'headRelation': form.headRelation,
    'phone1': form.phone1,
    'phone2': form.phone2,
    'job': form.job,
    'monthlyIncome': form.monthlyIncome,
    'workType': form.workType,
    'socialInsurance': form.socialInsurance,
    'takafulKarama': form.takafulKarama,
    'takafulKaramaAmount': form.takafulKaramaAmount,
    'governorate': form.governorate,
    'district': form.district,
    'village': form.village,
    'address': form.address,
    'referralDistrict': form.referralDistrict,
    'referralVillage': form.referralVillage,
    'charity': form.charity,
  };

  /// شكل جسم `PUT /beneficiary` — [rowVersion] نسخة صفّ **المستفيد** (غير
  /// قابلة للـ null، §19: الصف موجود دائمًا من لحظة إنشاء الحالة) لا نسخة
  /// الحالة. `nationalId` لا يظهر هنا إطلاقًا — العقد لا يقبله.
  static Map<String, dynamic> toApiPayload(
    BasicInfoFormData form, {
    required int rowVersion,
  }) => {
    'fullName': form.caseName,
    'phonePrimary': form.phone1,
    'phoneSecondary': form.phone2,
    'religion': form.religion,
    'education': form.educationLevel,
    'maritalStatus': null, // لا حقل مطابق في UI الحالي
    'healthStatus': null, // لا حقل مطابق في UI الحالي
    'employmentStatus': form.workType,
    'job': form.job,
    'monthlyIncome': form.monthlyIncome,
    'takafulBeneficiary': form.takafulKarama,
    'takafulAmount': form.takafulKaramaAmount,
    'centerId': null, // يحتاج ربط بمعرّف من GET /locations، لا نص خام
    'villageId': null, // نفس الملاحظة
    'address': form.address,
    'headRelation': form.headRelation,
    'rowVersion': rowVersion,
  };
}
