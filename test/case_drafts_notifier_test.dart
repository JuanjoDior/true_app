import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/application/case_draft_providers.dart';
import 'package:true_app/features/cases/data/case_drafts_store.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';

/// Fake en memoria que mimetiza `_FakeAssetBundle`: nada de IO real,
/// solo una lista mutable que representa "el disco".
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
  test('creates a new draft and autosaves it to the store', () async {
    final store = _FakeCaseDraftsStore();
    final container = ProviderContainer(
      overrides: [caseDraftsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    await container.read(caseDraftsProvider.future);
    final draftId = await container
        .read(caseDraftsProvider.notifier)
        .createDraft();

    final drafts = container.read(caseDraftsProvider).value!;
    expect(drafts, hasLength(1));
    expect(drafts.first.draftId, draftId);
    expect(store.saved, hasLength(1));
  });

  test('edits a field on the draft and autosaves without an explicit save',
      () async {
    final store = _FakeCaseDraftsStore();
    final container = ProviderContainer(
      overrides: [caseDraftsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    await container.read(caseDraftsProvider.future);
    final draftId = await container
        .read(caseDraftsProvider.notifier)
        .createDraft();

    await container
        .read(caseDraftsProvider.notifier)
        .updateDraft(CaseDraft(draftId: draftId, title: 'Nuevo título'));

    final drafts = container.read(caseDraftsProvider).value!;
    expect(drafts.first.title, 'Nuevo título');
    expect(store.saved.first.title, 'Nuevo título');
  });

  test('resumes drafts from a prior session on reload', () async {
    final store = _FakeCaseDraftsStore();
    final firstContainer = ProviderContainer(
      overrides: [caseDraftsStoreProvider.overrideWithValue(store)],
    );
    await firstContainer.read(caseDraftsProvider.future);
    await firstContainer.read(caseDraftsProvider.notifier).createDraft();
    firstContainer.dispose();

    final secondContainer = ProviderContainer(
      overrides: [caseDraftsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(secondContainer.dispose);

    final drafts = await secondContainer.read(caseDraftsProvider.future);

    expect(drafts, hasLength(1));
  });

  test('deletes a draft and removes it from local storage', () async {
    final store = _FakeCaseDraftsStore();
    final container = ProviderContainer(
      overrides: [caseDraftsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    await container.read(caseDraftsProvider.future);
    final draftId = await container
        .read(caseDraftsProvider.notifier)
        .createDraft();

    await container.read(caseDraftsProvider.notifier).deleteDraft(draftId);

    final drafts = container.read(caseDraftsProvider).value!;
    expect(drafts, isEmpty);
    expect(store.saved, isEmpty);
  });
}
