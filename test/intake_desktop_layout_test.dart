import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/config/map_config.dart';
import 'package:true_app/features/cases/application/case_draft_providers.dart';
import 'package:true_app/features/cases/application/cases_providers.dart';
import 'package:true_app/features/cases/application/intake_session_providers.dart';
import 'package:true_app/features/cases/data/case_drafts_store.dart';
import 'package:true_app/features/cases/data/reverse_geocoder.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';
import 'package:true_app/features/cases/domain/resolved_place.dart';
import 'package:true_app/features/cases/presentation/intake/intake_preview_panel.dart';
import 'package:true_app/features/cases/presentation/intake/intake_workspace_screen.dart';

import 'test_support/sample_cases.dart';
import 'test_support/fake_intake_auth.dart';

class _FakeCaseDraftsStore implements CaseDraftsStore {
  _FakeCaseDraftsStore([List<CaseDraft>? seed]) : saved = seed ?? const <CaseDraft>[];
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
  Future<ResolvedPlace?> resolve(double latitude, double longitude) async => null;
}

/// Ancho cómodamente por encima de `Breakpoints.intakeThreePane` (1200).
const _desktopSize = Size(1440, 900);

const _draftListWidth = 260.0;
const _previewPanelWidth = 380.0;

Future<ProviderContainer> _pumpDesktopWorkspace(
  WidgetTester tester, {
  List<CaseDraft> seedDrafts = const <CaseDraft>[],
  String? editingDraftId,
}) async {
  tester.view.physicalSize = _desktopSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      intakeAuthProvider.overrideWithValue(FakeIntakeAuth.signedIn()),
      caseDraftsStoreProvider.overrideWithValue(_FakeCaseDraftsStore(seedDrafts)),
      casesRepositoryProvider.overrideWithValue(const FakeCasesRepository([])),
      mapConfigProvider.overrideWithValue(MapConfig.testing()),
      reverseGeocoderProvider.overrideWithValue(_NoGeocoder()),
    ],
  );
  addTearDown(container.dispose);

  await container.read(caseDraftsProvider.future);
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

