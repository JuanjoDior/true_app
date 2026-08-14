import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/application/cases_providers.dart';
import 'package:true_app/features/cases/data/cases_repository.dart';
import 'package:true_app/features/cases/domain/case_category.dart';
import 'package:true_app/features/cases/domain/case_status.dart';
import 'package:true_app/features/cases/domain/true_crime_case.dart';

/// Buscar un caso publicado por su slug [spec: case-publication-route].
///
/// **El fixture tiene `id != slug` a propósito y eso NO es cosmética.** Los
/// quince casos del catálogo real tienen `id == slug`, así que con un caso
/// real o exportado un test no puede distinguir "busca por slug" de "busca por
/// id": las dos implementaciones pasarían y el test no probaría nada. Con
/// `id: 'legacy-7'` y `slug: 'known-case'`, sólo una pasa.

TrueCrimeCase _crimeCase({required String id, required String slug}) {
  return TrueCrimeCase(
    id: id,
    slug: slug,
    title: 'El caso del faro',
    category: CaseCategory.unsolved,
    country: 'España',
    countryCode: 'ES',
    regionOrCity: 'A Coruña',
    year: 1974,
    latitude: 43.39,
    longitude: -8.41,
    summary: 'Un farero desaparece durante una noche de temporal.',
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

class _FailingRepository implements CasesRepository {
  @override
  Future<List<TrueCrimeCase>> getCases() async =>
      throw StateError('el catálogo no se pudo leer');
}

ProviderContainer _containerWith(CasesRepository repository) {
  final container = ProviderContainer(
    overrides: [casesRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  return container;
}

final _catalog = [
  _crimeCase(id: 'legacy-7', slug: 'known-case'),
  _crimeCase(id: 'otro', slug: 'somerton'),
];

void main() {
  group('identidad: el slug no es el id', () {
    test('a known slug resolves its case', () async {
      final container = _containerWith(_StubRepository(_catalog));
      await container.read(casesProvider.future);

      expect(
        container.read(caseBySlugProvider('known-case')).value?.id,
        'legacy-7',
      );
    });

    test('the id of that same case does NOT resolve', () async {
      // Éste es el test que hace honesto al de arriba. Una búsqueda por id
      // pasaría el primero y moriría aquí.
      final container = _containerWith(_StubRepository(_catalog));
      await container.read(casesProvider.future);

      expect(container.read(caseBySlugProvider('legacy-7')).value, isNull);
    });

    test('an unknown slug resolves to null, not to a fallback case', () async {
      final container = _containerWith(_StubRepository(_catalog));
      await container.read(casesProvider.future);

      expect(container.read(caseBySlugProvider('no-existe')).value, isNull);
    });

    test('an unknown slug is a value, not an error', () async {
      // "No hay caso con ese slug" es una respuesta, no un fallo del catálogo.
      // La página distingue las dos cosas y enseña pantallas distintas.
      final container = _containerWith(_StubRepository(_catalog));
      await container.read(casesProvider.future);

      expect(container.read(caseBySlugProvider('no-existe')).hasError, isFalse);
    });

    test('each slug resolves its own case', () async {
      final container = _containerWith(_StubRepository(_catalog));
      await container.read(casesProvider.future);

      expect(container.read(caseBySlugProvider('somerton')).value?.id, 'otro');
    });
  });

  group('estados del catálogo', () {
    test('it is loading before the catalog arrives', () {
      final container = _containerWith(_StubRepository(_catalog));

      expect(
        container.read(caseBySlugProvider('known-case')).isLoading,
        isTrue,
      );
    });

    test('it stops loading once the catalog arrives', () async {
      final container = _containerWith(_StubRepository(_catalog));
      await container.read(casesProvider.future);

      expect(
        container.read(caseBySlugProvider('known-case')).isLoading,
        isFalse,
      );
    });

    test('a catalog failure surfaces as an error', () async {
      final container = _containerWith(_FailingRepository());
      await expectLater(
        container.read(casesProvider.future),
        throwsA(isA<StateError>()),
      );

      expect(container.read(caseBySlugProvider('known-case')).hasError, isTrue);
    });

    test('a catalog failure is not reported as a missing case', () async {
      // Sin esta distinción, un catálogo caído se vería como "caso no
      // encontrado" y quien comparte el enlace pensaría que borramos el caso.
      final container = _containerWith(_FailingRepository());
      await expectLater(
        container.read(casesProvider.future),
        throwsA(isA<StateError>()),
      );

      expect(
        container.read(caseBySlugProvider('known-case')).hasValue,
        isFalse,
      );
    });

    test('an empty catalog resolves nothing without erroring', () async {
      final container = _containerWith(_StubRepository(const []));
      await container.read(casesProvider.future);

      expect(container.read(caseBySlugProvider('known-case')).value, isNull);
    });
  });

  group('sin dependencia del mapa', () {
    test('it resolves without any map selection', () async {
      final container = _containerWith(_StubRepository(_catalog));
      await container.read(casesProvider.future);

      // `selectedCaseIdProvider` sigue en su valor inicial: el expediente
      // público no necesita que el mapa haya seleccionado nada primero.
      expect(container.read(selectedCaseIdProvider), isNull);
    });

    test('resolving a slug does not select anything on the map', () async {
      final container = _containerWith(_StubRepository(_catalog));
      await container.read(casesProvider.future);

      container.read(caseBySlugProvider('known-case'));

      expect(container.read(selectedCaseIdProvider), isNull);
    });

    test('a map selection does not change what a slug resolves', () async {
      final container = _containerWith(_StubRepository(_catalog));
      await container.read(casesProvider.future);
      container.read(selectedCaseIdProvider.notifier).state = 'otro';

      expect(
        container.read(caseBySlugProvider('known-case')).value?.id,
        'legacy-7',
      );
    });
  });
}
