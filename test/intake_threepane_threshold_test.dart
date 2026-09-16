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

Future<void> _pumpWorkspace(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      caseDraftsStoreProvider.overrideWithValue(
        _FakeCaseDraftsStore(const [CaseDraft(draftId: 'draft-a', title: 'Caso A')]),
      ),
      casesRepositoryProvider.overrideWithValue(const FakeCasesRepository([])),
      mapConfigProvider.overrideWithValue(MapConfig.testing()),
      reverseGeocoderProvider.overrideWithValue(_NoGeocoder()),
    ],
  );
  addTearDown(container.dispose);

  await container.read(caseDraftsProvider.future);
  container.read(intakeUnlockedProvider.notifier).state = true;
  container.read(editingDraftIdProvider.notifier).state = 'draft-a';

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: IntakeWorkspaceScreen()),
    ),
  );
  await tester.pump();
}

/// Fija el punto exacto en el que el workspace cambia de layout: la columna
/// de tres paneles necesita 260 (lista) + 380 (preview) + 40 (padding propio)
/// + 520 (`Breakpoints.formRowStack`, para que las filas de campos no se
/// apilen) = 1200px de pantalla. Por debajo, TODAS las filas se apilarían en
/// un layout que se presenta como "de escritorio" — el layout angosto, que ya
/// apila deliberadamente, da mejor resultado ahí [Pendiente: banda
/// 1024-1199px, PROJECT_CONTEXT.md].
void main() {
  testWidgets('at 1199px (just below the fixed-panel budget) uses the narrow layout',
      (tester) async {
    await _pumpWorkspace(tester, const Size(1199, 900));
    expect(tester.takeException(), isNull);

    // Afordancias que sólo existen en estrecho.
    expect(find.byKey(const Key('intake-drafts-toggle-button')), findsOneWidget);
    expect(find.byKey(const Key('intake-preview-toggle-button')), findsOneWidget);

    // El formulario ocupa la pantalla completa, no una columna apretada.
    expect(
      tester.getSize(find.byKey(const Key('intake-form-column'))).width,
      closeTo(1199, 0.5),
    );

    // La previsualización no vive permanentemente en su propia columna.
    expect(find.byType(IntakePreviewPanel), findsNothing);
  });

  testWidgets('at 1200px (the fixed-panel budget) uses the three-pane desktop layout',
      (tester) async {
    await _pumpWorkspace(tester, const Size(1200, 900));
    expect(tester.takeException(), isNull);

    // Sin afordancias de estrecho.
    expect(find.byKey(const Key('intake-drafts-toggle-button')), findsNothing);
    expect(find.byKey(const Key('intake-preview-toggle-button')), findsNothing);

    // Cada panel en su ancho fijo, y el formulario en lo que queda.
    final preview = find.byType(IntakePreviewPanel);
    expect(preview, findsOneWidget);
    expect(tester.getSize(preview).width, closeTo(380, 0.5));
    expect(
      tester.getSize(find.byKey(const Key('intake-form-column'))).width,
      closeTo(1200 - 260 - 380, 0.5),
    );
  });
}
