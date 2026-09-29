import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/sections/opinions_form.dart';
import '../widgets/editable_dropdown.dart';
import '../widgets/tab_progress_bar.dart';

const _socialWorkerOpinions = ['مقبول', 'مرفوض', 'لم يتم البدء'];
const _finalDecisions = ['اعتماد', 'رفض'];

/// تاب الرأي — 3 كروت جنب بعض: رأي الأخصائي (قابل للتعديل بـ مقبول/مرفوض/لم يتم البدء)،
/// رأي المراجع، رأي مدير التنمية (View-only للأخصائي).
class OpinionsTab extends StatefulWidget {
  final OpinionsFormData initialData;
  final ValueChanged<OpinionsFormData> onChanged;

  const OpinionsTab({
    super.key,
    required this.initialData,
    required this.onChanged,
  });

  @override
  State<OpinionsTab> createState() => _OpinionsTabState();
}

class _OpinionsTabState extends State<OpinionsTab> {
  late OpinionsFormData _data = widget.initialData;

  late final _reportCtrl = TextEditingController(
    text: _data.socialWorker.detailedReport ?? '',
  );

  /// `initialData` يوصل فاضيًا أول مرة (`CaseDetailsScreen` بيبني الفورم
  /// بمحتوى مبدئي فاضٍ قبل ما يخلص تحميل الكاش المحلي غير المتزامن)، وبعد
  /// كده يوصل تاني بالبيانات الحقيقية عبر إعادة بناء بـ **نسخة جديدة تمامًا**
  /// من `OpinionsFormData` — `late final` في الأعلى كانت بتتجاهل الوصول ده
  /// لأنها بتتحسب مرة واحدة بس عند إنشاء الـ State، فلو التاب اتبنى قبل
  /// اكتمال التحميل (شائع لأنه آخر تاب، بعيد عن نطاق التخزين المؤقت لـ
  /// `TabBarView`) كان يفضل فاضي للأبد.
  ///
  /// **بالهوية (`identical`) مش بالمحتوى**: أي round-trip عادي (المستخدم
  /// بيكتب → `_notify` → `onChanged` → الأب بيعمل `setState`) بيرجّع لنا
  /// نفس الكائن (`_data` اتعدّلت في مكانها)، فمفيش إعادة مزامنة كاذبة تمسح
  /// حاجة بيكتبها المستخدم دلوقتي.
  @override
  void didUpdateWidget(covariant OpinionsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.initialData, widget.initialData)) {
      _data = widget.initialData;
      _reportCtrl.text = _data.socialWorker.detailedReport ?? '';
    }
  }

  void _notify() => setState(() => widget.onChanged(_data));

  /// الرأي المختصر للمراجع — `null` طالما مسودة غير مُرسَلة (`isSubmitted ==
  /// false`)، فلا نعرض قرارًا لم يُقرَّر نهائيًا بعد (رد الباك إند طلب 14، §2).
  String? get _reviewerBriefValue {
    final reviewer = _data.reviewer;
    if (reviewer == null || !reviewer.isSubmitted) return null;
    return reviewer.briefOpinion;
  }

  String? get _reviewerNotes {
    final reviewer = _data.reviewer;
    if (reviewer == null || !reviewer.isSubmitted) return null;
    return reviewer.notes;
  }

  /// كارت الرأي السابق (View-only) — يُعرض فقط لو وصل فعليًا رأي أخصائي
  /// سابق للسيرفر (`decision` أو `notes` أو `detailedReport` موجود)، بصرف
  /// النظر عن `isSubmitted` (رد المزامنة قد لا يعيدها صراحة).
  PreviousWorkerOpinionCardData? get _previousOpinion {
    final previous = _data.previousWorkerOpinion;
    if (previous == null) return null;
    final hasDetails = previous.detailedReport?.isNotEmpty ?? false;
    if (previous.decision == null &&
        (previous.notes ?? '').trim().isEmpty &&
        !hasDetails) {
      return null;
    }
    return previous;
  }

  /// "آخر رأي أُرسِل: مقبول — 20/9/2026" — `null` طالما لم يُرسَل رأي بعد
  /// (submittedAtUtc فاضي، أي مجرد مسودة محلية لم تصل للسيرفر).
  String? get _submittedHint {
    final submittedAt = _data.socialWorker.submittedAtUtc;
    if (submittedAt == null) return null;
    final local = submittedAt.toLocal();
    final date =
        '${local.day}/${local.month}/${local.year}';
    return 'آخر رأي أُرسِل: ${_data.socialWorker.briefOpinion} — $date';
  }

  @override
  void dispose() {
    _reportCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabProgressBar(progress: _data.progress),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;

              final writableWorkerCard = _OpinionCard(
                title: 'رأي الأخصائي',
                icon: Icons.badge_outlined,
                color: AppColors.primary,
                editable: true,
                briefValue: _data.socialWorker.briefOpinion,
                briefOptions: _socialWorkerOpinions,
                onBriefChanged: (v) {
                  _data.socialWorker.briefOpinion = v;
                  _notify();
                },
                reportController: _reportCtrl,
                reportHint: 'التقرير التفصيلي...',
                onReportChanged: (v) {
                  _data.socialWorker.detailedReport = v;
                  _notify();
                },
                submittedHint: _submittedHint,
              );

              final previousOpinion = _previousOpinion;
              final workerColumn = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  writableWorkerCard,
                  if (previousOpinion != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _PreviousWorkerOpinionCard(data: previousOpinion),
                  ],
                ],
              );

              final otherCards = [
                _OpinionCard(
                  title: 'رأي المراجع',
                  icon: Icons.search,
                  color: AppColors.warning,
                  editable: false,
                  briefValue: _reviewerBriefValue,
                  briefPlaceholder: _data.reviewer == null
                      ? 'لم تتم المراجعة بعد'
                      : 'مسودة محفوظة — لم تُرسَل بعد',
                  reportPlaceholder: _reviewerNotes ?? 'ملاحظات المراجعة...',
                ),
                _OpinionCard(
                  title: 'رأي مدير التنمية',
                  icon: Icons.verified_outlined,
                  color: AppColors.success,
                  editable: false,
                  briefValue: _data.director?.finalDecision,
                  briefPlaceholder: 'اختر القرار...',
                  reportPlaceholder:
                      _data.director?.notes ?? 'التعليق النهائي للمدير...',
                ),
              ];

              final content = isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: workerColumn),
                        for (final card in otherCards) ...[
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: card),
                        ],
                      ],
                    )
                  : Column(
                      children: [
                        workerColumn,
                        for (final card in otherCards) ...[
                          const SizedBox(height: AppSpacing.md),
                          card,
                        ],
                      ],
                    );

              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_data.returnReason != null) ...[
                      _ReturnReasonBanner(
                        reason: _data.returnReason!,
                        byLabel: _data.returnedByLabel,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    content,
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _OpinionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool editable;
  final String? briefValue;
  final List<String>? briefOptions;
  final ValueChanged<String?>? onBriefChanged;
  final String? briefPlaceholder;
  final TextEditingController? reportController;
  final String? reportHint;
  final String? reportPlaceholder;
  final ValueChanged<String>? onReportChanged;

  /// تلميح "آخر رأي أُرسِل" — يظهر فوق حقل الرأي المختصر في الكارت القابل
  /// للتعديل فقط، `null` طالما لم يُرسَل رأي بعد. لا يمنع التعديل ولا
  /// إعادة الإرسال، مجرد تأكيد بصري لآخر رأي وصل فعليًا للسيرفر.
  final String? submittedHint;

  const _OpinionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.editable,
    this.briefValue,
    this.briefOptions,
    this.onBriefChanged,
    this.briefPlaceholder,
    this.reportController,
    this.reportHint,
    this.reportPlaceholder,
    this.onReportChanged,
    this.submittedHint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          if (submittedHint != null) ...[
            const SizedBox(height: 6),
            Text(
              submittedHint!,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: color.withValues(alpha: 0.85),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'الرأي المختصر',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          if (editable)
            EditableDropdown(
              label: '',
              value: briefValue,
              options: briefOptions ?? _finalDecisions,
              onChanged: onBriefChanged!,
            )
          else
            _ReadOnlyField(
              value: briefValue,
              placeholder: briefPlaceholder ?? '—',
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            editable ? 'التقرير التفصيلي' : 'ملاحظات',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          if (editable)
            TextField(
              controller: reportController,
              maxLines: 4,
              decoration: InputDecoration(hintText: reportHint),
              onChanged: onReportChanged,
            )
          else
            _ReadOnlyField(
              value: null,
              placeholder: reportPlaceholder ?? '—',
              minHeight: 90,
            ),
        ],
      ),
    );
  }
}

