import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/config/map_config.dart';
import 'package:true_app/features/cases/application/case_draft_providers.dart';
import 'package:true_app/features/cases/application/cases_providers.dart';
import 'package:true_app/features/cases/data/case_drafts_store.dart';
import 'package:true_app/features/cases/data/reverse_geocoder.dart';
import 'package:true_app/features/cases/domain/case_category.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';
import 'package:true_app/features/cases/domain/case_photo.dart';
import 'package:true_app/features/cases/domain/case_status.dart';
import 'package:true_app/features/cases/domain/resolved_place.dart';
import 'package:true_app/features/cases/domain/true_crime_case.dart';
import 'package:true_app/features/cases/presentation/intake/case_form_section.dart';
import 'package:true_app/features/cases/presentation/intake/intake_workspace_screen.dart';
import 'package:true_app/features/home/presentation/widgets/situation/case_dossier_panel.dart';

import 'test_support/sample_cases.dart';

class _FakeCaseDraftsStore implements CaseDraftsStore {
  _FakeCaseDraftsStore([List<CaseDraft>? seed])
    : saved = seed ?? const <CaseDraft>[];
  List<CaseDraft> saved;

  @override
  Future<List<CaseDraft>> loadDrafts() async => saved;

  @override
  Future<void> saveDrafts(List<CaseDraft> drafts) async {
    saved = drafts;
  }
}

class _NoGeocoder implements ReverseGeocoder {
  @override
  Future<ResolvedPlace?> resolve(double latitude, double longitude) async =>
      null;
}

const _narrowSize = Size(360, 780);

const _expectedCaseFormSectionTitles = <String>[
  'Datos básicos',
  'Ubicación',
  'Resumen y ficha',
  'Cronología',
  'Enlaces',
  'Fotografías',
  'Capítulos',
];

/// Un borrador con todos los campos obligatorios rellenos, listo para
/// exportar, igual que `_publishable` en `export_case_button_widget_test.dart`.
CaseDraft _publishableDraft(String draftId) {
  return CaseDraft(
    draftId: draftId,
    title: 'El caso del faro',
    category: CaseCategory.unsolved,
    year: 1974,
    status: CaseStatus.open,
    country: 'España',
    countryCode: 'ES',
    regionOrCity: 'Cuenca',
    latitude: 40.07,
    longitude: -2.13,
    summary: 'Un resumen editorial.',
  );
}

/// Levanta el workspace completo a 360x780 con un `ProviderContainer` propio,
/// para poder inspeccionar y forzar estado desde el test.
Future<ProviderContainer> _pumpNarrowWorkspace(
  WidgetTester tester, {
  List<CaseDraft> seedDrafts = const <CaseDraft>[],
  String? editingDraftId,
}) async {
  tester.view.physicalSize = _narrowSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      caseDraftsStoreProvider.overrideWithValue(
        _FakeCaseDraftsStore(seedDrafts),
      ),
      casesRepositoryProvider.overrideWithValue(const FakeCasesRepository([])),
      mapConfigProvider.overrideWithValue(MapConfig.testing()),
      reverseGeocoderProvider.overrideWithValue(_NoGeocoder()),
    ],
  );
  addTearDown(container.dispose);

  await container.read(caseDraftsProvider.future);
  container.read(intakeUnlockedProvider.notifier).state = true;
  if (editingDraftId != null) {
    container.read(editingDraftIdProvider.notifier).state = editingDraftId;
  }

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: IntakeWorkspaceScreen()),
    ),
  );
  await tester.pump();
  return container;
}

