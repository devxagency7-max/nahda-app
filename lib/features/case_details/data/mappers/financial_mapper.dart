import '../../domain/sections/financial_form.dart';

/// يحوّل [FinancialFormData] من/إلى شكل التخزين المحلي وشكل
/// `PUT /cases/{id}/financial` (§19) — **البنود اليدوية فقط**، البنود
/// الآلية (دخل رب الأسرة، تكافل وكرامة، دخل/إيجار الأرض) يعيد الخادم حسابها
/// دائمًا ولا تُرسَل من هنا (§19: "الخادم يعيد حساب البنود الآلية دومًا").
///
/// **فئات المصروفات:** العقد يرفض الحفظ بـ422 لو نقصت فئة واحدة من الخمس
/// الثابتة، فـ[_buildExpensePayload] يرسلها **كلها دائمًا** (صفر لغير
/// المُدخَل). الشاشة تعرض `الكهرباء`/`المياه`/`الغاز` كثلاث حقول منفصلة
/// (UI لا يتغيّر)، فتُدمَج قيمها في فئة `الكهرباء، المياه، الغاز` المُجمَّعة
/// التي يقبلها العقد. `إيجار أراضي زراعية` بند آلي منفصل (يُحسَب من تاب
/// الحيازة، لا يُرسَل ضمن الخمسة الثابتة).
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

  /// اسم البند المُجمَّع الذي يقبله العقد (فئة ثابتة واحدة من الخمسة).
  static const _combinedUtilitiesLabel = 'الكهرباء، المياه، الغاز';

  /// البنود الافتراضية في الشاشة (لا تزال منفصلة في الـ UI، راجع
  /// [FinancialFormData]) التي يجب دمجها في بند [_combinedUtilitiesLabel]
  /// الواحد قبل الإرسال — العقد لا يقبل غيره اسمًا لهذه الفئة.
  static const _utilitiesSubLabels = {'الكهرباء', 'المياه', 'الغاز'};

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

  /// شكل جسم `PUT /financial` — يستبعد كل بند آلي (بالاسم)، ويبني بنود
  /// المصروفات دائمًا بالفئات الخمس الثابتة كلها (راجع [_buildExpensePayload])
  /// لأن العقد يرفض أي حفظ ينقصه بند منها ولو بقيمة صفر.
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
    'expenseItems': _buildExpensePayload(form.expenseItems),
    'caseRowVersion': caseRowVersion,
  };

  /// يبني قائمة المصروفات الخمس الثابتة **دائمًا وبالكامل** — العقد يرفض
  /// الطلب بـ422 لو نقص منها بند واحد، فحتى فئة لم يُدخِل لها المستخدم قيمة
  /// (أو حذفها من الشاشة) تُرسَل بـ`amount: 0` بدل استبعادها. الكهرباء/المياه/
  /// الغاز المنفصلة في الشاشة (راجع [FinancialFormData._defaultExpenseItems])
  /// تُدمَج بمجموع قيمها الشهرية في فئة [_combinedUtilitiesLabel] الواحدة،
  /// لأن العقد يقبلها هكذا فقط لا ثلاث فئات منفصلة. أي بند غير آلي وغير
  /// مطابق للفئات الخمسة أو فرعياتها (بند حر أضافه المستخدم يدويًا) يُرسَل
  /// إضافةً على الخمسة كما هو.
  static List<Map<String, dynamic>> _buildExpensePayload(
    List<ExpenseItemFormData> expenseItems,
  ) {
    final totals = {for (final c in fixedExpenseCategories) c: 0.0};
    final extras = <Map<String, dynamic>>[];

    for (final e in expenseItems) {
      if (_autoExpenseLabels.contains(e.expenseType) || e.amount == null) {
        continue;
      }
      final label = _utilitiesSubLabels.contains(e.expenseType)
          ? _combinedUtilitiesLabel
          : e.expenseType;
      if (totals.containsKey(label)) {
        totals[label] = totals[label]! + e.monthlyAmount;
      } else {
        extras.add({
          'category': e.expenseType,
          'amount': e.amount,
          'period': e.frequency,
        });
      }
    }

    return [
      for (final c in fixedExpenseCategories)
        {'category': c, 'amount': totals[c], 'period': 'شهري'},
      ...extras,
    ];
  }
}
