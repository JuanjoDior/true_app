import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/application/case_draft_providers.dart';
import 'package:true_app/features/cases/data/case_drafts_store.dart';
import 'package:true_app/features/cases/domain/case_category.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';
import 'package:true_app/features/cases/domain/case_status.dart';
import 'package:true_app/features/cases/application/cases_providers.dart';
import 'package:true_app/features/cases/domain/true_crime_case.dart';
import 'package:true_app/features/cases/presentation/intake/export_case_button.dart';

import 'test_support/sample_cases.dart';

class _FakeCaseDraftsStore implements CaseDraftsStore {
  List<CaseDraft> saved = const <CaseDraft>[];

  @override
  Future<List<CaseDraft>> loadDrafts() async => saved;

  @override
  Future<void> saveDrafts(List<CaseDraft> drafts) async {
    saved = drafts;
  }
}

/// Caso ya publicado en el catálogo, sólo para ocupar un slug.
TrueCrimeCase publishedCaseWithSlug(String slug) {
  return TrueCrimeCase(
    id: slug,
    slug: slug,
    title: slug,
    category: CaseCategory.unsolved,
    country: 'España',
    countryCode: 'ES',
    regionOrCity: 'Cuenca',
    year: 1974,
    latitude: 40.07,
    longitude: -2.13,
    summary: '',
    tags: const <String>[],
    sources: const [],
  );
}

CaseDraft _publishable(String draftId) {
  return CaseDraft(
    draftId: draftId,
    title: 'El caso del faro',
    category: CaseCategory.unsolved,
    year: 1974,
    status: CaseStatus.open,
    country: 'España',
    countryCode: 'es',
    regionOrCity: 'Cuenca',
    latitude: 40.07,
    longitude: -2.13,
    summary: 'Un resumen editorial.',
  );
}

/// Captura lo que la app envía al portapapeles del sistema.
List<String> _interceptClipboard(WidgetTester tester) {
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
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });
  return copied;
}

Future<ProviderContainer> _pumpButton(
  WidgetTester tester, {
  CaseDraft? draft,
  List<TrueCrimeCase> published = const <TrueCrimeCase>[],
  List<CaseDraft> otherDrafts = const <CaseDraft>[],
}) async {
  final store = _FakeCaseDraftsStore()..saved = otherDrafts;
  final container = ProviderContainer(
    overrides: [
      caseDraftsStoreProvider.overrideWithValue(store),
      casesRepositoryProvider.overrideWithValue(FakeCasesRepository(published)),
    ],
  );
  addTearDown(container.dispose);

  await container.read(caseDraftsProvider.future);
  await container.read(casesProvider.future);
  final draftId = await container.read(caseDraftsProvider.notifier).createDraft();
  if (draft != null) {
    await container.read(caseDraftsProvider.notifier).updateDraft(draft);
  }
  container.read(editingDraftIdProvider.notifier).state = draftId;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(body: Center(child: ExportCaseButton())),
      ),
    ),
  );
  await tester.pump();
  return container;
}

void main() {
  testWidgets('is disabled while the draft is not publishable', (tester) async {
    await _pumpButton(tester);

    final button = tester.widget<TextButton>(
      find.byKey(const Key('intake-export-button')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('copies the case JSON to the clipboard when publishable',
      (tester) async {
    final copied = _interceptClipboard(tester);
    final container = await _pumpButton(tester);
    final draftId = container.read(editingDraftIdProvider)!;
    await container
        .read(caseDraftsProvider.notifier)
        .updateDraft(_publishable(draftId));
    await tester.pump();

    await tester.tap(find.byKey(const Key('intake-export-button')));
    await tester.pump();

    expect(copied, hasLength(1));
    final exported = jsonDecode(copied.single) as Map<String, dynamic>;
    expect(exported['slug'], 'el-caso-del-faro');
    expect(exported['countryCode'], 'ES');
    expect(exported['latitude'], 40.07);
  });

  testWidgets('suffixes the slug when the catalogue already has that case',
      (tester) async {
    // Exportar dos veces el mismo caso no debe emitir dos veces el mismo id.
    final copied = _interceptClipboard(tester);
    final container = await _pumpButton(
      tester,
      published: [publishedCaseWithSlug('el-caso-del-faro')],
    );
    final draftId = container.read(editingDraftIdProvider)!;
    await container
        .read(caseDraftsProvider.notifier)
        .updateDraft(_publishable(draftId));
    await tester.pump();

    await tester.tap(find.byKey(const Key('intake-export-button')));
    await tester.pump();

    final exported = jsonDecode(copied.single) as Map<String, dynamic>;
    expect(exported['slug'], 'el-caso-del-faro-2');
    expect(exported['id'], 'el-caso-del-faro-2');
  });

  testWidgets('also avoids colliding with another draft that is not published',
      (tester) async {
    final copied = _interceptClipboard(tester);
    final container = await _pumpButton(
      tester,
      otherDrafts: const [
        CaseDraft(draftId: 'draft-otro', title: 'El caso del faro'),
      ],
    );
    final draftId = container.read(editingDraftIdProvider)!;
    await container
        .read(caseDraftsProvider.notifier)
        .updateDraft(_publishable(draftId));
    await tester.pump();

    await tester.tap(find.byKey(const Key('intake-export-button')));
    await tester.pump();

    expect(
      (jsonDecode(copied.single) as Map<String, dynamic>)['slug'],
      'el-caso-del-faro-2',
    );
  });

  testWidgets('leaves the slug alone when nothing collides', (tester) async {
    final copied = _interceptClipboard(tester);
    final container = await _pumpButton(
      tester,
      published: [publishedCaseWithSlug('zodiac')],
    );
    final draftId = container.read(editingDraftIdProvider)!;
    await container
        .read(caseDraftsProvider.notifier)
        .updateDraft(_publishable(draftId));
    await tester.pump();

    await tester.tap(find.byKey(const Key('intake-export-button')));
    await tester.pump();

    expect(
      (jsonDecode(copied.single) as Map<String, dynamic>)['slug'],
      'el-caso-del-faro',
    );
  });

  testWidgets('confirms the copy so it is clear something happened',
      (tester) async {
    _interceptClipboard(tester);
    final container = await _pumpButton(tester);
    final draftId = container.read(editingDraftIdProvider)!;
    await container
        .read(caseDraftsProvider.notifier)
        .updateDraft(_publishable(draftId));
    await tester.pump();

    await tester.tap(find.byKey(const Key('intake-export-button')));
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('cases.json'), findsOneWidget);
  });

  testWidgets('renders nothing when no draft is being edited', (tester) async {
    final container = ProviderContainer(
      overrides: [
        caseDraftsStoreProvider.overrideWithValue(_FakeCaseDraftsStore()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(caseDraftsProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: Center(child: ExportCaseButton())),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('intake-export-button')), findsNothing);
  });
}
