import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/app/true_crime_app.dart';
import 'package:true_app/app/navigation/app_navigation.dart';
import 'package:true_app/features/cases/presentation/case_directory.dart';
import 'package:true_app/core/config/map_config.dart';
import 'package:true_app/core/design/design.dart';
import 'package:true_app/features/cases/application/cases_providers.dart';
import 'package:true_app/features/cases/data/cases_repository.dart';
import 'package:true_app/features/cases/domain/case_category.dart';
import 'package:true_app/features/cases/domain/case_status.dart';
import 'package:true_app/features/cases/domain/true_crime_case.dart';
import 'package:true_app/features/cases/presentation/case_detail_page.dart';
import 'package:true_app/features/home/presentation/portada/portada_shell_keys.dart';

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
  CaseCategory category = CaseCategory.unsolved,
}) {
  return TrueCrimeCase(
    id: slug,
    slug: slug,
    title: title ?? slug,
    category: category,
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

/// Bombeo acotado: la portada nunca se queda quieta (carrusel y globo), así
/// que `pumpAndSettle` se agota en lugar de converger.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 450));
}

/// Por debajo de `DsBreakpoints.desktop` el acceso es la barra inferior; a
/// partir de ahí, el enlace de la barra superior.
const _mobile = Size(500, 900);
const _tablet = Size(1000, 900);
const _desktop = Size(1300, 900);

Key _archiveEntryKey(Size size) => size.width < DsBreakpoints.desktop
    ? PortadaShellKeys.bottomBarArchive
    : PortadaShellKeys.topBarArchive;

Future<ProviderContainer> _pumpHome(
  WidgetTester tester, {
  Size size = _desktop,
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
/// Se arrastra mientras el objetivo no exista **o** exista pero siga fuera de
/// pantalla, porque construido no es lo mismo que visible: `ListView.builder`
/// construye un poco más allá del borde (`cacheExtent`), así que parar en cuanto
/// aparece probaría que se llegó a construir, no que se pueda leer.
///
/// Aquí la ausencia SÍ significa algo, y es propio de este widget: el directorio
/// es un `ListView.builder` y de verdad no ha construido las filas lejanas. En
/// el expediente, que es un `SingleChildScrollView`, todo existe desde el primer
/// frame y `findsNothing` sería una aserción que no puede fallar.
Future<void> _dragUntilFound(
  WidgetTester tester,
  Finder target, {
  int maxDrags = 40,
}) async {
  bool offScreen() =>
      target.evaluate().isEmpty || tester.getRect(target).top >= _mobile.height;

  for (var i = 0; i < maxDrags && offScreen(); i++) {
    await tester.dragFrom(const Offset(250, 450), const Offset(0, -280));
    await tester.pump();
  }
}

/// Texto dentro de la hoja del directorio: la portada también muestra títulos.
Finder _inDirectory(String text) => find.descendant(
  of: find.byKey(const Key('case-directory')),
  matching: find.text(text),
);

Future<void> _openDirectory(WidgetTester tester) async {
  final size = tester.view.physicalSize / tester.view.devicePixelRatio;
  await tester.tap(find.byKey(_archiveEntryKey(size)));
  await _settle(tester);
}

class _RecordingNavigation implements AppNavigation {
  String? slug;
  @override
  void openCase(String slug) => this.slug = slug;
  @override
  void openMap() {}
  @override
  void showSituationRoom() {}
}

Future<ProviderContainer> _pumpFilteredDirectory(
  WidgetTester tester, {
  CaseCategory? category,
  int? decade,
  required CasesRepository repository,
  required _RecordingNavigation navigation,
}) async {
  final container = ProviderContainer(
    overrides: [casesRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showCaseDirectory(
                context,
                navigation,
                initialCategory: category,
                initialDecade: decade,
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Abrir'));
  await _settle(tester);
  return container;
}

void main() {
  group('filtros iniciales del archivo', () {
    final cases = [
      _crimeCase(
        slug: 'serial-1940',
        year: 1940,
        category: CaseCategory.serialKiller,
      ),
      _crimeCase(
        slug: 'serial-1949',
        year: 1949,
        category: CaseCategory.serialKiller,
      ),
      _crimeCase(slug: 'unsolved-1950', year: 1950),
      _crimeCase(slug: 'unsolved-1939', year: 1939),
    ];

    testWidgets(
      'category filters ordered cases and opens the selected slug without changing map filters',
      (tester) async {
        final navigation = _RecordingNavigation();
        final container = await _pumpFilteredDirectory(
          tester,
          category: CaseCategory.serialKiller,
          repository: _StubRepository(cases),
          navigation: navigation,
        );
        expect(_inDirectory('Asesinos en serie'), findsOneWidget);
        expect(_inDirectory('serial-1949'), findsOneWidget);
        expect(_inDirectory('serial-1940'), findsOneWidget);
        expect(_inDirectory('unsolved-1950'), findsNothing);
        expect(
          tester.getTopLeft(_inDirectory('serial-1949')).dy,
          lessThan(tester.getTopLeft(_inDirectory('serial-1940')).dy),
        );
        expect(container.read(searchQueryProvider), '');
        expect(container.read(statusFilterProvider), isNull);
        expect(container.read(timelineYearProvider), kTimelineMaxYear);
        await tester.tap(_inDirectory('serial-1940'));
        await _settle(tester);
        expect(navigation.slug, 'serial-1940');
        expect(find.byKey(const Key('case-directory')), findsNothing);
      },
    );

    testWidgets('decade includes both boundaries and identifies the filter', (
      tester,
    ) async {
      await _pumpFilteredDirectory(
        tester,
        decade: 1940,
        repository: _StubRepository(cases),
        navigation: _RecordingNavigation(),
      );
      expect(_inDirectory('Década de 1940'), findsOneWidget);
      expect(_inDirectory('serial-1940'), findsOneWidget);
      expect(_inDirectory('serial-1949'), findsOneWidget);
      expect(_inDirectory('unsolved-1939'), findsNothing);
      expect(_inDirectory('unsolved-1950'), findsNothing);
    });

    testWidgets('category and decade intersect when both are supplied', (
      tester,
    ) async {
      await _pumpFilteredDirectory(
        tester,
        category: CaseCategory.unsolved,
        decade: 1950,
        repository: _StubRepository(cases),
        navigation: _RecordingNavigation(),
      );
      expect(_inDirectory('Caso sin resolver'), findsOneWidget);
      expect(_inDirectory('Década de 1950'), findsOneWidget);
      expect(_inDirectory('unsolved-1950'), findsOneWidget);
      expect(_inDirectory('unsolved-1939'), findsNothing);
      expect(_inDirectory('serial-1949'), findsNothing);
    });

    testWidgets(
      'a filter with no matches distinguishes an empty result from an empty archive',
      (tester) async {
        await _pumpFilteredDirectory(
          tester,
          decade: 1900,
          repository: _StubRepository(cases),
          navigation: _RecordingNavigation(),
        );
        expect(_inDirectory('Década de 1900'), findsOneWidget);
        expect(
          _inDirectory('No hay expedientes para este filtro.'),
          findsOneWidget,
        );
        expect(find.byKey(const Key('case-directory-empty')), findsNothing);
      },
    );
  });
  group('el punto de entrada existe en cada ancho', () {
    for (final (name, size) in [
      ('mobile', _mobile),
      ('tablet below ${DsBreakpoints.desktop.toInt()}', _tablet),
      ('desktop', _desktop),
    ]) {
      testWidgets('$name exposes a directory entry point', (tester) async {
        await _pumpHome(
          tester,
          size: size,
          repository: _StubRepository(_catalog),
        );

        expect(find.byKey(_archiveEntryKey(size)), findsOneWidget);
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

      expect(_inDirectory('El caso reciente'), findsOneWidget);
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

      await tester.tap(_inDirectory('El caso antiguo'));
      await _settle(tester);

      expect(find.byType(CaseDetailPage), findsOneWidget);
    });

    testWidgets('it opens the case that was tapped', (tester) async {
      await _pumpHome(tester, repository: _StubRepository(_catalog));
      await _openDirectory(tester);

      await tester.tap(_inDirectory('El caso antiguo'));
      await _settle(tester);

      // Por slug: la dirección pública del caso, no su id interno.
      expect(
        find.descendant(
          of: find.byType(CaseDetailPage),
          matching: find.text('El caso antiguo'),
        ),
        findsWidgets,
      );
    });

    testWidgets('the directory closes when a case is opened', (tester) async {
      await _pumpHome(tester, repository: _StubRepository(_catalog));
      await _openDirectory(tester);

      await tester.tap(_inDirectory('El caso antiguo'));
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

    testWidgets('closing it leaves the portada where it was', (tester) async {
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

      await tester.tap(_inDirectory('El caso antiguo'));
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
      final last = _inDirectory('Caso 0');
      // Precondición honesta AQUÍ y sólo aquí: `ListView.builder` no ha
      // construido los elementos lejanos, así que su ausencia significa algo.
      // En un `SingleChildScrollView` esta misma línea sería una aserción que
      // no puede fallar.
      expect(last, findsNothing);

      await _dragUntilFound(tester, last);

      // Visible, no sólo construido.
      expect(tester.getRect(last).top, lessThan(_mobile.height));
    });
  });
}
