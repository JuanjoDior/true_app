import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/config/map_config.dart';
import 'package:true_app/core/design/design.dart';
import 'package:true_app/features/cases/application/case_draft_providers.dart';
import 'package:true_app/features/cases/application/cases_providers.dart';
import 'package:true_app/features/cases/application/intake_session_providers.dart';
import 'package:true_app/features/cases/data/case_drafts_store.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';
import 'package:true_app/features/cases/presentation/intake/intake_workspace_screen.dart';

import 'test_support/fake_intake_auth.dart';
import 'test_support/sample_cases.dart';

class _FakeStore implements CaseDraftsStore {
  _FakeStore(this.saved);
  List<CaseDraft> saved;

  @override
  Future<List<CaseDraft>> loadDrafts() async => saved;

  @override
  Future<void> saveDrafts(List<CaseDraft> drafts) async => saved = drafts;
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  Size size = const Size(1440, 900),
  FakeIntakeAuth? auth,
  String? editing,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      intakeAuthProvider.overrideWithValue(auth ?? FakeIntakeAuth()),
      caseDraftsStoreProvider.overrideWithValue(
        _FakeStore(const [
          CaseDraft(draftId: 'draft-a', title: 'Caso A'),
          CaseDraft(draftId: 'draft-b'),
        ]),
      ),
      casesRepositoryProvider.overrideWithValue(const FakeCasesRepository([])),
      mapConfigProvider.overrideWithValue(MapConfig.testing()),
    ],
  );
  addTearDown(container.dispose);
  await container.read(caseDraftsProvider.future);
  if (editing != null) {
    container.read(editingDraftIdProvider.notifier).state = editing;
  }
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: IntakeWorkspaceScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('drafts pane uses the design system for header and cards', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.byType(DsMonoLabel), findsWidgets);
    expect(find.text('BORRADORES · 2'), findsOneWidget);
    final cardA = find.byKey(const Key('intake-draft-item-draft-a'));
    expect(
      find.descendant(of: cardA, matching: find.text('Caso A')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: cardA, matching: find.byType(DsStatusLabel)),
      findsOneWidget,
    );
    expect(find.text('Incompleto'), findsNWidgets(2));
    expect(
      find.byKey(const Key('intake-draft-delete-draft-a')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('intake-draft-delete-draft-a')),
        matching: find.byType(DsPressable),
      ),
      findsOneWidget,
    );
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('selecting a draft marks its card as selected', (tester) async {
    final container = await _pump(tester);
    await tester.tap(find.byKey(const Key('intake-draft-item-draft-b')));
    await tester.pumpAndSettle();

    expect(container.read(editingDraftIdProvider), 'draft-b');
    final selected = tester.getSemantics(
      find.byKey(const Key('intake-draft-item-draft-b')),
    );
    expect(selected.flagsCollection.isSelected.toString(), contains('isTrue'));
  });

  testWidgets('account footer offers sign-in as a design-system button', (
    tester,
  ) async {
    await _pump(tester);
    final signIn = find.byKey(const Key('intake-signin-open'));
    expect(signIn, findsOneWidget);
    expect(tester.widget(signIn), isA<DsButton>());
    expect(find.text('SIN SESIÓN'), findsOneWidget);
  });

  testWidgets('signed-in footer keeps the e-mail verbatim and sign-out', (
    tester,
  ) async {
    await _pump(tester, auth: FakeIntakeAuth.signedIn());
    expect(find.text('ivan@example.com'), findsOneWidget);
    expect(
      tester.widget(find.byKey(const Key('intake-signout-button'))),
      isA<DsButton>(),
    );
  });

  testWidgets('desktop top bar uses design-system controls', (tester) async {
    await _pump(tester);
    expect(
      tester.widget(find.byKey(const Key('intake-back-button'))),
      isA<DsIconButton>(),
    );
    final newDraft = find.byKey(const Key('intake-new-draft-button'));
    expect(tester.widget(newDraft), isA<DsButton>());
    expect(find.text('Nuevo borrador'), findsOneWidget);
    expect(find.text('Formulario de casos'), findsOneWidget);
  });

  testWidgets('narrow top bar keeps icon controls with the same keys', (
    tester,
  ) async {
    await _pump(tester, size: const Size(360, 780), editing: 'draft-a');
    for (final key in const [
      'intake-back-button',
      'intake-drafts-toggle-button',
      'intake-preview-toggle-button',
      'intake-new-draft-button',
    ]) {
      expect(
        tester.widget(find.byKey(Key(key))),
        isA<DsIconButton>(),
        reason: key,
      );
    }
    expect(tester.takeException(), isNull);
  });
}
