import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/data_providers.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/location_service.dart';
import '../../../core/widgets/app_background.dart';
import '../../attachments/domain/upload_stage.dart';
import '../../case_details/presentation/widgets/add_attachment_sheet.dart';
import '../../case_details/presentation/widgets/section_card.dart';
import '../data/field_visits_repository.dart';

/// نموذج تسجيل/تعديل زيارة ميدانية واحدة.
///
/// - **إنشاء** ([existingVisit] = null): يُنشئ صفًا محليًا فورًا عند الحفظ
///   (لا يلمس الشبكة — §13)، ثم يحاول الإرسال إن كان متصلًا.
/// - **تعديل**: مسموح فقط للزيارات التي لم تُرفَع بعد بنجاح كامل من هذا
///   الجهاز؛ العقد لا يسمح بتعديل `PUT /field-visits/{id}` إلا من الأخصائي
///   الذي أنشأها أصلًا (راجع تعليق `FieldVisitsScreen`).
class FieldVisitFormScreen extends ConsumerStatefulWidget {
  final String caseId;
  final FieldVisitRow? existingVisit;

  const FieldVisitFormScreen({
    super.key,
    required this.caseId,
    this.existingVisit,
  });

  @override
  ConsumerState<FieldVisitFormScreen> createState() =>
      _FieldVisitFormScreenState();
}

class _FieldVisitFormScreenState extends ConsumerState<FieldVisitFormScreen> {
  late DateTime _visitDate;
  final _outcomeController = TextEditingController();
  final _notesController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationDescController = TextEditingController();

  double? _latitude;
  double? _longitude;
  bool _locating = false;
  String? _locationError;

