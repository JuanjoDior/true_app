import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/application/case_draft_providers.dart';
import 'package:true_app/features/cases/application/cases_providers.dart';
import 'package:true_app/features/cases/data/case_drafts_store.dart';
import 'package:true_app/features/cases/domain/case_category.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';
import 'package:true_app/features/cases/domain/case_status.dart';

import 'test_support/sample_cases.dart';

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

  test('two drafts created in the same millisecond get different ids',
      () async {
    // `DateTime.now()` en web tiene resolución de milisegundo (el reloj de
    // JS), así que dos toques rápidos en "nuevo borrador" pueden compartir
    // timestamp. Con el mismo `now` fijo se reproduce ese instante exacto de
    // forma determinista, sin depender de que el test corra rápido.
    final store = _FakeCaseDraftsStore();
    final container = ProviderContainer(
      overrides: [caseDraftsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    await container.read(caseDraftsProvider.future);
    final notifier = container.read(caseDraftsProvider.notifier);
    final now = DateTime(2026, 9, 16, 12, 0, 0, 123);

    final firstId = await notifier.createDraft(now: now);
    final secondId = await notifier.createDraft(now: now);

    expect(firstId, isNot(secondId));
    final drafts = container.read(caseDraftsProvider).value!;
    expect(drafts.map((draft) => draft.draftId).toSet(), hasLength(2));
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

  test('applies an edit on top of the draft as it is right now', () async {
    final store = _FakeCaseDraftsStore();
    final container = ProviderContainer(
      overrides: [caseDraftsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    await container.read(caseDraftsProvider.future);
    final draftId =
        await container.read(caseDraftsProvider.notifier).createDraft();
    final notifier = container.read(caseDraftsProvider.notifier);

    await notifier.editDraft(draftId, (draft) => draft.copyWith(title: 'Faro'));
    await notifier.editDraft(draftId, (draft) => draft.copyWith(year: 1974));

    final drafts = container.read(caseDraftsProvider).value!;
    expect(drafts.single.title, 'Faro');
    expect(drafts.single.year, 1974);
  });

  test('two edits derived from the same stale snapshot both survive', () async {
    // El formulario captura el borrador en su `build`. Si dos campos se
    // editan antes de que Flutter reconstruya, ambos parten del MISMO
    // borrador viejo — y el segundo no debe borrar lo que escribió el
    // primero.
    final store = _FakeCaseDraftsStore();
    final container = ProviderContainer(
      overrides: [caseDraftsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    await container.read(caseDraftsProvider.future);
    final draftId =
        await container.read(caseDraftsProvider.notifier).createDraft();
    final notifier = container.read(caseDraftsProvider.notifier);

    final futures = [
      notifier.editDraft(draftId, (draft) => draft.copyWith(title: 'Faro')),
      notifier.editDraft(draftId, (draft) => draft.copyWith(latitude: 43.39)),
    ];
    await Future.wait(futures);

    final drafts = container.read(caseDraftsProvider).value!;
    expect(drafts.single.title, 'Faro');
    expect(drafts.single.latitude, 43.39);
    expect(store.saved.single.title, 'Faro');
    expect(store.saved.single.latitude, 43.39);
  });

  test('ignores an edit aimed at a draft that no longer exists', () async {
    final store = _FakeCaseDraftsStore();
    final container = ProviderContainer(
      overrides: [caseDraftsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    await container.read(caseDraftsProvider.future);
    final draftId =
        await container.read(caseDraftsProvider.notifier).createDraft();
    final notifier = container.read(caseDraftsProvider.notifier);
    await notifier.deleteDraft(draftId);

    await notifier.editDraft(draftId, (draft) => draft.copyWith(title: 'Faro'));

    expect(container.read(caseDraftsProvider).value, isEmpty);
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

  test(
    'markHandedOff persists the marker on exactly the named drafts in one batched write',
    () async {
      final store = _FakeCaseDraftsStore();
      final container = ProviderContainer(
        overrides: [caseDraftsStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);

      await container.read(caseDraftsProvider.future);
      final notifier = container.read(caseDraftsProvider.notifier);
      final firstId = await notifier.createDraft();
      final secondId = await notifier.createDraft();
      final untouchedId = await notifier.createDraft();
      final now = DateTime.utc(2026, 9, 12);

      await notifier.markHandedOff({
        firstId: 'el-primer-caso',
        secondId: 'el-segundo-caso',
      }, now: now);

      final drafts = container.read(caseDraftsProvider).value!;
      final first = drafts.firstWhere((draft) => draft.draftId == firstId);
      final second = drafts.firstWhere((draft) => draft.draftId == secondId);
      final untouched = drafts.firstWhere(
        (draft) => draft.draftId == untouchedId,
      );

      expect(first.handoffSlug, 'el-primer-caso');
      expect(first.handoffAt, now);
      expect(second.handoffSlug, 'el-segundo-caso');
      expect(second.handoffAt, now);
      expect(untouched.handoffSlug, isNull);
      expect(untouched.handoffAt, isNull);
      expect(store.saved, hasLength(3));
    },
  );

  test(
    'pendingHandoffDraftsProvider returns exactly the drafts in state handedOff',
    () async {
      final store = _FakeCaseDraftsStore();
      final container = ProviderContainer(
        overrides: [
          caseDraftsStoreProvider.overrideWithValue(store),
          casesRepositoryProvider.overrideWithValue(
            const FakeCasesRepository([]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(casesProvider.future);
      await container.read(caseDraftsProvider.future);
      final notifier = container.read(caseDraftsProvider.notifier);
      final handedOffId = await notifier.createDraft();
      final readyId = await notifier.createDraft();
      final incompleteId = await notifier.createDraft();
      // `incompleteId` se deja sin título: no es válido, así que nunca cuenta
      // como `handedOff` aunque tuviera marcador.

      const validFields = CaseDraft(
        draftId: '',
        title: 'Caso válido',
        category: CaseCategory.unsolved,
        year: 1994,
        status: CaseStatus.open,
        country: 'España',
        countryCode: 'ES',
        regionOrCity: 'Cuenca',
        latitude: 40.07,
        longitude: -2.13,
      );
      await notifier.updateDraft(
        CaseDraft(
          draftId: readyId,
          title: validFields.title,
          category: validFields.category,
          year: validFields.year,
          status: validFields.status,
          country: validFields.country,
          countryCode: validFields.countryCode,
          regionOrCity: validFields.regionOrCity,
          latitude: validFields.latitude,
          longitude: validFields.longitude,
        ),
      );
      await notifier.updateDraft(
        CaseDraft(
          draftId: handedOffId,
          title: validFields.title,
          category: validFields.category,
          year: validFields.year,
          status: validFields.status,
          country: validFields.country,
          countryCode: validFields.countryCode,
          regionOrCity: validFields.regionOrCity,
          latitude: validFields.latitude,
          longitude: validFields.longitude,
        ),
      );
      await notifier.markHandedOff({
        handedOffId: 'caso-valido',
      }, now: DateTime.utc(2026, 9, 12));

      final pending = container.read(pendingHandoffDraftsProvider);

      expect(pending, hasLength(1));
      expect(pending.single.draftId, handedOffId);
      expect(pending.any((draft) => draft.draftId == readyId), isFalse);
      expect(pending.any((draft) => draft.draftId == incompleteId), isFalse);
    },
  );
}
