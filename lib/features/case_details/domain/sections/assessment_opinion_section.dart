/// القسم 18 — Social Assessment. المصدر: Social Worker.
class SocialAssessmentSection {
  final String? familySituation;
  final String? economicSituation;
  final String? housingSituation;
  final String?
  livingCondition; // الوضع المعيشي — UNDEFINED / NEEDS BUSINESS DECISION (فرق عن housingSituation غير واضح)
  final String? familyCircumstances;
  final String? strengths; // نقاط القوة
  final String? weaknesses; // نقاط الضعف
  final String? mainProblems;
  final String needLevel;
  final String? overallAssessment;
  final String? socialWorkerNotes;

  const SocialAssessmentSection({
    this.familySituation,
    this.economicSituation,
    this.housingSituation,
    this.livingCondition,
    this.familyCircumstances,
    this.strengths,
    this.weaknesses,
    this.mainProblems,
    required this.needLevel,
    this.overallAssessment,
    this.socialWorkerNotes,
  });
}

/// القسم 19 — Social Worker Opinion. المصدر: Social Worker.
class SocialWorkerOpinionSection {
  final String opinion;
  final String caseSummary;
  final String assessment;
  final String reasons; // أسباب التقييم
  final String recommendation;
  final String? additionalNotes;

  const SocialWorkerOpinionSection({
    required this.opinion,
    required this.caseSummary,
    required this.assessment,
    required this.reasons,
    required this.recommendation,
    this.additionalNotes,
  });
}
