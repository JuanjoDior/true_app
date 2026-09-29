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
    this.storageKey = _defaultStorageKey,
    this.preferences = SharedPreferences.getInstance,
  });

  final String storageKey;

  /// Acceso a las preferencias, sustituible en tests para simular fallos de
  /// escritura.
  final Future<SharedPreferences> Function() preferences;

  static const String _defaultStorageKey = 'truecrime.case_drafts';

  static const String _legacyBackupStorageKey =
      'truecrime.case_drafts.legacy_backup';

  /// Marca de que el respaldo heredado ya se fundió en la lista principal.
  /// Va en una clave aparte para no tocar nunca el respaldo en sí.
  static const String _legacyRecoveredStorageKey =
      'truecrime.case_drafts.legacy_backup_recovered';
  static const int _schemaVersion = 1;

  @override
  Future<List<CaseDraft>> loadDrafts() async {
    final prefs = await preferences();
    final raw = prefs.getString(storageKey);
    final drafts = raw == null ? const <CaseDraft>[] : _decode(raw);
    if (storageKey != _defaultStorageKey) {
      return drafts;
    }
    return _recoverLegacyBackup(prefs, drafts);
  }

  /// Funde una sola vez el respaldo heredado en la lista principal.
  ///
  /// Sólo entran los borradores cuyo `draftId` no está en la principal; si
  /// coinciden, gana la principal, que es la que se ha seguido editando. La
  /// marca se escribe DESPUÉS de guardar la lista fundida: si guardar falla,
  /// la siguiente carga lo reintenta, y una vez recuperado un borrador que se
  /// borre no reaparece en cada carga. El respaldo nunca se borra.
  Future<List<CaseDraft>> _recoverLegacyBackup(
    SharedPreferences prefs,
    List<CaseDraft> drafts,
  ) async {
    if (prefs.getBool(_legacyRecoveredStorageKey) ?? false) {
      return drafts;
    }
    final rawBackup = prefs.getString(_legacyBackupStorageKey);
    if (rawBackup == null) {
      return drafts;
    }

    final List<CaseDraft> backup;
    try {
      backup = _decode(rawBackup);
    } on Object {
      // Un respaldo ilegible no puede impedir abrir los borradores actuales.
      return drafts;
    }

    final knownIds = {for (final draft in drafts) draft.draftId};
    final merged = [
      ...drafts,
      for (final draft in backup)
        if (knownIds.add(draft.draftId)) draft,
    ];
    try {
      final persisted =
          merged.length == drafts.length ||
          await prefs.setString(storageKey, _encode(merged));
      if (persisted) {
        await prefs.setBool(_legacyRecoveredStorageKey, true);
      }
    } on Object {
      // Sin marca: se reintenta en la próxima carga. La lista principal sólo
      // se sustituye por una que la contiene entera, así que no se pierde nada.
    }
    return List.unmodifiable(merged);
  }

  List<CaseDraft> _decode(String raw) {
    final envelope = jsonDecode(raw) as Map<String, dynamic>;
    final drafts = envelope['drafts'] as List<dynamic>? ?? const [];
    return drafts
        .map((draft) => CaseDraft.fromJson(draft as Map<String, dynamic>))
        .toList(growable: false);
  }

  String _encode(List<CaseDraft> drafts) {
    return jsonEncode({
      'schemaVersion': _schemaVersion,
      'drafts': drafts.map((draft) => draft.toJson()).toList(),
    });
  }

  @override
  Future<void> saveDrafts(List<CaseDraft> drafts) async {
    final prefs = await preferences();
    await prefs.setString(storageKey, _encode(drafts));
  }
}
