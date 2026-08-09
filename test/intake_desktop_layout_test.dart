import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/config/map_config.dart';
import 'package:true_app/features/cases/application/case_draft_providers.dart';
import 'package:true_app/features/cases/application/cases_providers.dart';
import 'package:true_app/features/cases/data/case_drafts_store.dart';
import 'package:true_app/features/cases/data/reverse_geocoder.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';
import 'package:true_app/features/cases/domain/resolved_place.dart';
import 'package:true_app/features/cases/presentation/intake/intake_preview_panel.dart';
import 'package:true_app/features/cases/presentation/intake/intake_workspace_screen.dart';

import 'test_support/sample_cases.dart';

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

/// Ancho cómodamente por encima de `Breakpoints.intakeThreePane` (1024).
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
      caseDraftsStoreProvider.overrideWithValue(_FakeCaseDraftsStore(seedDrafts)),
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
}
