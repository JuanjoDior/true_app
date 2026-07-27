import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/application/case_draft_providers.dart';
import 'package:true_app/features/cases/application/cases_providers.dart';
import 'package:true_app/features/cases/data/case_drafts_store.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';
import 'package:true_app/features/cases/presentation/intake/intake_preview_panel.dart';

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

Future<ProviderContainer> _pumpPreview(
  WidgetTester tester,
  List<DraftLink> links,
) async {
  final store = _FakeCaseDraftsStore();
  final container = ProviderContainer(
    overrides: [
      caseDraftsStoreProvider.overrideWithValue(store),
      casesRepositoryProvider.overrideWithValue(const FakeCasesRepository([])),
    ],
  );
  addTearDown(container.dispose);

  await container.read(caseDraftsProvider.future);
  final draftId = await container.read(caseDraftsProvider.notifier).createDraft();
  await container.read(caseDraftsProvider.notifier).updateDraft(
        CaseDraft(draftId: draftId, title: 'Caso agrupado', links: links),
      );
  container.read(editingDraftIdProvider.notifier).state = draftId;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
          body: SizedBox(height: 700, child: IntakePreviewPanel()),
        ),
      ),
    ),
  );
  await tester.pump();
  return container;
}

void main() {
  testWidgets('groups preview links by their typed kind', (tester) async {
    await _pumpPreview(tester, const [
      DraftLink(
        title: 'Serial',
        url: 'https://example.com/serial',
        kind: DraftLinkKind.podcast,
      ),
      DraftLink(
        title: 'Crimen en el bosque',
        url: 'https://example.com/crimen',
        kind: DraftLinkKind.podcast,
      ),
      DraftLink(
        title: 'Documental',
        url: 'https://example.com/doc',
        kind: DraftLinkKind.video,
      ),
    ]);

    final podcastGroup =
        find.byKey(const Key('intake-preview-link-group-podcast'));
    final videoGroup = find.byKey(const Key('intake-preview-link-group-video'));

    expect(podcastGroup, findsOneWidget);
    expect(videoGroup, findsOneWidget);

    // Los dos podcasts viven juntos en su grupo.
    expect(
      find.descendant(of: podcastGroup, matching: find.text('Serial')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: podcastGroup,
        matching: find.text('Crimen en el bosque'),
      ),
      findsOneWidget,
    );
    // Y el vídeo queda fuera de ese grupo, en el suyo.
    expect(
      find.descendant(of: podcastGroup, matching: find.text('Documental')),
      findsNothing,
    );
    expect(
      find.descendant(of: videoGroup, matching: find.text('Documental')),
      findsOneWidget,
    );
  });

  testWidgets('groups unset and "other" links under a single unclassified group',
      (tester) async {
    await _pumpPreview(tester, const [
      DraftLink(title: 'Sin tipo', url: 'https://example.com/a'),
      DraftLink(
        title: 'Marcado como otro',
        url: 'https://example.com/b',
        kind: DraftLinkKind.other,
      ),
    ]);

    final otherGroup = find.byKey(const Key('intake-preview-link-group-other'));

    expect(otherGroup, findsOneWidget);
    expect(
      find.descendant(of: otherGroup, matching: find.text('Sin tipo')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: otherGroup, matching: find.text('Marcado como otro')),
      findsOneWidget,
    );
  });

  testWidgets('renders no link groups when the draft has no links',
      (tester) async {
    await _pumpPreview(tester, const []);

    for (final kind in DraftLinkKind.values) {
      expect(
        find.byKey(Key('intake-preview-link-group-${kind.name}')),
        findsNothing,
      );
    }
  });
}
