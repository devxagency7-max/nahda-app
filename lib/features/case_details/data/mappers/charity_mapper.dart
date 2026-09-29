/// يبني جسم `PUT /cases/{id}/charity` (§10، رد الباك إند بتاريخ 2026-09-26) —
/// endpoint جديد لتغيير الجمعية المسؤولة عن حالة موجودة. قبل كده مفيش أي
/// endpoint كان يقبل تعديل `charityId` بعد إنشاء الحالة.
class CharityMapper {
  const CharityMapper._();

  /// [charityId] القيمة الجديدة، أو `null` لإزالة ارتباط الحالة بأي جمعية.
  static Map<String, dynamic> toApiPayload(
    String? charityId, {
    required int caseRowVersion,
  }) => {'charityId': charityId, 'caseRowVersion': caseRowVersion};
}
