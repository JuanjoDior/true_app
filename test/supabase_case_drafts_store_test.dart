import 'dart:async';
import 'dart:convert';

// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:true_app/features/cases/data/supabase_case_drafts_store.dart';
import 'package:true_app/features/cases/data/supabase_project.dart';
import 'package:true_app/features/cases/domain/case_draft.dart';
import 'package:true_app/features/cases/domain/case_status.dart';

/// Persistencia en la nube de los borradores de Iván (CRP-04).
///
/// Cada escritura pasa antes por `shared_preferences`, así que un corte de
/// red nunca pierde una edición: la red sólo confirma lo que ya está a
/// salvo en este navegador. Todos los tests corren dentro de [fakeAsync]
/// porque el store debounça (1s) y reintenta con un backoff (15s) con
/// `Timer` de verdad.
const _accountId = 'user-ivan';

Future<String?> _token() async => 'token-abc';

http.Response _json(Object body, int status) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

SupabaseCaseDraftsStore _store({
  required Future<http.Response> Function(http.Request) handler,
  Future<String?> Function()? accessToken,
}) {
  return SupabaseCaseDraftsStore(
    accountId: _accountId,
    accessToken: accessToken ?? _token,
    client: MockClient(handler),
  );
}

/// Corre [future] dentro de [async], avanzando microtareas hasta que se
/// resuelva. Los mocks de red no usan `Timer`, así que basta con vaciar la
/// cola de microtareas.
T _resolve<T>(FakeAsync async, Future<T> future) {
  late T value;
  Object? error;
  future.then<void>(
    (v) => value = v,
    onError: (Object e, StackTrace _) {
      error = e;
    },
  );
  async.flushMicrotasks();
  if (error != null) throw error!;
  return value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('loadDrafts', () {
    test('asks the remote drafts filtered by owner with the bearer token', () {
      fakeAsync((async) {
        late http.Request sent;
        final store = _store(
          handler: (request) async {
            sent = request;
            return _json([], 200);
          },
        );

        _resolve(async, store.loadDrafts());

        expect(sent.method, 'GET');
        expect(sent.url.path, '/rest/v1/drafts');
        expect(sent.url.queryParameters['owner'], 'eq.$_accountId');
        expect(sent.url.queryParameters['select'], 'id,payload,status');
        expect(sent.headers['apikey'], supabasePublishableKey);
        expect(sent.headers['Authorization'], 'Bearer token-abc');
      });
    });

    test('loads the drafts served by the remote', () {
      fakeAsync((async) {
        final store = _store(
          handler: (_) async => _json([
            {
              'id': 'draft-a',
              'payload': {'draftId': 'draft-a', 'title': 'Caso remoto'},
              'status': 'draft',
            },
          ], 200),
        );

        final drafts = _resolve(async, store.loadDrafts());

        expect(drafts, hasLength(1));
        expect(drafts.single.draftId, 'draft-a');
        expect(drafts.single.title, 'Caso remoto');
      });
    });

    test('a pending local edit wins over the remote version', () {
      SharedPreferences.setMockInitialValues({
        'truecrime.case_drafts.$_accountId': jsonEncode({
          'schemaVersion': 1,
          'drafts': [
            {'draftId': 'draft-a', 'title': 'Edición local sin subir'},
          ],
          'pendingUpserts': ['draft-a'],
          'pendingDeletes': <String>[],
          'remoteIds': ['draft-a'],
        }),
      });
      fakeAsync((async) {
        final store = _store(
          handler: (request) async {
            if (request.method != 'GET') return _json([], 200);
            return _json([
              {
                'id': 'draft-a',
                'payload': {
                  'draftId': 'draft-a',
                  'title': 'Versión vieja del servidor',
                },
                'status': 'draft',
              },
            ], 200);
          },
        );

        final drafts = _resolve(async, store.loadDrafts());

        expect(drafts.single.title, 'Edición local sin subir');
      });
    });

    test(
      'legacy drafts are uploaded and the legacy key is renamed, not deleted',
      () {
        SharedPreferences.setMockInitialValues({
          'truecrime.case_drafts': jsonEncode({
            'schemaVersion': 1,
            'drafts': [
              {'draftId': 'draft-legacy', 'title': 'Antes de la nube'},
            ],
          }),
        });
        fakeAsync((async) {
          final posted = <Map<String, dynamic>>[];
          final store = _store(
            handler: (request) async {
              if (request.method == 'GET') return _json([], 200);
              posted.add(jsonDecode(request.body) as Map<String, dynamic>);
              return http.Response('', 201);
            },
          );

          final drafts = _resolve(async, store.loadDrafts());
          expect(drafts.single.draftId, 'draft-legacy');

          // El vuelco a la nube ocurre en el flush programado tras la carga.
          async.elapse(const Duration(seconds: 2));
          expect(posted, hasLength(1));
          expect(posted.single['id'], 'draft-legacy');

          final prefs = _resolve(async, SharedPreferences.getInstance());
          expect(prefs.getString('truecrime.case_drafts'), isNull);
          expect(
            prefs.getString('truecrime.case_drafts.legacy_backup'),
            isNotNull,
          );
        });
      },
    );

    test('a legacy draft already pending locally keeps the local version', () {
      SharedPreferences.setMockInitialValues({
        'truecrime.case_drafts': jsonEncode({
          'schemaVersion': 1,
          'drafts': [
            {'draftId': 'draft-a', 'title': 'Legado'},
          ],
        }),
        'truecrime.case_drafts.$_accountId': jsonEncode({
          'schemaVersion': 1,
          'drafts': [
            {'draftId': 'draft-a', 'title': 'Ya editado en la nube'},
          ],
          'pendingUpserts': ['draft-a'],
          'pendingDeletes': <String>[],
          'remoteIds': <String>[],
        }),
      });
      fakeAsync((async) {
        final store = _store(handler: (request) async => _json([], 200));

        final drafts = _resolve(async, store.loadDrafts());

        expect(drafts.single.title, 'Ya editado en la nube');
      });
    });

    test('an unreachable remote returns the cached list and marks offline', () {
      SharedPreferences.setMockInitialValues({
        'truecrime.case_drafts.$_accountId': jsonEncode({
          'schemaVersion': 1,
          'drafts': [
            {'draftId': 'draft-cached', 'title': 'Guardado en este navegador'},
          ],
          'pendingUpserts': <String>[],
          'pendingDeletes': <String>[],
          'remoteIds': ['draft-cached'],
        }),
      });
      fakeAsync((async) {
        final store = _store(
          handler: (_) async => throw http.ClientException('offline'),
        );

        final drafts = _resolve(async, store.loadDrafts());

        expect(drafts.single.draftId, 'draft-cached');
        expect(store.currentStatus, DraftsSyncStatus.offline);
      });
    });
  });

  group('saveDrafts flush', () {
    test('a new id is sent as a POST with only id and payload', () {
      fakeAsync((async) {
        http.Request? sent;
        final store = _store(
          handler: (request) async {
            if (request.method == 'GET') return _json([], 200);
            sent = request;
            return http.Response('', 201);
          },
        );
        _resolve(async, store.loadDrafts());

        store.saveDrafts(const [
          CaseDraft(draftId: 'draft-new', title: 'Nuevo'),
        ]);
        async.elapse(const Duration(seconds: 2));

        expect(sent, isNotNull);
        expect(sent!.method, 'POST');
        expect(sent!.url.path, '/rest/v1/drafts');
        expect(sent!.headers['Prefer'], 'return=minimal');
        final body = jsonDecode(sent!.body) as Map<String, dynamic>;
        expect(body.keys, {'id', 'payload'});
        expect(body['id'], 'draft-new');
        expect(store.currentStatus, DraftsSyncStatus.synced);
      });
    });

    test('a known id is sent as a PATCH with only the payload', () {
      SharedPreferences.setMockInitialValues({
        'truecrime.case_drafts.$_accountId': jsonEncode({
          'schemaVersion': 1,
          'drafts': [
            {'draftId': 'draft-a', 'title': 'Viejo'},
          ],
          'pendingUpserts': <String>[],
          'pendingDeletes': <String>[],
          'remoteIds': ['draft-a'],
        }),
      });
      fakeAsync((async) {
        http.Request? sent;
        final store = _store(
          handler: (request) async {
            if (request.method == 'GET') {
              return _json([
                {
                  'id': 'draft-a',
                  'payload': {'draftId': 'draft-a', 'title': 'Viejo'},
                  'status': 'draft',
                },
              ], 200);
            }
            sent = request;
            return _json([
              {'id': 'draft-a'},
            ], 200);
          },
        );
        _resolve(async, store.loadDrafts());

        store.saveDrafts(const [
          CaseDraft(draftId: 'draft-a', title: 'Nuevo título'),
        ]);
        async.elapse(const Duration(seconds: 2));

        expect(sent, isNotNull);
        expect(sent!.method, 'PATCH');
        expect(sent!.url.queryParameters['id'], 'eq.draft-a');
        final body = jsonDecode(sent!.body) as Map<String, dynamic>;
        expect(body.keys, {'payload'});
      });
    });

    test('editing a published draft PATCHes payload and workflow status', () {
      SharedPreferences.setMockInitialValues({
        'truecrime.case_drafts.$_accountId': jsonEncode({
          'schemaVersion': 1,
          'drafts': [
            {'draftId': 'draft-a', 'title': 'Viejo'},
          ],
          'pendingUpserts': <String>[],
          'pendingDeletes': <String>[],
          'remoteIds': ['draft-a'],
        }),
      });
      fakeAsync((async) {
        http.Request? patch;
        final store = _store(
          handler: (request) async {
            if (request.method == 'GET') {
              return _json([
                {
                  'id': 'draft-a',
                  'payload': {
                    'draftId': 'draft-a',
                    'title': 'Viejo',
                    'status': 'inProgress',
                  },
                  'status': 'published',
                },
              ], 200);
            }
            patch = request;
            return _json([
              {'id': 'draft-a', 'status': 'draft'},
            ], 200);
          },
        );
        _resolve(async, store.loadDrafts());
        _resolve(
          async,
          store.saveDrafts(const [
            CaseDraft(
              draftId: 'draft-a',
              title: 'Editado',
              status: CaseStatus.solved,
            ),
          ]),
        );
        async.elapse(const Duration(seconds: 2));

        final body = jsonDecode(patch!.body) as Map<String, dynamic>;
        expect(patch!.method, 'PATCH');
        expect(body.keys, {'payload', 'status'});
        expect(body['status'], 'draft');
        expect((body['payload'] as Map<String, dynamic>)['status'], 'solved');
        expect(store.remoteStatuses['draft-a'], 'draft');
      });
    });

    test(
      'a published status survives restart and offline GET before PATCH',
      () {
        fakeAsync((async) {
          final firstStore = _store(
            handler: (request) async => _json([
              {
                'id': 'draft-published',
                'payload': {
                  'draftId': 'draft-published',
                  'title': 'Original',
                  'status': 'inProgress',
                },
                'status': 'published',
              },
            ], 200),
          );
          _resolve(async, firstStore.loadDrafts());
          _resolve(
            async,
            firstStore.saveDrafts(const [
              CaseDraft(
                draftId: 'draft-published',
                title: 'Editado sin conexión',
                status: CaseStatus.solved,
              ),
            ]),
          );
          firstStore.dispose();

          http.Request? patch;
          final restartedStore = _store(
            handler: (request) async {
              if (request.method == 'GET') {
                throw http.ClientException('offline after restart');
              }
              patch = request;
              return _json([
                {'id': 'draft-published', 'status': 'draft'},
              ], 200);
            },
          );
          _resolve(async, restartedStore.loadDrafts());
          async.elapse(const Duration(seconds: 16));

          expect(patch, isNotNull);
          expect(patch!.method, 'PATCH');
          final body = jsonDecode(patch!.body) as Map<String, dynamic>;
          expect(body.keys, {'payload', 'status'});
          expect(body['status'], 'draft');
          expect(
            (body['payload'] as Map<String, dynamic>)['status'],
            'solved',
          );

          final prefs = _resolve(async, SharedPreferences.getInstance());
          final cache =
              jsonDecode(
                    prefs.getString('truecrime.case_drafts.$_accountId')!,
                  )
                  as Map<String, dynamic>;
          expect(cache['pendingUpserts'], isEmpty);
          expect(cache['remoteStatuses'], {'draft-published': 'draft'});
        });
      },
    );

    test('an empty 204 DELETE confirms absence before clearing its tombstone', () {
      SharedPreferences.setMockInitialValues({
        'truecrime.case_drafts.$_accountId': jsonEncode({
          'schemaVersion': 1,
          'drafts': [
            {'draftId': 'draft-a', 'title': 'Se va a borrar'},
          ],
          'pendingUpserts': <String>[],
          'pendingDeletes': <String>[],
          'remoteIds': ['draft-a'],
        }),
      });
      fakeAsync((async) {
        final requests = <http.Request>[];
        final store = _store(
          handler: (request) async {
            requests.add(request);
            if (request.method == 'GET') {
              if (request.url.queryParameters.containsKey('id')) {
                return _json([], 200);
              }
              return _json([
                {
                  'id': 'draft-a',
                  'payload': {'draftId': 'draft-a', 'title': 'Se va a borrar'},
                  'status': 'draft',
                },
              ], 200);
            }
            return http.Response('', 204);
          },
        );
        _resolve(async, store.loadDrafts());

        _resolve(async, store.saveDrafts(const []));
        async.elapse(const Duration(seconds: 2));

        expect(requests.map((request) => request.method), ['GET', 'DELETE', 'GET']);
        final delete = requests[1];
        expect(delete.url.queryParameters['id'], 'eq.draft-a');
        final confirmation = requests[2];
        expect(confirmation.url.queryParameters['owner'], 'eq.$_accountId');
        expect(confirmation.url.queryParameters['id'], 'eq.draft-a');

        final prefs = _resolve(async, SharedPreferences.getInstance());
        final cache =
            jsonDecode(prefs.getString('truecrime.case_drafts.$_accountId')!)
                as Map<String, dynamic>;
        expect(cache['pendingDeletes'], isEmpty);
        expect(cache['deletedDrafts'], isEmpty);
      });
    });

    test('an offline DELETE keeps its tombstone and recoverable payload', () {
      SharedPreferences.setMockInitialValues({
        'truecrime.case_drafts.$_accountId': jsonEncode({
          'schemaVersion': 1,
          'drafts': [
            {'draftId': 'draft-a', 'title': 'Borrador sin conexión'},
          ],
          'pendingUpserts': <String>[],
          'pendingDeletes': <String>[],
          'remoteIds': ['draft-a'],
        }),
      });
      fakeAsync((async) {
        final store = _store(
          handler: (request) async {
            if (request.method == 'GET') {
              return _json([
                {
                  'id': 'draft-a',
                  'payload': {
                    'draftId': 'draft-a',
                    'title': 'Borrador sin conexión',
                  },
                  'status': 'draft',
                },
              ], 200);
            }
            throw http.ClientException('offline');
          },
        );
        _resolve(async, store.loadDrafts());
        _resolve(async, store.saveDrafts(const []));
        async.elapse(const Duration(seconds: 2));

        final prefs = _resolve(async, SharedPreferences.getInstance());
        final cache =
            jsonDecode(prefs.getString('truecrime.case_drafts.$_accountId')!)
                as Map<String, dynamic>;
        expect(cache['pendingDeletes'], ['draft-a']);
        final recoverable =
            (cache['deletedDrafts'] as Map<String, dynamic>)['draft-a']
                as Map<String, dynamic>;
        expect(recoverable['draftId'], 'draft-a');
        expect(recoverable['title'], 'Borrador sin conexión');
      });
    });

    test('a filtered 204 restores the draft and marks conflict without retrying', () {
      SharedPreferences.setMockInitialValues({
        'truecrime.case_drafts.$_accountId': jsonEncode({
          'schemaVersion': 1,
          'drafts': [
            {'draftId': 'draft-a', 'title': 'Sigue en revisión'},
          ],
          'pendingUpserts': <String>[],
          'pendingDeletes': <String>[],
          'remoteIds': ['draft-a'],
        }),
      });
      fakeAsync((async) {
        var deleteAttempts = 0;
        final requests = <http.Request>[];
        final store = _store(
          handler: (request) async {
            requests.add(request);
            if (request.method == 'GET') {
              if (request.url.queryParameters.containsKey('id')) {
                return _json([{'id': 'draft-a'}], 200);
              }
              return _json([
                {
                  'id': 'draft-a',
                  'payload': {
                    'draftId': 'draft-a',
                    'title': 'Sigue en revisión',
                  },
                  'status': 'in_review',
                },
              ], 200);
            }
            deleteAttempts++;
            return http.Response('', 204);
          },
        );
        _resolve(async, store.loadDrafts());
        _resolve(async, store.saveDrafts(const []));
        async.elapse(const Duration(seconds: 2));

        final confirmation = requests.singleWhere(
          (request) =>
              request.method == 'GET' &&
              request.url.queryParameters.containsKey('id'),
        );
        expect(confirmation.url.queryParameters['owner'], 'eq.$_accountId');
        expect(confirmation.url.queryParameters['id'], 'eq.draft-a');

        final restored = _resolve(async, store.loadDrafts());
        async.elapse(const Duration(seconds: 30));

        expect(restored.map((draft) => draft.draftId), ['draft-a']);
        expect(restored.single.title, 'Sigue en revisión');
        expect(deleteAttempts, 1);
        expect(store.currentStatus, DraftsSyncStatus.conflict);
      });
    });

    test('an offline 204 confirmation retains the pending delete and payload', () {
      SharedPreferences.setMockInitialValues({
        'truecrime.case_drafts.$_accountId': jsonEncode({
          'schemaVersion': 1,
          'drafts': [
            {'draftId': 'draft-a', 'title': 'No perder el borrador'},
          ],
          'pendingUpserts': <String>[],
          'pendingDeletes': <String>[],
          'remoteIds': ['draft-a'],
        }),
      });
      fakeAsync((async) {
        var confirmationAttempts = 0;
        final confirmations = <http.Request>[];
        final store = _store(
          handler: (request) async {
            if (request.method == 'GET') {
              if (request.url.queryParameters.containsKey('id')) {
                confirmations.add(request);
                confirmationAttempts++;
                if (confirmationAttempts == 1) {
                  throw http.ClientException('offline');
                }
                return _json([], 200);
              }
              return _json([
                {
                  'id': 'draft-a',
                  'payload': {
                    'draftId': 'draft-a',
                    'title': 'No perder el borrador',
                  },
                  'status': 'draft',
                },
              ], 200);
            }
            return http.Response('', 204);
          },
        );
        _resolve(async, store.loadDrafts());
        _resolve(async, store.saveDrafts(const []));
        async.elapse(const Duration(seconds: 2));

        final prefs = _resolve(async, SharedPreferences.getInstance());
        final cache =
            jsonDecode(prefs.getString('truecrime.case_drafts.$_accountId')!)
                as Map<String, dynamic>;
        expect(cache['pendingDeletes'], ['draft-a']);
        final recoverable =
            (cache['deletedDrafts'] as Map<String, dynamic>)['draft-a']
                as Map<String, dynamic>;
        expect(recoverable['draftId'], 'draft-a');
        expect(recoverable['title'], 'No perder el borrador');
        expect(store.currentStatus, DraftsSyncStatus.retrying);
        expect(confirmations, hasLength(1));
        expect(confirmations.single.url.queryParameters['owner'], 'eq.$_accountId');
        expect(confirmations.single.url.queryParameters['id'], 'eq.draft-a');

        async.elapse(const Duration(seconds: 16));
        expect(confirmationAttempts, 2);
      });
    });

    test('deleting a never-sent draft cancels it without a DELETE', () {
      fakeAsync((async) {
        var requests = 0;
        final store = _store(
          handler: (request) async {
            if (request.method == 'GET') return _json([], 200);
            requests++;
            return http.Response('', 204);
          },
        );
        _resolve(async, store.loadDrafts());
        _resolve(
          async,
          store.saveDrafts(const [
            CaseDraft(draftId: 'draft-new', title: 'No llegó a enviarse'),
          ]),
        );
        _resolve(async, store.saveDrafts(const []));
        async.elapse(const Duration(seconds: 2));

        expect(requests, 0);
      });
    });

    test('re-adding during an in-flight DELETE queues a POST', () {
      SharedPreferences.setMockInitialValues({
        'truecrime.case_drafts.$_accountId': jsonEncode({
          'schemaVersion': 1,
          'drafts': [
            {'draftId': 'draft-a', 'title': 'Versión remota'},
          ],
          'pendingUpserts': <String>[],
          'pendingDeletes': <String>[],
          'remoteIds': ['draft-a'],
        }),
      });
      fakeAsync((async) {
        final deleteStarted = Completer<void>();
        final deleteResponse = Completer<http.Response>();
        final requests = <http.Request>[];
        final store = _store(
          handler: (request) async {
            if (request.method == 'GET') {
              if (request.url.queryParameters.containsKey('id')) {
                return _json([], 200);
              }
              return _json([
                {
                  'id': 'draft-a',
                  'payload': {'draftId': 'draft-a', 'title': 'Versión remota'},
                  'status': 'draft',
                },
              ], 200);
            }
            requests.add(request);
            if (request.method == 'DELETE') {
              deleteStarted.complete();
              return deleteResponse.future;
            }
            return http.Response('', 201);
          },
        );
        _resolve(async, store.loadDrafts());
        _resolve(async, store.saveDrafts(const []));
        async.elapse(const Duration(seconds: 2));
        async.flushMicrotasks();
        expect(deleteStarted.isCompleted, isTrue);

        _resolve(
          async,
          store.saveDrafts(const [
            CaseDraft(draftId: 'draft-a', title: 'Importado de nuevo'),
          ]),
        );
        deleteResponse.complete(http.Response('', 204));
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 2));

        expect(requests.map((request) => request.method), ['DELETE', 'POST']);
        final post = jsonDecode(requests.last.body) as Map<String, dynamic>;
        expect(post['id'], 'draft-a');
        expect(
          (post['payload'] as Map<String, dynamic>)['title'],
          'Importado de nuevo',
        );
      });
    });

    test('deleting during an in-flight POST queues a DELETE', () {
      fakeAsync((async) {
        final postStarted = Completer<void>();
        final postResponse = Completer<http.Response>();
        final requests = <http.Request>[];
        final store = _store(
          handler: (request) async {
            if (request.method == 'GET') return _json([], 200);
            requests.add(request);
            if (request.method == 'POST') {
              postStarted.complete();
              return postResponse.future;
            }
            return http.Response('', 204);
          },
        );
        _resolve(async, store.loadDrafts());
        _resolve(
          async,
          store.saveDrafts(const [
            CaseDraft(draftId: 'draft-a', title: 'Enviándose'),
          ]),
        );
        async.elapse(const Duration(seconds: 2));
        async.flushMicrotasks();
        expect(postStarted.isCompleted, isTrue);

        _resolve(async, store.saveDrafts(const []));
        final prefs = _resolve(async, SharedPreferences.getInstance());
        final inFlightDelete =
            jsonDecode(prefs.getString('truecrime.case_drafts.$_accountId')!)
                as Map<String, dynamic>;
        expect(inFlightDelete['pendingDeletes'], ['draft-a']);
        expect(inFlightDelete['uncertainPostIds'], ['draft-a']);

        postResponse.complete(http.Response('', 201));
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 2));

        expect(requests.map((request) => request.method), ['POST', 'DELETE']);
      });
    });

    test('unchanged drafts are never sent', () {
      SharedPreferences.setMockInitialValues({
        'truecrime.case_drafts.$_accountId': jsonEncode({
          'schemaVersion': 1,
          'drafts': [
            {'draftId': 'draft-a', 'title': 'Sin cambios'},
          ],
          'pendingUpserts': <String>[],
          'pendingDeletes': <String>[],
          'remoteIds': ['draft-a'],
        }),
      });
      fakeAsync((async) {
        var requests = 0;
        final store = _store(
          handler: (request) async {
            if (request.method == 'GET') {
              return _json([
                {
                  'id': 'draft-a',
                  'payload': {'draftId': 'draft-a', 'title': 'Sin cambios'},
                  'status': 'draft',
                },
              ], 200);
            }
            requests++;
            return _json([
              {'id': 'draft-a'},
            ], 200);
          },
        );
        _resolve(async, store.loadDrafts());

        store.saveDrafts(const [
          CaseDraft(draftId: 'draft-a', title: 'Sin cambios'),
        ]);
        async.elapse(const Duration(seconds: 2));

        expect(requests, 0);
      });
    });

    test('several quick saves produce a single request per changed draft', () {
      fakeAsync((async) {
        var postCount = 0;
        final store = _store(
          handler: (request) async {
            if (request.method == 'GET') return _json([], 200);
            postCount++;
            return http.Response('', 201);
          },
        );
        _resolve(async, store.loadDrafts());

        store.saveDrafts(const [CaseDraft(draftId: 'draft-a', title: 'A')]);
        async.elapse(const Duration(milliseconds: 200));
        store.saveDrafts(const [CaseDraft(draftId: 'draft-a', title: 'AB')]);
        async.elapse(const Duration(milliseconds: 200));
        store.saveDrafts(const [CaseDraft(draftId: 'draft-a', title: 'ABC')]);
        async.elapse(const Duration(seconds: 2));

        expect(postCount, 1);
      });
    });

    test(
      'a failed POST keeps the entry pending and retries after the backoff',
      () {
        fakeAsync((async) {
          var attempts = 0;
          final store = _store(
            handler: (request) async {
              if (request.method == 'GET') return _json([], 200);
              attempts++;
              if (attempts == 1) {
                throw http.ClientException('offline');
              }
              return http.Response('', 201);
            },
          );
          _resolve(async, store.loadDrafts());

          _resolve(
            async,
            store.saveDrafts(const [CaseDraft(draftId: 'draft-a', title: 'A')]),
          );
          async.elapse(const Duration(seconds: 2));
          expect(store.currentStatus, DraftsSyncStatus.retrying);

          async.elapse(const Duration(seconds: 16));
          expect(attempts, 2);
          expect(store.currentStatus, DraftsSyncStatus.synced);
        });
      },
    );

    test(
      'a committed POST with a lost response is reconciled before deleting',
      () {
        fakeAsync((async) {
          final remoteRows = <String, Map<String, dynamic>>{};
          final requests = <http.Request>[];
          final deleteConfirmation = Completer<http.Response>();
          var deleteStarted = false;
          final store = _store(
            handler: (request) async {
              requests.add(request);
              if (request.method == 'GET') {
                if (request.url.queryParameters.containsKey('id')) {
                  if (deleteStarted) return deleteConfirmation.future;
                  final id = request.url.queryParameters['id']!.substring(3);
                  final row = remoteRows[id];
                  return _json(row == null ? [] : [{'id': id}], 200);
                }
                return _json(remoteRows.values.toList(), 200);
              }
              if (request.method == 'POST') {
                final body = jsonDecode(request.body) as Map<String, dynamic>;
                final id = body['id'] as String;
                remoteRows[id] = {
                  'id': id,
                  'payload': body['payload'],
                  'status': 'draft',
                };
                throw http.ClientException('server committed; response lost');
              }
              if (request.method == 'DELETE') {
                deleteStarted = true;
                remoteRows.remove(request.url.queryParameters['id']!.substring(3));
                return http.Response('', 204);
              }
              throw StateError('Unexpected ${request.method}');
            },
          );
          _resolve(async, store.loadDrafts());
          _resolve(
            async,
            store.saveDrafts(const [
              CaseDraft(draftId: 'draft-a', title: 'Commit ambiguo'),
            ]),
          );
          async.elapse(const Duration(seconds: 2));
          expect(remoteRows, contains('draft-a'));

          _resolve(async, store.saveDrafts(const []));
          final prefs = _resolve(async, SharedPreferences.getInstance());
          final deletedCache =
              jsonDecode(prefs.getString('truecrime.case_drafts.$_accountId')!)
                  as Map<String, dynamic>;
          expect(deletedCache['pendingDeletes'], ['draft-a']);
          expect(
            (deletedCache['deletedDrafts'] as Map<String, dynamic>)['draft-a'],
            isNotNull,
          );

          async.elapse(const Duration(seconds: 16));
          async.flushMicrotasks();
          final reconciliation = requests.singleWhere(
            (request) =>
                request.method == 'GET' &&
                request.url.queryParameters['select'] == 'id,status',
          );
          expect(reconciliation.url.queryParameters['owner'], 'eq.$_accountId');
          expect(reconciliation.url.queryParameters['id'], 'eq.draft-a');
          expect(reconciliation.headers['Authorization'], 'Bearer token-abc');
          expect(deleteStarted, isTrue);

          final whileConfirming =
              jsonDecode(prefs.getString('truecrime.case_drafts.$_accountId')!)
                  as Map<String, dynamic>;
          expect(whileConfirming['pendingDeletes'], ['draft-a']);
          expect(whileConfirming['deletedDrafts'], contains('draft-a'));

          deleteConfirmation.complete(_json([], 200));
          async.flushMicrotasks();
          expect(remoteRows, isEmpty);
          final confirmed =
              jsonDecode(prefs.getString('truecrime.case_drafts.$_accountId')!)
                  as Map<String, dynamic>;
          expect(confirmed['pendingDeletes'], isEmpty);
          expect(confirmed['deletedDrafts'], isEmpty);
        });
      },
    );

    test(
      'failed uncertain-delete reconciliation retains tombstone until absence is confirmed',
      () {
        SharedPreferences.setMockInitialValues({
          'truecrime.case_drafts.$_accountId': jsonEncode({
            'schemaVersion': 1,
            'drafts': <Map<String, dynamic>>[],
            'pendingUpserts': <String>[],
            'pendingDeletes': ['draft-delete'],
            'remoteIds': <String>[],
            'uncertainPostIds': ['draft-delete'],
            'deletedDrafts': {
              'draft-delete': {
                'draftId': 'draft-delete',
                'title': 'Payload recuperable',
              },
            },
          }),
        });
        fakeAsync((async) {
          var reconciliationAttempts = 0;
          var deleteAttempts = 0;
          final reconciliations = <http.Request>[];
          final store = _store(
            handler: (request) async {
              if (request.method == 'GET') {
                if (request.url.queryParameters.containsKey('id')) {
                  reconciliations.add(request);
                  reconciliationAttempts++;
                  if (reconciliationAttempts == 1) {
                    throw http.ClientException('reconciliation offline');
                  }
                  return _json([], 200);
                }
                return _json([], 200);
              }
              if (request.method == 'DELETE') deleteAttempts++;
              return http.Response('', 204);
            },
          );
          _resolve(async, store.loadDrafts());
          async.elapse(const Duration(seconds: 2));

          final prefs = _resolve(async, SharedPreferences.getInstance());
          final retained =
              jsonDecode(prefs.getString('truecrime.case_drafts.$_accountId')!)
                  as Map<String, dynamic>;
          expect(retained['pendingDeletes'], ['draft-delete']);
          expect(retained['uncertainPostIds'], ['draft-delete']);
          expect(
            (retained['deletedDrafts'] as Map<String, dynamic>)['draft-delete']
                ['title'],
            'Payload recuperable',
          );
          expect(deleteAttempts, 0);

          async.elapse(const Duration(seconds: 16));
          expect(reconciliationAttempts, 2);
          expect(deleteAttempts, 0);
          for (final request in reconciliations) {
            expect(request.url.queryParameters['owner'], 'eq.$_accountId');
            expect(request.url.queryParameters['id'], 'eq.draft-delete');
            expect(request.headers['Authorization'], 'Bearer token-abc');
          }
          final cleared =
              jsonDecode(prefs.getString('truecrime.case_drafts.$_accountId')!)
                  as Map<String, dynamic>;
          expect(cleared['pendingDeletes'], isEmpty);
          expect(cleared['uncertainPostIds'], isEmpty);
          expect(cleared['deletedDrafts'], isEmpty);
        });
      },
    );

    test(
      'uncertain POST reconciliation failure survives restart and retries absent IDs',
      () {
        fakeAsync((async) {
          final firstStore = _store(
            handler: (request) async {
              if (request.method == 'GET') return _json([], 200);
              throw http.ClientException('response lost');
            },
          );
          _resolve(async, firstStore.loadDrafts());
          _resolve(
            async,
            firstStore.saveDrafts(const [
              CaseDraft(draftId: 'draft-retry', title: 'Conservar localmente'),
            ]),
          );
          async.elapse(const Duration(seconds: 2));
          firstStore.dispose();

          var reconciliationAttempts = 0;
          var postAttempts = 0;
          final requests = <http.Request>[];
          final restartedStore = _store(
            handler: (request) async {
              requests.add(request);
              if (request.method == 'GET') {
                if (request.url.queryParameters.containsKey('id')) {
                  reconciliationAttempts++;
                  if (reconciliationAttempts == 1) {
                    throw http.ClientException('reconciliation offline');
                  }
                  return _json([], 200);
                }
                return _json([], 200);
              }
              postAttempts++;
              return http.Response('', 201);
            },
          );
          final loaded = _resolve(async, restartedStore.loadDrafts());
          expect(loaded.single.title, 'Conservar localmente');
          async.elapse(const Duration(seconds: 2));

          final prefs = _resolve(async, SharedPreferences.getInstance());
          final retained =
              jsonDecode(prefs.getString('truecrime.case_drafts.$_accountId')!)
                  as Map<String, dynamic>;
          expect(retained['pendingUpserts'], ['draft-retry']);
          expect(retained['uncertainPostIds'], ['draft-retry']);
          expect(
            (retained['drafts'] as List<dynamic>).single['title'],
            'Conservar localmente',
          );
          expect(postAttempts, 0);

          async.elapse(const Duration(seconds: 16));
          expect(reconciliationAttempts, 2);
          expect(postAttempts, 1);
          final reconciliations = requests
              .where((request) => request.url.queryParameters.containsKey('id'))
              .toList();
          expect(reconciliations, hasLength(2));
          for (final request in reconciliations) {
            expect(request.url.queryParameters['owner'], 'eq.$_accountId');
            expect(request.url.queryParameters['id'], 'eq.draft-retry');
            expect(request.headers['Authorization'], 'Bearer token-abc');
          }
          expect(
            requests.map((request) => request.method),
            ['GET', 'GET', 'GET', 'POST'],
          );
          final completed =
              jsonDecode(prefs.getString('truecrime.case_drafts.$_accountId')!)
                  as Map<String, dynamic>;
          expect(completed['pendingUpserts'], isEmpty);
          expect(completed['uncertainPostIds'], isEmpty);
        });
      },
    );

    test('typing after a failed request preserves its retry backoff', () {
      fakeAsync((async) {
        var attempts = 0;
        final store = _store(
          handler: (request) async {
            if (request.method == 'GET') return _json([], 200);
            attempts++;
            if (attempts == 1) throw http.ClientException('offline');
            return http.Response('', 201);
          },
        );
        _resolve(async, store.loadDrafts());
        _resolve(
          async,
          store.saveDrafts(const [CaseDraft(draftId: 'draft-a', title: 'A')]),
        );
        async.elapse(const Duration(seconds: 2));
        expect(attempts, 1);

        _resolve(
          async,
          store.saveDrafts(const [CaseDraft(draftId: 'draft-a', title: 'AB')]),
        );
        async.elapse(const Duration(seconds: 1));
        expect(attempts, 1);

        async.elapse(const Duration(seconds: 13));
        expect(attempts, 2);
        expect(store.currentStatus, DraftsSyncStatus.synced);
      });
    });

    test(
      'a 409 on POST marks a conflict and keeps the local data without looping',
      () {
        fakeAsync((async) {
          var attempts = 0;
          final store = _store(
            handler: (request) async {
              if (request.method == 'GET') return _json([], 200);
              attempts++;
              return http.Response('', 409);
            },
          );
          _resolve(async, store.loadDrafts());

          store.saveDrafts(const [CaseDraft(draftId: 'draft-a', title: 'A')]);
          async.elapse(const Duration(seconds: 30));

          expect(attempts, 1);
          expect(store.currentStatus, DraftsSyncStatus.conflict);
        });
      },
    );

    test(
      'deleting after a 409 reconciles instead of discarding a possible remote row',
      () {
        fakeAsync((async) {
          final requests = <http.Request>[];
          var postAttempts = 0;
          var deleteStarted = false;
          final store = _store(
            handler: (request) async {
              requests.add(request);
              if (request.method == 'GET') {
                if (request.url.queryParameters.containsKey('id')) {
                  if (deleteStarted) return _json([], 200);
                  return _json([{'id': 'draft-conflict'}], 200);
                }
                return _json([], 200);
              }
              if (request.method == 'POST') {
                postAttempts++;
                return http.Response('', 409);
              }
              if (request.method == 'DELETE') {
                deleteStarted = true;
                return http.Response('', 204);
              }
              throw StateError('Unexpected ${request.method}');
            },
          );
          _resolve(async, store.loadDrafts());
          _resolve(
            async,
            store.saveDrafts(const [
              CaseDraft(draftId: 'draft-conflict', title: 'Duplicado'),
            ]),
          );
          async.elapse(const Duration(seconds: 2));
          expect(postAttempts, 1);
          expect(store.currentStatus, DraftsSyncStatus.conflict);

          _resolve(async, store.saveDrafts(const []));
          final prefs = _resolve(async, SharedPreferences.getInstance());
          final tombstone =
              jsonDecode(prefs.getString('truecrime.case_drafts.$_accountId')!)
                  as Map<String, dynamic>;
          expect(tombstone['pendingDeletes'], ['draft-conflict']);
          expect(tombstone['deletedDrafts'], contains('draft-conflict'));

          async.elapse(const Duration(seconds: 2));
          expect(postAttempts, 1);
          expect(deleteStarted, isTrue);
          final reconciliation = requests.singleWhere(
            (request) =>
                request.method == 'GET' &&
                request.url.queryParameters['select'] == 'id,status',
          );
          expect(reconciliation.url.queryParameters['owner'], 'eq.$_accountId');
          expect(reconciliation.url.queryParameters['id'], 'eq.draft-conflict');
          expect(
            requests.map((request) => request.method),
            ['GET', 'POST', 'GET', 'DELETE', 'GET'],
          );
          final confirmed =
              jsonDecode(prefs.getString('truecrime.case_drafts.$_accountId')!)
                  as Map<String, dynamic>;
          expect(confirmed['pendingDeletes'], isEmpty);
          expect(confirmed['deletedDrafts'], isEmpty);
        });
      },
    );

    test(
      '0 rows back from a PATCH marks a conflict and keeps the local version',
      () {
        SharedPreferences.setMockInitialValues({
          'truecrime.case_drafts.$_accountId': jsonEncode({
            'schemaVersion': 1,
            'drafts': [
              {'draftId': 'draft-a', 'title': 'Viejo'},
            ],
            'pendingUpserts': <String>[],
            'pendingDeletes': <String>[],
            'remoteIds': ['draft-a'],
          }),
        });
        fakeAsync((async) {
          var attempts = 0;
          final store = _store(
            handler: (request) async {
              if (request.method == 'GET') {
                return _json([
                  {
                    'id': 'draft-a',
                    'payload': {'draftId': 'draft-a', 'title': 'Viejo'},
                    'status': 'draft',
                  },
                ], 200);
              }
              attempts++;
              return _json([], 200);
            },
          );
          _resolve(async, store.loadDrafts());

          store.saveDrafts(const [
            CaseDraft(draftId: 'draft-a', title: 'En revisión'),
          ]);
          async.elapse(const Duration(seconds: 30));

          expect(attempts, 1);
          expect(store.currentStatus, DraftsSyncStatus.conflict);
        });
      },
    );
  });
}
