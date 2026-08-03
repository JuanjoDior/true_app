import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;

import '../data/case_connections_seed.dart';
import '../data/cases_repository.dart';
import '../data/local_cases_repository.dart';
import '../domain/case_category.dart';
import '../domain/case_connection.dart';
import '../domain/case_status.dart';
import '../domain/true_crime_case.dart';
import 'case_search_service.dart';

/// Caso relacionado: el expediente vinculado y la etiqueta del vínculo.
typedef RelatedCase = ({TrueCrimeCase crimeCase, String relation});

/// Estadísticas agregadas del archivo para la cabecera.
typedef ArchiveStats = ({
  int documented,
  int unsolved,
  int yearsCovered,
  int sources,
});

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

/// Filtro por estado de investigación (null = todos).
final statusFilterProvider = StateProvider<CaseStatus?>((ref) => null);

/// Año máximo visible en la línea de tiempo del archivo.
final timelineYearProvider = StateProvider<int>((ref) => kTimelineMaxYear);

const int kTimelineMinYear = 1888;
const int kTimelineMaxYear = 2025;

final selectedCaseIdProvider = StateProvider<String?>((ref) => null);

/// Workspace visible en el shell principal: sala de situación o el
/// formulario de alta de casos de Iván (diseño #7).
enum Workspace { situationRoom, intake }

final workspaceProvider = StateProvider<Workspace>((ref) => Workspace.situationRoom);

/// Desbloqueo del workspace de intake, por sesión (no persiste al recargar).
final intakeUnlockedProvider = StateProvider<bool>((ref) => false);

final filteredCasesProvider = FutureProvider<List<TrueCrimeCase>>((ref) async {
  final search = ref.watch(caseSearchServiceProvider);
  final cases = await ref.watch(casesProvider.future);
  final activeCategory = ref.watch(activeCategoryProvider);
  final statusFilter = ref.watch(statusFilterProvider);
  final maxYear = ref.watch(timelineYearProvider);
  final query = ref.watch(searchQueryProvider);

  final preFiltered = cases.where((crimeCase) {
    if (activeCategory != null && crimeCase.category != activeCategory) {
      return false;
    }
    if (statusFilter != null && crimeCase.status != statusFilter) {
      return false;
    }
    if (crimeCase.year > maxYear) {
      return false;
    }
    return true;
  }).toList(growable: false);

  return search.search(preFiltered, query);
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

/// Capa relacional curada del archivo (conexiones entre casos).
final caseConnectionsProvider = Provider<List<CaseConnection>>((ref) {
  return kCaseConnections;
});

/// Casos relacionados con [caseId], con la etiqueta de cada vínculo.
final relatedCasesProvider = Provider.family<List<RelatedCase>, String>((
  ref,
  caseId,
) {
  final cases = ref.watch(casesProvider).value ?? const <TrueCrimeCase>[];
  final connections = ref.watch(caseConnectionsProvider);
  final byId = {for (final crimeCase in cases) crimeCase.id: crimeCase};

  final related = <RelatedCase>[];
  for (final connection in connections) {
    final otherId = connection.otherId(caseId);
    if (otherId == null) {
      continue;
    }
    final other = byId[otherId];
    if (other != null) {
      related.add((crimeCase: other, relation: connection.relation));
    }
  }
  return related;
});

/// Caso destacado de la semana ("EN EL FOCO"). Toma el de menor `featuredRank`.
final featuredCaseProvider = Provider<TrueCrimeCase?>((ref) {
  final cases = ref.watch(casesProvider).value ?? const <TrueCrimeCase>[];
  TrueCrimeCase? best;
  for (final crimeCase in cases) {
    if (crimeCase.featuredRank == null) {
      continue;
    }
    if (best == null || crimeCase.featuredRank! < best.featuredRank!) {
      best = crimeCase;
    }
  }
  return best;
});

/// Estadísticas del archivo mostradas en la cabecera.
final archiveStatsProvider = Provider<ArchiveStats>((ref) {
  final cases = ref.watch(casesProvider).value ?? const <TrueCrimeCase>[];
  if (cases.isEmpty) {
    return (documented: 0, unsolved: 0, yearsCovered: 0, sources: 0);
  }

  var unsolved = 0;
  var sources = 0;
  var minYear = cases.first.year;
  var maxYear = cases.first.year;
  for (final crimeCase in cases) {
    if (crimeCase.status == CaseStatus.open) {
      unsolved++;
    }
    sources += crimeCase.sources.length;
    if (crimeCase.year < minYear) minYear = crimeCase.year;
    if (crimeCase.year > maxYear) maxYear = crimeCase.year;
  }

  return (
    documented: cases.length,
    unsolved: unsolved,
    yearsCovered: maxYear - minYear,
    sources: sources,
  );
});
