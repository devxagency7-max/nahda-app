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

  /// يعيد بناء [UtilitiesEquipmentFormData] من شكل التخزين المحلي
  /// (`toCacheJson`) — بلا فقد. يُستخدَم عند إعادة فتح تاب المرافق/التجهيزات
  /// لعرض ما حفظه الأخصائي فعليًا بدل فورم فاضٍ (تلقائيًا بالقيم
  /// الافتراضية).
  static UtilitiesEquipmentFormData fromCacheJson(Map<String, dynamic> json) {
    final rawUtilities = json['utilities'] as List? ?? const [];
    final rawEquipment = json['equipment'] as List? ?? const [];
    return UtilitiesEquipmentFormData(
      utilities: [
        for (final u in rawUtilities.whereType<Map<String, dynamic>>())
          UtilityItemFormData(
            name: u['name'] as String? ?? '',
            isAvailable: u['isAvailable'] as bool? ?? false,
            condition: u['condition'] as String?,
            sourceOrMeter: u['sourceOrMeter'] as String?,
          ),
      ],
      equipment: [
        for (final e in rawEquipment.whereType<Map<String, dynamic>>())
          EquipmentItemFormData(
            name: e['name'] as String? ?? '',
            category: e['category'] as String? ?? '',
            isPresent: e['isPresent'] as bool? ?? false,
          ),
      ],
    );
  }

  /// يبني [UtilitiesEquipmentFormData] من استجابة `PUT`/`GET /utilities`
  /// الفعلية من الخادم (§19) — `appliances[].applianceKey` يقابل
  /// `EquipmentItemFormData.name`؛ الخادم لا يرجع `category` فتبقى فاضية
  /// (تجميع UI فقط، لا يصل للعقد أصلًا حسب [toApiPayload]).
  static UtilitiesEquipmentFormData fromApiResponse(
    Map<String, dynamic> json,
  ) {
    final rawAppliances = json['appliances'] as List? ?? const [];
    final rawUtilities = json['utilities'] as List? ?? const [];

    // لسه محدش عمل PUT لهذا القسم — نرجّع القوائم الافتراضية القابلة
    // للتعديل بدل قوائم فاضية تمامًا (نفس سلوك فورم جديد لم يُحفَظ بعد).
    if (rawAppliances.isEmpty && rawUtilities.isEmpty) {
      return UtilitiesEquipmentFormData();
    }

    return UtilitiesEquipmentFormData(
      utilities: [
        for (final u in rawUtilities.whereType<Map<String, dynamic>>())
          UtilityItemFormData(
            name: u['name'] as String? ?? '',
            isAvailable: u['isAvailable'] as bool? ?? false,
            condition: u['condition'] as String?,
            sourceOrMeter: u['sourceOrMeter'] as String?,
          ),
      ],
      equipment: [
        for (final a in rawAppliances.whereType<Map<String, dynamic>>())
          EquipmentItemFormData(
            name: a['applianceKey'] as String? ?? '',
            category: '',
            isPresent: a['isPresent'] as bool? ?? false,
          ),
      ],
    );
  }
}
