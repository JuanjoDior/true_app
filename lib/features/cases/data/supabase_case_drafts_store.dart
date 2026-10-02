import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/case_draft.dart';
import 'case_drafts_store.dart';
import 'supabase_project.dart';

/// Estado visible del guardado de borradores en la nube.
enum DraftsSyncStatus {
  saved,
  saving,
  offline,
  retrying,
  conflict;

  /// Alias de compatibilidad para describir un flush que terminó bien.
  static const DraftsSyncStatus synced = DraftsSyncStatus.saved;
}

/// Guarda primero en el navegador y sincroniza después con PostgREST.
///
/// Cada instancia pertenece a una cuenta. La identidad remota se conserva por
/// separado del contenido del borrador porque la API sólo permite insertar el
/// identificador y actualizar el payload.
class SupabaseCaseDraftsStore implements CaseDraftsStore {
  SupabaseCaseDraftsStore({
    required this.accountId,
    required this.accessToken,
    http.Client? client,
    this.timeout = kSupabaseNetworkTimeout,
    this.debounce = const Duration(seconds: 1),
    this.retryBackoff = const Duration(seconds: 15),
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  final String accountId;
  final Future<String?> Function() accessToken;
  final Duration timeout;
  final Duration debounce;
  final Duration retryBackoff;
  final http.Client _client;
  final bool _ownsClient;

  static const String legacyStorageKey = 'truecrime.case_drafts';
  static const String legacyBackupKey = 'truecrime.case_drafts.legacy_backup';
  static const int _schemaVersion = 1;

  String get storageKey => 'truecrime.case_drafts.$accountId';
  Uri get _draftsUri => Uri.parse('$supabaseUrl/rest/v1/drafts');

  final StreamController<DraftsSyncStatus> _statusChanges =
      StreamController<DraftsSyncStatus>.broadcast();
  DraftsSyncStatus _currentStatus = DraftsSyncStatus.saved;
  DraftsSyncStatus get currentStatus => _currentStatus;

  /// Estado de workflow remoto, conservado junto a la copia local de la cuenta.
  Map<String, String> get remoteStatuses =>
      Map<String, String>.unmodifiable(_remoteStatuses);

  Stream<DraftsSyncStatus> get statusChanges async* {
    yield _currentStatus;
    yield* _statusChanges.stream;
  }

  List<CaseDraft> _drafts = const <CaseDraft>[];
  final Set<String> _pendingUpserts = <String>{};
  final Set<String> _pendingDeletes = <String>{};
  final Set<String> _inFlightPosts = <String>{};
  final Set<String> _remoteIds = <String>{};
  final Set<String> _uncertainPostIds = <String>{};
  final Set<String> _conflictedIds = <String>{};
  final Map<String, CaseDraft> _deletedDrafts = <String, CaseDraft>{};
  final Map<String, String> _remoteStatuses = <String, String>{};
  Future<void> _cacheWrites = Future<void>.value();
  bool _cacheLoaded = false;
  bool _disposed = false;
  bool _flushRunning = false;
  bool _networkFailure = false;
  Timer? _flushTimer;

  @override
  Future<List<CaseDraft>> loadDrafts() async {
    await _loadCache();
    await _migrateLegacyDrafts();

    try {
      final token = await accessToken();
      if (token == null || token.isEmpty) {
        throw StateError('No hay una sesión disponible para sincronizar.');
      }
      final uri = _draftsUri.replace(
        queryParameters: {
          'select': 'id,payload,status',
          'owner': 'eq.$accountId',
          'order': 'updated_at.asc',
        },
      );
      final response = await _client
          .get(uri, headers: _headers(token))
          .timeout(timeout);
      if (response.statusCode != 200) {
        throw http.ClientException(
          'La lectura de borradores respondió ${response.statusCode}.',
          uri,
        );
      }

      final rows = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      final remote = <String, CaseDraft>{};
      final remoteIds = <String>{};
      _remoteStatuses.clear();
      for (final rawRow in rows) {
        final row = rawRow as Map<String, dynamic>;
        final id = row['id'] as String;
        final payload = row['payload'] as Map<String, dynamic>;
        remote[id] = CaseDraft.fromJson(payload);
        remoteIds.add(id);
        final status = row['status'];
        if (status is String) _remoteStatuses[id] = status;
      }

      _remoteIds
        ..clear()
        ..addAll(remoteIds);
      _drafts = _mergeRemote(remote);
      _networkFailure = false;
      await _persistCache();
      if (_hasConflicts) {
        _setStatus(DraftsSyncStatus.conflict);
      } else if (_hasPendingWork) {
        _setStatus(DraftsSyncStatus.saving);
      } else {
        _setStatus(DraftsSyncStatus.saved);
      }
      _scheduleFlush(debounce);
      return List<CaseDraft>.unmodifiable(_drafts);
    } catch (_) {
      _networkFailure = true;
      _setStatus(DraftsSyncStatus.offline);
      await _persistCache();
      if (_hasPendingWork) _scheduleFlush(retryBackoff);
      return List<CaseDraft>.unmodifiable(_drafts);
    }
  }

  @override
  Future<void> saveDrafts(List<CaseDraft> drafts) async {
    await _loadCache();
    final previous = {for (final draft in _drafts) draft.draftId: draft};
    final incoming = {for (final draft in drafts) draft.draftId: draft};

    for (final entry in incoming.entries) {
      final old = previous[entry.key];
      if (old == null || !_sameDraft(old, entry.value)) {
        _pendingUpserts.add(entry.key);
        _conflictedIds.remove(entry.key);
      }
      _pendingDeletes.remove(entry.key);
      _deletedDrafts.remove(entry.key);
    }
    for (final id in previous.keys) {
      if (incoming.containsKey(id)) continue;
      _pendingUpserts.remove(id);
      _conflictedIds.remove(id);
      if (_remoteIds.contains(id) ||
          _uncertainPostIds.contains(id) ||
          _inFlightPosts.contains(id)) {
        _deletedDrafts[id] = previous[id]!;
        _pendingDeletes.add(id);
      } else {
        // A draft that has never reached the server can be discarded locally;
        // issuing DELETE for it would turn a cancelled POST into a conflict.
        _deletedDrafts.remove(id);
        _pendingDeletes.remove(id);
      }
    }

    _drafts = List<CaseDraft>.unmodifiable(drafts);
    // El almacenamiento local siempre queda confirmado antes de programar
    // cualquier petición de red.
    await _persistCache();
    if (_hasConflicts) {
      _setStatus(DraftsSyncStatus.conflict);
      _scheduleFlush(debounce);
    } else if (_hasPendingWork) {
      if (_networkFailure) {
        if (_flushTimer == null) {
          _scheduleFlush(retryBackoff, retrying: true);
        }
      } else {
        _setStatus(DraftsSyncStatus.saving);
        _scheduleFlush(debounce);
      }
    } else {
      _setStatus(DraftsSyncStatus.saved);
      _cancelFlush();
    }
  }

  List<CaseDraft> _mergeRemote(Map<String, CaseDraft> remote) {
    final merged = <String, CaseDraft>{};
    for (final cached in _drafts) {
      final id = cached.draftId;
      if (_pendingDeletes.contains(id)) continue;
      if (_pendingUpserts.contains(id)) {
        merged[id] = cached;
      } else if (remote.containsKey(id)) {
        merged[id] = remote[id]!;
      }
    }
    for (final entry in remote.entries) {
      if (!_pendingDeletes.contains(entry.key)) {
        merged.putIfAbsent(entry.key, () => entry.value);
      }
    }
    // Si todavía no existe en la respuesta remota, el trabajo local sigue
    // siendo visible mientras se reintenta o se resuelve un conflicto.
    for (final id in _pendingUpserts) {
      if (_pendingDeletes.contains(id) || merged.containsKey(id)) continue;
      for (final draft in _drafts) {
        if (draft.draftId == id) {
          merged[id] = draft;
          break;
        }
      }
    }
    return List<CaseDraft>.unmodifiable(merged.values);
  }

  Future<void> _loadCache() async {
    if (_cacheLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw != null) {
      final cache = jsonDecode(raw) as Map<String, dynamic>;
      final cachedDrafts = cache['drafts'] as List<dynamic>? ?? const [];
      _drafts = cachedDrafts
          .map((draft) => CaseDraft.fromJson(draft as Map<String, dynamic>))
          .toList(growable: false);
      _pendingUpserts.addAll(_stringList(cache['pendingUpserts']));
      _pendingDeletes.addAll(_stringList(cache['pendingDeletes']));
      _remoteIds.addAll(_stringList(cache['remoteIds']));
      _uncertainPostIds.addAll(_stringList(cache['uncertainPostIds']));
      final remoteStatuses = cache['remoteStatuses'];
      if (remoteStatuses is Map<String, dynamic>) {
        for (final entry in remoteStatuses.entries) {
          if (entry.value is String) {
            _remoteStatuses[entry.key] = entry.value as String;
          }
        }
      }
      _conflictedIds.addAll(_stringList(cache['conflictedIds']));
      final deletedDrafts = cache['deletedDrafts'];
      if (deletedDrafts is Map<String, dynamic>) {
        _deletedDrafts.addAll(
          deletedDrafts.map(
            (id, draft) =>
                MapEntry(id, CaseDraft.fromJson(draft as Map<String, dynamic>)),
          ),
        );
      }
    }
    _cacheLoaded = true;
  }

  Future<void> _migrateLegacyDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(legacyStorageKey);
    if (raw == null) return;

    final envelope = jsonDecode(raw) as Map<String, dynamic>;
    if (envelope['schemaVersion'] != _schemaVersion) return;
    final legacy = (envelope['drafts'] as List<dynamic>? ?? const []).map(
      (draft) => CaseDraft.fromJson(draft as Map<String, dynamic>),
    );
    final draftsById = {for (final draft in _drafts) draft.draftId: draft};
    for (final draft in legacy) {
      if (_pendingUpserts.contains(draft.draftId)) continue;
      draftsById[draft.draftId] = draft;
      _pendingUpserts.add(draft.draftId);
    }
    _drafts = List<CaseDraft>.unmodifiable(draftsById.values);
    // Persistir la copia account-scoped antes de apartar la clave anterior
    // evita que una interrupción durante la migración pierda trabajo local.
    await _persistCache();
    if (!prefs.containsKey(legacyBackupKey)) {
      await prefs.setString(legacyBackupKey, raw);
    }
    await prefs.remove(legacyStorageKey);
  }

  Future<void> _persistCache() {
    final cache = <String, Object>{
      'schemaVersion': _schemaVersion,
      'drafts': _drafts.map((draft) => draft.toJson()).toList(),
      'pendingUpserts': _pendingUpserts.toList(),
      'pendingDeletes': _pendingDeletes.toList(),
      'remoteIds': _remoteIds.toList(),
      'uncertainPostIds': _uncertainPostIds.toList(),
      'remoteStatuses': _remoteStatuses,
      'conflictedIds': _conflictedIds.toList(),
      'deletedDrafts': {
        for (final entry in _deletedDrafts.entries)
          entry.key: entry.value.toJson(),
      },
    };
    final raw = jsonEncode(cache);
    final write = _cacheWrites.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(storageKey, raw);
    });
    _cacheWrites = write.catchError((Object _) {});
    return write;
  }

  Future<void> _flush() async {
    if (_disposed || _flushRunning || !_hasRunnableWork) return;
    _flushRunning = true;
    _networkFailure = false;
    _setStatus(DraftsSyncStatus.retrying);
    try {
      final token = await accessToken();
      if (token == null || token.isEmpty) {
        throw StateError('No hay una sesión disponible para sincronizar.');
      }
      for (final id in List<String>.of(_pendingDeletes)) {
        if (_disposed) return;
        if (_conflictedIds.contains(id)) continue;
        try {
          if (_uncertainPostIds.contains(id)) {
            final remoteRow = await _reconcileUncertainPost(id, token);
            _uncertainPostIds.remove(id);
            if (remoteRow == null) {
              final latest = _draftFor(id);
              _pendingDeletes.remove(id);
              _deletedDrafts.remove(id);
              _remoteIds.remove(id);
              _remoteStatuses.remove(id);
              _conflictedIds.remove(id);
              if (latest == null) {
                _pendingUpserts.remove(id);
              } else {
                _pendingUpserts.add(id);
              }
              await _persistCache();
              continue;
            }
            _remoteIds.add(id);
            final status = remoteRow['status'];
            if (status is String) _remoteStatuses[id] = status;
            await _persistCache();
          }
          await _deleteRemote(id, token);
          final latest = _draftFor(id);
          _pendingDeletes.remove(id);
          _deletedDrafts.remove(id);
          _remoteIds.remove(id);
          _remoteStatuses.remove(id);
          _uncertainPostIds.remove(id);
          _conflictedIds.remove(id);
          if (latest == null) {
            _pendingUpserts.remove(id);
          } else {
            _pendingUpserts.add(id);
          }
          await _persistCache();
        } on _DraftConflict {
          _pendingDeletes.remove(id);
          _conflictedIds.add(id);
          final deletedDraft = _deletedDrafts.remove(id);
          if (deletedDraft != null) {
            if (_draftFor(id) == null) {
              _drafts = List<CaseDraft>.unmodifiable([
                ..._drafts,
                deletedDraft,
              ]);
            }
            _pendingUpserts.add(id);
          }
          await _persistCache();
        } catch (_) {
          _networkFailure = true;
        }
      }
      for (final id in List<String>.of(_pendingUpserts)) {
        if (_disposed) return;
        if (_pendingDeletes.contains(id) || _conflictedIds.contains(id)) {
          continue;
        }
        final draft = _draftFor(id);
        if (draft == null) continue;
        var postAttempted = false;
        try {
          if (_uncertainPostIds.contains(id)) {
            final remoteRow = await _reconcileUncertainPost(id, token);
            _uncertainPostIds.remove(id);
            if (remoteRow == null) {
              _remoteIds.remove(id);
              _remoteStatuses.remove(id);
            } else {
              _remoteIds.add(id);
              final status = remoteRow['status'];
              if (status is String) _remoteStatuses[id] = status;
            }
            await _persistCache();
          }
          if (_remoteIds.contains(id)) {
            await _patchRemote(draft, token);
          } else {
            _inFlightPosts.add(id);
            postAttempted = true;
            try {
              _uncertainPostIds.add(id);
              await _persistCache();
              await _postRemote(draft, token);
              _remoteIds.add(id);
              _uncertainPostIds.remove(id);
              _remoteStatuses[id] = 'draft';
              postAttempted = false;
            } finally {
              _inFlightPosts.remove(id);
            }
          }
          final latest = _draftFor(id);
          if (_pendingDeletes.contains(id) || latest == null) {
            _pendingDeletes.add(id);
            _pendingUpserts.remove(id);
          } else if (_sameDraft(latest, draft)) {
            _pendingUpserts.remove(id);
            _conflictedIds.remove(id);
          }
          await _persistCache();
        } on _DraftConflict {
          if (postAttempted && !_remoteIds.contains(id)) {
            _uncertainPostIds.add(id);
            if (!_pendingDeletes.contains(id)) _conflictedIds.add(id);
            await _persistCache();
          } else {
            _conflictedIds.add(id);
          }
        } on _PostOutcomeUncertain {
          if (postAttempted && !_remoteIds.contains(id)) {
            _uncertainPostIds.add(id);
            await _persistCache();
          }
          _networkFailure = true;
        } on _PostRejected {
          if (postAttempted && !_remoteIds.contains(id)) {
            _uncertainPostIds.remove(id);
            await _persistCache();
          }
          _networkFailure = true;
        } catch (_) {
          _networkFailure = true;
        }
      }
    } catch (_) {
      _networkFailure = true;
    } finally {
      _flushRunning = false;
      if (!_disposed) {
        if (_networkFailure) {
          _setStatus(DraftsSyncStatus.offline);
          if (_hasRunnableWork) _scheduleFlush(retryBackoff, retrying: true);
        } else if (_hasConflicts) {
          _setStatus(DraftsSyncStatus.conflict);
          if (_hasRunnableWork) _scheduleFlush(debounce);
        } else if (_hasRunnableWork) {
          _setStatus(DraftsSyncStatus.saving);
          _scheduleFlush(debounce);
        } else if (_hasConflicts) {
          _setStatus(DraftsSyncStatus.conflict);
        } else {
          _setStatus(DraftsSyncStatus.saved);
        }
      }
    }
  }

  Future<void> _postRemote(CaseDraft draft, String token) async {
    final uri = _draftsUri;
    late final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {..._headers(token), 'Prefer': 'return=minimal'},
            body: jsonEncode({'id': draft.draftId, 'payload': draft.toJson()}),
          )
          .timeout(timeout);
    } catch (_) {
      throw const _PostOutcomeUncertain();
    }
    if (response.statusCode == 409) throw const _DraftConflict();
    if (response.statusCode == 408 || response.statusCode >= 500) {
      throw const _PostOutcomeUncertain();
    }
    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.statusCode != 204) {
      throw const _PostRejected();
    }
  }

  Future<Map<String, dynamic>?> _reconcileUncertainPost(
    String id,
    String token,
  ) async {
    final uri = _draftsUri.replace(
      queryParameters: {
        'owner': 'eq.$accountId',
        'id': 'eq.$id',
        'select': 'id,status',
      },
    );
    final response = await _client.get(uri, headers: _headers(token)).timeout(
      timeout,
    );
    if (response.statusCode != 200) {
      throw http.ClientException(
        'La reconciliación del borrador respondió ${response.statusCode}.',
        uri,
      );
    }
    final rows = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    if (rows.isEmpty) return null;
    return rows.first as Map<String, dynamic>;
  }

  Future<void> _patchRemote(CaseDraft draft, String token) async {
    final uri = _draftsUri.replace(
      queryParameters: {'id': 'eq.${draft.draftId}'},
    );
    final resetsPublishedStatus = _remoteStatuses[draft.draftId] == 'published';
    final response = await _client
        .patch(
          uri,
          headers: {..._headers(token), 'Prefer': 'return=representation'},
          body: jsonEncode({
            'payload': draft.toJson(),
            if (resetsPublishedStatus) 'status': 'draft',
          }),
        )
        .timeout(timeout);
    if (response.statusCode == 409) throw const _DraftConflict();
    if (response.statusCode != 200) {
      throw http.ClientException(
        'La actualización del borrador respondió ${response.statusCode}.',
        uri,
      );
    }
    final rows = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    if (rows.isEmpty) throw const _DraftConflict();
    final updatedRow = rows.first as Map<String, dynamic>;
    final updatedStatus = updatedRow['status'];
    if (updatedStatus is String) {
      _remoteStatuses[draft.draftId] = updatedStatus;
    } else if (resetsPublishedStatus) {
      _remoteStatuses[draft.draftId] = 'draft';
    }
  }

  Future<void> _deleteRemote(String id, String token) async {
    final uri = _draftsUri.replace(queryParameters: {'id': 'eq.$id'});
    final response = await _client
        .delete(
          uri,
          headers: {..._headers(token), 'Prefer': 'return=representation'},
        )
        .timeout(timeout);
    if (response.statusCode == 200) {
      final rows = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      if (rows.isEmpty) throw const _DraftConflict();
      return;
    }
    if (response.statusCode != 204) {
      throw http.ClientException(
        'El borrado del borrador respondió ${response.statusCode}.',
        uri,
      );
    }

    final confirmationUri = _draftsUri.replace(
      queryParameters: {
        'id': 'eq.$id',
        'owner': 'eq.$accountId',
        'select': 'id',
      },
    );
    final confirmation = await _client
        .get(confirmationUri, headers: _headers(token))
        .timeout(timeout);
    if (confirmation.statusCode != 200) {
      throw http.ClientException(
        'La confirmación del borrado respondió ${confirmation.statusCode}.',
        confirmationUri,
      );
    }
    final remainingRows =
        jsonDecode(utf8.decode(confirmation.bodyBytes)) as List<dynamic>;
    if (remainingRows.isNotEmpty) throw const _DraftConflict();
  }

  Map<String, String> _headers(String token) => {
    'apikey': supabasePublishableKey,
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  CaseDraft? _draftFor(String id) {
    for (final draft in _drafts) {
      if (draft.draftId == id) return draft;
    }
    return null;
  }

  bool get _hasPendingWork =>
      _pendingUpserts.isNotEmpty || _pendingDeletes.isNotEmpty;
  bool get _hasRunnableWork =>
      _pendingUpserts.any((id) => !_conflictedIds.contains(id)) ||
      _pendingDeletes.any((id) => !_conflictedIds.contains(id));
  bool get _hasConflicts => _conflictedIds.isNotEmpty;

  void _scheduleFlush(Duration delay, {bool retrying = false}) {
    if (_disposed || !_hasRunnableWork) return;
    _flushTimer?.cancel();
    if (retrying) _setStatus(DraftsSyncStatus.retrying);
    _flushTimer = Timer(delay, () {
      _flushTimer = null;
      unawaited(_flush());
    });
  }

  void _cancelFlush() {
    _flushTimer?.cancel();
    _flushTimer = null;
  }

  void _setStatus(DraftsSyncStatus status) {
    if (_disposed || _currentStatus == status) return;
    _currentStatus = status;
    if (!_statusChanges.isClosed) _statusChanges.add(status);
  }

  static List<String> _stringList(Object? value) =>
      value is List ? value.whereType<String>().toList() : <String>[];

  static bool _sameDraft(CaseDraft first, CaseDraft second) =>
      jsonEncode(first.toJson()) == jsonEncode(second.toJson());

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _cancelFlush();
    if (_ownsClient) _client.close();
    unawaited(_statusChanges.close());
  }
}

class _DraftConflict implements Exception {
  const _DraftConflict();
}

class _PostOutcomeUncertain implements Exception {
  const _PostOutcomeUncertain();
}

class _PostRejected implements Exception {
  const _PostRejected();
}
