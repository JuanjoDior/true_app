import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/config/map_config.dart';
import 'package:true_app/features/cases/application/case_draft_providers.dart';
import 'package:true_app/features/cases/application/cases_providers.dart';
import 'package:true_app/features/cases/data/case_drafts_store.dart';
import 'package:true_app/features/cases/domain/case_category.dart';
import 'package:true_app/features/cases/domain/case_connection.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';
import 'package:true_app/features/cases/domain/case_photo.dart';
import 'package:true_app/features/cases/domain/case_source.dart';
import 'package:true_app/features/cases/domain/case_status.dart';
import 'package:true_app/features/cases/domain/case_timeline_event.dart';
import 'package:true_app/features/cases/domain/true_crime_case.dart';
import 'package:true_app/features/cases/presentation/intake/intake_preview_panel.dart';
import 'package:true_app/features/home/presentation/widgets/situation/case_dossier_panel.dart';

import 'test_support/sample_cases.dart';

// CARACTERIZACIÓN, no TDD. Estos tests nacen EN VERDE y describen lo que el
// expediente hace HOY, antes de que la Unit 4a-2 mueva los nueve subwidgets a
// `CaseDossierContent`. No prueban nada nuevo: son la red que avisa si el
// traslado cambia algo por el camino [tarea 4.1].
//
// Por eso miran comportamiento observable — etiquetas, orden, omisiones,
// acciones — y nunca tipos privados: un test que nombrase `_Header` se
// rompería con el traslado aunque el traslado fuese correcto, que es
// exactamente lo contrario de lo que se le pide a una caracterización.

/// Las cuatro secciones condicionales, en versalitas como las pinta
/// `SituationSectionLabel`.
const _photos = 'FOTOGRAFÍAS';
const _timeline = 'CRONOLOGÍA VERIFICADA';
const _sources = 'FUENTES CITADAS';
const _related = 'CASOS RELACIONADOS';
const _sectionLabels = {_photos, _timeline, _sources, _related};

TrueCrimeCase _dossierCase({
  String id = 'caso-faro',
  String title = 'El caso del faro',
  List<CasePhoto> photos = const [],
  List<CaseTimelineEvent> timeline = const [],
  List<CaseSource> sources = const [],
  String? victim,
  String? statusLabel,
}) {
  return TrueCrimeCase(
    id: id,
    slug: id,
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
    sources: sources,
    photos: photos,
    timeline: timeline,
    victim: victim,
    status: CaseStatus.open,
    statusLabel: statusLabel,
  );
}

/// Monta el expediente con un catálogo y unas conexiones deterministas.
///
/// Devuelve el contenedor para poder leer los providers que el panel escribe:
/// la selección del mapa y el tic de recentrado son la mitad de su contrato.
Future<ProviderContainer> _pumpDossier(
  WidgetTester tester,
  TrueCrimeCase crimeCase, {
  List<TrueCrimeCase> catalog = const [],
  List<CaseConnection> connections = const [],
}) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      casesRepositoryProvider.overrideWithValue(FakeCasesRepository(catalog)),
      caseConnectionsProvider.overrideWithValue(connections),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(body: CaseDossierPanel(crimeCase: crimeCase)),
      ),
    ),
  );
  await tester.pump();
  return container;
}

/// Las etiquetas de sección presentes, en el orden en que las pinta el árbol.
List<String> _renderedSections(WidgetTester tester) {
  return tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data)
      .whereType<String>()
      .where(_sectionLabels.contains)
      .toList(growable: false);
}

