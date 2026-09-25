import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error_code.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/data_providers.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/sync/sync_operation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_background.dart';
import '../../cases/data/dto/case_details_dto.dart';
import '../../home/domain/case_priority.dart';
import '../../case_details/presentation/case_details_screen.dart';

/// خريطة نوع العملية ← فهرس التاب المطابق في [CaseDetailsScreen] — تُستخدَم
/// فقط لتوجيه "ادمج يدويًا"؛ راجع `_tabLabels` في `case_details_screen.dart`.
const _tabIndexForType = {
  SyncOperationType.updateBeneficiary: 0,
  SyncOperationType.updateFamilyMembers: 1,
  SyncOperationType.updateHousing: 3,
  SyncOperationType.updateUtilities: 4,
  SyncOperationType.updateAgriculture: 5,
  SyncOperationType.updateFinancial: 6,
  SyncOperationType.updateInitialNeeds: 2,
  SyncOperationType.updateClassification: 7,
  SyncOperationType.updateAssessedNeeds: 8,
  SyncOperationType.updateSupportRecommendations: 9,
};

const _typeLabels = {
  SyncOperationType.updateBeneficiary: 'بيانات المستفيد',
  SyncOperationType.updateFamilyMembers: 'أفراد الأسرة',
  SyncOperationType.updateHousing: 'بيانات السكن',
  SyncOperationType.updateUtilities: 'المرافق والأجهزة',
  SyncOperationType.updateAgriculture: 'الحيازة الزراعية',
  SyncOperationType.updateFinancial: 'الدخل والمصروفات',
  SyncOperationType.updateInitialNeeds: 'الاحتياج الأولي',
  SyncOperationType.updateClassification: 'التصنيف الاجتماعي',
  SyncOperationType.updateAssessedNeeds: 'الاحتياجات المُقيَّمة',
  SyncOperationType.updateSupportRecommendations: 'الدعم',
  SyncOperationType.acceptCase: 'قبول إسناد حالة',
  SyncOperationType.rejectAssignment: 'رفض إسناد حالة',
  SyncOperationType.submitWorkerOpinion: 'إرسال الرأي للمراجعة',
};

/// حقول `beneficiary` القابلة للمقارنة حقلًا بحقل مع استجابة `GET
/// /cases/{id}` — القسم الوحيد الذي يصل ضمن `CaseDetailsDto` كاملًا (§19).
/// باقي الأقسام (housing/agriculture/...) ليس لها GET مباشر ضمن هذه
/// الاستجابة، فتُعرض رسالة توضيحية بدل مقارنة غير دقيقة (راجع خطة المرحلة ٤).
const _beneficiaryFieldLabels = {
  'fullName': 'الاسم',
  'phonePrimary': 'رقم الهاتف',
  'phoneSecondary': 'رقم هاتف إضافي',
  'religion': 'الديانة',
  'education': 'المستوى التعليمي',
  'employmentStatus': 'حالة العمل',
  'job': 'الوظيفة',
  'monthlyIncome': 'الدخل الشهري',
  'takafulBeneficiary': 'مستفيد تكافل وكرامة',
  'takafulAmount': 'مبلغ تكافل وكرامة',
  'address': 'العنوان',
  'headRelation': 'صلة القرابة',
};

/// شاشة حلّ التعارض — تُعرَض حين تفشل عملية في الطابور بـ 409/422/403 ولا
/// تُحذَف تلقائيًا (§14.3 من العقد: "لا دمج تلقائي، لا كتابة فوقية").
///
/// **الإصلاح الجوهري هنا** (بعكس الزر القديم في `SyncStatusScreen`): "احتفظ
/// بقيمتي" يعيد المحاولة بـ `rowVersion` **طازج** من الخادم، لا القديم الذي
/// سبّب التعارض أصلًا — بدون هذا، إعادة المحاولة تتعارض من جديد حتمًا.
class ConflictResolutionScreen extends ConsumerStatefulWidget {
  final String operationId;

  const ConflictResolutionScreen({super.key, required this.operationId});

  static Future<void> open(BuildContext context, String operationId) =>
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ConflictResolutionScreen(operationId: operationId),
        ),
      );

  @override
  ConsumerState<ConflictResolutionScreen> createState() =>
      _ConflictResolutionScreenState();
}

