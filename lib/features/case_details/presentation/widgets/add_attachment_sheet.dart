import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/sections/pending_attachment.dart';

const _documentTypes = [
  'بطاقة شخصية',
  'مستندات الأسرة',
  'مستندات دخل',
  'مستندات علاج',
  'مستندات تعليم',
  'صور السكن',
  'صور ميدانية',
  'أخرى',
];

enum _AttachmentSource { camera, gallery, file }

class _PickedFile {
  final File file;
  final String fileName;

  const _PickedFile({required this.file, required this.fileName});
}

/// نافذة إضافة مرفق — اختيار نوع المستند ثم مصدر الصورة (كاميرا/معرض).
/// المرفق يبقى محليًا (Pending) حتى يتم التكامل مع Object Storage.
class AddAttachmentSheet {
  static Future<PendingAttachment?> show(BuildContext context) async {
    final documentType = await _pickDocumentType(context);
    if (documentType == null || !context.mounted) return null;

    final picked = await _pickFile(context);
    if (picked == null) return null;

    return PendingAttachment(
      file: picked.file,
      documentType: documentType,
      addedAt: DateTime.now(),
      fileName: picked.fileName,
    );
  }

  static Future<String?> _pickDocumentType(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'نوع المستند',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final type in _documentTypes)
                      ListTile(
                        title: Text(
                          type,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onTap: () async {
                          if (type == 'أخرى') {
                            final otherDetails =
                                await _promptOtherDetails(context);
                            if (otherDetails != null &&
                                otherDetails.trim().isNotEmpty) {
                              if (context.mounted) {
                                Navigator.of(context)
                                    .pop('أخرى - ${otherDetails.trim()}');
                              }
                            } else {
                              if (context.mounted) {
                                Navigator.of(context).pop('أخرى');
                              }
                            }
                          } else {
                            Navigator.of(context).pop(type);
                          }
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  static Future<String?> _promptOtherDetails(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'تفاصيل المرفق الآخر',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'اكتب اسم أو وصف المرفق هنا...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  /// يعرض اختيار مصدر المرفق: كاميرا، معرض الصور، أو أي ملف من الجهاز
  /// (PDF / Office / نصوص) — الأنواع المسموحة في [allowedAttachmentExtensions].
  static Future<_PickedFile?> _pickFile(BuildContext context) async {
    final source = await showModalBottomSheet<_AttachmentSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.primary,
              ),
              title: const Text(
                'التقاط صورة',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
              onTap: () =>
                  Navigator.of(context).pop(_AttachmentSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.primary,
              ),
              title: const Text(
                'اختيار من المعرض',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
              onTap: () =>
                  Navigator.of(context).pop(_AttachmentSource.gallery),
            ),
            ListTile(
              leading: const Icon(
                Icons.attach_file_outlined,
                color: AppColors.primary,
              ),
              title: const Text(
                'اختيار ملف (PDF / مستند)',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
              onTap: () => Navigator.of(context).pop(_AttachmentSource.file),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );

    switch (source) {
      case _AttachmentSource.camera:
      case _AttachmentSource.gallery:
        final picker = ImagePicker();
        final picked = await picker.pickImage(
          source: source == _AttachmentSource.camera
              ? ImageSource.camera
              : ImageSource.gallery,
          imageQuality: 80,
        );
        if (picked == null) return null;
        return _PickedFile(file: File(picked.path), fileName: picked.name);

      case _AttachmentSource.file:
        final result = await FilePicker.platform.pickFiles(
          type: FileType.any,
        );
        final path = result?.files.single.path;
        if (path == null) return null;
        return _PickedFile(
          file: File(path),
          fileName: result!.files.single.name,
        );

      case null:
        return null;
    }
  }

  /// التقاط صورة مباشرة عبر الكاميرا ثم فتح نافذة من الأسفل (نصف الصفحة تقريبًا)
  /// لكتابة أو اختيار نوع المرفق.
  static Future<PendingAttachment?> captureFromCameraAndSelectType(
    BuildContext context,
  ) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (picked == null || !context.mounted) return null;

    final file = File(picked.path);
    final documentType = await showTypeSelectionSheet(context, file);
    if (documentType == null || documentType.trim().isEmpty) return null;

    return PendingAttachment(
      file: file,
      documentType: documentType.trim(),
      addedAt: DateTime.now(),
      fileName: picked.name,
    );
  }

  /// نافذة من أسفل لنصف الصفحة تقريبًا لتحديد أو كتابة نوع المرفق
  static Future<String?> showTypeSelectionSheet(
    BuildContext context,
    File file,
  ) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TypeSelectionSheet(file: file),
    );
  }
}

class _TypeSelectionSheet extends StatefulWidget {
  final File file;

  const _TypeSelectionSheet({required this.file});

  @override
  State<_TypeSelectionSheet> createState() => _TypeSelectionSheetState();
}

class _TypeSelectionSheetState extends State<_TypeSelectionSheet> {
  final TextEditingController _controller = TextEditingController();
  String? _selectedPreset;

  final List<String> _quickTypes = const [
    'بطاقة شخصية',
    'مستندات دخل',
    'صور السكن',
    'مستندات علاج',
    'مستندات تعليم',
    'مستندات الأسرة',
    'صور ميدانية',
    'عقد إيجار',
    'إيصال مرافق',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectPreset(String type) {
    setState(() {
      _selectedPreset = type;
      _controller.text = type;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    });
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      Navigator.of(context).pop(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.75,
        minHeight: screenHeight * 0.45,
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg + bottomInset,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Header with thumbnail
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    widget.file,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تم التقاط الصورة بنجاح',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'اختر أو اكتب نوع المرفق لحفظه في الحالة',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Text input
            TextField(
              controller: _controller,
              autofocus: true,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                labelText: 'نوع المرفق أو المستند *',
                hintText: 'اكتب نوع المرفق أو اضغط على أي خيار بالأسفل...',
                prefixIcon: const Icon(
                  Icons.description_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() {
                          _controller.clear();
                          _selectedPreset = null;
                        }),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  if (val != _selectedPreset) {
                    _selectedPreset = null;
                  }
                });
              },
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.md),

            // Quick select label
            const Text(
              'مقترحات سريعة:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),

            // Quick chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in _quickTypes)
                  InkWell(
                    onTap: () => _selectPreset(type),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedPreset == type ||
                                _controller.text == type
                            ? AppColors.primary
                            : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _selectedPreset == type ||
                                  _controller.text == type
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _selectedPreset == type ||
                                  _controller.text == type
                              ? Colors.white
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Save / Confirm button
            ElevatedButton(
              onPressed: _controller.text.trim().isNotEmpty ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.border,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'تأكيد وحفظ المرفق',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
