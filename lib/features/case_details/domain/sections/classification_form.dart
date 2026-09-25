/// نموذج قابل للتعديل للتصنيف الاجتماعي (القسم 16) — لا تاب مخصص له كان
/// موجودًا قبل المرحلة ٣؛ العقد يدعمه (`PUT /classification`) فتُبنى له
/// شاشة بسيطة بدل تجاهل قسم مدعوم بالكامل.
class ClassificationFormData {
  List<String> mainClassifications;
  String? subClassification;
  String needLevel;
  String priorityLevel;
  String? vulnerabilityLevel;
  String? notes;

  ClassificationFormData({
    List<String>? mainClassifications,
    this.subClassification,
    this.needLevel = '',
    this.priorityLevel = '',
    this.vulnerabilityLevel,
    this.notes,
  }) : mainClassifications = mainClassifications ?? [];

  double get progress {
    var filled = 0;
    const total = 3;
    if (mainClassifications.isNotEmpty) filled++;
    if (needLevel.trim().isNotEmpty) filled++;
    if (priorityLevel.trim().isNotEmpty) filled++;
    return filled / total;
  }
}
