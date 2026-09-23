import '../data_source.dart';

/// القسم 7 — Documents & Attachments.
/// كل مرفق مرتبط بالمرحلة التي أُضيف فيها ومصدره.
class CaseAttachment {
  final String id;
  final String documentType;
  final String fileName;
  final String? description;
  final DateTime uploadedAt;
  final DataSource uploadedBy;
  final String status; // حالة المستند
  final String? notes;
  final String? visitId; // لو مرفق ميداني مرتبط بزيارة محددة

  const CaseAttachment({
    required this.id,
    required this.documentType,
    required this.fileName,
    this.description,
    required this.uploadedAt,
    required this.uploadedBy,
    required this.status,
    this.notes,
    this.visitId,
  });
}
