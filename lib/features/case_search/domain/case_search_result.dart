import '../../home/domain/case_priority.dart';

/// نتيجة بحث عن حالة في كل حالات النظام (مش مقتصر على حالات الأخصائي) —
/// يُستخدم لمنع تكرار الحالات (Rule 1) سواء من شريط البحث في الـ Home
/// أو قبل تسجيل حالة ميدانية جديدة.
class CaseSearchResult {
  final String id;
  final String displayId;
  final String personName;
  final String? nationalId; // Masked دائمًا في نتائج البحث
  final String? village;
  final String? charity;
  final String? phone;
  final DateTime? registeredAt;
  final String statusLabel;
  final CasePriority priority;
  final String? assignedWorkerName;

  /// `null` = غير معروف (مصدر البيانات لا يرجّع معلومة الإسناد، مثل
  /// `GET /search/cases` حاليًا) — البطاقة تُخفي قسم الإسناد كليًا بدل ما
  /// تفترض "غير مسندة" وهي معلومة ممكن تكون غلط.
  final bool? isAssignedToCurrentWorker;

  const CaseSearchResult({
    required this.id,
    required this.displayId,
    required this.personName,
    this.nationalId,
    this.village,
    this.charity,
    this.phone,
    this.registeredAt,
    required this.statusLabel,
    required this.priority,
    this.assignedWorkerName,
    this.isAssignedToCurrentWorker,
  });
}