/// تسميات عربية لحقول `detailedReport` (١٣ حقل حر لا يتحقق منه الخادم) —
/// راجع توثيق `POST /opinions/worker`. حقل غير معروف يُعرض بمفتاحه الخام
/// بدل إخفائه بصمت.
const _detailedReportLabels = {
  'familySituation': 'الوضع الأسري',
  'economicSituation': 'الوضع الاقتصادي',
  'housingSituation': 'الوضع السكني',
  'strengths': 'نقاط القوة',
  'mainProblems': 'المشاكل الرئيسية',
  'overallAssessment': 'التقييم العام',
  'needLevel': 'مستوى الاحتياج',
  'opinion': 'الرأي',
  'caseSummary': 'ملخص الحالة',
  'assessment': 'التقييم',
  'reasons': 'الأسباب',
  'recommendation': 'التوصية',
  'additionalNotes': 'ملاحظات إضافية',
};

/// كارت "الرأي السابق" — View-only بالكامل، يُعرض بجانب كارت كتابة رأي
/// الأخصائي دائمًا طالما وصل رأي فعليًا للسيرفر من قبل (§ [PreviousWorkerOpinionCardData]).
/// لا يُتاح فيه أي تعديل ولا يتأثر بما يكتبه الأخصائي في الكارت الآخر.
class _PreviousWorkerOpinionCard extends StatelessWidget {
  final PreviousWorkerOpinionCardData data;

