import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/app/true_crime_app.dart';
import 'package:true_app/core/config/map_config.dart';
import 'package:true_app/core/layout/breakpoints.dart';
import 'package:true_app/features/cases/application/cases_providers.dart';
import 'package:true_app/features/cases/data/cases_repository.dart';
import 'package:true_app/features/cases/domain/case_category.dart';
import 'package:true_app/features/cases/domain/case_status.dart';
import 'package:true_app/features/cases/domain/true_crime_case.dart';
import 'package:true_app/features/cases/presentation/case_detail_page.dart';

/// El directorio público de expedientes [spec: published-case-directory].
///
/// Se monta la aplicación ENTERA porque lo que se prueba sólo existe en la
/// composición: que el punto de entrada sea alcanzable en cada topología y que
/// abrir un caso desde aquí navegue de verdad. Fue un test así el que descubrió
/// que un enlace directo reventaba el mapa en la Unit 7.

TrueCrimeCase _crimeCase({
  required String slug,
  required int year,
  String? title,
}) {
  return TrueCrimeCase(
    id: slug,
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
  const _StubRepository(this._cases);

  final List<TrueCrimeCase> _cases;

  @override
  Future<List<TrueCrimeCase>> getCases() async => _cases;
}

class _FailingRepository implements CasesRepository {
  const _FailingRepository();

  @override
  Future<List<TrueCrimeCase>> getCases() async =>
      throw StateError('el catálogo no se pudo leer');
}

final _catalog = [
  _crimeCase(slug: 'reciente', year: 2001, title: 'El caso reciente'),
  _crimeCase(slug: 'antiguo', year: 1948, title: 'El caso antiguo'),
];

/// Bombeo acotado: la Sala de Situación nunca se queda quieta, así que
/// `pumpAndSettle` se agota en lugar de converger.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 450));
}

/// Las tres topologías reales del diseño, no dos.
const _mobile = Size(500, 900);
const _desktopNoRail = Size(1000, 900);
const _desktopWithRail = Size(1300, 900);

Future<ProviderContainer> _pumpHome(
  WidgetTester tester, {
  Size size = _desktopWithRail,
  CasesRepository repository = const _StubRepository([]),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [casesRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const TrueCrimeApp(),
    ),
  );
  await _settle(tester);
  return container;
}

final _longArchive = [
  for (var i = 0; i < 60; i++)
    _crimeCase(slug: 'caso-$i', year: 1900 + i, title: 'Caso $i'),
];

/// Arrastra con un gesto REAL hasta que [target] aparece.
///
/// **Nunca `jumpTo` ni `scrollUntilVisible`.** El primero llama a `forcePixels`
/// y el segundo mueve con `Scrollable.ensureVisible`: los dos se saltan la
/// física y pasan igual contra un `NeverScrollableScrollPhysics`. Lo que
/// demuestran es que el contenido existe, no que se pueda alcanzar. La spec lo
/// declara inadmisible por escrito, y con razón.
///
/// El bucle aquí sí es legítimo — lo que estaba mal en `scrollUntilVisible` no
/// era iterar, era de dónde salía el movimiento. Aquí sale de `dragFrom`, que
/// pasa por la física como el dedo de una persona.
///
/// La condición es de EXISTENCIA y no de posición porque el directorio usa
/// `ListView.builder`: los elementos lejanos no están construidos todavía. En
/// el expediente, que es un `SingleChildScrollView`, la condición correcta es
/// la contraria — allí todo se construye de golpe y hay que mirar la posición.
Future<void> _dragUntilFound(
  WidgetTester tester,
  Finder target, {
  int maxDrags = 40,
}) async {
  for (var i = 0; i < maxDrags && target.evaluate().isEmpty; i++) {
    await tester.dragFrom(const Offset(250, 450), const Offset(0, -280));
    await tester.pump();
  }
}

Future<void> _openDirectory(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('open-case-directory')));
  await _settle(tester);
}

