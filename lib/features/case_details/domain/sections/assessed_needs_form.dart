/// نموذج قابل للتعديل لاحتياج مُقيَّم واحد (القسم 17) — منفصل تمامًا عن
/// الاحتياج الأولي (§19)، قد يؤكد/يعدّل/يضيف عليه. لا تاب مخصص كان موجودًا
/// قبل المرحلة ٣؛ العقد يدعمه (`PUT /assessed-needs`).
class AssessedNeedFormData {
  String needType;
  String? category;
  String? description;
  String priorityLevel;
  String? reason;
  String source;
  String status;
  String? notes;

  AssessedNeedFormData({
    this.needType = '',
    this.category,
    this.description,
    this.priorityLevel = '',
    this.reason,
    this.source = '',
    this.status = '',
    this.notes,
  });

  bool get isComplete =>
      needType.trim().isNotEmpty &&
      priorityLevel.trim().isNotEmpty &&
      source.trim().isNotEmpty &&
      status.trim().isNotEmpty;
}

class AssessedNeedsFormData {
  List<AssessedNeedFormData> needs;

  AssessedNeedsFormData({List<AssessedNeedFormData>? needs})
    : needs = needs ?? [];

  /// مكتمل لو الاحتياجات المُقيَّمة **فاضية عمدًا** أو كل عنصر فيها مكتمل —
  /// قائمة فاضية حالة مشروعة (§19)، لا نقص.
  double get progress =>
      needs.isEmpty || needs.every((n) => n.isComplete) ? 1.0 : 0.0;
}
