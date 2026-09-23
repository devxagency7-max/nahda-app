import 'case_search_filter.dart';
import 'case_search_result.dart';

/// بحث Server-side في كل حالات النظام — Backend Contract §15 (Search Cases).
/// التنفيذ الحالي Mock، لاحقًا API حقيقي بدون تغيير في UI/Use Case.
abstract class CaseSearchRepository {
  Future<List<CaseSearchResult>> search(String query, {CaseSearchFilter? filter});
}

