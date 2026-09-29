import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';

import '../../../../core/providers/data_providers.dart';
import '../../../../core/storage/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../attachments/domain/upload_stage.dart';
import '../../domain/sections/initial_need_form.dart';
import '../widgets/add_attachment_sheet.dart';
import '../widgets/section_card.dart';
import '../widgets/tab_progress_bar.dart';

/// تاب المرفقات والمستندات — يستخدم `AttachmentUploader` الحقيقي
/// (§13 من العقد: الالتقاط لا يلمس الشبكة، الرفع يحدث عند توفّرها).
///
/// [initialData]/[onChanged] يحملان بيانات الاحتياج الأولي فقط لأجل
/// [CaseReadiness] (قسم بيانات اختياري لا يمنع الإرسال) — هذا التاب
/// بصريًا مرفقات فقط ولا يقرأ أو يعدّل عليهما.
class InitialNeedAttachmentsTab extends ConsumerStatefulWidget {
  final String caseId;
  final InitialNeedFormData initialData;
  final ValueChanged<InitialNeedFormData> onChanged;

  const InitialNeedAttachmentsTab({
    super.key,
    required this.caseId,
    required this.initialData,
    required this.onChanged,
  });

  @override
  ConsumerState<InitialNeedAttachmentsTab> createState() =>
      _InitialNeedAttachmentsTabState();
}

class _InitialNeedAttachmentsTabState
    extends ConsumerState<InitialNeedAttachmentsTab> {
  bool _capturing = false;

  Future<void> _capture(File file, String fileName, String documentType) async {
    setState(() => _capturing = true);
    try {
      final id = await ref
          .read(attachmentUploaderProvider)
          .capture(
            caseId: widget.caseId,
            sourceFile: file,
            documentType: documentType,
            fileName: fileName,
          );
      // الرفع يبدأ فورًا لو متصل؛ لو أوفلاين يبقى `captured` وينتظر
      // `SyncEngine`/`AttachmentUploader.uploadAllForCase` عند عودة الاتصال.
      unawaited(ref.read(attachmentUploaderProvider).upload(id));
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('معلش، مقدرناش نضيف المرفق: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _handleAddAttachment() async {
    final attachment = await AddAttachmentSheet.show(context);
    if (attachment == null || !mounted) return;
    await _capture(attachment.file, attachment.fileName, attachment.documentType);
  }

  Future<void> _handleCameraCapture() async {
    final attachment =
        await AddAttachmentSheet.captureFromCameraAndSelectType(context);
    if (attachment == null || !mounted) return;
    await _capture(attachment.file, attachment.fileName, attachment.documentType);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تمام! اتضاف مرفق (${attachment.documentType})'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _retry(String localId) async {
    await ref.read(attachmentUploaderProvider).upload(localId);
  }

  Future<void> _discard(String localId) async {
    await ref.read(attachmentUploaderProvider).discard(localId);
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d/M/yyyy', 'ar');
    final attachmentsAsync = ref.watch(
      pendingAttachmentsProvider(widget.caseId),
    );

    return attachmentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('تعذّر تحميل المرفقات')),
      data: (attachments) {
        final totalCount = attachments.length;
        final progress = totalCount > 0 ? 1.0 : 0.0;

        return Stack(
          children: [
            Column(
              children: [
                TabProgressBar(progress: progress),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      125,
                    ),
                    children: [
                      Text(
                        'المستندات والمرفقات ($totalCount)',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (totalCount == 0)
                        const SectionEmptyState(message: 'لا توجد مرفقات بعد')
                      else
                        for (final att in attachments) ...[
                          _AttachmentTile(
                            attachment: att,
                            dateLabel: df.format(att.createdAt),
                            onRetry: () => _retry(att.id),
                            onDelete: () => _discard(att.id),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton.icon(
                        onPressed: _capturing ? null : _handleAddAttachment,
                        icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                        label: const Text('رفع صورة / مستند جديد'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // زر الكاميرا العائم الأزرق أعلى زر الرجوع مباشرة بمسافة مريحة
            PositionedDirectional(
              start: AppSpacing.lg,
              bottom: 40.0,
              child: Tooltip(
                message: 'التقاط صورة بالكاميرا وإضافة مرفق',
                child: Material(
                  color: AppColors.primary,
                  shape: const CircleBorder(),
                  elevation: 5,
                  shadowColor: AppColors.primary.withValues(alpha: 0.4),
                  child: InkWell(
                    onTap: _capturing ? null : _handleCameraCapture,
                    customBorder: const CircleBorder(),
                    child: const SizedBox(
                      width: 54,
                      height: 54,
                      child: Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  final PendingAttachmentRow attachment;
  final String dateLabel;
  final VoidCallback onRetry;
  final VoidCallback onDelete;

  const _AttachmentTile({
    required this.attachment,
    required this.dateLabel,
    required this.onRetry,
    required this.onDelete,
  });

  bool get _isImage => const [
    'jpg',
    'jpeg',
    'png',
    'heic',
    'webp',
  ].contains(_extension);

  String get _extension {
    final dot = attachment.fileName.lastIndexOf('.');
    return dot == -1 ? '' : attachment.fileName.substring(dot + 1).toLowerCase();
  }

  Future<void> _open(BuildContext context) async {
    final file = File(attachment.localPath);
    if (_isImage) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _ImagePreviewScreen(
            file: file,
            title: attachment.fileName,
          ),
        ),
      );
      return;
    }
    final result = await OpenFilex.open(file.path);
    if (result.type != ResultType.done && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('معلش، مقدرناش نفتح الملف: ${result.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stage = UploadStage.fromWire(attachment.uploadStage);

    return SectionCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => _open(context),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.input),
              child: _isImage
                  ? Image.file(
                      File(attachment.localPath),
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 44,
                      height: 44,
                      color: AppColors.primaryLight,
                      child: Icon(
                        _iconForExtension(_extension),
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.documentType,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${attachment.fileName} · $dateLabel',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        stage.isDone
                            ? Icons.cloud_done_outlined
                            : stage == UploadStage.failed
                            ? Icons.error_outline
                            : Icons.cloud_off_outlined,
                        size: 13,
                        color: stage.isDone
                            ? AppColors.success
                            : stage == UploadStage.failed
                            ? AppColors.danger
                            : AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        stage.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: stage.isDone
                              ? AppColors.success
                              : stage == UploadStage.failed
                              ? AppColors.danger
                              : AppColors.warning,
                        ),
                      ),
                      if (stage == UploadStage.failed) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: onRetry,
                          child: const Text(
                            'إعادة المحاولة',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (!stage.isDone)
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.danger,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// عرض كامل الشاشة لصورة مرفق مع تكبير/تصغير باللمس.
class _ImagePreviewScreen extends StatelessWidget {
  final File file;
  final String title;

  const _ImagePreviewScreen({required this.file, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          title,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 5,
          child: Image.file(file),
        ),
      ),
    );
  }
}

IconData _iconForExtension(String extension) {
  return switch (extension) {
    'pdf' => Icons.picture_as_pdf_outlined,
    'doc' || 'docx' => Icons.description_outlined,
    'xls' || 'xlsx' => Icons.table_chart_outlined,
    'ppt' || 'pptx' => Icons.slideshow_outlined,
    'txt' => Icons.article_outlined,
    _ => Icons.insert_drive_file_outlined,
  };
}