  String? _localVisitId;
  bool _saving = false;
  bool _capturingPhoto = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingVisit;
    if (existing != null) {
      _localVisitId = existing.id;
      _visitDate = DateTime.tryParse(existing.visitDate) ?? DateTime.now();
      _outcomeController.text = existing.outcome;
      _notesController.text = existing.notes ?? '';
      _descriptionController.text = existing.description ?? '';
      _locationDescController.text = existing.locationDescription ?? '';
      _latitude = existing.latitude;
      _longitude = existing.longitude;
    } else {
      _visitDate = DateTime.now();
      // الالتقاط التلقائي عند فتح نموذج زيارة جديدة — يوفّر خطوة على
      // الأخصائي، ويبقى بلا أثر لو رفض الصلاحية أو كان مغلقًا (§15.10:
      // الموقع اختياري بالكامل).
      unawaited(_captureLocation());
    }
  }

  @override
  void dispose() {
    _outcomeController.dispose();
    _notesController.dispose();
    _descriptionController.dispose();
    _locationDescController.dispose();
    super.dispose();
  }

  Future<void> _captureLocation() async {
    setState(() {
      _locating = true;
      _locationError = null;
    });

    final result = await const LocationService().capture();
    if (!mounted) return;

    setState(() {
      _locating = false;
      switch (result) {
        case LocationCaptured(:final latitude, :final longitude):
          _latitude = latitude;
          _longitude = longitude;
        case LocationUnavailable(:final message):
          _locationError = message;
      }
    });
  }

  void _clearLocation() {
    setState(() {
      _latitude = null;
      _longitude = null;
      _locationError = null;
    });
  }

  Future<String> _ensureLocalVisit() async {
    if (_localVisitId != null) return _localVisitId!;

    final repo = ref.read(fieldVisitsRepositoryProvider);
    final id = await repo.createLocal(
      caseId: widget.caseId,
      visitDate: _visitDate,
      outcome: _outcomeController.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      locationDescription: _emptyToNull(_locationDescController.text),
      notes: _emptyToNull(_notesController.text),
      description: _emptyToNull(_descriptionController.text),
    );
    _localVisitId = id;
    return id;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _visitDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      // §20.9: لا يجوز تاريخ في المستقبل (بتسامح يوم واحد لفارق التوقيت).
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _visitDate = picked);
  }

  Future<void> _capturePhoto() async {
    final attachment = await AddAttachmentSheet.captureFromCameraAndSelectType(
      context,
    );
    if (attachment == null || !mounted) return;

    setState(() => _capturingPhoto = true);
    try {
      final visitId = await _ensureLocalVisit();
      final attachmentId = await ref
          .read(attachmentUploaderProvider)
          .capture(
            caseId: widget.caseId,
            sourceFile: attachment.file,
            documentType: attachment.documentType,
            fileName: attachment.fileName,
            fieldVisitLocalId: visitId,
          );
      await ref
          .read(fieldVisitsRepositoryProvider)
          .attachPhoto(visitId, attachmentId);
      unawaited(ref.read(attachmentUploaderProvider).upload(attachmentId));
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذّرت إضافة الصورة: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _capturingPhoto = false);
    }
  }

  bool get _isValid => _outcomeController.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('نتيجة الزيارة حقل إلزامي.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(fieldVisitsRepositoryProvider);
      final visitId = await _ensureLocalVisit();

      // الحقول قد تكون تغيّرت بعد الإنشاء الأولي (مثلًا أُنشئت الزيارة عند
      // أول صورة قبل أن يكمل الأخصائي كتابة النتيجة) — نحدّثها محليًا دائمًا.
      await repo.updateLocalFields(
        visitId,
        visitDate: _visitDate,
        outcome: _outcomeController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        locationDescription: _emptyToNull(_locationDescController.text),
        notes: _emptyToNull(_notesController.text),
        description: _emptyToNull(_descriptionController.text),
      );

      final result = await repo.submit(visitId);
      if (!mounted) return;

      switch (result) {
        case VisitSubmitted():
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إرسال الزيارة للخادم بنجاح.'),
              backgroundColor: AppColors.success,
            ),
          );
        case VisitQueued():
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'حُفظت الزيارة محليًا — ستُرسَل تلقائيًا عند توفر الاتصال.',
              ),
              backgroundColor: AppColors.warning,
            ),
          );
        case VisitFailed(:final error):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تعذّر إرسال الزيارة: ${error.displayMessage}'),
              backgroundColor: AppColors.danger,
            ),
          );
      }

      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMMM yyyy', 'ar');
    final attachmentsAsync = _localVisitId == null
        ? const AsyncValue<List<PendingAttachmentRow>>.data([])
        : ref.watch(pendingAttachmentsProvider(widget.caseId));

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            widget.existingVisit == null ? 'زيارة ميدانية جديدة' : 'تعديل الزيارة',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            120,
          ),
          children: [
            SectionCard(
              title: 'موعد الزيارة',
              child: InkWell(
                onTap: _pickDate,
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      df.format(_visitDate),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SectionCard(
              title: 'نتيجة الزيارة *',
              child: TextField(
                controller: _outcomeController,
                maxLines: 3,
                maxLength: 2000,
                decoration: const InputDecoration(
                  hintText: 'اكتب ملخّص نتيجة الزيارة الميدانية...',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SectionCard(
              title: 'وصف ما تم أثناء الزيارة',
              child: TextField(
                controller: _descriptionController,
                maxLines: 3,
                maxLength: 2000,
                decoration: const InputDecoration(
                  hintText: 'اختياري...',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SectionCard(
              title: 'ملاحظات',
              child: TextField(
                controller: _notesController,
                maxLines: 2,
                maxLength: 2000,
                decoration: const InputDecoration(
                  hintText: 'اختياري...',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _LocationCard(
              latitude: _latitude,
              longitude: _longitude,
              locating: _locating,
              error: _locationError,
              descriptionController: _locationDescController,
              onRetry: _captureLocation,
              onClear: _clearLocation,
            ),
            const SizedBox(height: AppSpacing.md),
            _PhotosCard(
              attachments: attachmentsAsync.value
                      ?.where((a) => a.fieldVisitLocalId == _localVisitId)
                      .toList() ??
                  const [],
              capturing: _capturingPhoto,
              onCapture: _capturePhoto,
              onRetry: (id) =>
                  ref.read(attachmentUploaderProvider).upload(id),
              onDiscard: (id) =>
                  ref.read(attachmentUploaderProvider).discard(id),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'حفظ الزيارة',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final bool locating;
  final String? error;
  final TextEditingController descriptionController;
  final VoidCallback onRetry;
  final VoidCallback onClear;

  const _LocationCard({
    required this.latitude,
    required this.longitude,
    required this.locating,
    required this.error,
    required this.descriptionController,
    required this.onRetry,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocation = latitude != null && longitude != null;

    return SectionCard(
      title: 'الموقع (GPS)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (locating)
            const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: AppSpacing.sm),
                Text(
                  'جارٍ تحديد الموقع...',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ],
            )
          else if (hasLocation)
            Row(
              children: [
                const Icon(Icons.my_location, size: 16, color: AppColors.success),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: onClear,
                  child: const Text('إزالة', style: TextStyle(fontSize: 12)),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (error != null) ...[
                  Text(
                    error!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.danger,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.my_location, size: 16),
                  label: const Text('تحديد الموقع الحالي'),
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: descriptionController,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: 'وصف نصي للموقع (اختياري)، مثال: بجوار المسجد',
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotosCard extends StatelessWidget {
  final List<PendingAttachmentRow> attachments;
  final bool capturing;
  final VoidCallback onCapture;
  final void Function(String id) onRetry;
  final void Function(String id) onDiscard;

  const _PhotosCard({
    required this.attachments,
    required this.capturing,
    required this.onCapture,
    required this.onRetry,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'صور الزيارة (${attachments.length})',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (attachments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'لا توجد صور بعد.',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final att in attachments)
                  _PhotoThumb(
                    attachment: att,
                    onRetry: () => onRetry(att.id),
                    onDiscard: () => onDiscard(att.id),
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: capturing ? null : onCapture,
            icon: const Icon(Icons.camera_alt_outlined, size: 18),
            label: const Text('التقاط صورة'),
          ),
        ],
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  final PendingAttachmentRow attachment;
  final VoidCallback onRetry;
  final VoidCallback onDiscard;

  const _PhotoThumb({
    required this.attachment,
    required this.onRetry,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final stage = UploadStage.fromWire(attachment.uploadStage);

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.input),
          child: Image.file(
            File(attachment.localPath),
            width: 72,
            height: 72,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          bottom: 2,
          right: 2,
          child: Icon(
            stage.isDone
                ? Icons.cloud_done_outlined
                : stage == UploadStage.failed
                ? Icons.error_outline
                : Icons.cloud_off_outlined,
            size: 14,
            color: stage.isDone
                ? AppColors.success
                : stage == UploadStage.failed
                ? AppColors.danger
                : AppColors.warning,
          ),
        ),
        if (stage == UploadStage.failed)
          Positioned(
            top: 0,
            left: 0,
            child: InkWell(
              onTap: onRetry,
              child: const Icon(Icons.refresh, size: 16, color: AppColors.primary),
            ),
          ),
        if (!stage.isDone)
          Positioned(
            top: 0,
            right: 0,
            child: InkWell(
              onTap: onDiscard,
              child: const Icon(Icons.close, size: 16, color: AppColors.danger),
            ),
          ),
      ],
    );
  }
}
