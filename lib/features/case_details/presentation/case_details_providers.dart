import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/data_providers.dart';
import '../data/case_details_repository_impl.dart';
import '../domain/case_details_repository.dart';
import '../domain/case_full_details.dart';

final caseDetailsRepositoryProvider = Provider<CaseDetailsRepository>((ref) {
  return CaseDetailsRepositoryImpl(
    casesRepository: ref.watch(casesRepositoryProvider),
  );
});

final caseDetailsProvider = FutureProvider.autoDispose
    .family<CaseFullDetails, String>((ref, caseId) async {
      final repository = ref.watch(caseDetailsRepositoryProvider);
      return repository.getCaseDetails(caseId);
    });
