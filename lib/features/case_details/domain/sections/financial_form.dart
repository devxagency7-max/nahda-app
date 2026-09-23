/// مساهم واحد في مبلغ "تكافل وكرامة" — مأخوذ من بيانات رب الأسرة أو أحد
/// الأفراد التابعين (تاب البيانات الأساسية / الأفراد التابعين).
/// [onAmountChanged] يكتب القيمة الجديدة مباشرة في مصدرها الأصلي (رب الأسرة
/// أو الفرد التابع) بحيث التعديل من تفاصيل تاب الدخل يبقى نفس مصدر الحقيقة.
class TakafulKaramaContributor {
  final String relation; // صلة القرابة (رب الأسرة أو صلة القرابة بالفرد)
  final double amount;
  final void Function(double? amount) onAmountChanged;

  const TakafulKaramaContributor({
    required this.relation,
    required this.amount,
    required this.onAmountChanged,
  });
}

/// نموذج قابل للتعديل لمصدر دخل واحد (القسم 13).
class IncomeItemFormData {
  String personName;
  String sourceType;
  double? amount;
  String frequency;
  String? notes;

  /// تفاصيل المساهمين — تُستخدم فقط لبند "تكافل وكرامة" (يُملأ تلقائيًا من
  /// رب الأسرة والأفراد التابعين، ويُعرض كتفاصيل عند فتح البند في الواجهة).
  List<TakafulKaramaContributor> contributors;

  /// موجود فقط لبند "دخل أراضي زراعية" — لو التعديل حصل يدويًا من هنا، يكتب
  /// القيمة (بعد تحويلها) في مصدرها الأصلي بتاب الحيازة الزراعية، بحيث
  /// المزامنة تبقى في الاتجاهين لا اتجاه واحد فقط.
  void Function(double? amount)? onExternalAmountChanged;

  IncomeItemFormData({
    this.personName = '',
    this.sourceType = '',
    this.amount,
    this.frequency = 'شهري',
    this.notes,
    List<TakafulKaramaContributor>? contributors,
    this.onExternalAmountChanged,
  }) : contributors = contributors ?? [];

  bool get isComplete => sourceType.trim().isNotEmpty && amount != null;

  /// تطبيع الدخل شهريًا حسب الدورية — لا يُترك للموظف يدويًا (Social Worker Spec §22).
  double get monthlyAmount {
    if (amount == null) return 0;
    return switch (frequency) {
      'يومي' => amount! * 30,
      'أسبوعي' => amount! * 4,
      'سنوي' => amount! / 12,
      _ => amount!, // شهري / موسمي كقيمة مباشرة
    };
  }
}

/// نموذج قابل للتعديل لبند مصروف واحد (القسم 14).
class ExpenseItemFormData {
  String expenseType;
  double? amount;
  String frequency;
  String? notes;

  /// موجود فقط لبند "إيجار أراضي زراعية" — لو التعديل حصل يدويًا من هنا،
  /// يكتب القيمة في مصدرها الأصلي بتاب الحيازة الزراعية (مزامنة في الاتجاهين).
  void Function(double? amount)? onExternalAmountChanged;

  ExpenseItemFormData({
    this.expenseType = '',
    this.amount,
    this.frequency = 'شهري',
    this.notes,
    this.onExternalAmountChanged,
  });

  bool get isComplete => expenseType.trim().isNotEmpty && amount != null;

  double get monthlyAmount {
    if (amount == null) return 0;
    return switch (frequency) {
      'يومي' => amount! * 30,
      'أسبوعي' => amount! * 4,
      'سنوي' => amount! / 12,
      _ => amount!,
    };
  }
}

/// القسم 13+14+15 — الدخل والمصروفات والملخص المالي محسوب تلقائيًا
/// (Backend-authoritative عند التكامل الفعلي؛ هنا Preview فقط).
class FinancialFormData {
  List<IncomeItemFormData> incomeItems;
  List<ExpenseItemFormData> expenseItems;
  int familyMembersCount;

  FinancialFormData({
    List<IncomeItemFormData>? incomeItems,
    List<ExpenseItemFormData>? expenseItems,
    this.familyMembersCount = 1,
  })  : incomeItems = incomeItems ?? _defaultIncomeItems(),
        expenseItems = expenseItems ?? _defaultExpenseItems();

  static List<IncomeItemFormData> _defaultIncomeItems() {
    return [
      IncomeItemFormData(sourceType: 'دخل رب الأسرة', personName: 'رب الأسرة'),
      IncomeItemFormData(sourceType: 'معاش', personName: 'رب الأسرة'),
      IncomeItemFormData(sourceType: 'تكافل وكرامة', personName: 'رب الأسرة'),
      IncomeItemFormData(sourceType: 'دخل أراضي زراعية', personName: 'رب الأسرة'),
    ];
  }

  static List<ExpenseItemFormData> _defaultExpenseItems() {
    return [
      ExpenseItemFormData(expenseType: 'الأكل والشرب'),
      ExpenseItemFormData(expenseType: 'المصروفات الدراسية'),
      ExpenseItemFormData(expenseType: 'الكهرباء'),
      ExpenseItemFormData(expenseType: 'المياه'),
      ExpenseItemFormData(expenseType: 'الغاز'),
      ExpenseItemFormData(expenseType: 'الإيجار'),
      ExpenseItemFormData(expenseType: 'القسط'),
      ExpenseItemFormData(expenseType: 'إيجار أراضي زراعية'),
    ];
  }

  double get totalMonthlyIncome =>
      incomeItems.fold(0, (sum, i) => sum + i.monthlyAmount);

  double get totalMonthlyExpenses =>
      expenseItems.fold(0, (sum, e) => sum + e.monthlyAmount);

  double get netIncome => totalMonthlyIncome - totalMonthlyExpenses;

  double get incomePerMember =>
      familyMembersCount == 0 ? 0 : netIncome / familyMembersCount;

  /// مكتمل لو فيه مصدر دخل واحد على الأقل ومصروف واحد على الأقل مسجلين
  /// (Social Worker Spec §38: "ينقص: مصدر دخل واحد على الأقل + إجمالي المصروفات").
  double get progress {
    int filled = 0;
    if (incomeItems.isNotEmpty) filled++;
    if (expenseItems.isNotEmpty) filled++;
    return filled / 2;
  }
}