void main() {
  group('secciones condicionales', () {
    testWidgets('a case with everything renders the four sections in order', (
      tester,
    ) async {
      final other = _dossierCase(id: 'caso-mina', title: 'El caso de la mina');
      await _pumpDossier(
        tester,
        _dossierCase(
          photos: const [CasePhoto(url: 'https://example.com/faro.jpg')],
          timeline: const [
            CaseTimelineEvent(
              title: 'Desaparición',
              date: '1974',
              kind: CaseTimelineKind.initial,
            ),
          ],
          sources: const [
            CaseSource(
              id: 's1',
              title: 'Crónica del temporal',
              url: 'https://elpais.com/articulo',
              kind: CaseSourceKind.investigation,
            ),
          ],
        ),
        catalog: [other],
        connections: const [
          CaseConnection(
            aId: 'caso-faro',
            bId: 'caso-mina',
            relation: 'Misma comarca',
          ),
        ],
      );

      expect(
        _renderedSections(tester),
        orderedEquals(const [_photos, _timeline, _sources, _related]),
      );
    });

    testWidgets('a case with nothing renders none of them', (tester) async {
      await _pumpDossier(tester, _dossierCase());

      expect(_renderedSections(tester), isEmpty);
    });

    testWidgets('only the section whose data exists is rendered', (
      tester,
    ) async {
      // El caso anterior deja el conjunto vacío, así que por sí solo no
      // distingue "omite lo vacío" de "no pinta nada nunca". Éste sí.
      await _pumpDossier(
        tester,
        _dossierCase(
          timeline: const [
            CaseTimelineEvent(
              title: 'Desaparición',
              date: '1974',
              kind: CaseTimelineKind.initial,
            ),
          ],
        ),
      );

      expect(_renderedSections(tester), orderedEquals(const [_timeline]));
    });
  });

  group('cabecera', () {
    testWidgets('renders the title and the location label', (tester) async {
      final crimeCase = _dossierCase();
      await _pumpDossier(tester, crimeCase);

      expect(find.text(crimeCase.locationLabel), findsOneWidget);
    });

    testWidgets('renders the victim block when there is a victim', (
      tester,
    ) async {
      await _pumpDossier(tester, _dossierCase(victim: 'Manuel Ferreiro'));

      // `findRichText` no es opcional aquí: el bloque es un `Text.rich` y sin
      // esa bandera el buscador no lo ve NUNCA, ni cuando está. El test de
      // omisión de abajo pasaría siempre — una aserción que no puede fallar.
      expect(
        find.textContaining('Manuel Ferreiro', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('omits the victim block when there is none', (tester) async {
      await _pumpDossier(tester, _dossierCase());

      expect(
        find.textContaining('VÍCTIMA(S)', findRichText: true),
        findsNothing,
      );
    });

    testWidgets('prefers an explicit status label over the enum label', (
      tester,
    ) async {
      await _pumpDossier(
        tester,
        _dossierCase(statusLabel: 'Reabierto en 2019'),
      );

      expect(find.text('REABIERTO EN 2019'), findsOneWidget);
    });

    testWidgets('falls back to the enum label when there is no explicit one', (
      tester,
    ) async {
      await _pumpDossier(tester, _dossierCase());

      expect(find.text(CaseStatus.open.label.toUpperCase()), findsOneWidget);
    });
  });

  group('rejilla de métricas', () {
    testWidgets('counts the related cases as connections', (tester) async {
      await _pumpDossier(
        tester,
        _dossierCase(),
        catalog: [_dossierCase(id: 'caso-mina', title: 'El caso de la mina')],
        connections: const [
          CaseConnection(
            aId: 'caso-faro',
            bId: 'caso-mina',
            relation: 'Misma comarca',
          ),
        ],
      );

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('shows no connections when the case is isolated', (
      tester,
    ) async {
      await _pumpDossier(tester, _dossierCase());

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('shows the year and the coordinates of the case', (
      tester,
    ) async {
      final crimeCase = _dossierCase();
      await _pumpDossier(tester, crimeCase);

      expect(find.text(crimeCase.coordsLabel), findsOneWidget);
    });
  });

  group('acciones que el panel escribe en el estado del mapa', () {
    testWidgets('going back to the map clears the selection', (tester) async {
      final container = await _pumpDossier(tester, _dossierCase());
      container.read(selectedCaseIdProvider.notifier).state = 'caso-faro';

      await tester.tap(find.text('VOLVER AL MAPA'));
      await tester.pump();

      expect(container.read(selectedCaseIdProvider), isNull);
    });

    testWidgets('tapping a related case selects it', (tester) async {
      final container = await _pumpDossier(
        tester,
        _dossierCase(),
        catalog: [_dossierCase(id: 'caso-mina', title: 'El caso de la mina')],
        connections: const [
          CaseConnection(
            aId: 'caso-faro',
            bId: 'caso-mina',
            relation: 'Misma comarca',
          ),
        ],
      );

      await tester.tap(find.text('El caso de la mina'));
      await tester.pump();

      expect(container.read(selectedCaseIdProvider), 'caso-mina');
    });

    testWidgets('centering bumps the recenter tick', (tester) async {
      final container = await _pumpDossier(tester, _dossierCase());
      final before = container.read(mapRecenterTickProvider);

      await tester.tap(find.text('Centrar'));
      await tester.pump();

      expect(container.read(mapRecenterTickProvider), before + 1);
    });
  });

  group('tarjetas de fuente', () {
    testWidgets('shows the source title and its host, not the full url', (
      tester,
    ) async {
      await _pumpDossier(
        tester,
        _dossierCase(
          sources: const [
            CaseSource(
              id: 's1',
              title: 'Crónica del temporal',
              url: 'https://elpais.com/articulo/1974',
              kind: CaseSourceKind.investigation,
            ),
          ],
        ),
      );

      expect(find.text('elpais.com'), findsOneWidget);
    });

    testWidgets('renders one card per source', (tester) async {
      await _pumpDossier(
        tester,
        _dossierCase(
          sources: const [
            CaseSource(
              id: 's1',
              title: 'Primera',
              url: 'https://elpais.com/a',
              kind: CaseSourceKind.investigation,
            ),
            CaseSource(
              id: 's2',
              title: 'Segunda',
              url: 'https://elmundo.es/b',
              kind: CaseSourceKind.podcast,
            ),
          ],
        ),
      );

      expect(find.text('Segunda'), findsOneWidget);
    });
  });

  group('la previsualización de intake hospeda el mismo expediente', () {
    testWidgets('an editing draft is previewed through CaseDossierPanel', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          casesRepositoryProvider.overrideWithValue(
            const FakeCasesRepository([]),
          ),
          caseDraftsStoreProvider.overrideWithValue(
            _SingleDraftStore(const CaseDraft(draftId: 'draft-a')),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(caseDraftsProvider.future);
      container.read(editingDraftIdProvider.notifier).state = 'draft-a';

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: IntakePreviewPanel())),
        ),
      );
      await tester.pump();

      // El contrato que la Unit 4c no puede romper: la previsualización no
      // tiene su propio renderizador, hospeda el del expediente.
      expect(find.byType(CaseDossierPanel), findsOneWidget);
    });

    testWidgets('without an editing draft it invites to pick one', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            casesRepositoryProvider.overrideWithValue(
              const FakeCasesRepository([]),
            ),
            caseDraftsStoreProvider.overrideWithValue(
              _SingleDraftStore(const CaseDraft(draftId: 'draft-a')),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: IntakePreviewPanel())),
        ),
      );
      await tester.pump();

      expect(find.byType(CaseDossierPanel), findsNothing);
    });
  });
}

class _SingleDraftStore implements CaseDraftsStore {
  _SingleDraftStore(this._draft);

  final CaseDraft _draft;

  @override
  Future<List<CaseDraft>> loadDrafts() async => [_draft];

  @override
  Future<void> saveDrafts(List<CaseDraft> drafts) async {}
}
