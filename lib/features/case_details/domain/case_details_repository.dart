import 'case_full_details.dart';

/// جلب تفاصيل الحالة الكاملة — التنفيذ الحالي Mock، لاحقًا API حقيقي
/// (GET /api/v1/cases/{caseId}) بدون تغيير في UI/Use Case.
abstract class CaseDetailsRepository {
  Future<CaseFullDetails> getCaseDetails(String caseId);
}
