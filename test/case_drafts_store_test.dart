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

  test(
    'saves drafts inside a schemaVersion envelope and reloads them',
    () async {
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
    },
  );

  test('recovers a legacy backup when there is no primary list', () async {
    SharedPreferences.setMockInitialValues({
      _legacyKey: _envelope(const [
        {'draftId': 'draft-backup', 'title': 'Copia del navegador'},
      ]),
    });
    final store = SharedPreferencesCaseDraftsStore();

    final drafts = await store.loadDrafts();

    expect(drafts.single.draftId, 'draft-backup');
    expect(drafts.single.title, 'Copia del navegador');
    final prefs = await SharedPreferences.getInstance();
    expect(_savedIds(prefs), const ['draft-backup']);
  });

  test('legacy drafts show up next to an existing primary list', () async {
    // El fallo que motivó esto: con la clave principal presente, el respaldo
    // se quedaba invisible aunque siguiera guardado.
    SharedPreferences.setMockInitialValues({
      _primaryKey: _envelope(const [
        {'draftId': 'draft-windows', 'title': 'Hecho en Windows'},
      ]),
      _legacyKey: _envelope(const [
        {'draftId': 'draft-browser', 'title': 'Hecho en el navegador'},
      ]),
    });
    final store = SharedPreferencesCaseDraftsStore();

    final drafts = await store.loadDrafts();

    expect(drafts.map((draft) => draft.draftId), const [
      'draft-windows',
      'draft-browser',
    ]);
  });

  test(
    'the primary version wins over the legacy one for the same draft',
    () async {
      SharedPreferences.setMockInitialValues({
        _primaryKey: _envelope(const [
          {'draftId': 'draft-a', 'title': 'Versión actual'},
        ]),
        _legacyKey: _envelope(const [
          {'draftId': 'draft-a', 'title': 'Versión vieja'},
        ]),
      });
      final store = SharedPreferencesCaseDraftsStore();

      final drafts = await store.loadDrafts();

      expect(drafts.single.title, 'Versión actual');
    },
  );

  test('the recovered list is persisted and the backup is kept', () async {
    SharedPreferences.setMockInitialValues({
      _primaryKey: _envelope(const [
        {'draftId': 'draft-windows'},
      ]),
      _legacyKey: _envelope(const [
        {'draftId': 'draft-browser'},
      ]),
    });
    final store = SharedPreferencesCaseDraftsStore();

    await store.loadDrafts();

    final prefs = await SharedPreferences.getInstance();
    expect(_savedIds(prefs), const ['draft-windows', 'draft-browser']);
    expect(prefs.getString(_legacyKey), isNotNull);
  });

  test('a recovered draft deleted later does not come back', () async {
    // Recuperar una sola vez: si no, borrar un borrador que venía del
    // respaldo sería imposible, reaparecería en cada carga.
    SharedPreferences.setMockInitialValues({
      _primaryKey: _envelope(const [
        {'draftId': 'draft-windows'},
      ]),
      _legacyKey: _envelope(const [
        {'draftId': 'draft-browser'},
      ]),
    });
    final store = SharedPreferencesCaseDraftsStore();
    final recovered = await store.loadDrafts();

    await store.saveDrafts(
      recovered.where((draft) => draft.draftId != 'draft-browser').toList(),
    );
    final reloaded = await store.loadDrafts();

    expect(reloaded.map((draft) => draft.draftId), const ['draft-windows']);
  });

  test('a failed write leaves the primary list and retries later', () async {
    SharedPreferences.setMockInitialValues({
      _primaryKey: _envelope(const [
        {'draftId': 'draft-windows'},
      ]),
      _legacyKey: _envelope(const [
        {'draftId': 'draft-browser'},
      ]),
    });
    final prefs = await SharedPreferences.getInstance();
    final failing = SharedPreferencesCaseDraftsStore(
      preferences: () async => _FailingWrites(prefs),
    );

    final drafts = await failing.loadDrafts();

    expect(drafts.map((draft) => draft.draftId), const [
      'draft-windows',
      'draft-browser',
    ]);
    expect(_savedIds(prefs), const ['draft-windows']);

    // Sin la marca, la siguiente carga vuelve a intentarlo y esta vez sí
    // queda guardado.
    await SharedPreferencesCaseDraftsStore().loadDrafts();
    expect(_savedIds(prefs), const ['draft-windows', 'draft-browser']);
  });

  test('a corrupt legacy backup does not break the primary list', () async {
    SharedPreferences.setMockInitialValues({
      _primaryKey: _envelope(const [
        {'draftId': 'draft-windows', 'title': 'Hecho en Windows'},
      ]),
      _legacyKey: '{esto no es json',
    });
    final store = SharedPreferencesCaseDraftsStore();

    final drafts = await store.loadDrafts();

    expect(drafts.single.title, 'Hecho en Windows');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_legacyKey), '{esto no es json');
  });

  test(
    'a custom local store does not read the default legacy backup',
    () async {
      SharedPreferences.setMockInitialValues({
        'truecrime.case_drafts.legacy_backup': jsonEncode({
          'schemaVersion': 1,
          'drafts': [
            {'draftId': 'draft-ivan', 'title': 'Sólo en el respaldo principal'},
          ],
        }),
      });
      final store = SharedPreferencesCaseDraftsStore(
        storageKey: 'other.drafts',
      );

      expect(await store.loadDrafts(), isEmpty);
    },
  );
}

const _primaryKey = 'truecrime.case_drafts';
const _legacyKey = 'truecrime.case_drafts.legacy_backup';

String _envelope(List<Map<String, dynamic>> drafts) {
  return jsonEncode({'schemaVersion': 1, 'drafts': drafts});
}

/// Ids guardados bajo la clave principal, en orden.
List<String> _savedIds(SharedPreferences prefs) {
  final envelope =
      jsonDecode(prefs.getString(_primaryKey)!) as Map<String, dynamic>;
  return [
    for (final draft in envelope['drafts'] as List<dynamic>)
      (draft as Map<String, dynamic>)['draftId'] as String,
  ];
}

/// Preferencias que leen de verdad pero no consiguen escribir, como un
/// almacenamiento lleno o bloqueado.
class _FailingWrites implements SharedPreferences {
  _FailingWrites(this._inner);

  final SharedPreferences _inner;

  @override
  String? getString(String key) => _inner.getString(key);

  @override
  bool? getBool(String key) => _inner.getBool(key);

  @override
  Future<bool> setString(String key, String value) async => false;

  @override
  Future<bool> setBool(String key, bool value) async => false;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
