import '../../domain/sections/initial_need_form.dart';

/// يحوّل [InitialNeedFormData] من/إلى شكل التخزين المحلي وشكل
/// `PUT /cases/{id}/initial-needs` (§19) — استبدال كامل، `caseRowVersion`.
///
/// **ملاحظة شكل:** الشاشة تعرض احتياجًا أوليًا واحدًا، بينما العقد يتوقع
/// مصفوفة `needs[]` (قسم قائمة) — نغلّفه في عنصر واحد؛ لو كان الوصف/النوع
/// فارغين لا يُرسَل العنصر إطلاقًا (مصفوفة فاضية صالحة للعقد، §19: "لا
/// دعم أولي حتى الآن" حالة مشروعة).
class InitialNeedMapper {
  const InitialNeedMapper._();

  static Map<String, dynamic> toCacheJson(InitialNeedFormData form) => {
    'needType': form.needType,
    'needCategory': form.needCategory,
    'description': form.description,
    'priorityLevel': form.priorityLevel,
    'details': form.details,
    'notes': form.notes,
  };

  static Map<String, dynamic> toApiPayload(
    InitialNeedFormData form, {
    required int caseRowVersion,
  }) => {
    'needs': [
      if (form.needType.trim().isNotEmpty)
        {
          'needType': form.needType,
          'needCategory': form.needCategory,
          'description': form.description,
          'priorityLevel': form.priorityLevel.trim().isEmpty
              ? 'medium'
              : form.priorityLevel,
          'details': form.details,
          'notes': form.notes,
        },
    ],
    'caseRowVersion': caseRowVersion,
  };

  /// يبني [InitialNeedFormData] من استجابة `PUT`/`GET /initial-needs` الفعلية
  /// من الخادم — الشاشة تعرض احتياجًا واحدًا بس، فنأخذ أول عنصر من `needs[]`
  /// إن وُجد.
  static InitialNeedFormData fromApiResponse(Map<String, dynamic> json) {
    final needs = json['needs'] as List? ?? const [];
    final first = needs.whereType<Map<String, dynamic>>().firstOrNull;
    if (first == null) return InitialNeedFormData();

    return InitialNeedFormData(
      needType: first['needType'] as String? ?? '',
      needCategory: first['needCategory'] as String?,
      description: first['description'] as String?,
      priorityLevel: first['priorityLevel'] as String? ?? '',
      details: first['details'] as String?,
      notes: first['notes'] as String?,
    );
  }
}
