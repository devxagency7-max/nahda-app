import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
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

  /// `pending_assignment` على الخادم — غير مُسندة لأي أخصائي بعد. **لا
  /// تُخلَط مع [assigned]**: كانت مدمجة فيها سابقًا فتعرض "مسندة إليك" على
  /// حالة لم تُسند فعليًا لأحد — بطاقتها تعرض بدلًا من ذلك زر "تكليف"
  /// (self-accept عبر `POST /cases/{id}/accept`، §2.2 من عقد الموبايل).
  pendingAssignment,

  /// `draft` على الخادم — حالة اتسجلت بس لسه محدش سنّدها ولا اتكلف بيها
  /// حد. **لا تُخلَط مع [assigned]**: كانت مدمجة فيها سابقًا فتعرض "مسندة
  /// إليك" على حالة لسه مسودة فعليًا.
  draft,

  /// `pending_approval` على الخادم — عند مدير الفرع بانتظار القرار النهائي.
  pendingApproval,

  /// `approved` على الخادم — حالة نهائية، اعتُمدت.
  approved,

  /// `rejected` على الخادم — حالة نهائية، اترفضت.
  rejected,
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
    CaseWorkStatus.pendingAssignment => 'متاحة للتكليف',
    CaseWorkStatus.draft => 'مسودة',
    CaseWorkStatus.pendingApproval => 'بانتظار اعتماد المدير',
    CaseWorkStatus.approved => 'معتمدة',
    CaseWorkStatus.rejected => 'مرفوضة',
  };

  Color get backgroundColor => switch (this) {
    CaseWorkStatus.assigned => AppColors.primaryLight,
    CaseWorkStatus.visitScheduled => AppColors.primaryLight,
    CaseWorkStatus.inProgress => AppColors.warningBg,
    CaseWorkStatus.returnedFromReview => AppColors.dangerBg,
    CaseWorkStatus.returnedFromManager => AppColors.dangerBg,
    CaseWorkStatus.readyForReview => AppColors.successBg,
    CaseWorkStatus.submittedForReview => AppColors.warningBg,
    CaseWorkStatus.pendingAssignment => AppColors.primaryLight,
    CaseWorkStatus.draft => AppColors.surfaceMuted,
    CaseWorkStatus.pendingApproval => AppColors.warningBg,
    CaseWorkStatus.approved => AppColors.successBg,
    CaseWorkStatus.rejected => AppColors.dangerBg,
  };

  Color get color => switch (this) {
    CaseWorkStatus.assigned => AppColors.primary,
    CaseWorkStatus.visitScheduled => AppColors.primary,
    CaseWorkStatus.inProgress => AppColors.warning,
    CaseWorkStatus.returnedFromReview => AppColors.danger,
    CaseWorkStatus.returnedFromManager => AppColors.danger,
    CaseWorkStatus.readyForReview => AppColors.success,
    CaseWorkStatus.submittedForReview => AppColors.warning,
    CaseWorkStatus.pendingAssignment => AppColors.primary,
    CaseWorkStatus.draft => AppColors.textMuted,
    CaseWorkStatus.pendingApproval => AppColors.warning,
    CaseWorkStatus.approved => AppColors.success,
    CaseWorkStatus.rejected => AppColors.danger,
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
