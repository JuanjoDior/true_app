import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:true_app/features/cases/data/case_drafts_store.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads an empty list when nothing was stored yet', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SharedPreferencesCaseDraftsStore();

    final drafts = await store.loadDrafts();

    expect(drafts, isEmpty);
  });

  test('saves drafts inside a schemaVersion envelope and reloads them', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SharedPreferencesCaseDraftsStore();
    const draft = CaseDraft(draftId: 'draft-1', title: 'Caso guardado');

    await store.saveDrafts(const [draft]);

    final prefs = await SharedPreferences.getInstance();
    final rawEnvelope =
        jsonDecode(prefs.getString('truecrime.case_drafts')!)
            as Map<String, dynamic>;
    expect(rawEnvelope['schemaVersion'], 1);
    expect(rawEnvelope['drafts'], hasLength(1));

    final reloaded = await store.loadDrafts();
    expect(reloaded, hasLength(1));
    expect(reloaded.first.draftId, 'draft-1');
    expect(reloaded.first.title, 'Caso guardado');
  });
}
