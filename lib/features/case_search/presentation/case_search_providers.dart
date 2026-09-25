import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nahda/features/case_search/data/api_case_search_repository.dart';

import '../../../core/providers/data_providers.dart';
import '../domain/case_search_filter.dart';
import '../domain/case_search_repository.dart';
import '../domain/case_search_result.dart';

final caseSearchRepositoryProvider = Provider<CaseSearchRepository>((ref) {
  return ApiCaseSearchRepository(ref.watch(casesRepositoryProvider));
});

final caseSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');
final caseSearchFilterProvider =
    StateProvider.autoDispose<CaseSearchFilter>((ref) => const CaseSearchFilter());

/// نتائج البحث متعددة المعايير مع Debounce لتقليل الطلبات أثناء الكتابة.
final caseSearchResultsProvider =
    FutureProvider.autoDispose<List<CaseSearchResult>>((ref) async {
      final query = ref.watch(caseSearchQueryProvider);
      final filter = ref.watch(caseSearchFilterProvider);

      if (query.trim().isEmpty && filter.isEmpty) return const [];

      final repository = ref.watch(caseSearchRepositoryProvider);

      final link = ref.keepAlive();
      final timer = Future.delayed(const Duration(milliseconds: 250));
      ref.onDispose(link.close);
      await timer;

      return repository.search(query, filter: filter);
    });
