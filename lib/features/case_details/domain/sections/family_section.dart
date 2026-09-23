/// القسم 4+5 — Family Information + Household Information.
/// المصدر: Data Entry (أولي)، قابل للتحقق من Social Worker.
class FamilyMember {
  final String name;
  final String? nationalId;
  final String relationship;
  final String gender;
  final DateTime? birthDate;
  final int? age;
  final String? maritalStatus;
  final String? educationLevel;
  final String? occupation;
  final String? employer;
  final double? income;
  final bool livesWithFamily; // حالة الاعتماد/الإعالة
  final String? notes;

  const FamilyMember({
    required this.name,
    this.nationalId,
    required this.relationship,
    required this.gender,
    this.birthDate,
    this.age,
    this.maritalStatus,
    this.educationLevel,
    this.occupation,
    this.employer,
    this.income,
    required this.livesWithFamily,
    this.notes,
  });
}

class FamilySection {
  final int familyMembersCount;
  final List<FamilyMember> members;

  // HOUSEHOLD INFORMATION
  final String? householdHead; // الشخص المسؤول عن الأسرة
  final int? dependentsCount;
  final int? childrenCount;
  final int? adultsCount;
  final int? elderlyCount;
  final int? workingMembersCount;
  final int? nonWorkingMembersCount;
  final String? additionalContactInfo;
  final String? generalNotes;

  const FamilySection({
    required this.familyMembersCount,
    required this.members,
    this.householdHead,
    this.dependentsCount,
    this.childrenCount,
    this.adultsCount,
    this.elderlyCount,
    this.workingMembersCount,
    this.nonWorkingMembersCount,
    this.additionalContactInfo,
    this.generalNotes,
  });
}
