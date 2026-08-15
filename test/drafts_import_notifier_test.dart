import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/application/case_draft_providers.dart';
import 'package:true_app/features/cases/data/case_drafts_store.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';

/// Importar una copia de seguridad en el workspace.
///
/// Las aserciones miran lo PERSISTIDO, no el estado en memoria: si la
/// importación no llega al disco, restaurar una copia y cerrar el navegador
/// pierde exactamente lo que se acababa de recuperar.

class _RecordingStore implements CaseDraftsStore {
  _RecordingStore(this._drafts);

  List<CaseDraft> _drafts;

  @override
  Future<List<CaseDraft>> loadDrafts() async => _drafts;

  @override
  Future<void> saveDrafts(List<CaseDraft> drafts) async => _drafts = drafts;

  List<CaseDraft> get saved => _drafts;
}

Future<(ProviderContainer, _RecordingStore)> _workspace(
  List<CaseDraft> existing,
) async {
  final store = _RecordingStore(existing);
  final container = ProviderContainer(
    overrides: [caseDraftsStoreProvider.overrideWithValue(store)],
  );
  addTearDown(container.dispose);
  await container.read(caseDraftsProvider.future);
  return (container, store);
}

void main() {
  test('an imported draft is persisted, not just held in memory', () async {
    final (container, store) = await _workspace(const []);

    await container.read(caseDraftsProvider.notifier).importDrafts(const [
      CaseDraft(draftId: 'draft-a', title: 'Recuperado'),
    ]);

    expect(store.saved.single.title, 'Recuperado');
  });

  test('an imported draft shows up in the workspace', () async {
    final (container, _) = await _workspace(const []);

    await container.read(caseDraftsProvider.notifier).importDrafts(const [
      CaseDraft(draftId: 'draft-a', title: 'Recuperado'),
    ]);

    expect(
      container.read(caseDraftsProvider).value!.single.title,
      'Recuperado',
    );
  });

  test('importing does not destroy a draft that only exists locally', () async {
    // Restaurar una copia vieja no puede borrar el trabajo posterior.
    final (container, store) = await _workspace(const [
      CaseDraft(draftId: 'draft-local', title: 'Hecho después'),
    ]);

    await container.read(caseDraftsProvider.notifier).importDrafts(const [
      CaseDraft(draftId: 'draft-a', title: 'De la copia'),
    ]);

    expect(
      store.saved.map((draft) => draft.draftId),
      containsAll(const ['draft-local', 'draft-a']),
    );
  });

  test('the backup version wins for a draft that exists in both', () async {
    final (container, store) = await _workspace(const [
      CaseDraft(draftId: 'draft-a', title: 'Viejo'),
    ]);

    await container.read(caseDraftsProvider.notifier).importDrafts(const [
      CaseDraft(draftId: 'draft-a', title: 'De la copia'),
    ]);

    expect(store.saved.single.title, 'De la copia');
  });

  test('importing an empty backup leaves everything alone', () async {
    final (container, store) = await _workspace(const [
      CaseDraft(draftId: 'draft-a', title: 'Local'),
    ]);

    await container.read(caseDraftsProvider.notifier).importDrafts(const []);

    expect(store.saved.single.title, 'Local');
  });
}
