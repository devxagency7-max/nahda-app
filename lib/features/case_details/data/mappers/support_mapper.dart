import '../../domain/sections/support_form.dart';

/// يحوّل [SupportRecommendationFormData] من/إلى شكل التخزين المحلي وشكل
/// `PUT /cases/{id}/support-recommendations` (§20) — استبدال كامل،
/// `caseRowVersion`.
///
/// **عدم تطابق شكلي:** الشاشة تعرض دعمًا مقترحًا واحدًا (اختيارات متعددة +
/// ملاحظة)، بينما العقد يتوقع مصفوفة `items[]` بحقول تفصيلية لكل بند
/// (`beneficiary`, `proposedAmount`, `reason`, `justification` إلزامية).
/// نبني عنصرًا واحدًا من كل نوع دعم مختار، بحقول إلزامية افتراضية معقولة
/// حين لا تتوفر قيمة من الشاشة — **هذا تبسيط مؤقت**: العقد يتطلب مبلغًا
/// مقترحًا رقميًا وسببًا/تبريرًا نصيين لكل بند، والشاشة الحالية لا تجمع هذه
/// الحقول اليوم (اختيار من قائمة + ملاحظة عامة واحدة فقط). حتى تُبنى حقول
/// إدخال مخصصة لكل بند، لا يمكن استيفاء `422` من الخادم لو أُرسل بمبلغ
/// صفري بلا سبب — **لذا `toApiPayload` هنا يُرجع `null` إن لم توجد بيانات
/// كافية**، فالحفظ المحلي يستمر بلا `enqueue` حتى تُستكمل حقول الشاشة.
class SupportMapper {
  const SupportMapper._();

  static Map<String, dynamic> toCacheJson(SupportRecommendationFormData form) => {
    'selectedSupportTypes': form.selectedSupportTypes,
    'selectedSubTypes': form.selectedSubTypes,
    'notes': form.notes,
  };

  /// يرجع `null` لو النموذج لا يحمل الحد الأدنى المطلوب من العقد — قسم غير
  /// مكتمل يُحفَظ محليًا فقط، بلا محاولة إرسال ناقصة سترفضها الخادم أصلًا.
  static Map<String, dynamic>? toApiPayload(
    SupportRecommendationFormData form, {
    required int caseRowVersion,
    required String beneficiaryName,
  }) {
    if (form.selectedSupportTypes.isEmpty) return null;
    if ((form.notes ?? '').trim().isEmpty) return null;

    return {
      'items': [
        for (final type in form.selectedSupportTypes)
          {
            'supportType': type,
            'supportCategory': null,
            'beneficiary': beneficiaryName,
            'proposedAmount': 0,
            'frequency': null,
            'duration': null,
            'reason': form.notes,
            'justification': form.notes,
            'priorityLevel': 'medium',
            'notes': form.selectedSubTypes.isEmpty
                ? null
                : form.selectedSubTypes.join('، '),
          },
      ],
      'caseRowVersion': caseRowVersion,
    };
  }
}
