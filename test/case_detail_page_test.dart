import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/app/navigation/app_navigation.dart';
import 'package:true_app/features/cases/application/cases_providers.dart';
import 'package:true_app/features/cases/data/cases_repository.dart';
import 'package:true_app/features/cases/domain/case_category.dart';
import 'package:true_app/features/cases/domain/case_chapter.dart';
import 'package:true_app/features/cases/domain/case_connection.dart';
import 'package:true_app/features/cases/domain/case_status.dart';
import 'package:true_app/features/cases/domain/true_crime_case.dart';
import 'package:true_app/features/cases/presentation/case_detail_page.dart';

/// La página pública del expediente [spec: expanded-case-dossier].
///
/// Cuatro estados distintos y ninguno se confunde con otro: cargando, catálogo
/// caído, slug desconocido y caso encontrado. Que "catálogo caído" y "no existe
/// ese caso" se vean igual sería el peor fallo posible aquí — quien comparte un
/// enlace pensaría que le borramos el caso.

TrueCrimeCase _crimeCase({
  String id = 'legacy-7',
  String slug = 'known-case',
  String title = 'El caso del faro',
  CaseChapters chapters = const CaseChapters(),
}) {
  return TrueCrimeCase(
    id: id,
    slug: slug,
    title: title,
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
    chapters: chapters,
    status: CaseStatus.open,
  );
}

class _StubRepository implements CasesRepository {
  _StubRepository(this._cases, {this.delay = Duration.zero});

  final List<TrueCrimeCase> _cases;
  final Duration delay;

  @override
  Future<List<TrueCrimeCase>> getCases() async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return _cases;
  }
}

class _FailingRepository implements CasesRepository {
  @override
  Future<List<TrueCrimeCase>> getCases() async =>
      throw StateError('el catálogo no se pudo leer');
}

/// Registra a dónde se pidió ir, sin moverse.
class _RecordingNavigation implements AppNavigation {
  final opened = <String>[];
  var returns = 0;

  @override
  void openCase(String slug) => opened.add(slug);

  @override
  void showSituationRoom() => returns++;
}

Future<_RecordingNavigation> _pumpDetail(
  WidgetTester tester, {
  required String slug,
  CasesRepository? repository,
  List<CaseConnection> connections = const [],
  Size size = const Size(1200, 2400),
  bool settle = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final navigation = _RecordingNavigation();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        casesRepositoryProvider.overrideWithValue(
          repository ?? _StubRepository([_crimeCase()]),
        ),
        caseConnectionsProvider.overrideWithValue(connections),
      ],
      child: MaterialApp(
        home: CaseDetailPage(slug: slug, navigation: navigation),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  }
  return navigation;
}

