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

/// سجل الدعم المصروف فعليًا — `GET /cases/{caseId}/support` (`history[]`،
/// §19.5). للعرض فقط هنا (بلا PUT مرتبط). يشمل الدعم القديم المستورَد من
/// الإكسيل (`source: legacy_import`) والمُسجَّل يدويًا لاحقًا (`manual`).
///
/// `recipientName` نص حر لا معرّف — المطابقة مع فرد بعينه في شاشة أفراد
/// الأسرة تتم بمقارنة الاسم، فلا تُعتبر مطابقة مضمونة 100% لو تكرر نفس الاسم.
class SupportHistoryEntry {
  final String id;
  final String recipientName;

  /// `head` (رب الأسرة) أو `family_member`.
  final String recipientType;
  final String supportType;
  final int quantity;
  final double? amount;
  final String? notes;

  /// `legacy_import` أو `manual`.
  final String source;
  final DateTime? createdAtUtc;

  const SupportHistoryEntry({
    required this.id,
    required this.recipientName,
    required this.recipientType,
    required this.supportType,
    required this.quantity,
    this.amount,
    this.notes,
    required this.source,
    this.createdAtUtc,
  });

  static SupportHistoryEntry fromJson(Map<String, dynamic> json) =>
      SupportHistoryEntry(
        id: json['id'] as String? ?? '',
        recipientName: json['recipientName'] as String? ?? '',
        recipientType: json['recipientType'] as String? ?? '',
        supportType: json['supportType'] as String? ?? '',
        quantity: switch (json['quantity']) {
          final int v => v,
          final num v => v.toInt(),
          _ => 0,
        },
        amount: (json['amount'] as num?)?.toDouble(),
        notes: json['notes'] as String?,
        source: json['source'] as String? ?? 'manual',
        createdAtUtc: DateTime.tryParse(json['createdAtUtc'] as String? ?? ''),
      );
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
