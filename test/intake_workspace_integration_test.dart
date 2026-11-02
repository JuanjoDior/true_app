import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/config/map_config.dart';
import 'package:true_app/features/cases/application/case_draft_providers.dart';
import 'package:true_app/features/cases/application/cases_providers.dart';
import 'package:true_app/features/cases/application/intake_session_providers.dart';
import 'package:true_app/features/cases/data/case_drafts_store.dart';
import 'package:true_app/features/cases/data/reverse_geocoder.dart';
import 'package:true_app/features/cases/domain/case_category.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';
import 'package:true_app/features/cases/domain/case_status.dart';
import 'package:true_app/features/cases/domain/resolved_place.dart';
import 'package:true_app/features/cases/presentation/dossier/dossier_body_footer.dart';
import 'package:true_app/features/cases/presentation/intake/intake_editor.dart';
import 'package:true_app/features/cases/presentation/intake/intake_preview_panel.dart';
import 'package:true_app/features/cases/presentation/intake/intake_workspace_screen.dart';

import 'test_support/fake_intake_auth.dart';
import 'test_support/sample_cases.dart';

class _FakeCaseDraftsStore implements CaseDraftsStore {
  _FakeCaseDraftsStore(this.saved);
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

const _complete = CaseDraft(
  draftId: 'draft-a',
  title: 'Caso completo',
  category: CaseCategory.serialKiller,
  year: 1990,
  status: CaseStatus.solved,
  country: 'España',
  countryCode: 'ES',
  regionOrCity: 'Badajoz',
  latitude: 38.8,
  longitude: -6.9,
);

Future<void> _pump(
  WidgetTester tester,
  Size size, {
  CaseDraft draft = const CaseDraft(draftId: 'draft-a'),
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      intakeAuthProvider.overrideWithValue(FakeIntakeAuth.signedIn()),
      caseDraftsStoreProvider.overrideWithValue(_FakeCaseDraftsStore([draft])),
      casesRepositoryProvider.overrideWithValue(const FakeCasesRepository([])),
      mapConfigProvider.overrideWithValue(MapConfig.testing()),
      reverseGeocoderProvider.overrideWithValue(_NoGeocoder()),
    ],
  );
  addTearDown(container.dispose);
  await container.read(caseDraftsProvider.future);
  container.read(editingDraftIdProvider.notifier).state = draft.draftId;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
        home: const IntakeWorkspaceScreen(),
      ),
    ),
  );
  await tester.pump();
}

double _scrollOffset(WidgetTester tester) => tester
    .state<ScrollableState>(
      find
          .descendant(
            of: find.byKey(const Key('intake-editor-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    )
    .position
    .pixels;

void main() {
  for (final size in const [Size(1440, 900), Size(1200, 900), Size(390, 844)]) {
    group('${size.width.toInt()}px', () {
      testWidgets('shows the editor with numbered sections, no overflow', (
        tester,
      ) async {
        await _pump(tester, size);
        expect(tester.takeException(), isNull);

        expect(find.byType(IntakeEditor), findsOneWidget);
        expect(find.byKey(const Key('intake-editor-card-0')), findsOneWidget);
        expect(find.text('01'), findsWidgets);
        expect(find.byKey(const Key('intake-editor-nav-6')), findsOneWidget);
      });
    });
  }

  testWidgets('desktop: all seven section pills fit the editor width', (
    tester,
  ) async {
    // La fuente de pruebas (Ahem) mide 1 em por letra, el doble que la real;
    // 0.55 acerca el ancho de los textos al de producción.
    await _pump(
      tester,
      const Size(1440, 900),
      textScaler: const TextScaler.linear(0.55),
    );
    final editorRight = tester
        .getBottomRight(find.byKey(const Key('intake-editor-scroll')))
        .dx;
    for (var i = 0; i < 7; i++) {
      final pill = find.byKey(Key('intake-editor-nav-$i'));
      expect(tester.getTopLeft(pill).dx, greaterThanOrEqualTo(0));
      expect(tester.getBottomRight(pill).dx, lessThanOrEqualTo(editorRight));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'desktop: dragging the preview keeps scrolling past the dossier',
    (tester) async {
      await _pump(tester, const Size(1440, 900), draft: _complete);
      final panel = find.byType(IntakePreviewPanel);
      final outer = tester.state<ScrollableState>(
        find.descendant(of: panel, matching: find.byType(Scrollable)).first,
      );
      // Con el panel al final el expediente queda entero a la vista.
      final end = outer.position.maxScrollExtent;
      expect(end, greaterThan(0));
      outer.position.jumpTo(end);
      await tester.pump();

      // El expediente no tiene scroll propio: un arrastre hacia abajo sobre su
      // final desplaza el único scroll del panel, sin quedarse atascado.
      final dossier = find.byType(DossierFooter);
      for (var i = 0; i < 3; i++) {
        await tester.drag(dossier, const Offset(0, 200));
        // El mapa del expediente anima de forma continua: no se espera a que
        // el árbol quede en reposo.
        await tester.pump(const Duration(milliseconds: 400));
      }

      expect(outer.position.pixels, lessThan(end));
    },
  );

  group('editor header', () {
    testWidgets('untitled incomplete draft', (tester) async {
      await _pump(tester, const Size(1440, 900));
      final header = find.byKey(const Key('intake-editor-header'));
      expect(
        find.descendant(of: header, matching: find.text('Sin título')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: header, matching: find.text('Incompleto')),
        findsOneWidget,
      );
      expect(find.text('Listo · sin publicar'), findsNothing);
    });

    testWidgets('complete draft is ready', (tester) async {
      await _pump(tester, const Size(1440, 900), draft: _complete);
      final header = find.byKey(const Key('intake-editor-header'));
      expect(
        find.descendant(of: header, matching: find.text('Caso completo')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: header,
          matching: find.text('Listo · sin publicar'),
        ),
        findsOneWidget,
      );
      expect(find.text('Incompleto'), findsNothing);
    });
  });

  group('checklist navigation', () {
    testWidgets('desktop: tapping a pending field scrolls the editor', (
      tester,
    ) async {
      await _pump(tester, const Size(1440, 900));
      expect(_scrollOffset(tester), 0);

      await tester.ensureVisible(
        find.byKey(const Key('intake-checklist-coordinates')),
      );
      await tester.tap(find.byKey(const Key('intake-checklist-coordinates')));
      await tester.pumpAndSettle();

      expect(_scrollOffset(tester), greaterThan(0));
      final viewportTop = tester
          .getTopLeft(find.byKey(const Key('intake-editor-scroll')))
          .dy;
      expect(
        tester.getTopLeft(find.byKey(const Key('intake-editor-card-1'))).dy,
        closeTo(viewportTop, 1.5),
      );
    });

    testWidgets('narrow: closes the preview sheet, then scrolls', (
      tester,
    ) async {
      await _pump(tester, const Size(390, 844));
      await tester.tap(find.byKey(const Key('intake-preview-toggle-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('intake-preview-sheet')), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const Key('intake-checklist-coordinates')),
      );
      await tester.tap(find.byKey(const Key('intake-checklist-coordinates')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('intake-preview-sheet')), findsNothing);
      expect(_scrollOffset(tester), greaterThan(0));
    });
  });
}
