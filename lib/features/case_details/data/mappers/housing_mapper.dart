import '../../domain/sections/housing_form.dart';

/// يحوّل [HousingFormData] (تاب السكن) من/إلى شكل التخزين المحلي وشكل
/// `PUT /cases/{id}/housing` (§19 من العقد).
///
/// **عدم تطابق مكتشف بين UI والعقد:** تاب السكن في الشاشة يعرض 17 حقل
/// Multi-select مطابقة لصفحة الويب، لكن `PUT /housing` في العقد له حقول
/// مختلفة تمامًا (`description, ownership, buildingType, walls, roof, floor,
/// entrance, roomsCount, bathroomCondition, sanitation, electricity, water,
/// waterMotor, transport, internet`). بعض حقول الشاشة (`fridge`, `washer`,
/// `oven`, `cookingAppliances`, `computer`, `tv`, `freezer`) هي فعليًا بيانات
/// "تجهيزات" (قسم `utilities`/equipment API-wise)، لا `housing` — راجع
/// `utilities_mapper.dart` حيث تُحوَّل لعناصر `EquipmentItem`.
class HousingMapper {
  const HousingMapper._();

  /// شكل التخزين المحلي الكامل — يحفظ كل حقل كما هو، بلا فقد، لأن الشاشة
  /// تحتاج استرجاع كل شيء حتى لو لم يُرسَل للخادم.
  static Map<String, dynamic> toCacheJson(HousingFormData form) => {
    'housingDescription': form.housingDescription,
    'housingType': form.housingType.selected.toList(),
    'housingTypeOther': form.housingType.freeTextValue,
    'walls': form.walls.selected.toList(),
    'wallsOther': form.walls.freeTextValue,
    'roof': form.roof.selected.toList(),
    'roofOther': form.roof.freeTextValue,
    'floor': form.floor.selected.toList(),
    'floorOther': form.floor.freeTextValue,
    'entrance': form.entrance.selected.toList(),
    'entranceOther': form.entrance.freeTextValue,
    'bathroomType': form.bathroomType.selected.toList(),
    'bathroomCondition': form.bathroomCondition.selected.toList(),
    'electricity': form.electricity.selected.toList(),
    'waterMeter': form.waterMeter.selected.toList(),
    'waterMotor': form.waterMotor.selected.toList(),
    'fridge': form.fridge.selected.toList(),
    'washer': form.washer.selected.toList(),
    'oven': form.oven.selected.toList(),
    'cookingAppliances': form.cookingAppliances.selected.toList(),
    'computer': form.computer.selected.toList(),
    'tv': form.tv.selected.toList(),
    'freezer': form.freezer.selected.toList(),
    'transportation': form.transportation.selected.toList(),
    'internet': form.internet.selected.toList(),
  };

  /// شكل جسم `PUT /housing` — الحقول المطابقة فعليًا فقط. [rowVersion]
  /// نسخة صفّ السكن (قابلة للـ null أول حفظ، §19).
  ///
  /// حقول التجهيزات (فريجة/غسالة/تلفزيون/إنترنت...) **غير مُرسَلة من هنا** —
  /// المستخدم لن يفقدها (محفوظة في [toCacheJson])، لكنها لا تصل لهذا الـ PUT.
  static Map<String, dynamic> toApiPayload(
    HousingFormData form, {
    required int? rowVersion,
  }) => {
    'description': form.housingDescription,
    'ownership': _single(form.housingType),
    'buildingType': null, // لا حقل مطابق في UI الحالي
    'walls': _single(form.walls),
    'roof': _single(form.roof),
    'floor': _single(form.floor),
    'entrance': _single(form.entrance),
    'roomsCount': null, // لا حقل مطابق في UI الحالي — القسم يقبله كنص
    'bathroomCondition': _single(form.bathroomCondition),
    'sanitation': null, // لا حقل مطابق — "الصرف الصحي" غير معروض في تاب السكن
    'electricity': _single(form.electricity),
    'water': _single(form.waterMeter),
    'waterMotor': form.waterMotor.selected.contains('يوجد'),
    'transport': _single(form.transportation),
    'internet': form.internet.selected.contains('يوجد'),
    'rowVersion': rowVersion,
  };

