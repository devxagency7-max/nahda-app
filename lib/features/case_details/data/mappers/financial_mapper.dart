import '../../domain/sections/financial_form.dart';

/// يحوّل [FinancialFormData] من/إلى شكل التخزين المحلي وشكل
/// `PUT /cases/{id}/financial` (§19) — **البنود اليدوية فقط**، البنود
/// الآلية (دخل رب الأسرة، تكافل وكرامة، دخل/إيجار الأرض) يعيد الخادم حسابها
/// دائمًا ولا تُرسَل من هنا (§19: "الخادم يعيد حساب البنود الآلية دومًا").
///
/// **عدم تطابق مكتشف:** فئات المصروفات الافتراضية في الشاشة (`الكهرباء`,
/// `المياه`, `الغاز` كثلاث بنود منفصلة + `إيجار أراضي زراعية`) لا تطابق
/// الفئات الخمس الثابتة الإلزامية في العقد (`الأكل والشرب`,
/// `المصروفات الدراسية`, `الكهرباء، المياه، الغاز` كبند واحد مُجمَّع,
/// `الإيجار`, `القسط`) — الخادم يرفض أي مجموعة فئات غير مطابقة **تمامًا**
/// بـ 422. `إيجار أراضي زراعية` بند آلي منفصل (يُحسَب من تاب الحيازة، لا
/// يُرسَل ضمن الخمسة الثابتة).
class FinancialMapper {
  const FinancialMapper._();

  /// الفئات الخمس الثابتة كما وردت حرفيًا في العقد (§19،
  /// `FixedExpenseCategories.All`) — أي بند بغير هذه الأسماء بالضبط لا يُرسَل.
  static const fixedExpenseCategories = [
    'الأكل والشرب',
    'المصروفات الدراسية',
    'الكهرباء، المياه، الغاز',
    'الإيجار',
    'القسط',
  ];

  /// أسماء البنود الآلية — لا تُرسَل ضمن هذا القسم لأن الخادم يحسبها بنفسه
  /// من أقسام أخرى (beneficiary/agriculture/family-members، §19).
  static const _autoIncomeLabels = {
    'دخل رب الأسرة',
    'معاش',
    'تكافل وكرامة',
    'دخل أراضي زراعية',
  };
  static const _autoExpenseLabels = {'إيجار أراضي زراعية'};

  static Map<String, dynamic> toCacheJson(FinancialFormData form) => {
    'incomeItems': [
      for (final i in form.incomeItems)
        {
          'personName': i.personName,
          'sourceType': i.sourceType,
          'amount': i.amount,
          'frequency': i.frequency,
          'notes': i.notes,
        },
    ],
    'expenseItems': [
      for (final e in form.expenseItems)
        {
          'expenseType': e.expenseType,
          'amount': e.amount,
          'frequency': e.frequency,
          'notes': e.notes,
        },
    ],
    'familyMembersCount': form.familyMembersCount,
  };

  /// شكل جسم `PUT /financial` — يستبعد كل بند آلي (بالاسم) ويرسل الباقي فقط.
  ///
  /// **تحذير:** لا يضمن هذا المابر أن فئات المصروفات اليدوية المتبقية تطابق
  /// الخمس الثابتة بالضبط — لو المستخدم عدّل/حذف أحد البنود الافتراضية
  /// (الكهرباء/المياه/الغاز منفصلة اليوم) سيرفض الخادم الطلب بـ 422. هذا
  /// انعكاس مباشر لعدم تطابق نموذج الشاشة مع العقد (موثّق في تعليق الملف) —
  /// يحتاج تصحيحًا في تصميم تاب الدخل نفسه، خارج نطاق هذه الجولة.
  static Map<String, dynamic> toApiPayload(
    FinancialFormData form, {
    required int caseRowVersion,
  }) => {
    'incomeItems': [
      for (final i in form.incomeItems)
        if (!_autoIncomeLabels.contains(i.sourceType) && i.amount != null)
          {
            'label': i.sourceType,
            'amount': i.amount,
            'period': i.frequency,
          },
    ],
    'expenseItems': [
      for (final e in form.expenseItems)
        if (!_autoExpenseLabels.contains(e.expenseType) && e.amount != null)
          {
            'category': e.expenseType,
            'amount': e.amount,
            'period': e.frequency,
          },
    ],
    'caseRowVersion': caseRowVersion,
  };
}
