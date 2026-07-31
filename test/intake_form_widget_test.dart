import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/application/case_draft_providers.dart';
import 'package:true_app/features/cases/application/cases_providers.dart';
import 'package:true_app/features/cases/data/case_drafts_store.dart';
import 'package:true_app/features/cases/domain/case_category.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';
import 'package:true_app/features/cases/domain/case_status.dart';
import 'package:true_app/features/cases/presentation/intake/case_form_section.dart';
import 'package:true_app/features/home/presentation/widgets/situation/case_dossier_panel.dart';

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

void main() {
  testWidgets(
    'a draft filled through the intake sections renders via CaseDossierPanel with matching values',
    (tester) async {
      final store = _FakeCaseDraftsStore();
      final container = ProviderContainer(
        overrides: [
          caseDraftsStoreProvider.overrideWithValue(store),
          casesRepositoryProvider
              .overrideWithValue(const FakeCasesRepository([])),
        ],
      );
      addTearDown(container.dispose);

      await container.read(caseDraftsProvider.future);
      final draftId =
          await container.read(caseDraftsProvider.notifier).createDraft();
      await container.read(caseDraftsProvider.notifier).updateDraft(
            CaseDraft(
              draftId: draftId,
              category: CaseCategory.kidnapping,
              status: CaseStatus.solved,
              links: const [DraftLink()],
            ),
          );
      container.read(editingDraftIdProvider.notifier).state = draftId;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final section in kCaseFormSections)
                      Builder(builder: section.builder),
                    Consumer(
                      builder: (context, ref, _) {
                        final previewCase =
                            ref.watch(draftPreviewCaseProvider);
                        if (previewCase == null) {
                          return const SizedBox.shrink();
                        }
                        return SizedBox(
                          height: 700,
                          child: CaseDossierPanel(crimeCase: previewCase),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(
        find.byKey(const Key('intake-field-title')),
        'Caso de Iván',
      );
      await tester.enterText(
        find.byKey(const Key('intake-field-year')),
        '2010',
      );
      await tester.enterText(
        find.byKey(const Key('intake-field-summary')),
        'Resumen del caso de prueba.',
      );
      await tester.enterText(
        find.byKey(const Key('intake-field-link-title-0')),
        'Fuente citada',
      );
      await tester.enterText(
        find.byKey(const Key('intake-field-link-url-0')),
        'https://example.com',
      );
      await tester.pump();

      expect(
        find.descendant(
          of: find.byKey(const Key('detail-panel')),
          matching: find.text('Caso de Iván'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('detail-panel')),
          matching: find.text('SECUESTRO'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('detail-panel')),
          matching: find.text('RESUELTO'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('detail-panel')),
          matching: find.text('Resumen del caso de prueba.'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('detail-panel')),
          matching: find.text('Fuente citada'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'the link kind dropdown offers the typed kinds and persists the selection',
    (tester) async {
      final store = _FakeCaseDraftsStore();
      final container = ProviderContainer(
        overrides: [
          caseDraftsStoreProvider.overrideWithValue(store),
          casesRepositoryProvider
              .overrideWithValue(const FakeCasesRepository([])),
        ],
      );
      addTearDown(container.dispose);

      await container.read(caseDraftsProvider.future);
      final draftId =
          await container.read(caseDraftsProvider.notifier).createDraft();
      await container.read(caseDraftsProvider.notifier).updateDraft(
            CaseDraft(draftId: draftId, links: const [DraftLink()]),
          );
      container.read(editingDraftIdProvider.notifier).state = draftId;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final section in kCaseFormSections)
                      Builder(builder: section.builder),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // El formulario ya no cabe en el viewport de test: hay que traer el
      // desplegable a pantalla antes de tocarlo.
      await tester.ensureVisible(
        find.byKey(const Key('intake-field-link-kind-0')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('intake-field-link-kind-0')));
      await tester.pumpAndSettle();

      // El desplegable sólo ofrece los tipos tipados, sin texto libre.
      for (final kind in DraftLinkKind.values) {
        expect(find.text(kind.label), findsWidgets);
      }

      await tester.tap(find.text(DraftLinkKind.podcast.label).last);
      await tester.pumpAndSettle();

      expect(
        container.read(editingDraftProvider)!.links.single.kind,
        DraftLinkKind.podcast,
      );
      expect(store.saved.single.links.single.kind, DraftLinkKind.podcast);
    },
  );
}
