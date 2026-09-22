import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/application/cases_providers.dart';
import 'package:true_app/features/cases/data/cases_repository.dart';
import 'package:true_app/features/cases/domain/case_category.dart';
import 'package:true_app/features/cases/domain/case_status.dart';
import 'package:true_app/features/cases/domain/true_crime_case.dart';

/// `publishedCatalogPayloadProvider` expone el texto crudo del catálogo
/// publicado, y `publishedSlugsProvider` deriva los slugs ya publicados a
/// partir de `casesProvider` [design.md §9].

TrueCrimeCase _crimeCase({required String slug}) {
  return TrueCrimeCase(
    id: slug,
    slug: slug,
    title: slug,
    category: CaseCategory.unsolved,
    country: 'España',
    countryCode: 'ES',
    regionOrCity: 'A Coruña',
    year: 1974,
    latitude: 43.39,
    longitude: -8.41,
    summary: 'Resumen.',
    tags: const <String>[],
    sources: const [],
    status: CaseStatus.open,
  );
}

class _StubRepository implements CasesRepository {
  _StubRepository(this._cases);

  final List<TrueCrimeCase> _cases;

  @override
  Future<List<TrueCrimeCase>> getCases() async => _cases;
}

void main() {
  group('publishedCatalogPayloadProvider', () {
    test('exposes PublishedCatalogSource.loadPayload() through the provider', () async {
      const payload = '[{"slug":"el-caso"}]';
      final container = ProviderContainer(
        overrides: [publishedCatalogPayloadProvider.overrideWith((ref) async => payload)],
      );
      addTearDown(container.dispose);

      final result = await container.read(publishedCatalogPayloadProvider.future);

      expect(result, payload);
    });

    test('is overridable independently of casesRepositoryProvider', () async {
      // Prueba de triangulación: un payload DISTINTO en el override demuestra
      // que el provider devuelve lo que el override dice, no un valor fijo.
      const otherPayload = '[{"slug":"otro-caso"},{"slug":"tercero"}]';
      final container = ProviderContainer(
        overrides: [
          publishedCatalogPayloadProvider.overrideWith((ref) async => otherPayload),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(publishedCatalogPayloadProvider.future);

      expect(result, otherPayload);
    });
  });

  group('publishedSlugsProvider', () {
    test('derives the set of slugs from casesProvider', () async {
      final container = ProviderContainer(
        overrides: [
          casesRepositoryProvider.overrideWithValue(
            _StubRepository([
              _crimeCase(slug: 'el-caso'),
              _crimeCase(slug: 'otro-caso'),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(casesProvider.future);

      final slugs = container.read(publishedSlugsProvider);

      expect(slugs, {'el-caso', 'otro-caso'});
    });

    test('an empty catalog yields an empty slug set, not an error', () async {
      final container = ProviderContainer(
        overrides: [
          casesRepositoryProvider.overrideWithValue(_StubRepository(const [])),
        ],
      );
      addTearDown(container.dispose);
      await container.read(casesProvider.future);

      expect(container.read(publishedSlugsProvider), isEmpty);
    });
  });
}
