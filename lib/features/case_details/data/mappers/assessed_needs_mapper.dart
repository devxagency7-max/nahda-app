import '../../domain/sections/assessed_needs_form.dart';

/// يحوّل [AssessedNeedsFormData] من/إلى شكل التخزين المحلي وشكل
/// `PUT /cases/{id}/assessed-needs` (§19) — استبدال كامل، `caseRowVersion`.
class AssessedNeedsMapper {
  const AssessedNeedsMapper._();

  static Map<String, dynamic> toCacheJson(AssessedNeedsFormData form) => {
    'needs': [
      for (final n in form.needs)
        {
          'needType': n.needType,
          'category': n.category,
          'description': n.description,
          'priorityLevel': n.priorityLevel,
          'reason': n.reason,
          'source': n.source,
          'status': n.status,
          'notes': n.notes,
        },
    ],
  };

  static Map<String, dynamic> toApiPayload(
    AssessedNeedsFormData form, {
    required int caseRowVersion,
  }) => {
    'needs': [
      for (final n in form.needs)
        if (n.needType.trim().isNotEmpty)
          {
            'needType': n.needType,
            'category': n.category,
            'description': n.description,
            'priorityLevel': n.priorityLevel,
            'reason': n.reason,
            'source': n.source,
            'status': n.status,
            'notes': n.notes,
          },
    ],
    'caseRowVersion': caseRowVersion,
  };
}
