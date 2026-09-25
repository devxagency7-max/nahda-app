/// نموذج قابل للتعديل للدعم المقترح (القسم 20) — من صلاحية الأخصائي.
/// الدعم المعتمد (القسم 22) من صلاحية المراجع فقط ويبقى View-only هنا
/// (Rule: proposedSupport ≠ approvedSupport، لا overwrite بينهما).
class SupportRecommendationFormData {
  List<String> selectedSupportTypes;
  List<String> selectedSubTypes;
  String? notes;

  SupportRecommendationFormData({
    List<String>? selectedSupportTypes,
    List<String>? selectedSubTypes,
    this.notes,
  })  : selectedSupportTypes = selectedSupportTypes ?? [],
        selectedSubTypes = selectedSubTypes ?? [];

  double get progress => selectedSupportTypes.isNotEmpty ? 1.0 : 0.0;
}
