import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/case_draft.dart';

/// Persistencia local de los borradores de Iván.
abstract class CaseDraftsStore {
  Future<List<CaseDraft>> loadDrafts();
  Future<void> saveDrafts(List<CaseDraft> drafts);
}

/// Implementación respaldada por `shared_preferences` (localStorage en web).
///
/// Guarda todos los borradores bajo una única clave, en un sobre versionado
/// `{"schemaVersion": 1, "drafts": [...]}` para permitir migraciones futuras.
class SharedPreferencesCaseDraftsStore implements CaseDraftsStore {
  SharedPreferencesCaseDraftsStore({
    this.storageKey = 'truecrime.case_drafts',
  });

  final String storageKey;

  static const int _schemaVersion = 1;

  @override
  Future<List<CaseDraft>> loadDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null) {
      return const <CaseDraft>[];
    }

    final envelope = jsonDecode(raw) as Map<String, dynamic>;
    final drafts = envelope['drafts'] as List<dynamic>? ?? const [];
    return drafts
        .map((draft) => CaseDraft.fromJson(draft as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<void> saveDrafts(List<CaseDraft> drafts) async {
    final prefs = await SharedPreferences.getInstance();
    final envelope = {
      'schemaVersion': _schemaVersion,
      'drafts': drafts.map((draft) => draft.toJson()).toList(),
    };
    await prefs.setString(storageKey, jsonEncode(envelope));
  }
}
