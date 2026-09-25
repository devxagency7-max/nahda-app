import 'dart:convert';

import '../../../core/storage/app_database.dart';
import '../../home/domain/case_priority.dart';
import '../../home/domain/social_worker_case.dart';
import '../domain/case_status.dart';

/// يحوّل صفّ الكاش إلى نموذج العرض الذي تستهلكه الشاشات.
///
/// **طبقة عزل مقصودة.** الشبكة تعرف عشر حالات، والواجهة تعرض سبعًا؛ حالتان
/// منها (`visitScheduled` و `readyForReview`) **لا وجود لهما على الشبكة
/// إطلاقًا** وتُشتقّان من بيانات أخرى. وضع هذا المنطق في مكان واحد يعني أن
/// إضافة `returnInfo` من الباك إند لاحقًا (§7) لا تمسّ أي شاشة.
class CaseStatusMapper {
  const CaseStatusMapper._();

  /// يحوّل صفّ الكاش إلى `SocialWorkerCase`.
  static SocialWorkerCase toDisplayCase(CachedCaseRow row) {
    final status = CaseStatus.fromWire(row.status);

    return SocialWorkerCase(
      id: row.id,
      displayId: '#${row.displayId}',
      personName: row.beneficiaryFullName,
      village: row.nextVisitLocation,
      priority: _priority(row.priority),
      status: _displayStatus(row, status),
      origin: CaseOrigin.dataEntry,
      scheduledVisitAt: _visitDateTime(row),
      progress: (row.completionPercentage / 100).clamp(0.0, 1.0),
      lastUpdatedAt: row.serverUpdatedAt ?? row.fetchedAt,
      hasUnsyncedChanges: row.syncState != 'synced',
      returnNotes: _returnReason(row),
      returnAuthor: _returnAuthor(row),
    );
  }

  /// يشتقّ حالة العرض من الحالة الفعلية + بيانات مساعدة.
  static CaseWorkStatus _displayStatus(CachedCaseRow row, CaseStatus status) {
    switch (status) {
      case CaseStatus.assigned:
        return CaseWorkStatus.assigned;

      case CaseStatus.returnedToWorker:
        // التمييز بين مصدري الإرجاع يحتاج `returnInfo` من الباك إند (§7).
        // حتى تصل، نقرأ ما هو متاح ونرجع للمراجع كافتراض لأنه الأشيع.
        return _returnSource(row) == ReturnSource.manager
            ? CaseWorkStatus.returnedFromManager
            : CaseWorkStatus.returnedFromReview;

      case CaseStatus.accepted:
      case CaseStatus.inResearch:
        // "زيارة مجدولة" ليست حالة على الشبكة — تُشتقّ من وجود زيارة قادمة.
        if (row.nextVisitDate != null) return CaseWorkStatus.visitScheduled;
        // "جاهزة للإرسال" تُشتقّ من اكتمال الأقسام لا من حقل حالة.
        if (row.completionPercentage >= 100) {
          return CaseWorkStatus.readyForReview;
        }
        return CaseWorkStatus.inProgress;

      case CaseStatus.pendingReview:
      case CaseStatus.pendingApproval:
      case CaseStatus.approved:
      case CaseStatus.rejected:
        return CaseWorkStatus.submittedForReview;

      case CaseStatus.draft:
      case CaseStatus.pendingAssignment:
      case CaseStatus.unknown:
        return CaseWorkStatus.assigned;
    }
  }

  static ReturnSource _returnSource(CachedCaseRow row) {
    final info = _returnInfo(row);
    return ReturnSource.fromWire(info?['returnedBy'] as String?);
  }

  static String? _returnReason(CachedCaseRow row) =>
      _returnInfo(row)?['reason'] as String?;

  static String? _returnAuthor(CachedCaseRow row) {
    final info = _returnInfo(row);
    if (info == null) return null;

    final name = info['returnedByName'] as String?;
    final source = ReturnSource.fromWire(info['returnedBy'] as String?);

    if (name == null) return source.label;
    return switch (source) {
      ReturnSource.reviewer => '$name (مراجع الجودة)',
      ReturnSource.manager => '$name (مدير الفرع)',
      ReturnSource.unknown => name,
    };
  }

  /// يقرأ `returnInfo` من تفاصيل الحالة المخزَّنة.
  ///
  /// غائب في العقد الحالي؛ يعمل تلقائيًا فور إضافته دون تغيير كود.
  static Map<String, dynamic>? _returnInfo(CachedCaseRow row) {
    final raw = row.detailsJson;
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final info = decoded['returnInfo'];
      return info is Map<String, dynamic> ? info : null;
    } on FormatException {
      return null;
    }
  }

  static DateTime? _visitDateTime(CachedCaseRow row) {
    if (row.nextVisitStartTimeUtc != null) {
      return row.nextVisitStartTimeUtc!.toLocal();
    }
    final date = row.nextVisitDate;
    return date == null ? null : DateTime.tryParse(date);
  }

  static CasePriority _priority(String wire) =>
      switch (CasePriorityWire.fromWire(wire)) {
        CasePriorityWire.urgent => CasePriority.urgent,
        CasePriorityWire.high => CasePriority.high,
        CasePriorityWire.medium => CasePriority.medium,
        CasePriorityWire.low => CasePriority.low,
        CasePriorityWire.unknown => CasePriority.medium,
      };

  /// الإجراءات المتاحة من الكاش — تلميح واجهة لا تفويض (§15.7).
  static List<WorkflowAction> availableActions(CachedCaseRow row) {
    final raw = row.availableActionsJson;
    if (raw == null) return const [];

    try {
      final decoded = jsonDecode(raw);
      return decoded is List
          ? decoded
                .whereType<String>()
                .map(WorkflowAction.fromWire)
                .where((a) => a != WorkflowAction.unknown)
                .toList(growable: false)
          : const [];
    } on FormatException {
      return const [];
    }
  }
}