/// Cobertura de la rama ANCHA del workspace (>= `Breakpoints.intakeThreePane`).
///
/// Por qué existe este archivo: hasta ahora los dos únicos tests que montaban
/// `IntakeWorkspaceScreen` acababan los dos en la rama estrecha — uno fuerza
/// 360x780 y el otro corre en el viewport por defecto de 800x600, también por
/// debajo de 1024. La rama de tres columnas quedaba SIN NINGÚN test: forzando
/// `isNarrow = true` la suite entera seguía en verde. Justamente esa rama es la
/// que refactorizó la fase 3 al extraer `_IntakeFormColumn` de `_FormAndPreview`.
///
/// Las aserciones miden GEOMETRÍA, no ausencia de excepciones: un layout roto
/// tiende a encoger sus hijos flexibles en lugar de desbordar, así que
/// `takeException()` por sí solo no distingue lo correcto de lo roto.
void main() {
  group('desktop three-pane composition (1440x900)', () {
    testWidgets(
      'shows draft list, form and preview simultaneously, each at its own width',
      (tester) async {
        await _pumpDesktopWorkspace(
          tester,
          seedDrafts: const [
            CaseDraft(draftId: 'draft-a', title: 'Caso A'),
            CaseDraft(draftId: 'draft-b', title: 'Caso B'),
          ],
          editingDraftId: 'draft-a',
        );
        expect(tester.takeException(), isNull);

        // La previsualización vive permanentemente en su columna, sin que
        // nadie tenga que abrir ninguna hoja.
        final preview = find.byType(IntakePreviewPanel);
        expect(preview, findsOneWidget);
        expect(
          tester.getSize(preview).width,
          closeTo(_previewPanelWidth, 0.5),
          reason: 'The preview pane must keep its fixed 380px column.',
        );

        // El formulario ocupa lo que queda entre los dos paneles fijos.
        expect(
          tester.getSize(find.byKey(const Key('intake-form-column'))).width,
          closeTo(_desktopSize.width - _draftListWidth - _previewPanelWidth, 0.5),
          reason: 'The form column must be squeezed between the draft list '
              'and the preview pane, not span the full width.',
        );
      },
    );

    testWidgets(
      'keeps every draft permanently listed, with no overlay and no narrow-only affordances',
      (tester) async {
        await _pumpDesktopWorkspace(
          tester,
          seedDrafts: const [
            CaseDraft(draftId: 'draft-a', title: 'Caso A'),
            CaseDraft(draftId: 'draft-b', title: 'Caso B'),
          ],
          editingDraftId: 'draft-a',
        );
        expect(tester.takeException(), isNull);

        // Los borradores se ven sin abrir nada.
        expect(find.byKey(const Key('intake-draft-item-draft-a')), findsOneWidget);
        expect(find.byKey(const Key('intake-draft-item-draft-b')), findsOneWidget);

        // Y las affordances que sólo existen en estrecho no aparecen aquí.
        expect(find.byKey(const Key('intake-drafts-toggle-button')), findsNothing);
        expect(find.byKey(const Key('intake-draft-list-sheet')), findsNothing);
        expect(find.byKey(const Key('intake-draft-list-scrim')), findsNothing);
        expect(find.byKey(const Key('intake-preview-sheet')), findsNothing);
      },
    );

    testWidgets(
      'with no draft selected it shows the placeholder instead of auto-landing on one',
      (tester) async {
        // El aterrizaje automático es comportamiento de la rama estrecha
        // [Diseño D6]. En escritorio el hueco central sigue siendo el texto
        // de "crea o selecciona", que es lo que había antes del cambio.
        await _pumpDesktopWorkspace(
          tester,
          seedDrafts: const [CaseDraft(draftId: 'draft-a', title: 'Caso A')],
        );
        await tester.pump();
        expect(tester.takeException(), isNull);

        expect(
          find.text('Crea o selecciona un borrador para editarlo.'),
          findsOneWidget,
        );
        expect(find.byKey(const Key('intake-form-column')), findsNothing);
      },
    );
  });

  // Un clic en la papelera no puede llevarse un borrador sin confirmación
  // [S4]. Se comprueba la lista visible, el almacén y el borrador en edición.
  group('draft deletion asks for confirmation (1440x900)', () {
    const seed = [
      CaseDraft(draftId: 'draft-a', title: 'Caso A'),
      CaseDraft(draftId: 'draft-b'),
    ];

    List<String> storedIds(ProviderContainer container) =>
        (container.read(caseDraftsStoreProvider) as _FakeCaseDraftsStore).saved
            .map((draft) => draft.draftId)
            .toList();

    List<String> listedIds(ProviderContainer container) => container
        .read(caseDraftsProvider)
        .value!
        .map((draft) => draft.draftId)
        .toList();

    void expectNothingDeleted(ProviderContainer container) {
      expect(find.byKey(const Key('intake-draft-item-draft-a')), findsOneWidget);
      expect(find.byKey(const Key('intake-draft-item-draft-b')), findsOneWidget);
      expect(listedIds(container), ['draft-a', 'draft-b']);
      expect(storedIds(container), ['draft-a', 'draft-b']);
      expect(container.read(editingDraftIdProvider), 'draft-a');
    }

    testWidgets('each delete button exposes the «Borrar borrador» tooltip', (
      tester,
    ) async {
      await _pumpDesktopWorkspace(
        tester,
        seedDrafts: seed,
        editingDraftId: 'draft-a',
      );

      for (final id in ['draft-a', 'draft-b']) {
        final button = tester.widget<IconButton>(
          find.byKey(Key('intake-draft-delete-$id')),
        );
        expect(button.tooltip, 'Borrar borrador');
      }
      expect(find.byTooltip('Borrar borrador'), findsNWidgets(2));
    });

    testWidgets('tapping delete opens the dialog and deletes nothing yet', (
      tester,
    ) async {
      final container = await _pumpDesktopWorkspace(
        tester,
        seedDrafts: seed,
        editingDraftId: 'draft-a',
      );

      await tester.tap(find.byKey(const Key('intake-draft-delete-draft-a')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      expect(find.text('¿Borrar este borrador?'), findsOneWidget);
      expect(
        find.textContaining('Se borra de este equipo y no se puede deshacer.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('intake-draft-delete-cancel')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('intake-draft-delete-confirm')),
        findsOneWidget,
      );
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Borrar'), findsOneWidget);
      // El cuerpo nombra el borrador con la misma etiqueta que la lista.
      expect(
        find.descendant(
          of: find.byKey(const Key('intake-draft-delete-dialog')),
          matching: find.textContaining('Caso A'),
        ),
        findsOneWidget,
      );
      expectNothingDeleted(container);
    });

    testWidgets('an untitled draft is named «Sin título» in the dialog', (
      tester,
    ) async {
      await _pumpDesktopWorkspace(
        tester,
        seedDrafts: seed,
        editingDraftId: 'draft-a',
      );

      await tester.tap(find.byKey(const Key('intake-draft-delete-draft-b')));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const Key('intake-draft-delete-dialog')),
          matching: find.textContaining('Sin título'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('«Cancelar» closes the dialog and keeps every draft', (
      tester,
    ) async {
      final container = await _pumpDesktopWorkspace(
        tester,
        seedDrafts: seed,
        editingDraftId: 'draft-a',
      );

      await tester.tap(find.byKey(const Key('intake-draft-delete-draft-a')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('intake-draft-delete-cancel')));
      await tester.pumpAndSettle();

      expect(find.text('¿Borrar este borrador?'), findsNothing);
      expectNothingDeleted(container);
    });

    testWidgets('Escape and tapping outside also keep every draft', (
      tester,
    ) async {
      final container = await _pumpDesktopWorkspace(
        tester,
        seedDrafts: seed,
        editingDraftId: 'draft-a',
      );

      await tester.tap(find.byKey(const Key('intake-draft-delete-draft-a')));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('¿Borrar este borrador?'), findsNothing);
      expectNothingDeleted(container);

      await tester.tap(find.byKey(const Key('intake-draft-delete-draft-a')));
      await tester.pumpAndSettle();
      expect(find.text('¿Borrar este borrador?'), findsOneWidget);
      // Esquina de la barrera, lejos del panel centrado del diálogo.
      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();
      expect(find.text('¿Borrar este borrador?'), findsNothing);
      expectNothingDeleted(container);
    });

    testWidgets(
      '«Borrar» removes exactly that draft from the list and the store',
      (tester) async {
        final container = await _pumpDesktopWorkspace(
          tester,
          seedDrafts: seed,
          editingDraftId: 'draft-a',
        );

        await tester.tap(find.byKey(const Key('intake-draft-delete-draft-a')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('intake-draft-delete-confirm')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        expect(find.text('¿Borrar este borrador?'), findsNothing);
        expect(find.byKey(const Key('intake-draft-item-draft-a')), findsNothing);
        expect(
          find.byKey(const Key('intake-draft-item-draft-b')),
          findsOneWidget,
        );
        expect(listedIds(container), ['draft-b']);
        expect(storedIds(container), ['draft-b']);
        // Era el borrador en edición: se suelta, como antes del diálogo.
        expect(container.read(editingDraftIdProvider), isNull);
      },
    );
  });
}
