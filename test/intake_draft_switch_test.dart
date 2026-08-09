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
  Future<ResolvedPlace?> resolve(double latitude, double longitude) async => null;
}

const _first = CaseDraft(
  draftId: 'draft-a',
  title: 'Caso de Yecla',
  year: 1995,
  summary: 'Resumen del primero.',
  regionOrCity: 'Yecla',
  country: 'España',
);
const _second = CaseDraft(draftId: 'draft-b');

/// Busca un texto DENTRO de un campo concreto del formulario.
///
/// Hace falta acotar así porque el título del borrador también aparece en la
/// lista lateral, donde sí debe verse.
Finder inField(String fieldKey, String text) {
  return find.descendant(
    of: find.byKey(Key(fieldKey)),
    matching: find.text(text),
  );
}

void main() {
  testWidgets('switching drafts refreshes what the text fields show',
      (tester) async {
    // Los campos guardan su texto internamente: al cambiar de borrador hay
    // que forzar que vuelvan a leer el valor, o enseñan el del anterior y lo
    // que se ve deja de ser lo que se guarda.
    // Sin viewport forzado: en el de 800x600 por defecto el workspace entra
    // por la rama estrecha, así que este test cubre el cambio de borrador
    // justo donde antes ni se renderizaba.
    final container = ProviderContainer(
      overrides: [
        caseDraftsStoreProvider
            .overrideWithValue(_FakeCaseDraftsStore([_first, _second])),
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

    expect(inField('intake-field-title', 'Caso de Yecla'), findsOneWidget);
    expect(inField('intake-field-year', '1995'), findsOneWidget);

    container.read(editingDraftIdProvider.notifier).state = 'draft-b';
    await tester.pump();
    await tester.pump();

    // El segundo borrador está vacío: los campos no deben arrastrar nada.
    expect(inField('intake-field-title', 'Caso de Yecla'), findsNothing);
    expect(inField('intake-field-year', '1995'), findsNothing);
    expect(
      inField('intake-field-summary', 'Resumen del primero.'),
      findsNothing,
    );
    expect(
      inField('intake-field-region-or-city-0', 'Yecla'),
      findsNothing,
    );
  });

  testWidgets('coming back to a draft shows its own values again',
      (tester) async {
    // Sin viewport forzado: ver la nota del primer test.
    final container = ProviderContainer(
      overrides: [
        caseDraftsStoreProvider
            .overrideWithValue(_FakeCaseDraftsStore([_first, _second])),
        casesRepositoryProvider.overrideWithValue(const FakeCasesRepository([])),
        mapConfigProvider.overrideWithValue(MapConfig.testing()),
        reverseGeocoderProvider.overrideWithValue(_NoGeocoder()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(caseDraftsProvider.future);
    container.read(intakeUnlockedProvider.notifier).state = true;
    container.read(editingDraftIdProvider.notifier).state = 'draft-b';

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: IntakeWorkspaceScreen()),
      ),
    );
    await tester.pump();

    container.read(editingDraftIdProvider.notifier).state = 'draft-a';
    await tester.pump();
    await tester.pump();

    expect(inField('intake-field-title', 'Caso de Yecla'), findsOneWidget);
    expect(inField('intake-field-year', '1995'), findsOneWidget);
    expect(
      inField('intake-field-region-or-city-0', 'Yecla'),
      findsOneWidget,
    );
  });
}
