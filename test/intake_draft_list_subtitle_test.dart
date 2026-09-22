import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/config/map_config.dart';
import 'package:true_app/features/cases/application/case_draft_providers.dart';
import 'package:true_app/features/cases/application/cases_providers.dart';
import 'package:true_app/features/cases/data/case_drafts_store.dart';
import 'package:true_app/features/cases/data/reverse_geocoder.dart';
import 'package:true_app/features/cases/domain/case_category.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';
import 'package:true_app/features/cases/domain/case_status.dart';
import 'package:true_app/features/cases/domain/resolved_place.dart';
import 'package:true_app/features/cases/domain/true_crime_case.dart';
import 'package:true_app/features/cases/presentation/intake/intake_workspace_screen.dart';

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

/// Ancho por encima de `Breakpoints.intakeThreePane`, para que `_DraftList`
/// se renderice permanentemente en vez de quedar detrás del overlay estrecho
/// (mismo patrón que `intake_desktop_layout_test.dart`).
const _desktopSize = Size(1440, 900);

const _validDraft = CaseDraft(
  draftId: 'draft-valid',
  title: 'Caso del faro',
  category: CaseCategory.unsolved,
  year: 1994,
  status: CaseStatus.open,
  country: 'España',
  countryCode: 'ES',
  regionOrCity: 'Cuenca',
  latitude: 40.07,
  longitude: -2.13,
);

/// Busca un texto DENTRO del `ListTile` de un borrador concreto de la lista.
///
/// Hace falta acotar así porque el mismo texto podría existir en otro sitio
/// de la pantalla (mismo patrón que `intake_draft_switch_test.dart:inField`).
Finder subtitleTextFor(String draftId, String text) => find.descendant(
  of: find.byKey(Key('intake-draft-item-$draftId')),
  matching: find.text(text),
);

void main() {
  testWidgets(
    'a handed-off draft shows the delivered subtitle, not "Listo · sin publicar"',
    (tester) async {
      tester.view.physicalSize = _desktopSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final handedOff = _validDraft.markHandedOff(
        slug: 'caso-del-faro',
        at: DateTime(2026, 9, 12),
      );
      final container = ProviderContainer(
        overrides: [
          caseDraftsStoreProvider.overrideWithValue(
            _FakeCaseDraftsStore([handedOff]),
          ),
          casesRepositoryProvider.overrideWithValue(
            const FakeCasesRepository([]),
          ),
          mapConfigProvider.overrideWithValue(MapConfig.testing()),
          reverseGeocoderProvider.overrideWithValue(_NoGeocoder()),
        ],
      );
      addTearDown(container.dispose);

      await container.read(casesProvider.future);
      await container.read(caseDraftsProvider.future);
      container.read(intakeUnlockedProvider.notifier).state = true;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: IntakeWorkspaceScreen()),
        ),
      );
      await tester.pump();

      expect(
        subtitleTextFor(
          'draft-valid',
          'Entregado el 12/09 · pendiente de publicar',
        ),
        findsOneWidget,
      );
      expect(
        subtitleTextFor('draft-valid', 'Listo · sin publicar'),
        findsNothing,
      );
    },
  );

  testWidgets('a published draft shows "Publicado"', (tester) async {
    tester.view.physicalSize = _desktopSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final published = _validDraft.markHandedOff(
      slug: 'caso-del-faro',
      at: DateTime(2026, 9, 12),
    );
    final container = ProviderContainer(
      overrides: [
        caseDraftsStoreProvider.overrideWithValue(
          _FakeCaseDraftsStore([published]),
        ),
        casesRepositoryProvider.overrideWithValue(
          const FakeCasesRepository([
            TrueCrimeCase(
              id: 'caso-del-faro',
              slug: 'caso-del-faro',
              title: 'Caso del faro',
              category: CaseCategory.unsolved,
              country: 'España',
              countryCode: 'ES',
              regionOrCity: 'Cuenca',
              year: 1994,
              latitude: 40.07,
              longitude: -2.13,
              summary: 'Resumen.',
              tags: [],
              sources: [],
            ),
          ]),
        ),
        mapConfigProvider.overrideWithValue(MapConfig.testing()),
        reverseGeocoderProvider.overrideWithValue(_NoGeocoder()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(casesProvider.future);
    await container.read(caseDraftsProvider.future);
    container.read(intakeUnlockedProvider.notifier).state = true;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: IntakeWorkspaceScreen()),
      ),
    );
    await tester.pump();

    expect(subtitleTextFor('draft-valid', 'Publicado'), findsOneWidget);
  });

  testWidgets(
    'a never-handed-off valid draft still shows "Listo · sin publicar"',
    (tester) async {
      tester.view.physicalSize = _desktopSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final container = ProviderContainer(
        overrides: [
          caseDraftsStoreProvider.overrideWithValue(
            _FakeCaseDraftsStore([_validDraft]),
          ),
          casesRepositoryProvider.overrideWithValue(
            const FakeCasesRepository([]),
          ),
          mapConfigProvider.overrideWithValue(MapConfig.testing()),
          reverseGeocoderProvider.overrideWithValue(_NoGeocoder()),
        ],
      );
      addTearDown(container.dispose);

      await container.read(casesProvider.future);
      await container.read(caseDraftsProvider.future);
      container.read(intakeUnlockedProvider.notifier).state = true;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: IntakeWorkspaceScreen()),
        ),
      );
      await tester.pump();

      expect(
        subtitleTextFor('draft-valid', 'Listo · sin publicar'),
        findsOneWidget,
      );
    },
  );

  testWidgets('an incomplete draft still shows "Incompleto"', (tester) async {
    tester.view.physicalSize = _desktopSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    const incomplete = CaseDraft(draftId: 'draft-incompleto');
    final container = ProviderContainer(
      overrides: [
        caseDraftsStoreProvider.overrideWithValue(
          _FakeCaseDraftsStore([incomplete]),
        ),
        casesRepositoryProvider.overrideWithValue(
          const FakeCasesRepository([]),
        ),
        mapConfigProvider.overrideWithValue(MapConfig.testing()),
        reverseGeocoderProvider.overrideWithValue(_NoGeocoder()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(casesProvider.future);
    await container.read(caseDraftsProvider.future);
    container.read(intakeUnlockedProvider.notifier).state = true;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: IntakeWorkspaceScreen()),
      ),
    );
    await tester.pump();

    expect(
      subtitleTextFor('draft-incompleto', 'Incompleto'),
      findsOneWidget,
    );
  });
}