void main() {
  group('narrow workspace composition (360x780)', () {
    testWidgets(
      'shows the form full-screen by default, with no permanent draft list or preview',
      (tester) async {
        await _pumpNarrowWorkspace(
          tester,
          seedDrafts: const [CaseDraft(draftId: 'draft-a')],
          editingDraftId: 'draft-a',
        );
        expect(tester.takeException(), isNull);

        // Geometría, no sólo ausencia de excepción: el formulario ocupa todo
        // el ancho disponible, no una columna comprimida entre paneles.
        final formSize = tester.getSize(
          find.byKey(const Key('intake-form-column')),
        );
        expect(formSize.width, closeTo(360, 0.5));

        expect(find.byKey(const Key('intake-draft-list-sheet')), findsNothing);
        expect(find.byKey(const Key('intake-preview-sheet')), findsNothing);
      },
    );

    testWidgets(
      'all seven form sections are reachable by dragging, in registry order, at 360px',
      (tester) async {
        await _pumpNarrowWorkspace(
          tester,
          seedDrafts: const [CaseDraft(draftId: 'draft-a')],
          editingDraftId: 'draft-a',
        );
        expect(tester.takeException(), isNull);

        // La lista explícita fija el contrato de siete secciones. Derivarla del
        // registro permitiría que eliminar una sección redujera también la
        // expectativa y dejara el test en verde.
        expect(
          kCaseFormSections.map((section) => section.title),
          orderedEquals(_expectedCaseFormSectionTitles),
        );

        final form = find.byKey(const Key('intake-form-column'));
        final scrollable = find
            .descendant(of: form, matching: find.byType(Scrollable))
            .first;
        expect(scrollable, findsOneWidget);

        Finder headerOf(String title) =>
            find.descendant(of: form, matching: find.text(title.toUpperCase()));

        for (final title in _expectedCaseFormSectionTitles) {
          expect(headerOf(title), findsOneWidget);
        }

        final viewport = tester.getRect(form);
        final position = tester.state<ScrollableState>(scrollable).position;

        bool isFullyVisible(String title) {
          final header = tester.getRect(headerOf(title));
          return header.top >= viewport.top && header.bottom <= viewport.bottom;
        }

        // Precondición: el escenario habla de desplazarse, así que el
        // formulario tiene que desbordar y la última sección tiene que nacer
        // fuera de la ventana. Sin esto, "alcanzable" se cumpliría sola.
        expect(position.maxScrollExtent, greaterThan(0));
        expect(isFullyVisible(_expectedCaseFormSectionTitles.last), isFalse);

        // Se arrastra con el dedo en vez de usar `scrollUntilVisible`: ese
        // helper sólo arrastra mientras el finder no encuentra nada, y en un
        // `SingleChildScrollView` los siete hijos se construyen de golpe, así
        // que cae directo en `Scrollable.ensureVisible`. Eso mueve la ventana
        // por programa y se salta la física, de modo que un formulario con
        // `NeverScrollableScrollPhysics` también pasaría.
        const dragStep = 240.0;
        // El punto de arrastre va sobre el margen izquierdo del scroll, fuera
        // del relleno de 20px: dentro viven mapas y campos que se quedarían
        // con el gesto.
        final dragOrigin = Offset(viewport.left + 10, viewport.center.dy);
        final maxDrags = (position.maxScrollExtent / dragStep).ceil() + 4;

        final reached = <String>[];
        for (var drag = 0; drag <= maxDrags; drag++) {
          // Las que entran en el mismo frame se apuntan por su posición real,
          // no por la esperada: apuntarlas en el orden esperado haría que la
          // aserción de orden no pudiera fallar entre secciones vecinas.
          final newlyVisible =
              <String>[
                for (final title in _expectedCaseFormSectionTitles)
                  if (!reached.contains(title) && isFullyVisible(title)) title,
              ]..sort(
                (a, b) => tester
                    .getRect(headerOf(a))
                    .top
                    .compareTo(tester.getRect(headerOf(b)).top),
              );
          reached.addAll(newlyVisible);
          if (reached.length == _expectedCaseFormSectionTitles.length) {
            break;
          }
          await tester.dragFrom(dragOrigin, const Offset(0, -dragStep));
          await tester.pumpAndSettle();
        }

        // El orden en que aparecen al bajar es el del registro, así que una
        // sola aserción cubre alcance y orden vertical.
        expect(reached, orderedEquals(_expectedCaseFormSectionTitles));
      },
    );

    testWidgets(
      'tapping the drafts affordance opens a scrimmed overlay with every draft selectable, and tap-outside dismisses it',
      (tester) async {
        await _pumpNarrowWorkspace(
          tester,
          seedDrafts: const [
            CaseDraft(draftId: 'draft-a', title: 'Caso A'),
            CaseDraft(draftId: 'draft-b', title: 'Caso B'),
          ],
          editingDraftId: 'draft-a',
        );

        await tester.tap(find.byKey(const Key('intake-drafts-toggle-button')));
        await tester.pump();
        expect(tester.takeException(), isNull);

        expect(
          find.byKey(const Key('intake-draft-list-sheet')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('intake-draft-list-scrim')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('intake-draft-item-draft-a')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('intake-draft-item-draft-b')),
          findsOneWidget,
        );

        // Toca un punto garantizado fuera de la hoja (el propio borde del
        // scrim a pantalla completa), no el centro (que la hoja cubre).
        final scrimCorner =
            tester.getTopLeft(
              find.byKey(const Key('intake-draft-list-scrim')),
            ) +
            const Offset(2, 2);
        await tester.tapAt(scrimCorner);
        await tester.pump();

        expect(find.byKey(const Key('intake-draft-list-sheet')), findsNothing);
      },
    );

    testWidgets(
      'tapping the preview affordance opens a sheet with no scrim, sized at half the screen height',
      (tester) async {
        await _pumpNarrowWorkspace(
          tester,
          seedDrafts: const [CaseDraft(draftId: 'draft-a')],
          editingDraftId: 'draft-a',
        );

        await tester.tap(find.byKey(const Key('intake-preview-toggle-button')));
        await tester.pump();
        expect(tester.takeException(), isNull);

        expect(find.byKey(const Key('intake-preview-sheet')), findsOneWidget);
        // Sin scrim: a diferencia de la lista de borradores, nada intercepta
        // los toques al formulario detrás [Diseño D3].
        expect(find.byKey(const Key('intake-draft-list-scrim')), findsNothing);

        final sheetSize = tester.getSize(
          find.byKey(const Key('intake-preview-sheet')),
        );
        expect(sheetSize.height, closeTo(780 * 0.5, 0.5));
      },
    );

    testWidgets(
      'typing into the title field while the preview sheet stays open updates the preview live',
      (tester) async {
        await _pumpNarrowWorkspace(
          tester,
          seedDrafts: const [CaseDraft(draftId: 'draft-a')],
          editingDraftId: 'draft-a',
        );

        await tester.tap(find.byKey(const Key('intake-preview-toggle-button')));
        await tester.pump();
        expect(find.byKey(const Key('intake-preview-sheet')), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('intake-field-title')),
          'Título en vivo',
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        // La hoja sigue abierta: no se cerró y volvió a abrir para reflejar
        // el cambio [Requirement: Live Preview Behind an Open Sheet].
        expect(find.byKey(const Key('intake-preview-sheet')), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const Key('detail-panel')),
            matching: find.text('Título en vivo'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'with zero drafts, opening the workspace auto-creates a blank draft and opens the form directly',
      (tester) async {
        await _pumpNarrowWorkspace(tester);
        // Post-frame callback: hace falta un ciclo extra para que se cree y
        // se seleccione el borrador en blanco.
        await tester.pump();
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('intake-field-title')), findsOneWidget);
        expect(find.byKey(const Key('intake-draft-list-sheet')), findsNothing);
        expect(
          find.textContaining('Crea o selecciona un borrador'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'with existing drafts, opening the workspace lands on the last one, not the list',
      (tester) async {
        await _pumpNarrowWorkspace(
          tester,
          seedDrafts: const [
            CaseDraft(draftId: 'draft-a', title: 'Caso A'),
            CaseDraft(draftId: 'draft-b', title: 'Caso B'),
          ],
        );
        await tester.pump();
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('intake-draft-list-sheet')), findsNothing);
        expect(
          find.descendant(
            of: find.byKey(const Key('intake-field-title')),
            matching: find.text('Caso B'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'intake-export-button is present and enabled for a complete draft at 360px',
      (tester) async {
        await _pumpNarrowWorkspace(
          tester,
          seedDrafts: [_publishableDraft('draft-a')],
          editingDraftId: 'draft-a',
        );
        expect(tester.takeException(), isNull);

        final button = tester.widget<IconButton>(
          find.byKey(const Key('intake-export-button')),
        );
        expect(button.onPressed, isNotNull);
      },
    );

    testWidgets(
      'creating, deleting and exporting a draft at 360px reach the same outcomes as desktop',
      (tester) async {
        final copied = <String>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              copied.add((call.arguments as Map)['text'] as String);
            }
            return null;
          },
        );
        addTearDown(() {
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          );
        });

        final container = await _pumpNarrowWorkspace(
          tester,
          seedDrafts: [_publishableDraft('draft-a')],
          editingDraftId: 'draft-a',
        );

        // Exportar el borrador completo ya seleccionado.
        await tester.tap(find.byKey(const Key('intake-export-button')));
        await tester.pump();
        expect(copied, hasLength(1));

        // Crear un borrador nuevo.
        await tester.tap(find.byKey(const Key('intake-new-draft-button')));
        await tester.pump();
        expect(container.read(caseDraftsProvider).value, hasLength(2));

        // Borrar el borrador original desde la hoja de lista.
        await tester.tap(find.byKey(const Key('intake-drafts-toggle-button')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('intake-draft-delete-draft-a')));
        await tester.pump();

        expect(tester.takeException(), isNull);
        final remaining = container.read(caseDraftsProvider).value!;
        expect(remaining.any((draft) => draft.draftId == 'draft-a'), isFalse);
      },
    );
  });

  group('CaseDossierPanel preview content at the sheet budget (336px)', () {
    testWidgets('renders without overflow [pins design decision D4]', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            casesRepositoryProvider.overrideWithValue(
              const FakeCasesRepository([]),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 336,
                height: 700,
                child: CaseDossierPanel(
                  crimeCase: TrueCrimeCase(
                    id: 'caso-faro',
                    slug: 'caso-faro',
                    title: 'El caso del faro de Finisterre',
                    category: CaseCategory.unsolved,
                    country: 'España',
                    countryCode: 'ES',
                    regionOrCity: 'A Coruña',
                    year: 1974,
                    latitude: 43.39,
                    longitude: -8.41,
                    summary:
                        'Resumen del caso, con texto suficiente para probar el ajuste.',
                    tags: <String>[],
                    sources: [],
                    photos: [
                      CasePhoto(
                        url: 'https://example.com/faro.jpg',
                        caption: 'El faro',
                      ),
                      CasePhoto(url: 'https://example.com/plano.png'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