  /// يحوّل اختيارًا متعددًا (Chips) لقيمة نصية واحدة كما يتوقعها العقد —
  /// يأخذ أول قيمة مختارة، أو النص الحر لو "أخرى" هي المختارة.
  static String? _single(MultiSelectField field) {
    if (field.selected.isEmpty) return null;
    if (field.hasOther) return field.freeTextValue;
    return field.selected.first;
  }

  /// يعيد بناء [HousingFormData] من شكل التخزين المحلي (`toCacheJson`) —
  /// **بلا فقد**، عكس [housing_section.dart]'s `HousingSection` (نموذج عرض
  /// مسطّح لا يحتمل استرجاع الفورم منه). يُستخدَم عند إعادة فتح تاب السكن
  /// لعرض ما حفظه الأخصائي فعليًا بدل فورم فاضٍ.
  static HousingFormData fromCacheJson(Map<String, dynamic> json) =>
      HousingFormData(
        housingDescription: json['housingDescription'] as String?,
        housingType: _field(json, 'housingType', 'housingTypeOther'),
        walls: _field(json, 'walls', 'wallsOther'),
        roof: _field(json, 'roof', 'roofOther'),
        floor: _field(json, 'floor', 'floorOther'),
        entrance: _field(json, 'entrance', 'entranceOther'),
        bathroomType: _field(json, 'bathroomType', null),
        bathroomCondition: _field(json, 'bathroomCondition', null),
        electricity: _field(json, 'electricity', null),
        waterMeter: _field(json, 'waterMeter', null),
        waterMotor: _field(json, 'waterMotor', null),
        fridge: _field(json, 'fridge', null),
        washer: _field(json, 'washer', null),
        oven: _field(json, 'oven', null),
        cookingAppliances: _field(json, 'cookingAppliances', null),
        computer: _field(json, 'computer', null),
        tv: _field(json, 'tv', null),
        freezer: _field(json, 'freezer', null),
        transportation: _field(json, 'transportation', null),
        internet: _field(json, 'internet', null),
      );

  static MultiSelectField _field(
    Map<String, dynamic> json,
    String key,
    String? otherKey,
  ) => MultiSelectField(
    selected: (json[key] as List?)?.whereType<String>().toSet() ?? {},
    freeTextValue: otherKey != null ? json[otherKey] as String? : null,
  );

  /// يبني [HousingFormData] من استجابة `PUT`/`GET /housing` الفعلية من
  /// الخادم (§19) — شكل **مختلف تمامًا** عن [toCacheJson] (قيمة نصية واحدة
  /// لكل حقل، لا Multi-select). كل قيمة تُرفَع لعنصر وحيد في `selected`.
  ///
  /// حقول التجهيزات (`fridge`, `washer`, `oven`, `computer`, `tv`,
  /// `freezer`, `bathroomType`, `waterMeter`) **لا وجود لها في استجابة
  /// السكن** — تبقى فاضية هنا مهما كانت قيمتها المحفوظة محليًا سابقًا،
  /// لأن العقد لا يرسلها ضمن هذا القسم أصلًا (راجع تعليق الملف).
  static HousingFormData fromApiResponse(Map<String, dynamic> json) =>
      HousingFormData(
        housingDescription: json['description'] as String?,
        housingType: _single_(json['ownership'] as String?),
        walls: _single_(json['walls'] as String?),
        roof: _single_(json['roof'] as String?),
        floor: _single_(json['floor'] as String?),
        entrance: _single_(json['entrance'] as String?),
        bathroomCondition: _single_(json['bathroomCondition'] as String?),
        electricity: _single_(json['electricity'] as String?),
        waterMeter: _single_(json['water'] as String?),
        waterMotor: _bool_(json['waterMotor'] as bool?),
        transportation: _single_(json['transport'] as String?),
        internet: _bool_(json['internet'] as bool?),
      );

  static MultiSelectField _single_(String? value) => MultiSelectField(
    selected: (value == null || value.isEmpty) ? {} : {value},
  );

  static MultiSelectField _bool_(bool? value) =>
      MultiSelectField(selected: value == true ? {'يوجد'} : {});
}
