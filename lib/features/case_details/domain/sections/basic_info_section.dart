import '../data_source.dart';

/// القسم 1+2+3 — Case Basic Information + Applicant Personal Information + Address.
/// المصدر: Data Entry.
class BasicInfoSection {
  // 1. CASE BASIC INFORMATION
  final String caseId;
  final String caseNumber;
  final DateTime createdAt;
  final String statusLabel;
  final String priorityLabel;
  final DateTime lastUpdatedAt;

  // 2. APPLICANT PERSONAL INFORMATION
  final FieldValue<String> fullName;
  final FieldValue<String> nationalId;
  final String gender;
  final DateTime birthDate;
  final int age; // محسوب من تاريخ الميلاد
  final String maritalStatus;
  final String? educationLevel;
  final String? occupation;
  final String?
  employer; // جهة العمل — UNDEFINED / NEEDS BUSINESS DECISION هل مطلوبة دائمًا
  final FieldValue<String> phone;
  final String? alternatePhone;
  final String?
  email; // UNDEFINED / NEEDS BUSINESS DECISION — غير مذكور في وثائق الأدوار الثلاثة

  // كانت ناقصة من GET /cases/{id} (اتصلحت من الباك إند — commit bcc9d61،
  // 2026-09-25). موجودة أصلاً في UI/PUT، لكن الشاشة كانت بتفضل فاضية عند
  // فتح حالة محفوظة للتعديل لأن السلسلة مكانتش بتقرأها من رد GET.
  final String? religion;
  final double? monthlyIncome;
  final String? employmentStatus; // طبيعة العمل
  final bool? takafulBeneficiary;
  final double? takafulAmount;
  final String? headRelation;

  // 3. ADDRESS & LOCATION
  final String governorate;
  final String district;
  final String village;

  // معرّفات المركز/القرية الحقيقية (GUID من GET /locations) — لازمة عشان
  // نقدر نبعتهم فعليًا في PUT /beneficiary لو المستخدم عدّلهم. اتأكد من
  // الباك إند إن centerId/villageId قابلين للتعديل على حالة موجودة (على
  // عكس charityId اللي معندهوش أي endpoint تعديل لسه — لسه مستنيين رد
  // الباك إند بخصوصه).
  final String? centerId;
  final String? villageId;
  final String? area; // المنطقة
  final String? street; // UNDEFINED / NEEDS BUSINESS DECISION
  final String? buildingNumber; // UNDEFINED / NEEDS BUSINESS DECISION
  final String? floor; // UNDEFINED / NEEDS BUSINESS DECISION
  final String? apartmentNumber; // UNDEFINED / NEEDS BUSINESS DECISION
  final String? landmark; // علامة مميزة — UNDEFINED / NEEDS BUSINESS DECISION
  final String? addressDescription;

  const BasicInfoSection({
    required this.caseId,
    required this.caseNumber,
    required this.createdAt,
    required this.statusLabel,
    required this.priorityLabel,
    required this.lastUpdatedAt,
    required this.fullName,
    required this.nationalId,
    required this.gender,
    required this.birthDate,
    required this.age,
    required this.maritalStatus,
    this.educationLevel,
    this.occupation,
    this.employer,
    required this.phone,
    this.alternatePhone,
    this.email,
    this.religion,
    this.monthlyIncome,
    this.employmentStatus,
    this.takafulBeneficiary,
    this.takafulAmount,
    this.headRelation,
    required this.governorate,
    required this.district,
    required this.village,
    this.centerId,
    this.villageId,
    this.area,
    this.street,
    this.buildingNumber,
    this.floor,
    this.apartmentNumber,
    this.landmark,
    this.addressDescription,
  });
}
