import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;

import '../data/cases_repository.dart';
import '../data/local_cases_repository.dart';
import '../domain/case_category.dart';
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

final activeCategoryProvider = StateProvider<CaseCategory?>((ref) => null);

final selectedCaseIdProvider = StateProvider<String?>((ref) => null);

final featuredCasesProvider = FutureProvider<List<TrueCrimeCase>>((ref) async {
  final search = ref.watch(caseSearchServiceProvider);
  final cases = await ref.watch(casesProvider.future);
  final activeCategory = ref.watch(activeCategoryProvider);
  final filteredCases = activeCategory == null
      ? cases
      : cases
            .where((crimeCase) => crimeCase.category == activeCategory)
            .toList(growable: false);
  return search.topFeatured(filteredCases);
});

final filteredCasesProvider = FutureProvider<List<TrueCrimeCase>>((ref) async {
  final search = ref.watch(caseSearchServiceProvider);
  final cases = await ref.watch(casesProvider.future);
  final activeCategory = ref.watch(activeCategoryProvider);
  final query = ref.watch(searchQueryProvider);
  final categoryFiltered = activeCategory == null
      ? cases
      : cases
            .where((crimeCase) => crimeCase.category == activeCategory)
            .toList(growable: false);
  return search.search(categoryFiltered, query);
});

final relevantSuggestionsProvider = FutureProvider<List<TrueCrimeCase>>((
  ref,
) async {
  final search = ref.watch(caseSearchServiceProvider);
  final cases = await ref.watch(casesProvider.future);
  final activeCategory = ref.watch(activeCategoryProvider);
  final filteredCases = activeCategory == null
      ? cases
      : cases
            .where((crimeCase) => crimeCase.category == activeCategory)
            .toList(growable: false);
  return search.topRelevant(filteredCases);
});

final categoryCountsProvider = Provider<Map<CaseCategory, int>>((ref) {
  final search = ref.watch(caseSearchServiceProvider);
  final cases = ref.watch(casesProvider).value ?? const <TrueCrimeCase>[];
  return search.countByCategory(cases);
});

final emptyCatalogProvider = Provider<bool>((ref) {
  return ref
      .watch(casesProvider)
      .when(
        data: (cases) => cases.isEmpty,
        loading: () => false,
        error: (_, stackTrace) => false,
      );
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
