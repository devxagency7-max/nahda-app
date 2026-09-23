/// القسم 13 — Income Information. المصدر: Social Worker (متحقق)، Data Entry (مُعلن أولي).
class IncomeItem {
  final String personName; // صاحب الدخل
  final String sourceType; // مصدر الدخل
  final String incomeType; // نوع الدخل
  final double amount;
  final String frequency; // دورية الدخل
  final double monthlyAmount; // الدخل الشهري (مُطبَّع)
  final String?
  nature; // طبيعة الدخل — UNDEFINED / NEEDS BUSINESS DECISION (فرق عن sourceType/incomeType غير واضح)
  final String verificationStatus;
  final String? proofSource; // مصدر إثبات الدخل
  final String? notes;

  const IncomeItem({
    required this.personName,
    required this.sourceType,
    required this.incomeType,
    required this.amount,
    required this.frequency,
    required this.monthlyAmount,
    this.nature,
    required this.verificationStatus,
    this.proofSource,
    this.notes,
  });
}

/// القسم 14 — Expense Information. المصدر: Social Worker.
class ExpenseItem {
  final String expenseType;
  final String? category;
  final double amount;
  final String frequency;
  final double monthlyAmount;
  final String? description;
  final String verificationStatus;
  final String? proofDocument;
  final String? notes;

  const ExpenseItem({
    required this.expenseType,
    this.category,
    required this.amount,
    required this.frequency,
    required this.monthlyAmount,
    this.description,
    required this.verificationStatus,
    this.proofDocument,
    this.notes,
  });
}

/// القسم 15 — Financial Summary. المصدر: محسوبة تلقائيًا (System Calculated).
/// لا يُعتمد على قيمة مُرسلة من الواجهة كمصدر حقيقة — الـ Backend هو صاحب الحساب.
class FinancialSummarySection {
  final List<IncomeItem> incomeItems;
  final List<ExpenseItem> expenseItems;
  final double totalMonthlyIncome;
  final double totalMonthlyExpenses;
  final double netIncome;
  final int familyMembersCount;
  final int? dependentsCount;
  final double? incomePerMember;
  final double? incomePerDependent;

  const FinancialSummarySection({
    required this.incomeItems,
    required this.expenseItems,
    required this.totalMonthlyIncome,
    required this.totalMonthlyExpenses,
    required this.netIncome,
    required this.familyMembersCount,
    this.dependentsCount,
    this.incomePerMember,
    this.incomePerDependent,
  });
}
