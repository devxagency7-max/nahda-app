/// نموذج قابل للتعديل للاحتياج الأولي (القسم 6) — لا يشمل المرفقات
/// لأنها تُدار برفع ملفات منفصل وليست حقل نصي.
class InitialNeedFormData {
  String needType;
  String? needCategory;
  String? description;
  String priorityLevel;
  String? details;
  String? notes;

  InitialNeedFormData({
    this.needType = '',
    this.needCategory,
    this.description,
    this.priorityLevel = '',
    this.details,
    this.notes,
  });

  int get totalFieldsCount => 6;

  int get filledFieldsCount {
    int count = 0;
    if (needType.trim().isNotEmpty) count++;
    if (needCategory != null && needCategory!.trim().isNotEmpty) count++;
    if (description != null && description!.trim().isNotEmpty) count++;
    if (priorityLevel.trim().isNotEmpty) count++;
    if (details != null && details!.trim().isNotEmpty) count++;
    if (notes != null && notes!.trim().isNotEmpty) count++;
    return count;
  }

  double get progress => filledFieldsCount / totalFieldsCount;
}
