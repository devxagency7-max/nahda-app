/// القسم 10 — Housing Information. المصدر: Social Worker.
class HousingSection {
  final String housingType;
  final String ownershipStatus; // إيجار / تمليك / سكن مع الغير
  final int? roomsCount;
  final String? housingCondition;
  final String? buildingCondition;
  final String wallsCondition;
  final String roofType;
  final String? roofCondition;
  final String floorsType;
  final String?
  doorsWindowsCondition; // UNDEFINED / NEEDS BUSINESS DECISION — غير مفصّل في وثائق الأدوار
  final int? bathroomsCount;
  final String? bathroomCondition;
  final String? housingLevel; // مستوى السكن
  final String? description;
  final String? socialWorkerNotes;
  final List<String> photos;

  const HousingSection({
    required this.housingType,
    required this.ownershipStatus,
    this.roomsCount,
    this.housingCondition,
    this.buildingCondition,
    required this.wallsCondition,
    required this.roofType,
    this.roofCondition,
    required this.floorsType,
    this.doorsWindowsCondition,
    this.bathroomsCount,
    this.bathroomCondition,
    this.housingLevel,
    this.description,
    this.socialWorkerNotes,
    this.photos = const [],
  });
}
