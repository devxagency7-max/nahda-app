import 'case_priority.dart';

/// حالة الحالة من منظور الأخصائي — Social Worker Spec §39.
/// أسماء مبسطة للعرض فقط؛ الـ Backend لاحقًا يحمل الـ Status التقني الكامل.
enum CaseWorkStatus {
  assigned, // ASSIGNED_TO_SOCIAL_WORKER
  visitScheduled, // VISIT_SCHEDULED
  inProgress, // SOCIAL_ASSESSMENT_IN_PROGRESS
  returnedFromReview, // RETURNED_FROM_REVIEW — مرتجعة من المراجع
  returnedFromManager, // RETURNED_FROM_MANAGER — مرتجعة من المدير
  readyForReview, // READY_FOR_REVIEW
  submittedForReview, // UNDER_REVIEW — تم إرسالها فعليًا للمراجع
}

extension CaseWorkStatusX on CaseWorkStatus {
  String get label => switch (this) {
    CaseWorkStatus.assigned => 'مسندة إليك',
    CaseWorkStatus.visitScheduled => 'زيارة مجدولة',
    CaseWorkStatus.inProgress => 'قيد البحث',
    CaseWorkStatus.returnedFromReview => 'مرتجعة من المراجع',
    CaseWorkStatus.returnedFromManager => 'مرتجعة من المدير',
    CaseWorkStatus.readyForReview => 'جاهزة للإرسال',
    CaseWorkStatus.submittedForReview => 'تم الإرسال للمراجع',
  };
}

/// مصدر إنشاء الحالة — Rule جديد: الأخصائي ممكن يكون هو نفسه بادئ الحالة
/// (تسجيل ميداني) بدل الاعتماد الحصري على Data Entry.
enum CaseOrigin { dataEntry, socialWorker }

class SocialWorkerCase {
  final String id;
  final String displayId; // Case ID زي "#1024"
  final String personName;
  final String? village;
  final CasePriority priority;
  final String? priorityReason;
  final CaseWorkStatus status;
  final CaseOrigin origin;
  final DateTime? scheduledVisitAt;
  final double progress; // 0.0 - 1.0
  final DateTime lastUpdatedAt;
  final bool hasUnsyncedChanges; // Offline — لسه مش اتزامن مع السيرفر
  final String? returnNotes;
  final String? returnAuthor;

  const SocialWorkerCase({
    required this.id,
    required this.displayId,
    required this.personName,
    this.village,
    required this.priority,
    this.priorityReason,
    required this.status,
    required this.origin,
    this.scheduledVisitAt,
    required this.progress,
    required this.lastUpdatedAt,
    this.hasUnsyncedChanges = false,
    this.returnNotes,
    this.returnAuthor,
  });
}
