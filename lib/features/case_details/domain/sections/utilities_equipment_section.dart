/// القسم 11 — Utilities. المصدر: Social Worker.
class UtilityItem {
  final String name; // كهرباء / مياه / غاز / صرف صحي / أخرى
  final bool isAvailable;
  final String? condition;
  final String?
  sourceOrMeter; // مصدر المياه / نوع مصدر الغاز / نوع الصرف / العداد
  final String? notes;

  const UtilityItem({
    required this.name,
    required this.isAvailable,
    this.condition,
    this.sourceOrMeter,
    this.notes,
  });
}

/// القسم 12 — Household Equipment & Possessions. المصدر: Social Worker.
/// القائمة يجب أن تكون Configurable من إعدادات النظام لاحقًا.
class EquipmentItem {
  final String name;
  final String
  category; // أجهزة كهربائية / أثاث / أجهزة منزلية / تبريد / تدفئة / طبخ / أخرى
  final bool isPresent;
  final int? count;
  final String? condition;
  final bool? isUsable;
  final String? notes;

  const EquipmentItem({
    required this.name,
    required this.category,
    required this.isPresent,
    this.count,
    this.condition,
    this.isUsable,
    this.notes,
  });
}

class UtilitiesEquipmentSection {
  final List<UtilityItem> utilities;
  final List<EquipmentItem> equipment;

  const UtilitiesEquipmentSection({
    required this.utilities,
    required this.equipment,
  });
}