  const _PreviousWorkerOpinionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final report = data.detailedReport;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.history_edu_outlined,
                size: 18,
                color: AppColors.textMuted,
              ),
              SizedBox(width: 6),
              Text(
                'الرأي السابق',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'الرأي المختصر',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          _ReadOnlyField(value: data.briefOpinion, placeholder: '—'),
          if ((data.notes ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'ملاحظات',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            _ReadOnlyField(
              value: data.notes,
              placeholder: '—',
              minHeight: 60,
            ),
          ],
          if (report != null && report.isNotEmpty)
            for (final entry in report.entries)
              if ((entry.value?.toString().trim().isNotEmpty ?? false)) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _detailedReportLabels[entry.key] ?? entry.key,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                _ReadOnlyField(
                  value: entry.value.toString(),
                  placeholder: '—',
                  minHeight: 44,
                ),
              ],
        ],
      ),
    );
  }
}

/// يعرض سبب رجوع الحالة الحالي، من `returnInfo` (مصدر الحقيقة الوحيد
/// المضمون — يفضل يشتغل حتى لو رأي المراجع اتمسح بعد رجوع من المدير).
class _ReturnReasonBanner extends StatelessWidget {
  final String reason;
  final String? byLabel;

  const _ReturnReasonBanner({required this.reason, this.byLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.undo_rounded, size: 18, color: AppColors.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  byLabel ?? 'مرتجعة إليك',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.danger,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String? value;
  final String placeholder;
  final double minHeight;

  const _ReadOnlyField({
    this.value,
    required this.placeholder,
    this.minHeight = 44,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      alignment: Alignment.topRight,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        hasValue ? value! : placeholder,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: hasValue ? AppColors.textPrimary : AppColors.textMuted,
        ),
      ),
    );
  }
}
