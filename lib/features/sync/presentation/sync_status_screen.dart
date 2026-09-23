import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/providers/data_providers.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/sync/sync_operation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_background.dart';
import '../../attachments/domain/upload_stage.dart';
import 'conflict_resolution_screen.dart';

/// العمليات التي تحتاج تدخّل المستخدم.
final _needsAttentionProvider = StreamProvider<List<SyncOperationRow>>(
  (ref) => ref.watch(syncQueueProvider).watchNeedingAttention(),
);

/// شاشة حالة المزامنة.
///
/// تجيب سؤالًا واحدًا يقلق الأخصائي: **هل عملي وصل؟** بدونها يبقى العمل
/// المحفوظ محليًا صندوقًا أسود، والشكّ يدفعه لإعادة إدخال بيانات موجودة.
class SyncStatusScreen extends ConsumerWidget {
  const SyncStatusScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const SyncStatusScreen()),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingSyncCountProvider).valueOrNull ?? 0;
    final photos = ref.watch(pendingAttachmentCountProvider).valueOrNull ?? 0;
    final connection = ref.watch(connectionKindProvider).valueOrNull;
    final attention = ref.watch(_needsAttentionProvider).valueOrNull ?? const [];

    final isOnline = connection?.isOnline ?? false;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('حالة المزامنة'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _ConnectionCard(isOnline: isOnline),
              const SizedBox(height: AppSpacing.md),

              _SummaryCard(
                pendingOperations: pending,
                pendingPhotos: photos,
                isOnline: isOnline,
              ),

              if (attention.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                const Text(
                  'يحتاج مراجعتك',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'هذه التغييرات لم تُرفَع وتحتاج قرارًا منك. لن تُحذَف تلقائيًا.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ...attention.map((op) => _AttentionTile(operation: op)),
              ],

              const SizedBox(height: AppSpacing.xl),
              _PrepareForFieldCard(isOnline: isOnline),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({required this.isOnline});

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            isOnline ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
            size: 22,
            color: isOnline ? AppColors.success : AppColors.textMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnline ? 'متصل بالإنترنت' : 'بدون اتصال',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isOnline
                      ? 'يتم رفع عملك تلقائيًا'
                      : 'يمكنك متابعة العمل — كل شيء يُحفَظ على الجهاز',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.pendingOperations,
    required this.pendingPhotos,
    required this.isOnline,
  });

  final int pendingOperations;
  final int pendingPhotos;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final allSynced = pendingOperations == 0 && pendingPhotos == 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: allSynced ? AppColors.successBg : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: allSynced ? AppColors.success : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                allSynced ? Icons.check_circle : Icons.schedule,
                size: 20,
                color: allSynced ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 10),
              Text(
                allSynced ? 'كل عملك مرفوع' : 'عمل بانتظار الرفع',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: allSynced ? AppColors.success : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (!allSynced) ...[
            const SizedBox(height: AppSpacing.md),
            if (pendingOperations > 0)
              _Row(label: 'تغييرات على الحالات', value: '$pendingOperations'),
            if (pendingPhotos > 0)
              _Row(label: 'مرفقات وصور', value: '$pendingPhotos'),
            const SizedBox(height: 10),
            Text(
              isOnline
                  ? 'جارٍ الرفع الآن…'
                  : 'سيُرفَع تلقائيًا فور عودة الاتصال.',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// عملية متوقّفة تحتاج قرار المستخدم.
class _AttentionTile extends ConsumerWidget {
  const _AttentionTile({required this.operation});

  final SyncOperationRow operation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = SyncOperationStatus.fromWire(operation.status);
    final isConflict = status == SyncOperationStatus.conflict;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isConflict ? AppColors.warning : AppColors.danger,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isConflict ? Icons.sync_problem : Icons.error_outline,
                size: 18,
                color: isConflict ? AppColors.warning : AppColors.danger,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _typeLabel(operation.type),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (operation.lastErrorMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              operation.lastErrorMessage!,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (isConflict)
                TextButton(
                  // إعادة المحاولة المباشرة (بلا rowVersion جديد) كانت تعيد
                  // إرسال نفس البيانات القديمة، فتتعارض من جديد حتمًا — شاشة
                  // التعارض تجلب نسخة طازجة أولًا وتعرض ثلاثة خيارات صريحة
                  // (§14.3، خطة المرحلة ٤).
                  onPressed: () =>
                      ConflictResolutionScreen.open(context, operation.id),
                  child: const Text('حلّ التعارض'),
                ),
              const Spacer(),
              // الحذف بقرار صريح فقط — لا حذف تلقائي لعمل غير مرفوع.
              TextButton(
                onPressed: () => _confirmDiscard(context, ref),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.danger,
                ),
                child: const Text('تجاهل'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDiscard(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تجاهل هذا التغيير؟'),
        content: const Text(
          'سيُحذَف هذا التغيير نهائيًا من الجهاز ولن يصل إلى الخادم. '
          'لا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('تجاهل نهائيًا'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(syncQueueProvider).discard(operation.id);
    }
  }

  static String _typeLabel(String wire) {
    final type = SyncOperationType.values
        .where((t) => t.wireValue == wire)
        .firstOrNull;

    return switch (type) {
      SyncOperationType.createFieldVisit => 'تسجيل زيارة ميدانية',
      SyncOperationType.updateFieldVisit => 'تعديل زيارة ميدانية',
      SyncOperationType.submitWorkerOpinion => 'إرسال الرأي للمراجعة',
      SyncOperationType.acceptCase => 'قبول إسناد حالة',
      SyncOperationType.rejectAssignment => 'رفض إسناد حالة',
      SyncOperationType.updateBeneficiary => 'بيانات المستفيد',
      SyncOperationType.updateFamilyMembers => 'أفراد الأسرة',
      SyncOperationType.updateHousing => 'بيانات السكن',
      SyncOperationType.updateUtilities => 'المرافق والأجهزة',
      SyncOperationType.updateAgriculture => 'الحيازة الزراعية',
      SyncOperationType.updateFinancial => 'الدخل والمصروفات',
      SyncOperationType.updateInitialNeeds => 'الاحتياج الأولي',
      SyncOperationType.updateClassification => 'التصنيف الاجتماعي',
      SyncOperationType.updateAssessedNeeds => 'الاحتياجات المُقيَّمة',
      SyncOperationType.updateFieldVerification => 'التحقق الميداني',
      _ => 'تغيير على حالة',
    };
  }
}

/// تحضير الجهاز للعمل بلا اتصال.
class _PrepareForFieldCard extends ConsumerStatefulWidget {
  const _PrepareForFieldCard({required this.isOnline});

  final bool isOnline;

  @override
  ConsumerState<_PrepareForFieldCard> createState() =>
      _PrepareForFieldCardState();
}

class _PrepareForFieldCardState extends ConsumerState<_PrepareForFieldCard> {
  bool _running = false;
  String? _step;
  int _done = 0;
  int _total = 0;

  @override
  Widget build(BuildContext context) {
    final ready = ref.watch(offlineReadyProvider).valueOrNull ?? false;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'التحضير للعمل الميداني',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            ready
                ? 'بياناتك جاهزة للعمل بدون اتصال. حدّثها قبل الخروج للميدان.'
                : 'لم تُحمَّل البيانات بعد. شغّل التحضير وأنت متصل، وإلا تعذّر '
                      'ملء النماذج في الميدان.',
            style: const TextStyle(
              fontSize: 12,
              height: 1.6,
              color: AppColors.textMuted,
            ),
          ),
          if (_running) ...[
            const SizedBox(height: AppSpacing.md),
            LinearProgressIndicator(
              value: _total > 0 ? _done / _total : null,
              backgroundColor: AppColors.surfaceMuted,
            ),
            const SizedBox(height: 6),
            Text(
              _total > 0 ? '$_step ($_done من $_total)' : '$_step…',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.isOnline && !_running ? _prepare : null,
              icon: const Icon(Icons.download_for_offline_outlined, size: 18),
              label: Text(_running ? 'جارٍ التحضير…' : 'تحضير للعمل الميداني'),
            ),
          ),
          if (!widget.isOnline)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'يتطلب اتصالًا بالإنترنت.',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _prepare() async {
    setState(() {
      _running = true;
      _step = 'جارٍ البدء';
      _done = 0;
      _total = 0;
    });

    await ref
        .read(startupServiceProvider)
        .prepareForFieldWork(
          onProgress: (step, done, total) {
            if (!mounted) return;
            setState(() {
              _step = step;
              _done = done;
              _total = total;
            });
          },
        );

    if (!mounted) return;
    setState(() => _running = false);
    ref.invalidate(offlineReadyProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تحضير البيانات للعمل بدون اتصال')),
    );
  }
}

/// حالة الرفع لمرفق واحد — تُعرَض داخل شاشة الحالة.
String attachmentStageLabel(String wire) =>
    UploadStage.fromWire(wire).label;
