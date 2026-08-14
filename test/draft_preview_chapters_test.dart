import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/application/case_draft_providers.dart';
import 'package:true_app/features/cases/data/case_drafts_store.dart';
import 'package:true_app/features/cases/domain/case_chapter.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';

/// Los capítulos llegan al caso de previsualización, que es lo que pinta el
/// expediente compartido [spec: case-editorial-chapters, Draft Persistence and
/// Live Preview]. Todavía sin editor: la Unit 5 es la que lo expone.
class _FakeStore implements CaseDraftsStore {
  _FakeStore(this._drafts);

  List<CaseDraft> _drafts;

  @override
  Future<List<CaseDraft>> loadDrafts() async => _drafts;

  @override
  Future<void> saveDrafts(List<CaseDraft> drafts) async => _drafts = drafts;
}

Future<ProviderContainer> _editing(CaseDraft draft) async {
  final container = ProviderContainer(
    overrides: [
      caseDraftsStoreProvider.overrideWithValue(_FakeStore([draft])),
    ],
  );
  addTearDown(container.dispose);
  await container.read(caseDraftsProvider.future);
  container.read(editingDraftIdProvider.notifier).state = draft.draftId;
  return container;
}

void main() {
  test('the preview case carries the meaningful chapters', () async {
    final container = await _editing(
      const CaseDraft(
        draftId: 'draft-a',
        chapters: CaseChapters(background: 'Antes'),
      ),
    );

    final preview = container.read(draftPreviewCaseProvider);

    expect(preview!.chapters.contentFor(CaseChapterType.background), 'Antes');
  });

  test('the preview case orders them editorially', () async {
    final container = await _editing(
      const CaseDraft(
        draftId: 'draft-a',
        chapters: CaseChapters(currentStatus: 'Ahora', background: 'Antes'),
      ),
    );

    final preview = container.read(draftPreviewCaseProvider);

    expect(
      preview!.chapters.orderedMeaningful.map((chapter) => chapter.type),
      orderedEquals(const [
        CaseChapterType.background,
        CaseChapterType.currentStatus,
      ]),
    );
  });

  // Este y el siguiente llevan SIEMPRE un capítulo con contenido al lado del
  // vacío. Con `isEmpty` a secas pasarían igual sin proyección ninguna: una
  // aserción que no puede fallar. Con el capítulo bueno delante, sólo pasan si
  // los capítulos cruzan de verdad.
  test('the preview case omits a whitespace-only chapter', () async {
    final container = await _editing(
      const CaseDraft(
        draftId: 'draft-a',
        chapters: CaseChapters(background: 'Antes', events: '   '),
      ),
    );

    final preview = container.read(draftPreviewCaseProvider);

    expect(
      preview!.chapters.orderedMeaningful.map((chapter) => chapter.type),
      orderedEquals(const [CaseChapterType.background]),
    );
  });

  test('clearing a chapter removes it from the preview', () async {
    final container = await _editing(
      const CaseDraft(
        draftId: 'draft-a',
        chapters: CaseChapters(background: 'Antes', events: 'Hechos'),
      ),
    );

    await container
        .read(caseDraftsProvider.notifier)
        .editDraft(
          'draft-a',
          (current) => current.copyWith(
            chapters: current.chapters.withContent(
              CaseChapterType.background,
              '  ',
            ),
          ),
        );

    expect(
      container
          .read(draftPreviewCaseProvider)!
          .chapters
          .orderedMeaningful
          .map((chapter) => chapter.type),
      orderedEquals(const [CaseChapterType.events]),
    );
  });

  // Éste sí es `isEmpty` de verdad: el guardia contra darle un placeholder a
  // los capítulos como el resto del provider hace con 'Sin título' o 'Por
  // confirmar'. Muere si alguien inventa contenido para un caso sin capítulos.
  test('a draft without chapters previews without them', () async {
    final container = await _editing(const CaseDraft(draftId: 'draft-a'));

    expect(
      container.read(draftPreviewCaseProvider)!.chapters.orderedMeaningful,
      isEmpty,
    );
  });
}
