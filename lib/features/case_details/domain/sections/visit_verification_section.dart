/// القسم 8 — Social Worker Field Visit. المصدر: Social Worker.
class FieldVisitSection {
  final DateTime visitDate;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? location; // GPS أو وصف نصي
  final String outcome; // نتيجة الزيارة
  final String status;
  final String? notes;
  final String? description; // وصف ما تم أثناء الزيارة
  final List<String> photos;
  final List<String> attachments;

  const FieldVisitSection({
    required this.visitDate,
    this.startTime,
    this.endTime,
    this.location,
    required this.outcome,
    required this.status,
    this.notes,
    this.description,
    this.photos = const [],
    this.attachments = const [],
  });
}

/// القسم 9 — Field Verification. مقارنة القيمة الأصلية بالمتحققة.
class VerifiedFieldDiff {
  final String fieldLabel;
  final String originalValue;
  final String verifiedValue;
  final String? differenceReason;
  final bool isDifferent;

  const VerifiedFieldDiff({
    required this.fieldLabel,
    required this.originalValue,
    required this.verifiedValue,
    this.differenceReason,
    required this.isDifferent,
  });
}

class FieldVerificationSection {
  final List<String> verifiedFields;
  final List<String> unverifiedFields;
  final List<VerifiedFieldDiff> differences;
  final String? socialWorkerNotes;
  final String verificationStatus;

  const FieldVerificationSection({
    required this.verifiedFields,
    required this.unverifiedFields,
    required this.differences,
    this.socialWorkerNotes,
    required this.verificationStatus,
  });
}
