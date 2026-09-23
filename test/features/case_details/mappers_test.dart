import 'package:flutter_test/flutter_test.dart';
import 'package:nahda/features/case_details/data/mappers/agriculture_mapper.dart';
import 'package:nahda/features/case_details/data/mappers/assessed_needs_mapper.dart';
import 'package:nahda/features/case_details/data/mappers/beneficiary_mapper.dart';
import 'package:nahda/features/case_details/data/mappers/classification_mapper.dart';
import 'package:nahda/features/case_details/data/mappers/family_members_mapper.dart';
import 'package:nahda/features/case_details/data/mappers/financial_mapper.dart';
import 'package:nahda/features/case_details/data/mappers/housing_mapper.dart';
import 'package:nahda/features/case_details/data/mappers/initial_need_mapper.dart';
import 'package:nahda/features/case_details/data/mappers/support_mapper.dart';
import 'package:nahda/features/case_details/data/mappers/utilities_mapper.dart';
import 'package:nahda/features/case_details/domain/sections/agricultural_holding_form.dart';
import 'package:nahda/features/case_details/domain/sections/assessed_needs_form.dart';
import 'package:nahda/features/case_details/domain/sections/basic_info_family_form.dart';
import 'package:nahda/features/case_details/domain/sections/classification_form.dart';
import 'package:nahda/features/case_details/domain/sections/financial_form.dart';
import 'package:nahda/features/case_details/domain/sections/housing_form.dart';
import 'package:nahda/features/case_details/domain/sections/initial_need_form.dart';
import 'package:nahda/features/case_details/domain/sections/support_form.dart';
import 'package:nahda/features/case_details/domain/sections/utilities_equipment_form.dart';

