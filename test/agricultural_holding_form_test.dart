import 'package:flutter_test/flutter_test.dart';
import 'package:nahda/features/case_details/domain/sections/agricultural_holding_form.dart';

/// نفس حالات اختبار المرحلة 5 في الويب — عشان المنصّتين تفضل متطابقة.
void main() {
  AgriculturalHoldingFormData visited({
    HoldingAnswer land = HoldingAnswer.unanswered,
    String? landType,
    double? area,
    HoldingAnswer livestock = HoldingAnswer.unanswered,
    List<String>? selected,
    String? other,
  }) {
    return AgriculturalHoldingFormData(
      landAnswer: land,
      landType: landType,
      landAreaFeddan: area,
      livestockAnswer: livestock,
      selectedLivestock: selected,
      livestockOther: other,
      visited: true,
    );
  }

  group('progress', () {
    test('تاب لسه محدش فتحه = 0% حتى لو الحقول افتراضية', () {
      final d = AgriculturalHoldingFormData();
      expect(d.visited, isFalse);
      expect(d.progress, 0.0);
    });

    test('مفتوح بس بدون إجابة = 0%', () {
      expect(visited().progress, 0.0);
    });

    test('إجابة (لا) للاتنين = 100% — رفض صريح مش نقص', () {
      final d = visited(
        land: HoldingAnswer.no,
        livestock: HoldingAnswer.no,
      );
      expect(d.progress, 1.0);
      expect(d.isComplete, isTrue);
    });

    test('أرض (نعم) بدون تفاصيل = 50%', () {
      final d = visited(
        land: HoldingAnswer.yes,
        livestock: HoldingAnswer.no,
      );
      expect(d.progress, 0.5);
    });

    test('أرض (نعم) مستوفاة = 100%', () {
      final d = visited(
        land: HoldingAnswer.yes,
        landType: 'تمليك',
        area: 3,
        livestock: HoldingAnswer.no,
      );
      expect(d.progress, 1.0);
    });

    test('"أخرى" مختارة بدون نص = ناقصة', () {
      final d = visited(
        land: HoldingAnswer.no,
        livestock: HoldingAnswer.yes,
        selected: ['أخرى'],
      );
      expect(d.progress, 0.5);
      expect(d.missingFields, contains('اكتب تفاصيل خيار "أخرى" في المواشي'));
    });

    test('"أخرى" مع نص = مكتملة', () {
      final d = visited(
        land: HoldingAnswer.no,
        livestock: HoldingAnswer.yes,
        selected: ['أخرى'],
        other: 'بط',
      );
      expect(d.progress, 1.0);
      expect(d.isComplete, isTrue);
    });

    test('مساحة سالبة مرفوضة', () {
      final d = visited(
        land: HoldingAnswer.yes,
        landType: 'إيجار',
        area: -5,
        livestock: HoldingAnswer.no,
      );
      expect(d.progress, 0.5);
      expect(d.missingFields,
          contains('مساحة الأرض لا يمكن أن تكون قيمة سالبة'));
    });

    test('مواشي (نعم) بدون اختيار = ناقصة', () {
      final d = visited(
        land: HoldingAnswer.no,
        livestock: HoldingAnswer.yes,
      );
      expect(d.progress, 0.5);
      expect(d.missingFields,
          contains('اختر نوعًا واحدًا على الأقل من المواشي'));
    });
  });

  group('مسح البيانات الشبح', () {
    test('الرجوع لـ(لا) يمسح تفاصيل الأرض', () {
      final d = AgriculturalHoldingFormData(
        landAnswer: HoldingAnswer.yes,
        landType: 'إيجار',
        landAreaFeddan: 4,
        landRentAmount: 900,
        cropType: 'قمح',
        visited: true,
      );
      d.landAnswer = HoldingAnswer.no;
      d.clearLandDetailsIfDenied();

      expect(d.landType, isNull);
      expect(d.landAreaFeddan, isNull);
      expect(d.landRentAmount, isNull);
      expect(d.cropType, isNull);
    });

    test('الرجوع لـ(لا) يمسح اختيارات المواشي', () {
      final d = AgriculturalHoldingFormData(
        livestockAnswer: HoldingAnswer.yes,
        selectedLivestock: ['بقرة', 'أخرى'],
        livestockOther: 'بط',
        livestockDetails: '3 رؤوس',
        visited: true,
      );
      d.livestockAnswer = HoldingAnswer.no;
      d.clearLivestockDetailsIfDenied();

      expect(d.selectedLivestock, isEmpty);
      expect(d.livestockOther, isNull);
      expect(d.livestockDetails, isNull);
    });

    test('تغيير نوع الحيازة يمسح الحقل غير المناسب', () {
      final d = AgriculturalHoldingFormData(
        landAnswer: HoldingAnswer.yes,
        landType: 'إيجار',
        landRentAmount: 900,
        visited: true,
      );
      d.landType = 'تمليك';
      d.clearIrrelevantTenureField();

      expect(d.landRentAmount, isNull, reason: 'الإيجار لازم يتمسح');

      d.annualLandIncome = 12000;
      d.landType = 'إيجار';
      d.clearIrrelevantTenureField();
      expect(d.annualLandIncome, isNull, reason: 'الدخل السنوي لازم يتمسح');
    });
  });

  group('التوافق الرجعي', () {
    test('hasLand/hasLivestock لسه شغالين للمزامنة المالية', () {
      final d = visited(land: HoldingAnswer.yes, livestock: HoldingAnswer.no);
      expect(d.hasLand, isTrue);
      expect(d.hasLivestock, isFalse);
    });
  });
}