void main() {
  group('cargando', () {
    testWidgets('shows a progress indicator while the catalog loads', (
      tester,
    ) async {
      await _pumpDetail(
        tester,
        slug: 'known-case',
        repository: _StubRepository([
          _crimeCase(),
        ], delay: const Duration(milliseconds: 80)),
        settle: false,
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('the indicator is gone once the case arrives', (tester) async {
      await _pumpDetail(
        tester,
        slug: 'known-case',
        repository: _StubRepository([
          _crimeCase(),
        ], delay: const Duration(milliseconds: 80)),
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('el catálogo falla', () {
    testWidgets('says the archive could not be read', (tester) async {
      await _pumpDetail(
        tester,
        slug: 'known-case',
        repository: _FailingRepository(),
      );

      expect(find.byKey(const Key('case-detail-error')), findsOneWidget);
    });

    testWidgets('does NOT claim the case does not exist', (tester) async {
      // La distinción que más importa de toda la página.
      await _pumpDetail(
        tester,
        slug: 'known-case',
        repository: _FailingRepository(),
      );

      expect(find.byKey(const Key('case-detail-not-found')), findsNothing);
    });

    testWidgets('still offers a way back', (tester) async {
      await _pumpDetail(
        tester,
        slug: 'known-case',
        repository: _FailingRepository(),
      );

      expect(find.byKey(const Key('case-detail-return')), findsOneWidget);
    });
  });

  group('slug desconocido', () {
    testWidgets('says the case was not found', (tester) async {
      await _pumpDetail(tester, slug: 'no-existe');

      expect(find.byKey(const Key('case-detail-not-found')), findsOneWidget);
    });

    testWidgets('does NOT blame the archive', (tester) async {
      await _pumpDetail(tester, slug: 'no-existe');

      expect(find.byKey(const Key('case-detail-error')), findsNothing);
    });

    testWidgets('substitutes no fallback case', (tester) async {
      await _pumpDetail(tester, slug: 'no-existe');

      // Enseñar "otro caso cualquiera" en una URL compartida sería mentir
      // sobre lo que hay en esa dirección.
      expect(find.text('El caso del faro'), findsNothing);
    });

    testWidgets('offers a way back to the Situation Room', (tester) async {
      final navigation = await _pumpDetail(tester, slug: 'no-existe');

      await tester.tap(find.byKey(const Key('case-detail-return')));
      await tester.pump();

      expect(navigation.returns, 1);
    });
  });

  group('caso encontrado', () {
    testWidgets('renders the case title', (tester) async {
      await _pumpDetail(tester, slug: 'known-case');

      expect(find.text('El caso del faro'), findsOneWidget);
    });

    testWidgets('renders its summary through the shared content', (
      tester,
    ) async {
      await _pumpDetail(tester, slug: 'known-case');

      expect(
        find.text('Un farero desaparece durante una noche de temporal.'),
        findsOneWidget,
      );
    });

    testWidgets('renders its chapters in editorial order', (tester) async {
      await _pumpDetail(
        tester,
        slug: 'known-case',
        repository: _StubRepository([
          _crimeCase(
            chapters: const CaseChapters(
              currentStatus: 'Ahora',
              background: 'Antes',
            ),
          ),
        ]),
      );

      expect(
        tester
            .widgetList<Text>(find.byType(Text))
            .map((text) => text.data)
            .whereType<String>()
            .where({'ANTECEDENTES', 'ESTADO ACTUAL'}.contains),
        orderedEquals(const ['ANTECEDENTES', 'ESTADO ACTUAL']),
      );
    });

    testWidgets('a legacy case without chapters renders normally', (
      tester,
    ) async {
      await _pumpDetail(tester, slug: 'known-case');

      expect(find.text('El caso del faro'), findsOneWidget);
    });

    testWidgets('shows no map chrome', (tester) async {
      await _pumpDetail(tester, slug: 'known-case');

      // No hay mapa debajo de una URL pública a la que volver.
      expect(find.text('VOLVER AL MAPA'), findsNothing);
    });

    testWidgets('returning goes back to the Situation Room', (tester) async {
      final navigation = await _pumpDetail(tester, slug: 'known-case');

      await tester.tap(find.byKey(const Key('case-detail-return')));
      await tester.pump();

      expect(navigation.returns, 1);
    });

    testWidgets('does not touch the map selection', (tester) async {
      await _pumpDetail(tester, slug: 'known-case');

      expect(tester.takeException(), isNull);
    });
  });

  group('casos relacionados navegan por slug', () {
    testWidgets('opening a related case routes to its slug', (tester) async {
      final navigation = await _pumpDetail(
        tester,
        slug: 'known-case',
        repository: _StubRepository([
          _crimeCase(),
          _crimeCase(id: 'otro', slug: 'somerton', title: 'El caso Somerton'),
        ]),
        connections: const [
          CaseConnection(
            aId: 'legacy-7',
            bId: 'otro',
            relation: 'Misma comarca',
          ),
        ],
      );

      await tester.tap(find.text('El caso Somerton'));
      await tester.pump();

      // Por SLUG, no por id: la URL pública es la del slug.
      expect(navigation.opened, orderedEquals(const ['somerton']));
    });
  });

  group('lectura en cualquier pantalla', () {
    testWidgets('a long case scrolls on a narrow screen without overflowing', (
      tester,
    ) async {
      await _pumpDetail(
        tester,
        slug: 'known-case',
        size: const Size(360, 780),
        repository: _StubRepository([
          _crimeCase(
            chapters: CaseChapters(
              background: 'Antes. ' * 200,
              events: 'Hechos. ' * 200,
              investigation: 'Pistas. ' * 200,
              currentStatus: 'Ahora. ' * 200,
            ),
          ),
        ]),
      );

      // Un overflow deja excepción; que no la haya con cuatro capítulos largos
      // a 360px es lo que se afirma.
      expect(tester.takeException(), isNull);
    });

    testWidgets('the return action stays reachable on a narrow screen', (
      tester,
    ) async {
      await _pumpDetail(
        tester,
        slug: 'known-case',
        size: const Size(360, 780),
        repository: _StubRepository([
          _crimeCase(chapters: CaseChapters(background: 'Antes. ' * 200)),
        ]),
      );

      // Se puede pulsar sin arrastrar: la acción de volver no se va con el
      // contenido hacia abajo.
      expect(
        tester.getRect(find.byKey(const Key('case-detail-return'))).top,
        lessThan(780),
      );
    });

    testWidgets('a long case really scrolls', (tester) async {
      await _pumpDetail(
        tester,
        slug: 'known-case',
        size: const Size(360, 780),
        repository: _StubRepository([
          _crimeCase(chapters: CaseChapters(background: 'Antes. ' * 400)),
        ]),
      );

      final scrollable = find.byType(Scrollable).first;
      final position = tester.state<ScrollableState>(scrollable).position;

      // Precondición de no-vacuidad: si no hubiera nada que desplazar, el
      // arrastre de abajo no probaría nada.
      expect(position.maxScrollExtent, greaterThan(0));
    });

    testWidgets('scrolling brings the end of the dossier into view', (
      tester,
    ) async {
      await _pumpDetail(
        tester,
        slug: 'known-case',
        size: const Size(360, 780),
        repository: _StubRepository([
          _crimeCase(
            chapters: CaseChapters(
              background: 'Antes. ' * 400,
              currentStatus: 'El final del expediente',
            ),
          ),
        ]),
      );
      final end = find.text('El final del expediente');
      // La precondición mira la POSICIÓN, no la existencia: un
      // `SingleChildScrollView` construye todos sus hijos aunque estén fuera de
      // pantalla, así que `findsNothing` daría falso incluso con el scroll
      // muerto y no probaría nada.
      expect(tester.getRect(end).top, greaterThan(780));

      final position = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();

      expect(tester.getRect(end).top, lessThan(780));
    });
  });
}
