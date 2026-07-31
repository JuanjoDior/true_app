import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/application/case_draft_providers.dart';
import 'package:true_app/features/cases/data/case_drafts_store.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';
import 'package:true_app/features/cases/presentation/intake/sections/location_section.dart';

class _FakeCaseDraftsStore implements CaseDraftsStore {
  List<CaseDraft> saved = const <CaseDraft>[];

  @override
  Future<List<CaseDraft>> loadDrafts() async => saved;

  @override
  Future<void> saveDrafts(List<CaseDraft> drafts) async {
    saved = drafts;
  }
}

Future<(ProviderContainer, _FakeCaseDraftsStore)> _pumpSection(
  WidgetTester tester, {
  CaseDraft Function(String draftId)? draft,
}) async {
  final store = _FakeCaseDraftsStore();
  final container = ProviderContainer(
    overrides: [caseDraftsStoreProvider.overrideWithValue(store)],
  );
  addTearDown(container.dispose);

  await container.read(caseDraftsProvider.future);
  final draftId = await container.read(caseDraftsProvider.notifier).createDraft();
  if (draft != null) {
    await container.read(caseDraftsProvider.notifier).updateDraft(draft(draftId));
  }
  container.read(editingDraftIdProvider.notifier).state = draftId;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: LocationSection()),
        ),
      ),
    ),
  );
  await tester.pump();
  return (container, store);
}

void main() {
  testWidgets('captures the full location and autosaves it', (tester) async {
    final (container, store) = await _pumpSection(tester);

    await tester.enterText(
      find.byKey(const Key('intake-field-country')),
      'España',
    );
    await tester.enterText(
      find.byKey(const Key('intake-field-country-code')),
      'ES',
    );
    await tester.enterText(
      find.byKey(const Key('intake-field-region-or-city')),
      'Cuenca',
    );
    await tester.enterText(
      find.byKey(const Key('intake-field-latitude')),
      '40.07',
    );
    await tester.enterText(
      find.byKey(const Key('intake-field-longitude')),
      '-2.13',
    );
    await tester.pump();

    final saved = container.read(editingDraftProvider)!;
    expect(saved.country, 'España');
    expect(saved.countryCode, 'ES');
    expect(saved.regionOrCity, 'Cuenca');
    expect(saved.latitude, 40.07);
    expect(saved.longitude, -2.13);
    expect(store.saved.single.latitude, 40.07);
  });

  testWidgets('keeps every field when they are typed without a rebuild between',
      (tester) async {
    // Reproduce lo observado en el navegador: al escribir de corrido, cada
    // campo partía del borrador capturado en el `build` anterior y borraba
    // en silencio lo que había escrito el campo previo.
    final (container, _) = await _pumpSection(tester);

    await tester.enterText(
      find.byKey(const Key('intake-field-country')),
      'España',
    );
    await tester.enterText(
      find.byKey(const Key('intake-field-country-code')),
      'ES',
    );
    await tester.enterText(
      find.byKey(const Key('intake-field-latitude')),
      '43.39',
    );
    await tester.pump();

    final saved = container.read(editingDraftProvider)!;
    expect(saved.country, 'España');
    expect(saved.countryCode, 'ES');
    expect(saved.latitude, 43.39);
  });

  testWidgets('shows the required-field errors on an empty location',
      (tester) async {
    await _pumpSection(tester);

    expect(find.text('El país es obligatorio'), findsOneWidget);
    expect(find.text('El código de país es obligatorio'), findsOneWidget);
    expect(find.text('La región o ciudad es obligatoria'), findsOneWidget);
    expect(find.text('La latitud es obligatoria'), findsOneWidget);
    expect(find.text('La longitud es obligatoria'), findsOneWidget);
  });

  testWidgets('rejects a country code that is not two letters', (tester) async {
    await _pumpSection(
      tester,
      draft: (draftId) => CaseDraft(draftId: draftId, countryCode: 'ESP'),
    );

    expect(find.text('Usa el código ISO de dos letras (ES, US, GB…)'),
        findsOneWidget);
  });

  testWidgets('warns when a coordinate falls outside its range',
      (tester) async {
    await _pumpSection(
      tester,
      draft: (draftId) => CaseDraft(
        draftId: draftId,
        latitude: 120,
        longitude: -2.13,
      ),
    );

    expect(find.text('La latitud va de -90 a 90'), findsOneWidget);
  });

  testWidgets('keeps an unparsable coordinate out of the draft',
      (tester) async {
    final (container, _) = await _pumpSection(tester);

    await tester.enterText(
      find.byKey(const Key('intake-field-latitude')),
      'cuarenta',
    );
    await tester.pump();

    // Texto que no es un número no debe corromper el borrador.
    expect(container.read(editingDraftProvider)!.latitude, isNull);
    expect(find.text('La latitud es obligatoria'), findsOneWidget);
  });
}
