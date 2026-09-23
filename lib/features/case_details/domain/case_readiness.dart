import 'sections/basic_info_family_form.dart';
import 'sections/financial_form.dart';
import 'sections/housing_form.dart';
import 'sections/initial_need_form.dart';
import 'sections/opinions_form.dart';
import 'sections/support_form.dart';

/// جاهزية الحالة للإرسال للمراجع — Definition of Done حسب
/// Social Worker Spec §38/§56: التقييم، السكن، الدخل، الاحتياج، والدعم
/// المقترح يجب أن تكون مكتملة قبل السماح بالإرسال. تاب "التقييمات"
/// يُحسب بناءً على رأي الأخصائي فقط (الكارت الوحيد القابل للتعديل).
class CaseReadiness {
  final BasicInfoFormData basicInfo;
  final FamilyMembersFormData familyMembers;
  // [initialNeed] مُمرَّر ومُحتفَظ به لكنه عمدًا غير داخل في isReadyForReview/
  // missingSections: قسم بيانات اختياري لا يمنع الإرسال للمراجعة (قرار منتج).
  final InitialNeedFormData initialNeed;
  final HousingFormData housing;
  final FinancialFormData financial;
  final OpinionsFormData opinions;
  final SupportRecommendationFormData support;

  const CaseReadiness({
    required this.basicInfo,
    required this.familyMembers,
    required this.initialNeed,
    required this.housing,
    required this.financial,
    required this.opinions,
    required this.support,
  });

  bool get isReadyForReview {
    return basicInfo.progress >= 1.0 &&
        familyMembers.progress >= 1.0 &&
        housing.progress >= 1.0 &&
        financial.progress >= 1.0 &&
        opinions.progress >= 1.0 &&
        support.progress >= 1.0;
  }

  List<String> get missingSections {
    final missing = <String>[];
    if (basicInfo.progress < 1.0) missing.add('البيانات الأساسية');
    if (familyMembers.progress < 1.0) missing.add('الأفراد التابعين');
    if (housing.progress < 1.0) missing.add('السكن');
    if (financial.progress < 1.0) missing.add('الدخل والمصروفات');
    if (opinions.progress < 1.0) missing.add('التقييمات');
    if (support.progress < 1.0) missing.add('الدعم');
    return missing;
  }
}