/// اختبارات مابرات المرحلة ٣ — تطابق شكل جسم الـ PUT حرفيًا مع §19/§20 من
/// FLUTTER_API_DOCUMENTATION.md، لا مسار سعيد عام.
void main() {
  group('HousingMapper', () {
    test('يحوّل أول قيمة مختارة من كل Multi-select لحقل نصّي واحد', () {
      final form = HousingFormData(housingDescription: 'وصف');
      form.housingType.selected.addAll(['خاص']);
      form.walls.selected.addAll(['طوب احمر']);
      form.waterMotor.selected.addAll(['يوجد']);
      form.internet.selected.addAll(['يوجد']);

      final payload = HousingMapper.toApiPayload(form, rowVersion: 3);

      expect(payload['description'], 'وصف');
      expect(payload['ownership'], 'خاص');
      expect(payload['walls'], 'طوب احمر');
      expect(payload['waterMotor'], isTrue);
      expect(payload['internet'], isTrue);
      expect(payload['rowVersion'], 3);
    });

    test('rowVersion يبقى null أول حفظ — العقد يقبل ذلك صراحة', () {
      final payload = HousingMapper.toApiPayload(
        HousingFormData(),
        rowVersion: null,
      );
      expect(payload['rowVersion'], isNull);
    });

    test('حقول التجهيزات (فريجة/غسالة) لا تظهر في جسم PUT /housing', () {
      final form = HousingFormData();
      form.fridge.selected.addAll(['يوجد']);
      form.washer.selected.addAll(['عادية']);

      final payload = HousingMapper.toApiPayload(form, rowVersion: 1);

      expect(payload.containsKey('fridge'), isFalse);
      expect(payload.containsKey('washer'), isFalse);
    });

    test('toCacheJson يحفظ كل الحقول بلا فقد، بما فيها التجهيزات', () {
      final form = HousingFormData();
      form.fridge.selected.addAll(['يوجد']);

      final cached = HousingMapper.toCacheJson(form);
      expect(cached['fridge'], ['يوجد']);
    });
  });

  group('UtilitiesMapper', () {
    test('يبني appliances من equipment و utilities كما هي', () {
      final form = UtilitiesEquipmentFormData(
        utilities: [
          UtilityItemFormData(name: 'كهرباء', isAvailable: true, condition: 'جيدة'),
        ],
        equipment: [
          EquipmentItemFormData(name: 'ثلاجة', category: 'أجهزة منزلية', isPresent: true),
        ],
      );

      final payload = UtilitiesMapper.toApiPayload(form, caseRowVersion: 5);

      expect(payload['appliances'], [
        {'applianceKey': 'ثلاجة', 'isPresent': true},
      ]);
      expect(
        (payload['utilities'] as List).single,
        containsPair('name', 'كهرباء'),
      );
      expect(payload['caseRowVersion'], 5);
    });
  });

  group('AgricultureMapper', () {
    test('يحوّل HoldingAnswer لقيم wire الثابتة', () {
      final form = AgriculturalHoldingFormData(
        landAnswer: HoldingAnswer.yes,
        landAreaFeddan: 3,
        landType: 'تمليك',
        livestockAnswer: HoldingAnswer.no,
      );

      final payload = AgricultureMapper.toApiPayload(form, rowVersion: null);

      expect(payload['hasLand'], 'yes');
      expect(payload['hasLivestock'], 'no');
      expect(payload['landAreaFeddan'], 3);
      expect(payload['landType'], 'تمليك');
    });

    test('unanswered يترجم لـ unanswered لا قيمة افتراضية أخرى', () {
      final payload = AgricultureMapper.toApiPayload(
        AgriculturalHoldingFormData(),
        rowVersion: null,
      );
      expect(payload['hasLand'], 'unanswered');
      expect(payload['hasLivestock'], 'unanswered');
    });

    test('decodeSelectedLivestock يفكّ نص JSON من استجابة الخادم', () {
      expect(
        AgricultureMapper.decodeSelectedLivestock('["cows","other"]'),
        ['cows', 'other'],
      );
      expect(AgricultureMapper.decodeSelectedLivestock(null), isEmpty);
      expect(AgricultureMapper.decodeSelectedLivestock(''), isEmpty);
    });
  });

  group('FinancialMapper', () {
    test('يستبعد البنود الآلية من الـ payload', () {
      final form = FinancialFormData(
        incomeItems: [
          IncomeItemFormData(sourceType: 'دخل رب الأسرة', amount: 3000),
          IncomeItemFormData(sourceType: 'دخل إضافي', amount: 500),
        ],
        expenseItems: [
          ExpenseItemFormData(expenseType: 'إيجار أراضي زراعية', amount: 200),
          ExpenseItemFormData(expenseType: 'الأكل والشرب', amount: 800),
        ],
      );

      final payload = FinancialMapper.toApiPayload(form, caseRowVersion: 3);

      final incomeLabels = (payload['incomeItems'] as List)
          .map((i) => (i as Map)['label'])
          .toList();
      final expenseLabels = (payload['expenseItems'] as List)
          .map((e) => (e as Map)['category'])
          .toList();

      expect(incomeLabels, ['دخل إضافي']);
      expect(expenseLabels, ['الأكل والشرب']);
    });

    test('يتجاهل بنودًا بلا مبلغ', () {
      final form = FinancialFormData(
        incomeItems: [IncomeItemFormData(sourceType: 'دخل إضافي')],
        expenseItems: [],
      );
      final payload = FinancialMapper.toApiPayload(form, caseRowVersion: 1);
      expect(payload['incomeItems'], isEmpty);
    });

    test('الفئات الخمس الثابتة مطابقة حرفيًا للعقد', () {
      expect(FinancialMapper.fixedExpenseCategories, [
        'الأكل والشرب',
        'المصروفات الدراسية',
        'الكهرباء، المياه، الغاز',
        'الإيجار',
        'القسط',
      ]);
    });
  });

  group('BeneficiaryMapper', () {
    test('لا يرسل nationalId إطلاقًا — العقد لا يقبله في هذا القسم', () {
      final form = BasicInfoFormData(nationalId: '29001011234567');
      final payload = BeneficiaryMapper.toApiPayload(form, rowVersion: 2);
      expect(payload.containsKey('nationalId'), isFalse);
    });

    test('rowVersion غير قابل للـ null — نسخة المستفيد دائمًا موجودة', () {
      final payload = BeneficiaryMapper.toApiPayload(
        BasicInfoFormData(caseName: 'اسم'),
        rowVersion: 1,
      );
      expect(payload['rowVersion'], 1);
      expect(payload['fullName'], 'اسم');
    });
  });

  group('FamilyMembersMapper', () {
    test('يمسح الحقول التعليمية عند isStudent=false', () {
      final form = FamilyMembersFormData(
        members: [
          FamilyMemberFormData(
            name: 'فرد',
            relation: 'ابن',
            isStudent: false,
            educationStage: 'إعدادي', // يجب أن يُمسَح
            nonStudentEducation: 'مؤهل متوسط',
          ),
        ],
      );

      final payload = FamilyMembersMapper.toApiPayload(form, caseRowVersion: 3);
      final member = (payload['members'] as List).single as Map;

      expect(member['educationStage'], isNull);
      expect(member['education'], 'مؤهل متوسط');
    });

    test('sortOrder يُشتَق من ترتيب القائمة، يبدأ من 1', () {
      final form = FamilyMembersFormData(
        members: [
          FamilyMemberFormData(name: 'أول', relation: 'ابن'),
          FamilyMemberFormData(name: 'ثانٍ', relation: 'ابنة'),
        ],
      );
      final payload = FamilyMembersMapper.toApiPayload(form, caseRowVersion: 1);
      final members = payload['members'] as List;
      expect((members[0] as Map)['sortOrder'], 1);
      expect((members[1] as Map)['sortOrder'], 2);
    });
  });

  group('InitialNeedMapper', () {
    test('needType فارغ ينتج مصفوفة needs فاضية — لا عنصر ناقص', () {
      final payload = InitialNeedMapper.toApiPayload(
        InitialNeedFormData(),
        caseRowVersion: 1,
      );
      expect(payload['needs'], isEmpty);
    });

    test('priorityLevel فارغ يُستبدَل بـ medium افتراضيًا', () {
      final payload = InitialNeedMapper.toApiPayload(
        InitialNeedFormData(needType: 'دعم مالي'),
        caseRowVersion: 1,
      );
      final need = (payload['needs'] as List).single as Map;
      expect(need['priorityLevel'], 'medium');
    });
  });

  group('ClassificationMapper', () {
    test('rowVersion قابل للـ null أول حفظ', () {
      final payload = ClassificationMapper.toApiPayload(
        ClassificationFormData(
          mainClassifications: ['فقر'],
          needLevel: 'high',
          priorityLevel: 'high',
        ),
        rowVersion: null,
      );
      expect(payload['mainClassifications'], ['فقر']);
      expect(payload['rowVersion'], isNull);
    });
  });

  group('AssessedNeedsMapper', () {
    test('يتجاهل عناصر بلا needType', () {
      final form = AssessedNeedsFormData(
        needs: [AssessedNeedFormData(needType: '', priorityLevel: 'high')],
      );
      final payload = AssessedNeedsMapper.toApiPayload(form, caseRowVersion: 1);
      expect(payload['needs'], isEmpty);
    });
  });

  group('SupportMapper', () {
    test('يرجع null إن لم توجد ملاحظة — لا إرسال ناقص للخادم', () {
      final form = SupportRecommendationFormData(
        selectedSupportTypes: ['مساعدة مالية'],
      );
      final payload = SupportMapper.toApiPayload(
        form,
        caseRowVersion: 1,
        beneficiaryName: 'أحمد',
      );
      expect(payload, isNull);
    });

    test('يبني عنصرًا لكل نوع دعم مختار عند اكتمال الحد الأدنى', () {
      final form = SupportRecommendationFormData(
        selectedSupportTypes: ['مساعدة مالية', 'زي مدرسي'],
        notes: 'سبب الاحتياج',
      );
      final payload = SupportMapper.toApiPayload(
        form,
        caseRowVersion: 2,
        beneficiaryName: 'أحمد',
      );
      expect(payload, isNotNull);
      expect(payload!['items'], hasLength(2));
      expect((payload['items'] as List).first, containsPair('beneficiary', 'أحمد'));
    });
  });
}
