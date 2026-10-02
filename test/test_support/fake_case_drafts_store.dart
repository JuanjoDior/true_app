import 'package:true_app/features/cases/data/case_drafts_store.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';

/// [CaseDraftsStore] en memoria, compartido entre tests que necesitan un
/// doble simple sin tocar `shared_preferences` (mismo patrón que los
/// `_FakeCaseDraftsStore` privados repetidos en varios ficheros de test).
class FakeCaseDraftsStore implements CaseDraftsStore {
  FakeCaseDraftsStore([List<CaseDraft>? seed]) : saved = seed ?? const [];

  List<CaseDraft> saved;
  int saveCalls = 0;

  @override
  Future<List<CaseDraft>> loadDrafts() async => saved;

  @override
  Future<void> saveDrafts(List<CaseDraft> drafts) async {
    saveCalls++;
    saved = drafts;
  }
}