class _ConflictResolutionScreenState
    extends ConsumerState<ConflictResolutionScreen> {
  bool _loading = true;
  bool _acting = false;
  SyncOperationRow? _op;
  CaseDetailsDto? _serverDetails;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final queue = ref.read(syncQueueProvider);
    final op = await queue.operationById(widget.operationId);
    if (op == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'هذا التغيير لم يعد موجودًا — رُبما حُلّ بالفعل.';
      });
      return;
    }

    // الخطوة الإلزامية أولًا (§14.3): ما الوضع الحقيقي على الخادم الآن؟
    final cases = ref.read(casesRepositoryProvider);
    final refresh = await cases.refreshCaseDetails(op.caseId);

    if (!mounted) return;

    if (!refresh.isSuccess && !refresh.isOfflineFailure) {
      setState(() {
        _loading = false;
        _op = op;
        _loadError = 'تعذّر جلب أحدث بيانات الحالة من الخادم.';
      });
      return;
    }

    final details = await cases.cachedDetails(op.caseId);

    if (!mounted) return;
    setState(() {
      _op = op;
      _serverDetails = details;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('حلّ التعارض'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final op = _op;
    if (op == null) {
      return _ErrorState(message: _loadError ?? 'حدث خطأ غير متوقع.');
    }

    final type = SyncOperationType.fromWire(op.type);
    final errorCode = ApiErrorCode.fromWire(op.lastErrorCode);

    // 422/403 ليس له معنى "دمج بيانات" — الحالة نفسها تغيّرت، لا محتواها.
    if (errorCode == ApiErrorCode.invalidStatusTransition ||
        errorCode == ApiErrorCode.forbidden) {
      return _StatusChangedState(
        operation: op,
        errorCode: errorCode,
        onDiscard: _acting ? null : () => _discard(op),
      );
    }

    return _ComparisonState(
      operation: op,
      type: type,
      serverDetails: _serverDetails,
      loadError: _loadError,
      acting: _acting,
      onKeepMine: () => _keepMine(op),
      onTakeServer: () => _takeServer(op),
      onMergeManually: () => _mergeManually(op, type),
    );
  }

  Future<void> _keepMine(SyncOperationRow op) async {
    setState(() => _acting = true);
    try {
      // الإصلاح الجوهري: rowVersion **طازج** من الحالة التي أُعيد جلبها
      // للتوّ — لا القديم الذي سبّب التعارض. للأقسام "المفردة" (housing/
      // agriculture/classification) rowVersion الحالة لا يكفي؛ نمرّر ما هو
      // متاح والخادم يرفض ثانيةً لو ما زال غير مطابق، فيعود المستخدم هنا.
      final freshRowVersion = _serverDetails?.rowVersion;
      await ref
          .read(syncQueueProvider)
          .retryAfterResolution(op.id, newRowVersion: freshRowVersion);
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _takeServer(SyncOperationRow op) async {
    setState(() => _acting = true);
    try {
      await ref.read(syncQueueProvider).discard(op.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _mergeManually(
    SyncOperationRow op,
    SyncOperationType type,
  ) async {
    setState(() => _acting = true);
    try {
      // نتخلّى عن الالتزام القديم أولًا — المستخدم سيحفظ من جديد عبر
      // saveSection العادية، وهي تُنشئ enqueue جديدًا بـ rowVersion طازج
      // تلقائيًا (§4 من خطة المرحلة ٤).
      await ref.read(syncQueueProvider).discard(op.id);
      if (!mounted) return;

      final cached = await ref
          .read(casesRepositoryProvider)
          .readCase(op.caseId);
      if (!mounted) return;
      if (cached == null) {
        Navigator.of(context).pop();
        return;
      }

      final tabIndex = _tabIndexForType[type] ?? 0;
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CaseDetailsScreen(
            caseId: cached.id,
            personName: cached.beneficiaryFullName,
            displayId: '#${cached.displayId}',
            priority: _priorityFromWire(cached.priority),
            initialTabIndex: tabIndex,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _discard(SyncOperationRow op) async {
    setState(() => _acting = true);
    try {
      await ref.read(syncQueueProvider).discard(op.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  CasePriority _priorityFromWire(String wire) => switch (wire) {
    'urgent' => CasePriority.urgent,
    'high' => CasePriority.high,
    'low' => CasePriority.low,
    _ => CasePriority.medium,
  };
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

/// حالة 422/403 — لا مقارنة بيانات، رسالة توضيحية + تجاهل فقط.
class _StatusChangedState extends StatelessWidget {
  final SyncOperationRow operation;
  final ApiErrorCode errorCode;
  final VoidCallback? onDiscard;

  const _StatusChangedState({
    required this.operation,
    required this.errorCode,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final message = errorCode == ApiErrorCode.forbidden
        ? 'الحالة لم تعد مُسنَدة إليك — رُبما أُعيد إسنادها لأخصائي آخر أثناء '
              'عملك أوفلاين.'
        : 'الحالة تغيّرت أثناء عملك — أُعيد إسنادها أو سُحبت من نافذة البحث '
              'الميداني.';

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.dangerBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.danger),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline, color: AppColors.danger),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      height: 1.6,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'التغيير المتأثر: ${_typeLabels[SyncOperationType.fromWire(operation.type)] ?? 'تغيير على حالة'}',
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onDiscard,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
              ),
              child: const Text('تجاهل هذا التغيير'),
            ),
          ),
        ],
      ),
    );
  }
}

/// حالة 409 — مقارنة "قيمتك ↔ قيمة الخادم" وثلاثة خيارات صريحة.
class _ComparisonState extends StatelessWidget {
  final SyncOperationRow operation;
  final SyncOperationType type;
  final CaseDetailsDto? serverDetails;
  final String? loadError;
  final bool acting;
  final VoidCallback onKeepMine;
  final VoidCallback onTakeServer;
  final VoidCallback onMergeManually;

  const _ComparisonState({
    required this.operation,
    required this.type,
    required this.serverDetails,
    required this.loadError,
    required this.acting,
    required this.onKeepMine,
    required this.onTakeServer,
    required this.onMergeManually,
  });

  @override
  Widget build(BuildContext context) {
    final localPayload = _decodePayload(operation.payload);
    final isBeneficiary = type == SyncOperationType.updateBeneficiary;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.warningBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.warning),
          ),
          child: Row(
            children: [
              const Icon(Icons.sync_problem, color: AppColors.warning),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'حدث تعديل على "${_typeLabels[type] ?? 'هذا القسم'}" من '
                  'جهة أخرى أثناء عملك. اختر كيف تريد المتابعة:',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.6,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (isBeneficiary && serverDetails != null)
          _FieldComparisonTable(
            localPayload: localPayload,
            serverBeneficiary: serverDetails!.beneficiary,
          )
        else
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'الخادم لا يوفر عرضًا تفصيليًا لهذا القسم بعد المقارنة حقلًا '
              'بحقل — إن اخترت "احتفظ بقيمتي" سيُعاد إرسال بياناتك المحلية '
              'فوق أحدث نسخة معروفة من الحالة.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.6,
                color: AppColors.textMuted,
              ),
            ),
          ),
        if (loadError != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            loadError!,
            style: const TextStyle(fontSize: 12, color: AppColors.danger),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        _ActionButton(
          label: 'احتفظ بقيمتي',
          description: 'يُعاد إرسال بياناتك فوق أحدث نسخة من الحالة.',
          color: AppColors.primary,
          onPressed: acting ? null : onKeepMine,
        ),
        const SizedBox(height: AppSpacing.sm),
        _ActionButton(
          label: 'خذ قيمة الخادم',
          description: 'تُهمَل تعديلاتك المحلية لهذا القسم نهائيًا.',
          color: AppColors.textSecondary,
          onPressed: acting ? null : onTakeServer,
        ),
        const SizedBox(height: AppSpacing.sm),
        _ActionButton(
          label: 'ادمج يدويًا',
          description: 'افتح القسم وعدّل القيم بنفسك قبل الحفظ من جديد.',
          color: AppColors.success,
          onPressed: acting ? null : onMergeManually,
        ),
      ],
    );
  }

  Map<String, dynamic> _decodePayload(String raw) {
    if (raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } on FormatException {
      return const {};
    }
  }
}

class _FieldComparisonTable extends StatelessWidget {
  final Map<String, dynamic> localPayload;
  final BeneficiaryDto serverBeneficiary;

  const _FieldComparisonTable({
    required this.localPayload,
    required this.serverBeneficiary,
  });

  @override
  Widget build(BuildContext context) {
    final serverMap = <String, dynamic>{
      'fullName': serverBeneficiary.fullName,
      'phonePrimary': serverBeneficiary.phonePrimary,
      'phoneSecondary': serverBeneficiary.phoneSecondary,
      'address': serverBeneficiary.address,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'الحقل',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'قيمتك',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'قيمة الخادم',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ),
          for (final entry in _beneficiaryFieldLabels.entries)
            if (localPayload.containsKey(entry.key))
              _ConflictFieldRow(
                label: entry.value,
                localValue: localPayload[entry.key],
                serverValue: serverMap[entry.key],
              ),
        ],
      ),
    );
  }
}

class _ConflictFieldRow extends StatelessWidget {
  final String label;
  final dynamic localValue;
  final dynamic serverValue;

  const _ConflictFieldRow({
    required this.label,
    required this.localValue,
    required this.serverValue,
  });

  bool get _differs => '$localValue' != '$serverValue';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _display(localValue),
              style: TextStyle(
                fontSize: 12,
                fontWeight: _differs ? FontWeight.w800 : FontWeight.w600,
                color: _differs ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _display(serverValue),
              style: TextStyle(
                fontSize: 12,
                fontWeight: _differs ? FontWeight.w800 : FontWeight.w600,
                color: _differs ? AppColors.warning : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _display(dynamic value) {
    if (value == null) return '—';
    if (value is bool) return value ? 'نعم' : 'لا';
    return '$value';
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final String description;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.description,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(AppSpacing.md),
          side: BorderSide(color: color),
          alignment: Alignment.centerRight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
