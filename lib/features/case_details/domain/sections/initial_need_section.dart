/// القسم 6 — Initial Needs. المصدر: Data Entry.
/// يجب الفصل بين هذا القسم و Assessed Needs (قسم 17) — ليس نتيجة نهائية.
class InitialNeedSection {
  final String needType;
  final String? needCategory;
  final String? description;
  final String priorityLevel;
  final String? details;
  final String? notes;

  const InitialNeedSection({
    required this.needType,
    this.needCategory,
    this.description,
    required this.priorityLevel,
    this.details,
    this.notes,
  });
}
