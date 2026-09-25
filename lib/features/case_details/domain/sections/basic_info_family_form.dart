/// نموذج قابل للتعديل يطابق حقول صفحة "البيانات الأساسية" في الويب
/// (web/index.html — SECTION 1 المعلومات الشخصية، SECTION 2 الوظيفية والدينية،
/// SECTION 3 العنوان).
class BasicInfoFormData {
  // SECTION 1 — المعلومات الشخصية (رب الأسرة)
  String caseName; // اسم الحالة *
  String nationalId; // الرقم القومي *
  String? educationLevel; // المرحلة التعليمية
  int? age; // السن الحالي
  String? gender; // النوع
  String? religion; // الديانة
  String? headRelation; // صلة القرابة (لرب الأسرة)
  String? phone1;
  String? phone2;

  // SECTION 2 — المعلومات الوظيفية والمالية
  String? job;
  double? monthlyIncome;
  String? workType; // طبيعة العمل
  String? socialInsurance; // التأمين الاجتماعي
  bool takafulKarama; // مستفيد من برنامج تكافل وكرامة
  double? takafulKaramaAmount; // مبلغ تكافل وكرامة

  // SECTION 3 — العنوان والموقع
  String governorate; // المحافظة (محل السكن)
  String? district; // المركز
  String? village; // القرية
  String? address; // العنوان بالتفصيل

  String? birthGovernorate; // محافظة الميلاد (مستخرجة تلقائياً من الرقم القومي)

  // الجمعية والنطاق الجغرافي — المركز والقرية والجمعية المسؤولة عن متابعة الحالة
  String? referralDistrict; // المركز / المدينة
  String? referralVillage; // القرية / المنطقة
  String? charity; // الجمعية

  BasicInfoFormData({
    this.caseName = '',
    this.nationalId = '',
    this.educationLevel,
    this.age,
    this.gender,
    this.birthGovernorate,
    this.headRelation,
    this.phone1,
    this.phone2,
    this.job,
    this.monthlyIncome,
    this.workType,
    this.socialInsurance,
    this.takafulKarama = false,
    this.takafulKaramaAmount,
    this.religion,
    this.governorate = 'بني سويف',
    this.district,
    this.village,
    this.address,
    this.referralDistrict,
    this.referralVillage,
    this.charity,
  });

  /// الحقول المطلوبة فقط حسب الويب (عليها * — اسم الحالة والرقم القومي).
  /// باقي الحقول اختيارية، فالـ Progress هنا يُحسب على مجمل الحقول المعروضة
  /// (مطلوبة + اختيارية) عشان يعكس فعليًا "اكتمال البيانات" لا الحد الأدنى فقط.
  int get totalFieldsCount => 15;

  int get filledFieldsCount {
    int count = 0;
    if (caseName.trim().isNotEmpty) count++;
    if (nationalId.trim().isNotEmpty) count++;
    if (educationLevel != null && educationLevel!.isNotEmpty) count++;
    if (age != null) count++;
    if (gender != null && gender!.isNotEmpty) count++;
    if (headRelation != null && headRelation!.trim().isNotEmpty) count++;
    if (phone1 != null && phone1!.trim().isNotEmpty) count++;
    if (phone2 != null && phone2!.trim().isNotEmpty) count++;
    if (job != null && job!.trim().isNotEmpty) count++;
    if (monthlyIncome != null) count++;
    if (workType != null && workType!.trim().isNotEmpty) count++;
    if (socialInsurance != null && socialInsurance!.trim().isNotEmpty) count++;
    if (religion != null && religion!.isNotEmpty) count++;
    if (district != null && district!.trim().isNotEmpty) count++;
    if (village != null && village!.trim().isNotEmpty) count++;
    return count;
  }

  double get progress =>
      totalFieldsCount == 0 ? 0 : filledFieldsCount / totalFieldsCount;
}

/// القسم 4 — أفراد الأسرة التابعين (SECTION 4 في الويب). تاب مستقل بذاته.
class FamilyMemberFormData {
  String name;
  String relation; // صلة القرابة
  String? nationalId;
  int? age;
  String? gender; // النوع (مستخرج تلقائياً من الرقم القومي)
  String? religion; // الديانة (مستخرجة تلقائياً من الرقم القومي)
  bool isStudent;
  String? educationStage; // المرحلة التعليمية (لو طالب)
  String? educationGrade; // الصف الدراسي (لو طالب)
  String?
  universityName; // اسم الكلية/الجامعة — يظهر فقط لو المرحلة "كلية / جامعة"
  String? nonStudentEducation; // المؤهل الدراسي / المستوى التعليمي إذا كان غير طالب
  String? job;
  double? monthlyIncome;
  bool takafulKarama; // مستفيد من برنامج تكافل وكرامة
  double? takafulKaramaAmount; // مبلغ تكافل وكرامة
  String? notes;

  FamilyMemberFormData({
    this.name = '',
    this.relation = '',
    this.nationalId,
    this.age,
    this.gender,
    this.religion,
    this.isStudent = false,
    this.educationStage,
    this.educationGrade,
    this.universityName,
    this.nonStudentEducation,
    this.job,
    this.monthlyIncome,
    this.takafulKarama = false,
    this.takafulKaramaAmount,
    this.notes,
  });

  bool get isComplete => name.trim().isNotEmpty && relation.trim().isNotEmpty;
}

class FamilyMembersFormData {
  List<FamilyMemberFormData> members;

  FamilyMembersFormData({List<FamilyMemberFormData>? members})
    : members = members ?? [];

  /// وجود فرد واحد على الأقل يعتبر التاب مكتملًا — العدد نفسه غير ثابت
  /// (قد يزيد أو يقل)، فالمنطق هو "هل فيه بيانات مسجلة أصلاً".
  double get progress => members.isNotEmpty ? 1.0 : 0.0;
}
