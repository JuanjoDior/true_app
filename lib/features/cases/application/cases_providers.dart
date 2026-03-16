import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;

import '../data/cases_repository.dart';
import '../data/local_cases_repository.dart';
import '../domain/true_crime_case.dart';
import 'case_search_service.dart';

final casesRepositoryProvider = Provider<CasesRepository>((ref) {
  return LocalCasesRepository();
});

final caseSearchServiceProvider = Provider<CaseSearchService>((ref) {
  return const CaseSearchService();
});

final casesProvider = FutureProvider<List<TrueCrimeCase>>((ref) async {
  final repository = ref.watch(casesRepositoryProvider);
  return repository.getCases();
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final selectedCaseIdProvider = StateProvider<String?>((ref) => null);

final featuredCasesProvider = FutureProvider<List<TrueCrimeCase>>((ref) async {
  final search = ref.watch(caseSearchServiceProvider);
  final cases = await ref.watch(casesProvider.future);
  return search.topFeatured(cases);
});

final searchResultsProvider = FutureProvider<List<TrueCrimeCase>>((ref) async {
  final search = ref.watch(caseSearchServiceProvider);
  final cases = await ref.watch(casesProvider.future);
  final query = ref.watch(searchQueryProvider);
  return search.search(cases, query);
});

final relevantSuggestionsProvider = FutureProvider<List<TrueCrimeCase>>((
  ref,
) async {
  final search = ref.watch(caseSearchServiceProvider);
  final cases = await ref.watch(casesProvider.future);
  return search.topRelevant(cases);
});

final selectedCaseProvider = Provider<AsyncValue<TrueCrimeCase?>>((ref) {
  final selectedCaseId = ref.watch(selectedCaseIdProvider);
  final casesAsync = ref.watch(casesProvider);
  return casesAsync.whenData((cases) {
    if (selectedCaseId == null) {
      return null;
    }
    for (final crimeCase in cases) {
      if (crimeCase.id == selectedCaseId) {
        return crimeCase;
      }
    }
    return null;
  });
});
