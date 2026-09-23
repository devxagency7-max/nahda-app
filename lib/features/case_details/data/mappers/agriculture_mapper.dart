import 'dart:convert';

import '../../domain/sections/agricultural_holding_form.dart';

/// يحوّل [AgriculturalHoldingFormData] من/إلى شكل التخزين المحلي وشكل
/// `PUT /cases/{id}/agriculture` (§19) — التطابق شبه حرفي بالفعل (النموذج
/// صُمم أصلًا مطابقًا لقواعد المسح الشرطي في العقد، راجع تعليقات الملف
/// الأصلي `agricultural_holding_form.dart`).
class AgricultureMapper {
  const AgricultureMapper._();

  static Map<String, dynamic> toCacheJson(AgriculturalHoldingFormData form) => {
    'landAnswer': form.landAnswer.name,
    'landAreaFeddan': form.landAreaFeddan,
    'landType': form.landType,
    'landRentAmount': form.landRentAmount,
    'annualLandIncome': form.annualLandIncome,
    'cropType': form.cropType,
    'livestockAnswer': form.livestockAnswer.name,
    'selectedLivestock': form.selectedLivestock,
    'livestockOther': form.livestockOther,
    'livestockDetails': form.livestockDetails,
    'notes': form.notes,
    'visited': form.visited,
  };

  /// شكل جسم `PUT /agriculture` — [rowVersion] نسخة صفّ الزراعة (قابلة
  /// للـ null أول حفظ، §19). `hasLand`/`hasLivestock` بقيم wire ثابتة
  /// (`unanswered`/`yes`/`no`) — الخادم يعيد حساب المسح الشرطي بنفسه، لا
  /// داعي لتكرار منطق [AgriculturalHoldingFormData.clearLandDetailsIfDenied]
  /// هنا؛ نرسل القيم كما هي والخادم يتجاهل/يمسح ما لا يلزم.
  static Map<String, dynamic> toApiPayload(
    AgriculturalHoldingFormData form, {
    required int? rowVersion,
  }) => {
    'hasLand': _holdingWire(form.landAnswer),
    'landAreaFeddan': form.landAreaFeddan,
    'landType': form.landType,
    'landRentAmount': form.landRentAmount,
    'annualLandIncome': form.annualLandIncome,
    'cropType': form.cropType,
    'hasLivestock': _holdingWire(form.livestockAnswer),
    'selectedLivestock': form.selectedLivestock,
    'livestockOther': form.livestockOther,
    'livestockDetails': form.livestockDetails,
    'notes': form.notes,
    'visited': form.visited,
    'rowVersion': rowVersion,
  };

  static String _holdingWire(HoldingAnswer answer) => switch (answer) {
    HoldingAnswer.unanswered => 'unanswered',
    HoldingAnswer.yes => 'yes',
    HoldingAnswer.no => 'no',
  };

  /// يفكّ استجابة الخادم (`selectedLivestockJson` نص JSON، §19) — يُستخدَم
  /// عند إعادة بناء [AgriculturalHoldingFormData] من الكاش بعد مزامنة ناجحة.
  static List<String> decodeSelectedLivestock(String? json) {
    if (json == null || json.isEmpty) return const [];
    final decoded = jsonDecode(json);
    return decoded is List
        ? decoded.whereType<String>().toList(growable: false)
        : const [];
  }
}
