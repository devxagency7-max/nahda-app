import 'package:flutter_test/flutter_test.dart';
import 'package:nahda/features/case_details/domain/sections/opinions_form.dart';

void main() {
  group('SocialWorkerOpinionCardData.decisionWireValue', () {
    test('مقبول يتحول لـ accepted', () {
      final data = SocialWorkerOpinionCardData(briefOpinion: 'مقبول');
      expect(data.decisionWireValue, 'accepted');
    });

    test('مرفوض يتحول لـ rejected', () {
      final data = SocialWorkerOpinionCardData(briefOpinion: 'مرفوض');
      expect(data.decisionWireValue, 'rejected');
    });

    test('لم يتم البدء (الافتراضي) يرجع null، لا نص حر', () {
      final data = SocialWorkerOpinionCardData();
      expect(data.briefOpinion, 'لم يتم البدء');
      expect(data.decisionWireValue, isNull);
    });
  });

  group('SocialWorkerOpinionCardData.isFilled', () {
    test('لم يتم البدء + تقرير مكتوب لا يُعتبر مكتملًا (الباج القديم)', () {
      final data = SocialWorkerOpinionCardData(
        detailedReport: 'تقرير مفصّل عن الزيارة',
      );
      expect(data.isFilled, isFalse);
    });

    test('قرار محدَّد بلا تقرير لا يُعتبر مكتملًا', () {
      final data = SocialWorkerOpinionCardData(briefOpinion: 'مقبول');
      expect(data.isFilled, isFalse);
    });

    test('قرار محدَّد + تقرير غير فارغ = مكتمل', () {
      final data = SocialWorkerOpinionCardData(
        briefOpinion: 'مرفوض',
        detailedReport: 'تقرير مفصّل عن الزيارة',
      );
      expect(data.isFilled, isTrue);
    });
  });

  group('OpinionsFormData.progress', () {
    test('يعكس isFilled الصحيح لرأي الأخصائي فقط', () {
      final ready = OpinionsFormData(
        socialWorker: SocialWorkerOpinionCardData(
          briefOpinion: 'مقبول',
          detailedReport: 'تقرير',
        ),
      );
      expect(ready.progress, 1.0);

      final notStarted = OpinionsFormData();
      expect(notStarted.progress, 0.0);
    });
  });
}