void main() {
  group('el punto de entrada existe en las tres topologías', () {
    // El rail sólo aparece a partir de 1100, así que un directorio que
    // dependiera de él sería inalcanzable en dos de las tres.
    for (final (name, size) in [
      ('mobile below ${Breakpoints.sidePanel.toInt()}', _mobile),
      (
        'desktop without rail below ${Breakpoints.navRail.toInt()}',
        _desktopNoRail,
      ),
      ('desktop with rail', _desktopWithRail),
    ]) {
      testWidgets('$name exposes a directory entry point', (tester) async {
        await _pumpHome(
          tester,
          size: size,
          repository: _StubRepository(_catalog),
        );

        expect(find.byKey(const Key('open-case-directory')), findsOneWidget);
      });

      testWidgets('$name can open the directory', (tester) async {
        await _pumpHome(
          tester,
          size: size,
          repository: _StubRepository(_catalog),
        );

        await _openDirectory(tester);

        expect(find.byKey(const Key('case-directory')), findsOneWidget);
      });
    }
  });

  group('lo que lista', () {
    testWidgets('it lists the published cases', (tester) async {
      await _pumpHome(tester, repository: _StubRepository(_catalog));

      await _openDirectory(tester);

      expect(find.text('El caso reciente'), findsOneWidget);
    });

    testWidgets('it lists them most recent first', (tester) async {
      await _pumpHome(tester, repository: _StubRepository(_catalog));
      await _openDirectory(tester);

      final directory = find.byKey(const Key('case-directory'));
      final titles = tester
          .widgetList<Text>(
            find.descendant(of: directory, matching: find.byType(Text)),
          )
          .map((text) => text.data)
          .whereType<String>()
          .where({'El caso reciente', 'El caso antiguo'}.contains);

      expect(
        titles,
        orderedEquals(const ['El caso reciente', 'El caso antiguo']),
      );
    });

    testWidgets('an empty archive says so instead of showing a blank sheet', (
      tester,
    ) async {
      await _pumpHome(tester, repository: const _StubRepository([]));

      await _openDirectory(tester);

      expect(find.byKey(const Key('case-directory-empty')), findsOneWidget);
    });

    testWidgets('a broken catalog says so', (tester) async {
      await _pumpHome(tester, repository: const _FailingRepository());

      await _openDirectory(tester);

      expect(find.byKey(const Key('case-directory-error')), findsOneWidget);
    });

    testWidgets('a broken catalog does not claim the archive is empty', (
      tester,
    ) async {
      await _pumpHome(tester, repository: const _FailingRepository());

      await _openDirectory(tester);

      expect(find.byKey(const Key('case-directory-empty')), findsNothing);
    });
  });

  group('navegar y cerrar', () {
    testWidgets('tapping a case opens its detail page', (tester) async {
      await _pumpHome(tester, repository: _StubRepository(_catalog));
      await _openDirectory(tester);

      await tester.tap(find.text('El caso antiguo'));
      await _settle(tester);

      expect(find.byType(CaseDetailPage), findsOneWidget);
    });

    testWidgets('it opens the case that was tapped', (tester) async {
      await _pumpHome(tester, repository: _StubRepository(_catalog));
      await _openDirectory(tester);

      await tester.tap(find.text('El caso antiguo'));
      await _settle(tester);

      // Por slug: la dirección pública del caso, no su id interno.
      expect(find.text('El caso antiguo'), findsOneWidget);
    });

    testWidgets('the directory closes when a case is opened', (tester) async {
      await _pumpHome(tester, repository: _StubRepository(_catalog));
      await _openDirectory(tester);

      await tester.tap(find.text('El caso antiguo'));
      await _settle(tester);

      expect(find.byKey(const Key('case-directory')), findsNothing);
    });

    testWidgets('it can be closed without opening anything', (tester) async {
      await _pumpHome(tester, repository: _StubRepository(_catalog));
      await _openDirectory(tester);

      await tester.tap(find.byKey(const Key('case-directory-close')));
      await _settle(tester);

      expect(find.byKey(const Key('case-directory')), findsNothing);
    });

    testWidgets('closing it leaves the Situation Room where it was', (
      tester,
    ) async {
      await _pumpHome(tester, repository: _StubRepository(_catalog));
      await _openDirectory(tester);

      await tester.tap(find.byKey(const Key('case-directory-close')));
      await _settle(tester);

      expect(find.byType(CaseDetailPage), findsNothing);
    });
  });

  group('el mapa se queda como estaba', () {
    testWidgets('opening the directory does not change the map selection', (
      tester,
    ) async {
      final container = await _pumpHome(
        tester,
        repository: _StubRepository(_catalog),
      );

      await _openDirectory(tester);

      expect(container.read(selectedCaseIdProvider), isNull);
    });

    testWidgets('opening the directory does not change the search filter', (
      tester,
    ) async {
      final container = await _pumpHome(
        tester,
        repository: _StubRepository(_catalog),
      );
      final before = container.read(searchQueryProvider);

      await _openDirectory(tester);

      expect(container.read(searchQueryProvider), before);
    });

    testWidgets('opening a case from the directory does not select it on the '
        'map', (tester) async {
      final container = await _pumpHome(
        tester,
        repository: _StubRepository(_catalog),
      );
      await _openDirectory(tester);

      await tester.tap(find.text('El caso antiguo'));
      await _settle(tester);

      // La ruta y la selección del mapa son estados separados [diseño §7.4].
      expect(container.read(selectedCaseIdProvider), isNull);
    });

    testWidgets('opening the directory does not bump the recenter tick', (
      tester,
    ) async {
      final container = await _pumpHome(
        tester,
        repository: _StubRepository(_catalog),
      );

      await _openDirectory(tester);

      expect(container.read(mapRecenterTickProvider), 0);
    });
  });

  group('lectura de una lista larga', () {
    testWidgets('a long archive scrolls without overflowing', (tester) async {
      await _pumpHome(
        tester,
        size: _mobile,
        repository: _StubRepository([
          for (var i = 0; i < 60; i++)
            _crimeCase(slug: 'caso-$i', year: 1900 + i, title: 'Caso $i'),
        ]),
      );

      await _openDirectory(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('a long archive really has something to scroll', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        size: _mobile,
        repository: _StubRepository(_longArchive),
      );
      await _openDirectory(tester);

      final position = tester
          .state<ScrollableState>(
            find.descendant(
              of: find.byKey(const Key('case-directory')),
              matching: find.byType(Scrollable),
            ),
          )
          .position;

      // Precondición de no-vacuidad: sin nada que desplazar, "se puede
      // desplazar" no significaría nada. Pero por sí sola tampoco prueba que se
      // ALCANCE nada — eso lo hace el test de abajo, arrastrando.
      expect(position.maxScrollExtent, greaterThan(0));
    });

    testWidgets('dragging reaches a case near the end of a long archive', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        size: _mobile,
        repository: _StubRepository(_longArchive),
      );
      await _openDirectory(tester);

      // El más antiguo: con orden descendente por año, el último de la lista.
      final last = find.text('Caso 0');
      // Precondición honesta AQUÍ y sólo aquí: `ListView.builder` no ha
      // construido los elementos lejanos, así que su ausencia significa algo.
      // En un `SingleChildScrollView` esta misma línea sería una aserción que
      // no puede fallar.
      expect(last, findsNothing);

      await _dragUntilFound(tester, last);

      expect(last, findsOneWidget);
    });
  });
}
