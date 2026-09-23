import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/localized_number_parser.dart';
import '../../data/mappers/financial_mapper.dart';
import '../../domain/sections/financial_form.dart';
import '../widgets/editable_dropdown.dart';
import '../widgets/editable_text_field.dart';
import '../widgets/section_card.dart';
import '../widgets/tab_progress_bar.dart';

/// تاب الدخل والمصروفات — قابل للتعديل، القسم 13+14+15 من Case Data Master.
/// صافي الدخل يُحسب لحظيًا كـ Preview؛ القيمة النهائية Backend-authoritative
/// عند التكامل الفعلي (Backend Contract §32، §67).
class FinancialTab extends StatefulWidget {
  final FinancialFormData initialData;
  final ValueChanged<FinancialFormData> onChanged;

  const FinancialTab({
    super.key,
    required this.initialData,
    required this.onChanged,
  });

  @override
  State<FinancialTab> createState() => _FinancialTabState();
}

class _FinancialTabState extends State<FinancialTab> {
  late final FinancialFormData _data = widget.initialData;
  bool _showAddIncome = false;
  bool _showAddExpense = false;

  void _notify() => widget.onChanged(_data);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabProgressBar(progress: _data.progress),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            children: [
              SectionCard(
                title: 'الملخص المالي',
                child: Column(
                  children: [
                    _SummaryRow(
                      label: 'إجمالي الدخل الشهري',
                      value:
                          '${_data.totalMonthlyIncome.toStringAsFixed(0)} جنيه',
                      color: AppColors.success,
                    ),
                    _SummaryRow(
                      label: 'إجمالي المصروفات الشهرية',
                      value:
                          '${_data.totalMonthlyExpenses.toStringAsFixed(0)} جنيه',
                      color: AppColors.danger,
                    ),
                    const Divider(height: AppSpacing.xl),
                    _SummaryRow(
                      label: 'صافي الدخل',
                      value: '${_data.netIncome.toStringAsFixed(0)} جنيه',
                      color: AppColors.primary,
                      bold: true,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'محسوب تلقائيًا (Preview — القيمة النهائية من الخادم)',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildListSection(
                title: 'مصادر الدخل',
                count: _data.incomeItems.length,
                showAddForm: _showAddIncome,
                onToggleAdd: () =>
                    setState(() => _showAddIncome = !_showAddIncome),
                addForm: _AddIncomeForm(
                  onSave: (item) {
                    setState(() {
                      _data.incomeItems.add(item);
                      _showAddIncome = false;
                    });
                    _notify();
                  },
                  onCancel: () => setState(() => _showAddIncome = false),
                ),
                emptyMessage: 'لم يتم تسجيل أي مصدر دخل بعد',
                items: [
                  for (int i = 0; i < _data.incomeItems.length; i++)
                    _IncomeRow(
                      item: _data.incomeItems[i],
                      onChanged: _notify,
                      onDelete: i >= 4
                          ? () {
                              setState(() => _data.incomeItems.removeAt(i));
                              _notify();
                            }
                          : null,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildListSection(
                title: 'المصروفات',
                count: _data.expenseItems.length,
                showAddForm: _showAddExpense,
                onToggleAdd: () =>
                    setState(() => _showAddExpense = !_showAddExpense),
                addForm: _AddExpenseForm(
                  onSave: (item) {
                    setState(() {
                      _data.expenseItems.add(item);
                      _showAddExpense = false;
                    });
                    _notify();
                  },
                  onCancel: () => setState(() => _showAddExpense = false),
                ),
                emptyMessage: 'لم يتم تسجيل أي مصروف بعد',
                items: [
                  for (int i = 0; i < _data.expenseItems.length; i++)
                    _ExpenseRow(
                      item: _data.expenseItems[i],
                      onChanged: _notify,
                      onDelete: i >= 8
                          ? () {
                              setState(() => _data.expenseItems.removeAt(i));
                              _notify();
                            }
                          : null,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListSection({
    required String title,
    required int count,
    required bool showAddForm,
    required VoidCallback onToggleAdd,
    required Widget addForm,
    required String emptyMessage,
    required List<Widget> items,
  }) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$title ($count)',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onToggleAdd,
                icon: Icon(showAddForm ? Icons.close : Icons.add, size: 18),
                label: Text(showAddForm ? 'إلغاء' : 'إضافة'),
              ),
            ],
          ),
          if (showAddForm) ...[const SizedBox(height: AppSpacing.md), addForm],
          const SizedBox(height: AppSpacing.md),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            )
          else
            for (final item in items) ...[
              item,
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: bold ? 14 : 12.5,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 17 : 13.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomeRow extends StatefulWidget {
  final IncomeItemFormData item;
  final VoidCallback onChanged;
  final VoidCallback? onDelete;

  const _IncomeRow({
    required this.item,
    required this.onChanged,
    this.onDelete,
  });

  @override
  State<_IncomeRow> createState() => _IncomeRowState();
}

class _IncomeRowState extends State<_IncomeRow> {
  late final _amountCtrl = TextEditingController(
    text: widget.item.amount != null && widget.item.amount! > 0
        ? widget.item.amount!.toStringAsFixed(0)
        : '',
  );
  bool _expanded = false;
  double? _lastSyncedAmount;

  @override
  void initState() {
    super.initState();
    _lastSyncedAmount = widget.item.amount;
  }

  @override
  void didUpdateWidget(covariant _IncomeRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // البند بيتحدث تلقائيًا من الخارج (مزامنة تكافل وكرامة) — لازم نعكس
    // القيمة الجديدة في الحقل لو مختلفة عن آخر قيمة معروفة، من غير ما نكسر
    // كتابة المستخدم الحالية.
    if (widget.item.amount != _lastSyncedAmount) {
      _lastSyncedAmount = widget.item.amount;
      final text = widget.item.amount != null && widget.item.amount! > 0
          ? widget.item.amount!.toStringAsFixed(0)
          : '';
      if (_amountCtrl.text != text) {
        _amountCtrl.text = text;
      }
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasContributors = widget.item.contributors.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.sourceType,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              SizedBox(
                width: 120,
                height: 40,
                child: TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final parsed = parseLocalizedDouble(v);
                    widget.item.amount = parsed;
                    _lastSyncedAmount = parsed;
                    widget.item.onExternalAmountChanged?.call(parsed);
                    widget.onChanged();
                  },
                  decoration: const InputDecoration(
                    hintText: 'المبلغ',
                    suffixText: 'ج',
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              if (hasContributors) ...[
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primary,
                  ),
                  tooltip: 'تفاصيل المساهمين',
                ),
              ],
              if (widget.onDelete != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  onPressed: widget.onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.danger,
                    size: 18,
                  ),
                ),
              ],
            ],
          ),
          if (_expanded && hasContributors) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.input),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final c in widget.item.contributors)
                    _ContributorRow(contributor: c),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContributorRow extends StatefulWidget {
  final TakafulKaramaContributor contributor;

  const _ContributorRow({required this.contributor});

  @override
  State<_ContributorRow> createState() => _ContributorRowState();
}

class _ContributorRowState extends State<_ContributorRow> {
  late final _amountCtrl = TextEditingController(
    text: widget.contributor.amount > 0
        ? widget.contributor.amount.toStringAsFixed(0)
        : '',
  );
  late double _lastSyncedAmount = widget.contributor.amount;

  @override
  void didUpdateWidget(covariant _ContributorRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // القيمة ممكن تتغيّر من مصدر خارجي (تعديل في تاب الأفراد التابعين نفسه)
    // بينما هذا الصف مفتوح — نعكسها هنا من غير ما نكسر كتابة المستخدم الحالية.
    if (widget.contributor.amount != _lastSyncedAmount) {
      _lastSyncedAmount = widget.contributor.amount;
      final text = widget.contributor.amount > 0
          ? widget.contributor.amount.toStringAsFixed(0)
          : '';
      if (_amountCtrl.text != text) {
        _amountCtrl.text = text;
      }
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              widget.contributor.relation,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          SizedBox(
            width: 100,
            height: 36,
            child: TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
              onChanged: (v) {
                final parsed = parseLocalizedDouble(v);
                _lastSyncedAmount = parsed ?? 0;
                widget.contributor.onAmountChanged(parsed);
              },
              decoration: const InputDecoration(
                hintText: 'المبلغ',
                suffixText: 'ج',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseRow extends StatefulWidget {
  final ExpenseItemFormData item;
  final VoidCallback onChanged;
  final VoidCallback? onDelete;

  const _ExpenseRow({
    required this.item,
    required this.onChanged,
    this.onDelete,
  });

  @override
  State<_ExpenseRow> createState() => _ExpenseRowState();
}

class _ExpenseRowState extends State<_ExpenseRow> {
  late final _amountCtrl = TextEditingController(
    text: widget.item.amount != null && widget.item.amount! > 0
        ? widget.item.amount!.toStringAsFixed(0)
        : '',
  );

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              widget.item.expenseType,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 120,
            height: 40,
            child: TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              onChanged: (v) {
                final parsed = parseLocalizedDouble(v);
                widget.item.amount = parsed;
                widget.item.onExternalAmountChanged?.call(parsed);
                widget.onChanged();
              },
              decoration: const InputDecoration(
                hintText: 'المبلغ',
                suffixText: 'ج',
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          if (widget.onDelete != null) ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: widget.onDelete,
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.danger,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AddIncomeForm extends StatefulWidget {
  final ValueChanged<IncomeItemFormData> onSave;
  final VoidCallback onCancel;

  const _AddIncomeForm({required this.onSave, required this.onCancel});

  @override
  State<_AddIncomeForm> createState() => _AddIncomeFormState();
}

class _AddIncomeFormState extends State<_AddIncomeForm> {
  final _item = IncomeItemFormData();
  final _sourceCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _sourceCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AddItemFormContainer(
      children: [
        EditableTextField(
          label: 'اسم / مصدر الدخل',
          required: true,
          controller: _sourceCtrl,
          onChanged: (v) => setState(() => _item.sourceType = v),
        ),
        EditableTextField(
          label: 'القيمة الشهرية (جنيه)',
          required: true,
          controller: _amountCtrl,
          keyboardType: TextInputType.number,
          onChanged: (v) => setState(() => _item.amount = parseLocalizedDouble(v)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: widget.onCancel, child: const Text('إلغاء')),
            const SizedBox(width: AppSpacing.sm),
            ElevatedButton(
              onPressed: _item.isComplete ? () => widget.onSave(_item) : null,
              child: const Text('إضافة'),
            ),
          ],
        ),
      ],
    );
  }
}

class _AddExpenseForm extends StatefulWidget {
  final ValueChanged<ExpenseItemFormData> onSave;
  final VoidCallback onCancel;

  const _AddExpenseForm({required this.onSave, required this.onCancel});

  @override
  State<_AddExpenseForm> createState() => _AddExpenseFormState();
}

class _AddExpenseFormState extends State<_AddExpenseForm> {
  final _item = ExpenseItemFormData();
  final _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AddItemFormContainer(
      children: [
        // فئات ثابتة حرفيًا (§19) — الخادم يرفض أي فئة مصروف غير مطابقة
        // تمامًا لإحدى الخمس دي بـ 422 VALIDATION_ERROR، فلا مجال لنص حر
        // أو خيار "أخرى" هنا (بعكس حقول أخرى في نفس التاب).
        EditableDropdown(
          label: 'فئة المصروف',
          required: true,
          value: _item.expenseType.isEmpty ? null : _item.expenseType,
          options: FinancialMapper.fixedExpenseCategories,
          onChanged: (v) => setState(() => _item.expenseType = v ?? ''),
        ),
        EditableTextField(
          label: 'القيمة الشهرية (جنيه)',
          required: true,
          controller: _amountCtrl,
          keyboardType: TextInputType.number,
          onChanged: (v) => setState(() => _item.amount = parseLocalizedDouble(v)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: widget.onCancel, child: const Text('إلغاء')),
            const SizedBox(width: AppSpacing.sm),
            ElevatedButton(
              onPressed: _item.isComplete ? () => widget.onSave(_item) : null,
              child: const Text('إضافة'),
            ),
          ],
        ),
      ],
    );
  }
}

class _AddItemFormContainer extends StatelessWidget {
  final List<Widget> children;

  const _AddItemFormContainer({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(children: children),
    );
  }
}
