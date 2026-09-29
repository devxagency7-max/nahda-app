import 'case_full_details.dart';

/// جلب تفاصيل الحالة الكاملة من الكاش المحلي — راجع
/// [CaseDetailsRepositoryImpl] للتفاصيل. لا مصدر بيانات وهمي.
abstract class CaseDetailsRepository {
  Future<CaseFullDetails> getCaseDetails(String caseId);
}
