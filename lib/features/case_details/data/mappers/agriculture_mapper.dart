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

  /// يبني [AgriculturalHoldingFormData] من استجابة `PUT`/`GET /agriculture`
  /// الفعلية من الخادم (§19) — `selectedLivestockJson` نص JSON، لا مصفوفة،
  /// فيُفكّ عبر [decodeSelectedLivestock].
  static AgriculturalHoldingFormData fromApiResponse(
    Map<String, dynamic> json,
  ) {
    final landAnswer = _holdingAnswer(json['hasLand'] as String?);
    final livestockAnswer = _holdingAnswer(json['hasLivestock'] as String?);

    return AgriculturalHoldingFormData(
      landAnswer: landAnswer,
      landAreaFeddan: (json['landAreaFeddan'] as num?)?.toDouble(),
      landType: json['landType'] as String?,
      landRentAmount: (json['landRentAmount'] as num?)?.toDouble(),
      annualLandIncome: (json['annualLandIncome'] as num?)?.toDouble(),
      cropType: json['cropType'] as String?,
      livestockAnswer: livestockAnswer,
      selectedLivestock: decodeSelectedLivestock(
        json['selectedLivestockJson'] as String?,
      ),
      livestockOther: json['livestockOther'] as String?,
      livestockDetails: json['livestockDetails'] as String?,
      notes: json['notes'] as String?,
      // لسه محدش جاوب على أي سؤال — القسم فعليًا لم يُفتَح، لا نعتبره "زائرًا".
      visited:
          landAnswer != HoldingAnswer.unanswered ||
          livestockAnswer != HoldingAnswer.unanswered,
    );
  }

  static HoldingAnswer _holdingAnswer(String? wire) => switch (wire) {
    'yes' => HoldingAnswer.yes,
    'no' => HoldingAnswer.no,
    _ => HoldingAnswer.unanswered,
  };
}
