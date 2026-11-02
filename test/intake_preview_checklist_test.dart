import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/application/case_draft_providers.dart';
import 'package:true_app/features/cases/application/cases_providers.dart';
import 'package:true_app/features/cases/application/draft_validator.dart';
import 'package:true_app/features/cases/data/case_drafts_store.dart';
import 'package:true_app/features/cases/domain/case_category.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';
import 'package:true_app/features/cases/domain/case_status.dart';
import 'package:true_app/features/cases/presentation/intake/case_form_section.dart';
import 'package:true_app/features/cases/presentation/intake/intake_preview_panel.dart';

import 'test_support/sample_cases.dart';

class _FakeStore implements CaseDraftsStore {
  @override
  Future<List<CaseDraft>> loadDrafts() async => const <CaseDraft>[];

  @override
  Future<void> saveDrafts(List<CaseDraft> drafts) async {}
}

const _ids = ['title', 'classification', 'place', 'coordinates'];

Future<ProviderContainer> _pump(
  WidgetTester tester,
  CaseDraft Function(String id) draft, {
  ValueChanged<int>? onSelectSection,
  Size size = const Size(1440, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      caseDraftsStoreProvider.overrideWithValue(_FakeStore()),
      casesRepositoryProvider.overrideWithValue(const FakeCasesRepository([])),
    ],
  );
  addTearDown(container.dispose);
  await container.read(caseDraftsProvider.future);
  final id = await container.read(caseDraftsProvider.notifier).createDraft();
  await container.read(caseDraftsProvider.notifier).updateDraft(draft(id));
  container.read(editingDraftIdProvider.notifier).state = id;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: IntakePreviewPanel(onSelectSection: onSelectSection),
        ),
      ),
    ),
  );
  await tester.pump();
  return container;
}

CaseDraft _complete(String id) => CaseDraft(
  draftId: id,
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

bool _done(WidgetTester tester, String id) => find
    .descendant(
      of: find.byKey(Key('intake-checklist-$id')),
      matching: find.byIcon(Icons.check),
    )
    .evaluate()
    .isNotEmpty;

void main() {
  testWidgets('the checklist mirrors validateDraft for an empty draft', (
    tester,
  ) async {
    final container = await _pump(tester, (id) => CaseDraft(draftId: id));
    final result = validateDraft(container.read(editingDraftProvider)!);

    expect(result.titleError, isNotNull);
    for (final id in _ids) {
      expect(find.byKey(Key('intake-checklist-$id')), findsOneWidget);
      expect(_done(tester, id), isFalse, reason: id);
    }
    expect(find.text('Campos obligatorios'.toUpperCase()), findsOneWidget);
    expect(find.text(result.titleError!), findsOneWidget);
    expect(find.text(result.categoryError!), findsOneWidget);
    expect(find.text(result.countryError!), findsOneWidget);
    expect(find.text(result.latitudeError!), findsOneWidget);
  });

  testWidgets('a complete draft marks every item as done', (tester) async {
    await _pump(tester, _complete);
    for (final id in _ids) {
      expect(_done(tester, id), isTrue, reason: id);
    }
  });

  testWidgets('the checklist updates when a field is fixed', (tester) async {
    final container = await _pump(
      tester,
      (id) => _complete(id).copyWith(title: ''),
    );
    expect(_done(tester, 'title'), isFalse);
    expect(_done(tester, 'place'), isTrue);

    final draft = container.read(editingDraftProvider)!;
    await container
        .read(caseDraftsProvider.notifier)
        .updateDraft(draft.copyWith(title: 'Ya tiene título'));
    await tester.pump();

    expect(_done(tester, 'title'), isTrue);
  });

  testWidgets('tapping an item reports the index of its section', (
    tester,
  ) async {
    final selected = <int>[];
    await _pump(
      tester,
      (id) => CaseDraft(draftId: id),
      onSelectSection: selected.add,
    );

    int indexOf(String title) =>
        kCaseFormSections.indexWhere((s) => s.title == title);

    await tester.ensureVisible(find.byKey(const Key('intake-checklist-title')));
    await tester.tap(find.byKey(const Key('intake-checklist-title')));
    await tester.tap(find.byKey(const Key('intake-checklist-coordinates')));
    expect(selected, [indexOf('Datos básicos'), indexOf('Ubicación')]);
  });

  testWidgets('shows the reserved review notice and no submit action', (
    tester,
  ) async {
    await _pump(tester, _complete);
    expect(find.text('ENVIAR A REVISIÓN · RESERVADO'), findsOneWidget);
    expect(
      find.text(
        'Aquí irá el envío a revisión. Todavía no está disponible: de '
        'momento, exporta con «Copiar JSON».',
      ),
      findsOneWidget,
    );
    expect(find.byType(ElevatedButton), findsNothing);
  });

  testWidgets('keeps the empty state without a draft', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          caseDraftsStoreProvider.overrideWithValue(_FakeStore()),
          casesRepositoryProvider.overrideWithValue(
            const FakeCasesRepository([]),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: IntakePreviewPanel())),
      ),
    );
    await tester.pump();
    expect(
      find.text('Crea o selecciona un borrador para previsualizarlo.'),
      findsOneWidget,
    );
    expect(find.text('Campos obligatorios'.toUpperCase()), findsNothing);
  });

  for (final size in const [Size(1440, 900), Size(390, 844)]) {
    testWidgets('does not overflow at ${size.width.toInt()} px', (
      tester,
    ) async {
      await _pump(tester, (id) => CaseDraft(draftId: id), size: size);
      expect(tester.takeException(), isNull);
      await _pump(tester, _complete, size: size);
      expect(tester.takeException(), isNull);
    });
  }
}
