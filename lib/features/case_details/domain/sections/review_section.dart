/// القسم 21 — Review Information. المصدر: Reviewer.
class ReviewCommentEntry {
  final String? section;
  final String? field;
  final String comment;
  final DateTime createdAt;

  const ReviewCommentEntry({
    this.section,
    this.field,
    required this.comment,
    required this.createdAt,
  });
}

class ReviewSection {
  final String reviewStatus;
  final List<ReviewCommentEntry> comments;
  final List<String> pointsNeedingClarification;
  final String? reviewOutcome;
  final String? decision;
  final String? returnReason;
  final String? rejectionReason;

  const ReviewSection({
    required this.reviewStatus,
    this.comments = const [],
    this.pointsNeedingClarification = const [],
    this.reviewOutcome,
    this.decision,
    this.returnReason,
    this.rejectionReason,
  });
}
