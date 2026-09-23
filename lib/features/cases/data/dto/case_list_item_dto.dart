import '../../domain/case_status.dart';

/// عنصر قائمة الحالات.
///
/// الشكل **موحّد حرفيًا** بين `GET /cases` و `GET /search/cases` و
/// `GET /dashboard/work-queue` — العقد يؤكد تطابق السجلات الثلاثة حقلًا بحقل
/// وتحرسه اختبارات تعاقد على الخادم (§19، §21).
class CaseListItemDto {
  const CaseListItemDto({
    required this.id,
    required this.caseNumber,
    required this.displayId,
    required this.status,
    required this.priority,
    required this.beneficiaryFullName,
    this.nationalId,
    this.charityId,
    this.registrationDate,
    required this.completionPercentage,
    this.createdAtUtc,
    this.nextVisitDate,
    this.nextVisitStartTimeUtc,
    this.nextVisitLocation,
    required this.isBookmarked,
    this.returnedBy,
  });

  final String id;
  final String caseNumber;
  final String displayId;
  final CaseStatus status;
  final CasePriorityWire priority;
  final String beneficiaryFullName;
  final String? nationalId;
  final String? charityId;

  /// تاريخ التسجيل — `YYYY-MM-DD` بلا وقت.
  final String? registrationDate;

  final double completionPercentage;
  final DateTime? createdAtUtc;

  /// أقرب زيارة لم تكتمل بعد. حقول مسطّحة لا كائن متداخل — تصميم مقصود.
  final String? nextVisitDate;
  final DateTime? nextVisitStartTimeUtc;
  final String? nextVisitLocation;

  final bool isBookmarked;

  /// مصدر الإرجاع — **غير موجود في العقد الحالي**، طُلب من الباك إند (§7).
  /// يُقرأ تفاؤليًا: يعمل فور إضافته دون تغيير كود.
  final ReturnSource? returnedBy;

  /// هل توجد زيارة مجدولة؟
  ///
  /// "زيارة مجدولة" ليست حالة على الشبكة — تُشتقّ من وجود `nextVisitDate`.
  bool get hasScheduledVisit => nextVisitDate != null;

  bool get isComplete => completionPercentage >= 100;

  static CaseListItemDto fromJson(Map<String, dynamic> json) {
    return CaseListItemDto(
      id: json['id'] as String? ?? '',
      caseNumber: json['caseNumber'] as String? ?? '',
      displayId: json['displayId'] as String? ?? '',
      status: CaseStatus.fromWire(json['status'] as String?),
      priority: CasePriorityWire.fromWire(json['priority'] as String?),
      beneficiaryFullName: json['beneficiaryFullName'] as String? ?? '',
      nationalId: json['nationalId'] as String?,
      charityId: json['charityId'] as String?,
      registrationDate: json['registrationDate'] as String?,
      completionPercentage: _double(json['completionPercentage']),
      createdAtUtc: _date(json['createdAtUtc']),
      nextVisitDate: json['nextVisitDate'] as String?,
      nextVisitStartTimeUtc: _date(json['nextVisitStartTimeUtc']),
      nextVisitLocation: json['nextVisitLocation'] as String?,
      isBookmarked: json['isBookmarked'] == true,
      returnedBy: json['returnedBy'] == null
          ? null
          : ReturnSource.fromWire(json['returnedBy'] as String?),
    );
  }

  static double _double(Object? value) => switch (value) {
    final num v => v.toDouble(),
    final String v => double.tryParse(v) ?? 0,
    _ => 0,
  };

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toUtc() : null;
}
