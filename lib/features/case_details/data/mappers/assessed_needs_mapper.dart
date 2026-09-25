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

  /// يبني [AssessedNeedsFormData] من استجابة `PUT`/`GET /assessed-needs`
  /// الفعلية من الخادم.
  static AssessedNeedsFormData fromApiResponse(Map<String, dynamic> json) {
    final rawNeeds = json['needs'] as List? ?? const [];
    return AssessedNeedsFormData(
      needs: [
        for (final n in rawNeeds.whereType<Map<String, dynamic>>())
          AssessedNeedFormData(
            needType: n['needType'] as String? ?? '',
            category: n['category'] as String?,
            description: n['description'] as String?,
            priorityLevel: n['priorityLevel'] as String? ?? '',
            reason: n['reason'] as String?,
            source: n['source'] as String? ?? '',
            status: n['status'] as String? ?? '',
            notes: n['notes'] as String?,
          ),
      ],
    );
  }
}
