import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/application/case_draft_providers.dart';
import 'package:true_app/features/cases/data/case_drafts_store.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';
import 'package:true_app/features/cases/domain/case_timeline_event.dart';
import 'package:true_app/features/cases/presentation/intake/sections/summary_section.dart';
import 'package:true_app/features/cases/presentation/intake/sections/timeline_section.dart';

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
  WidgetTester tester,
  Widget section, {
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
      child: MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: section)),
      ),
    ),
  );
  await tester.pump();
  return (container, store);
}

void main() {
  group('SummarySection', () {
    testWidgets('captures the victim description and autosaves it',
        (tester) async {
      final (container, store) =
          await _pumpSection(tester, const SummarySection());

      await tester.enterText(
        find.byKey(const Key('intake-field-victim')),
        'Al menos 5 víctimas confirmadas',
      );
      await tester.pump();

      expect(container.read(editingDraftProvider)!.victim,
          'Al menos 5 víctimas confirmadas');
      expect(store.saved.single.victim, 'Al menos 5 víctimas confirmadas');
    });

    testWidgets('turns the tag line into normalised tags', (tester) async {
      final (container, _) =
          await _pumpSection(tester, const SummarySection());

      await tester.enterText(
        find.byKey(const Key('intake-field-tags')),
        '1960s, EE. UU. , cifrado',
      );
      await tester.pump();

      expect(container.read(editingDraftProvider)!.tags,
          ['1960s', 'ee. uu.', 'cifrado']);
    });

    testWidgets('shows the tags of a resumed draft as an editable line',
        (tester) async {
      await _pumpSection(
        tester,
        const SummarySection(),
        draft: (draftId) => CaseDraft(
          draftId: draftId,
          tags: const ['1960s', 'ee. uu.'],
        ),
      );

      expect(find.text('1960s, ee. uu.'), findsOneWidget);
    });

    testWidgets('keeps summary, victim and tags when typed one after another',
        (tester) async {
      // El mismo riesgo de siempre: sin rebuild entre campos, no deben
      // pisarse entre sí.
      final (container, _) =
          await _pumpSection(tester, const SummarySection());

      await tester.enterText(
        find.byKey(const Key('intake-field-summary')),
        'Un resumen.',
      );
      await tester.enterText(
        find.byKey(const Key('intake-field-victim')),
        'Dos víctimas',
      );
      await tester.enterText(
        find.byKey(const Key('intake-field-tags')),
        'cifrado',
      );
      await tester.pump();

      final saved = container.read(editingDraftProvider)!;
      expect(saved.summary, 'Un resumen.');
      expect(saved.victim, 'Dos víctimas');
      expect(saved.tags, ['cifrado']);
    });
  });

  group('TimelineSection', () {
    testWidgets('adds a milestone with its date, title and kind',
        (tester) async {
      final (container, store) =
          await _pumpSection(tester, const TimelineSection());

      await tester.tap(find.byKey(const Key('intake-add-timeline-button')));
      await tester.pump();

      await tester.enterText(
        find.byKey(const Key('intake-field-timeline-date-0')),
        '1968–69',
      );
      await tester.enterText(
        find.byKey(const Key('intake-field-timeline-title-0')),
        'Primeros ataques confirmados',
      );
      await tester.pump();

      final event = container.read(editingDraftProvider)!.timeline.single;
      expect(event.date, '1968–69');
      expect(event.title, 'Primeros ataques confirmados');
      expect(store.saved.single.timeline.single.title,
          'Primeros ataques confirmados');
    });

    testWidgets('offers every timeline kind and keeps the choice',
        (tester) async {
      final (container, _) = await _pumpSection(
        tester,
        const TimelineSection(),
        draft: (draftId) => CaseDraft(
          draftId: draftId,
          timeline: const [DraftTimelineEvent(date: '1969', title: 'Hito')],
        ),
      );

      await tester.tap(find.byKey(const Key('intake-field-timeline-kind-0')));
      await tester.pumpAndSettle();

      for (final kind in CaseTimelineKind.values) {
        expect(find.text(kind.label), findsWidgets);
      }

      await tester.tap(find.text(CaseTimelineKind.solved.label).last);
      await tester.pumpAndSettle();

      expect(container.read(editingDraftProvider)!.timeline.single.kind,
          CaseTimelineKind.solved);
    });

    testWidgets('removes a milestone from the draft', (tester) async {
      final (container, _) = await _pumpSection(
        tester,
        const TimelineSection(),
        draft: (draftId) => CaseDraft(
          draftId: draftId,
          timeline: const [
            DraftTimelineEvent(date: '1968', title: 'Primero'),
            DraftTimelineEvent(date: '1969', title: 'Segundo'),
          ],
        ),
      );

      await tester.tap(find.byKey(const Key('intake-field-timeline-remove-0')));
      await tester.pump();

      final timeline = container.read(editingDraftProvider)!.timeline;
      expect(timeline, hasLength(1));
      expect(timeline.single.title, 'Segundo');
    });

    testWidgets('keeps both milestones when typed without a rebuild between',
        (tester) async {
      final (container, _) = await _pumpSection(
        tester,
        const TimelineSection(),
        draft: (draftId) => CaseDraft(
          draftId: draftId,
          timeline: const [DraftTimelineEvent(), DraftTimelineEvent()],
        ),
      );

      await tester.enterText(
        find.byKey(const Key('intake-field-timeline-title-0')),
        'Primero',
      );
      await tester.enterText(
        find.byKey(const Key('intake-field-timeline-title-1')),
        'Segundo',
      );
      await tester.pump();

      final timeline = container.read(editingDraftProvider)!.timeline;
      expect(timeline.first.title, 'Primero');
      expect(timeline.last.title, 'Segundo');
    });
  });
}
