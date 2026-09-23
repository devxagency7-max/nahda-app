import '../../domain/sections/utilities_equipment_form.dart';

/// يحوّل [UtilitiesEquipmentFormData] من/إلى شكل التخزين المحلي وشكل
/// `PUT /cases/{id}/utilities` (§19 من العقد) — القسم يجمع `appliances` +
/// `utilities` في جسم واحد.
class UtilitiesMapper {
  const UtilitiesMapper._();

  static Map<String, dynamic> toCacheJson(UtilitiesEquipmentFormData form) => {
    'utilities': [
      for (final u in form.utilities)
        {
          'name': u.name,
          'isAvailable': u.isAvailable,
          'condition': u.condition,
          'sourceOrMeter': u.sourceOrMeter,
        },
    ],
    'equipment': [
      for (final e in form.equipment)
        {
          'name': e.name,
          'category': e.category,
          'isPresent': e.isPresent,
        },
    ],
  };

  /// شكل جسم `PUT /utilities` — `caseRowVersion` (نسخة **الحالة**، لا قسم
  /// مفرد — §19: هذا قسم "قائمة" يُستبدَل بالكامل).
  ///
  /// **انتبه (§19):** حقل الجهاز `applianceKey` يجب ألّا يتكرر داخل نفس
  /// الطلب، وكذلك `name` في `utilities` — الخادم يرفض التكرار بـ 422.
  static Map<String, dynamic> toApiPayload(
    UtilitiesEquipmentFormData form, {
    required int caseRowVersion,
  }) => {
    'appliances': [
      for (final e in form.equipment)
        {'applianceKey': e.name, 'isPresent': e.isPresent},
    ],
    'utilities': [
      for (final u in form.utilities)
        {
          'name': u.name,
          'isAvailable': u.isAvailable,
          'condition': u.condition,
          'sourceOrMeter': u.sourceOrMeter,
          'notes': null,
        },
    ],
    'caseRowVersion': caseRowVersion,
  };
}
