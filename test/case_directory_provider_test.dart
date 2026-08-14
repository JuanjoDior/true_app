import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/application/cases_providers.dart';
import 'package:true_app/features/cases/data/cases_repository.dart';
import 'package:true_app/features/cases/domain/case_category.dart';
import 'package:true_app/features/cases/domain/case_status.dart';
import 'package:true_app/features/cases/domain/true_crime_case.dart';

/// El orden del directorio público [spec: published-case-directory].
///
/// Se deriva SÓLO de `casesProvider`. No carga nada por su cuenta: el catálogo
/// ya está en memoria cuando el mapa lo pintó, y una segunda lectura sería un
/// segundo origen de verdad que puede discrepar del primero.

TrueCrimeCase _crimeCase({
  required String slug,
  required int year,
  String? title,
  String? id,
}) {
  return TrueCrimeCase(
    id: id ?? slug,
    slug: slug,
    title: title ?? slug,
    category: CaseCategory.unsolved,
    country: 'España',
    countryCode: 'ES',
    regionOrCity: 'A Coruña',
    year: year,
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
  var loads = 0;

  @override
  Future<List<TrueCrimeCase>> getCases() async {
    loads++;
    return _cases;
  }
}

ProviderContainer _containerWith(CasesRepository repository) {
  final container = ProviderContainer(
    overrides: [casesRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  return container;
}

Future<List<String>> _slugsOf(ProviderContainer container) async {
  await container.read(casesProvider.future);
  return container
      .read(publishedDirectoryProvider)
      .value!
      .map((crimeCase) => crimeCase.slug)
      .toList(growable: false);
}

void main() {
  group('orden: año descendente', () {
    test('the most recent case comes first', () async {
      final container = _containerWith(
        _StubRepository([
          _crimeCase(slug: 'viejo', year: 1948),
          _crimeCase(slug: 'nuevo', year: 2001),
        ]),
      );

      expect(await _slugsOf(container), orderedEquals(['nuevo', 'viejo']));
    });

    test('the input order does not decide it', () async {
      // El mismo par al revés en la entrada. Sin ordenar de verdad, uno de los
      // dos tests pasaría por casualidad.
      final container = _containerWith(
        _StubRepository([
          _crimeCase(slug: 'nuevo', year: 2001),
          _crimeCase(slug: 'viejo', year: 1948),
        ]),
      );

      expect(await _slugsOf(container), orderedEquals(['nuevo', 'viejo']));
    });
  });

  group('desempates deterministas', () {
    test('same year falls back to title ascending', () async {
      final container = _containerWith(
        _StubRepository([
          _crimeCase(slug: 'b', year: 1974, title: 'Zorro'),
          _crimeCase(slug: 'a', year: 1974, title: 'Alba'),
        ]),
      );

      expect(await _slugsOf(container), orderedEquals(['a', 'b']));
    });

    test('same year and title falls back to slug ascending', () async {
      final container = _containerWith(
        _StubRepository([
          _crimeCase(slug: 'zeta', year: 1974, title: 'Igual'),
          _crimeCase(slug: 'alfa', year: 1974, title: 'Igual'),
        ]),
      );

      // Sin este último desempate el orden dependería del JSON y dos cargas
      // podrían listar lo mismo en distinto orden.
      expect(await _slugsOf(container), orderedEquals(['alfa', 'zeta']));
    });

    test('the tie-break does not override the year', () async {
      // 'Alba' iría primero por título, pero es más antiguo: el año manda.
      final container = _containerWith(
        _StubRepository([
          _crimeCase(slug: 'alba', year: 1948, title: 'Alba'),
          _crimeCase(slug: 'zorro', year: 2001, title: 'Zorro'),
        ]),
      );

      expect(await _slugsOf(container), orderedEquals(['zorro', 'alba']));
    });
  });

  group('todo el catálogo entra', () {
    test('every loaded case is listed', () async {
      final container = _containerWith(
        _StubRepository([
          _crimeCase(slug: 'a', year: 1990),
          _crimeCase(slug: 'b', year: 1991),
          _crimeCase(slug: 'c', year: 1992),
        ]),
      );

      expect(await _slugsOf(container), hasLength(3));
    });

    test('a legacy case with a differing id is listed too', () async {
      final container = _containerWith(
        _StubRepository([
          _crimeCase(slug: 'known-case', year: 1974, id: 'legacy-7'),
        ]),
      );

      expect(await _slugsOf(container), orderedEquals(['known-case']));
    });

    test('an empty catalog lists nothing without erroring', () async {
      final container = _containerWith(_StubRepository(const []));
      await container.read(casesProvider.future);

      expect(container.read(publishedDirectoryProvider).hasError, isFalse);
    });

    test('an empty catalog yields an empty list, not null', () async {
      final container = _containerWith(_StubRepository(const []));

      expect(await _slugsOf(container), isEmpty);
    });
  });

  group('reutiliza el catálogo, no lo recarga', () {
    test('reading the directory does not load the catalog again', () async {
      final repository = _StubRepository([_crimeCase(slug: 'a', year: 1990)]);
      final container = _containerWith(repository);
      await container.read(casesProvider.future);
      final before = repository.loads;

      container.read(publishedDirectoryProvider);

      expect(repository.loads, before);
    });

    test('it loads exactly once for map and directory together', () async {
      final repository = _StubRepository([_crimeCase(slug: 'a', year: 1990)]);
      final container = _containerWith(repository);

      await container.read(casesProvider.future);
      container.read(publishedDirectoryProvider);
      container.read(filteredCasesProvider);

      expect(repository.loads, 1);
    });
  });

  group('estados heredados del catálogo', () {
    test('it is loading before the catalog arrives', () {
      final container = _containerWith(
        _StubRepository([_crimeCase(slug: 'a', year: 1990)]),
      );

      expect(container.read(publishedDirectoryProvider).isLoading, isTrue);
    });

    test('a catalog failure surfaces as an error', () async {
      final container = _containerWith(_ThrowingRepository());
      await expectLater(
        container.read(casesProvider.future),
        throwsA(isA<StateError>()),
      );

      expect(container.read(publishedDirectoryProvider).hasError, isTrue);
    });
  });

  group('no toca el estado del mapa', () {
    test('the directory ignores the active filters', () async {
      final container = _containerWith(
        _StubRepository([
          _crimeCase(slug: 'a', year: 1990),
          _crimeCase(slug: 'b', year: 1991),
        ]),
      );
      await container.read(casesProvider.future);
      // Un filtro que en el mapa dejaría fuera casos: el directorio lista el
      // archivo completo, no lo que el mapa esté enseñando ahora mismo.
      container.read(searchQueryProvider.notifier).state = 'nada-coincide';

      expect(container.read(publishedDirectoryProvider).value, hasLength(2));
    });

    test('reading the directory does not clear the map selection', () async {
      final container = _containerWith(
        _StubRepository([_crimeCase(slug: 'a', year: 1990)]),
      );
      await container.read(casesProvider.future);
      container.read(selectedCaseIdProvider.notifier).state = 'a';

      container.read(publishedDirectoryProvider);

      expect(container.read(selectedCaseIdProvider), 'a');
    });
  });
}

class _ThrowingRepository implements CasesRepository {
  @override
  Future<List<TrueCrimeCase>> getCases() async =>
      throw StateError('el catálogo no se pudo leer');
}
