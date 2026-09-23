/// القسم 16 — Social Classification. المصدر: Social Worker.
class SocialClassificationSection {
  final List<String> mainClassifications; // Multi-select
  final String? subClassification;
  final String needLevel; // مستوى الاحتياج
  final String priorityLevel;
  final String? vulnerabilityLevel; // مستوى الهشاشة
  final String? notes;

  const SocialClassificationSection({
    required this.mainClassifications,
    this.subClassification,
    required this.needLevel,
    required this.priorityLevel,
    this.vulnerabilityLevel,
    this.notes,
  });
}

/// القسم 17 — Assessed Needs. المصدر: Social Worker.
/// منفصل تمامًا عن Initial Need (قسم 6) — قد يؤكد/يعدّل/يضيف على الاحتياج الأولي.
class AssessedNeed {
  final String needType;
  final String? category;
  final String? description;
  final String priorityLevel;
  final String? reason; // سبب الاحتياج
  final String source; // مصدر الاحتياج (تأكيد من الأولي / جديد من البحث)
  final String status;
  final String? notes;

  const AssessedNeed({
    required this.needType,
    this.category,
    this.description,
    required this.priorityLevel,
    this.reason,
    required this.source,
    required this.status,
    this.notes,
  });
}
