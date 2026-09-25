/// القسم 20 — Support Recommendation. المصدر: Social Worker.
class SupportRecommendationSection {
  final String supportType;
  final String? supportCategory;
  final String beneficiary;
  final double proposedAmount;
  final String? frequency;
  final String? duration;
  final String reason;
  final String justification;
  final String priorityLevel;
  final String? notes;

  const SupportRecommendationSection({
    required this.supportType,
    this.supportCategory,
    required this.beneficiary,
    required this.proposedAmount,
    this.frequency,
    this.duration,
    required this.reason,
    required this.justification,
    required this.priorityLevel,
    this.notes,
  });
}

/// القسم 22 — Approved Support. المصدر: Reviewer.
/// يبقى دائمًا محفوظًا بجانب SupportRecommendationSection — لا overwrite.
class ApprovedSupportSection {
  final String approvedSupportType;
  final double approvedAmount;
  final String beneficiary;
  final String? frequency;
  final String? duration;
  final DateTime approvedAt;
  final String? approvalNotes;

  const ApprovedSupportSection({
    required this.approvedSupportType,
    required this.approvedAmount,
    required this.beneficiary,
    this.frequency,
    this.duration,
    required this.approvedAt,
    this.approvalNotes,
  });
}
