import 'dart:io';

/// مرفق أضافه الأخصائي محليًا ولسه ما اترفعش للسيرفر — Pending Sync
/// (Offline Contract §71: Local Draft → Pending Sync → Sync).
class PendingAttachment {
  final File file;
  final String documentType;
  final DateTime addedAt;
  final String fileName;

  const PendingAttachment({
    required this.file,
    required this.documentType,
    required this.addedAt,
    required this.fileName,
  });

  String get extension {
    final dot = fileName.lastIndexOf('.');
    return dot == -1 ? '' : fileName.substring(dot + 1).toLowerCase();
  }

  bool get isImage =>
      ['jpg', 'jpeg', 'png', 'heic', 'webp'].contains(extension);
}
