import '../../domain/sections/basic_info_family_form.dart';

/// يحوّل [BasicInfoFormData] من/إلى شكل التخزين المحلي وشكل
/// `PUT /cases/{id}/beneficiary` (§19).
///
/// **عدم تطابق مكتشف:** `caseName` (اسم الحالة، يظهر في الشاشة) لا يقابله
/// `fullName` في العقد إلا اسميًا — العقد لا يعرض `nationalId` ضمن هذا الـ
/// PUT إطلاقًا (ثابت من الإنشاء)، فحقل `nationalId` في الشاشة **لا يُرسَل**.
/// `referralDistrict`/`referralVillage` (أسماء المركز/القرية للعرض) لا تُرسَل
/// مباشرة — بدلها `centerId`/`villageId` (المعرّفات الحقيقية) هما اللي
/// بيترسلوا فعليًا. `charity`/`socialInsurance` مالهمش نظير في هذا العقد —
/// الجمعية (`charityId`) بترسل من خلال `PUT /cases/{id}/charity` المنفصل
/// (راجع [CharityMapper])، و`socialInsurance` بيفضل محفوظ محليًا بس.
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
  ///
  /// **تحذير من الباك إند (اتأكد منه صراحة):** PUT /beneficiary بيعمل
  /// استبدال كامل — أي حقل يترسل null بيتمسح فعليًا على الخادم. فلازم الفورم
  /// يتملى بكل الحقول العشرة (عن طريق _seedFromServerData) قبل أي حفظ، وإلا
  /// أي حقل الفورم مالمسوش هيترجع null هنا ويمسح القيمة الحقيقية.
  static Map<String, dynamic> toApiPayload(
    BasicInfoFormData form, {
    required int rowVersion,
  }) => {
    'fullName': form.caseName,
    'phonePrimary': form.phone1,
    'phoneSecondary': form.phone2,
    'religion': form.religion,
    'education': form.educationLevel,
    // ماعندناش حقل UI مستقل لـ "الحالة الاجتماعية" — زي الويب بالظبط،
    // بنستخدم نفس قيمة صلة القرابة (headRelation) للحقلين، عشان لا نبعتها
    // null ونمسح قيمة حقيقية محفوظة (راجع التحذير فوق).
    'maritalStatus': form.headRelation,
    'healthStatus': null, // لا حقل مطابق في UI الحالي
    'employmentStatus': form.workType,
    'job': form.job,
    'monthlyIncome': form.monthlyIncome,
    'takafulBeneficiary': form.takafulKarama,
    'takafulAmount': form.takafulKaramaAmount,
    // centerId/villageId قابلين للتعديل فعليًا على حالة موجودة (اتأكد من
    // الباك إند) — basic_info_tab.dart بيملاهم بمعرّف حقيقي (GUID) لما
    // المستخدم يغيّر المركز/القرية من الـ Dropdown الجديد.
    'centerId': form.centerId,
    'villageId': form.villageId,
    'address': form.address,
    'headRelation': form.headRelation,
    'rowVersion': rowVersion,
  };
}

/// يحوّل [BasicInfoFormData] لشكل جسم `PUT /cases/{id}/charity` — endpoint
/// منفصل تمامًا عن `PUT /beneficiary` (رد الباك إند بتاريخ 2026-09-26).
///
/// **تحذير:** [caseRowVersion] هنا نسخة **الحالة** (`CaseDetailsDto.rowVersion`)
/// لا نسخة صفّ المستفيد — خلطهما يعني 409 دائم (راجع `cases_api.dart`).
/// `charityId: null` يمسح الجمعية عن الحالة (سلوك مقصود من الباك إند).
class CharityMapper {
  const CharityMapper._();

  static Map<String, dynamic> toApiPayload(
    BasicInfoFormData form, {
    required int caseRowVersion,
  }) => {'charityId': form.charityId, 'caseRowVersion': caseRowVersion};
}
