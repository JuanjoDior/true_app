import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:true_app/features/cases/data/draft_submission.dart';
import 'package:true_app/features/cases/data/draft_submission_service.dart';
import 'package:true_app/features/cases/data/supabase_project.dart';

import 'test_support/fake_intake_auth.dart';

const _okBody =
    '{"status":"in_review","submitted_at":"2026-09-29T10:00:00+00:00"}';

http.Response _json(int status, Map<String, Object?> body) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

({DraftSubmissionService service, List<http.Request> requests}) _build(
  Future<http.Response> Function(http.Request request) handler, {
  FakeIntakeAuth? auth,
  Duration timeout = const Duration(seconds: 5),
}) {
  final requests = <http.Request>[];
  final client = MockClient((request) {
    requests.add(request);
    return handler(request);
  });
  addTearDown(client.close);
  return (
    service: DraftSubmissionService(
      auth: auth ?? FakeIntakeAuth.signedIn(),
      client: client,
      timeout: timeout,
    ),
    requests: requests,
  );
}

DraftSubmission _begin({String accountId = 'user-ivan'}) =>
    DraftSubmission.begin(submittableTestDraft(), accountId: accountId);

Future<Object> _failure(Future<Object?> call) async {
  try {
    await call;
  } catch (error) {
    return error;
  }
  fail('Expected the call to fail');
}

void main() {
  group('request', () {
    test(
      'posts the exact snapshot to the RPC with the account token',
      () async {
        final built = _build((_) async => http.Response(_okBody, 200));
        final submission = _begin();

        await built.service.send(submission);

        final request = built.requests.single;
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          '$supabaseUrl/rest/v1/rpc/submit_draft_snapshot',
        );
        expect(request.headers['apikey'], supabasePublishableKey);
        expect(request.headers['Authorization'], 'Bearer token-user-ivan');
        expect(request.headers['Accept'], 'application/json');
        expect(request.headers['Content-Type'], startsWith('application/json'));
        expect(jsonDecode(request.body), {
          'p_draft_id': submission.draftId,
          'p_submission_id': submission.submissionId,
          'p_payload': submittableTestDraft().toJson(),
        });
      },
    );

    test('returns the receipt of a 200', () async {
      final built = _build((_) async => http.Response(_okBody, 200));

      final receipt = await built.service.send(_begin());

      expect(receipt.status, DraftSubmissionStatus.inReview);
      expect(receipt.submittedAt, DateTime.utc(2026, 9, 29, 10));
    });

    for (final entry in {
      'draft': DraftSubmissionStatus.draft,
      'returned': DraftSubmissionStatus.returned,
      'published': DraftSubmissionStatus.published,
    }.entries) {
      test('understands the status ${entry.key}', () async {
        final built = _build(
          (_) async => _json(200, {
            'status': entry.key,
            'submitted_at': '2026-09-29T10:00:00+00:00',
          }),
        );

        expect((await built.service.send(_begin())).status, entry.value);
      });
    }
  });

  group('retries', () {
    for (final failure in <String, Object>{
      'a timeout': TimeoutException('lento'),
      'a network error': http.ClientException('sin red'),
    }.entries) {
      test(
        'after ${failure.key} reuse the same id and frozen payload',
        () async {
          var attempts = 0;
          final built = _build((_) async {
            if (attempts++ == 0) throw failure.value;
            return http.Response(_okBody, 200);
          });
          var draft = submittableTestDraft();
          final submission = DraftSubmission.begin(
            draft,
            accountId: 'user-ivan',
          );

          final error = await _failure(built.service.send(submission));
          expect(error, isA<SubmissionOutcomeUnknownException>());
          final unknown = error as SubmissionOutcomeUnknownException;
          expect(unknown.submission, same(submission));

          // Iván sigue editando en local entre el fallo y el reintento.
          draft = draft.copyWith(title: 'Editado después del fallo');
          await built.service.send(unknown.submission);

          expect(built.requests, hasLength(2));
          expect(built.requests[1].body, built.requests[0].body);
          final body =
              jsonDecode(built.requests[1].body) as Map<String, dynamic>;
          expect(body['p_submission_id'], submission.submissionId);
          expect(
            (body['p_payload'] as Map)['title'],
            submittableTestDraft().title,
          );
          expect(draft.title, 'Editado después del fallo');
        },
      );
    }

    test('a new intention uses a different id', () async {
      final built = _build((_) async => http.Response(_okBody, 200));

      await built.service.send(_begin());
      await built.service.send(_begin());

      final ids = built.requests
          .map((r) => (jsonDecode(r.body) as Map)['p_submission_id'])
          .toSet();
      expect(ids, hasLength(2));
    });

    // No se serializa: el servidor es idempotente por submission_id (el
    // perdedor de la carrera espera al ganador y devuelve el mismo estado).
    test('two concurrent calls of one intention both complete', () async {
      final built = _build((_) async => http.Response(_okBody, 200));
      final submission = _begin();

      final receipts = await Future.wait([
        built.service.send(submission),
        built.service.send(submission),
      ]);

      expect(
        receipts.map((r) => r.status),
        everyElement(DraftSubmissionStatus.inReview),
      );
      expect(built.requests, hasLength(2));
      expect(built.requests[0].body, built.requests[1].body);
    });
  });

  group('ambiguous outcomes', () {
    test('a timeout is unknown', () async {
      final built = _build(
        (_) => Completer<http.Response>().future,
        timeout: const Duration(milliseconds: 20),
      );

      expect(
        await _failure(built.service.send(_begin())),
        isA<SubmissionOutcomeUnknownException>(),
      );
    });

    test('a 200 with an unreadable body is unknown, never a success', () async {
      for (final body in ['no es json', '[]', '{"status":"raro"}', '']) {
        final built = _build((_) async => http.Response(body, 200));

        expect(
          await _failure(built.service.send(_begin())),
          isA<SubmissionOutcomeUnknownException>(),
          reason: body,
        );
      }
    });

    test('a 5xx without a known code is unknown', () async {
      for (final response in [
        http.Response('Bad gateway', 502),
        _json(500, {'message': 'boom'}),
        _json(503, {'code': 'XX000'}),
      ]) {
        final built = _build((_) async => response);

        expect(
          await _failure(built.service.send(_begin())),
          isA<SubmissionOutcomeUnknownException>(),
        );
      }
    });
  });

  group('definitive failures', () {
    test('a 500 with code 55000 is already in review', () async {
      final built = _build((_) async => _json(500, {'code': '55000'}));

      expect(
        await _failure(built.service.send(_begin())),
        isA<SubmissionAlreadyInReviewException>(),
      );
    });

    test('a 400 with code 22023 is rejected', () async {
      final built = _build((_) async => _json(400, {'code': '22023'}));

      expect(
        await _failure(built.service.send(_begin())),
        isA<SubmissionRejectedException>(),
      );
    });

    test('a 4xx without a known code is rejected with its status', () async {
      final built = _build((_) async => http.Response('nope', 418));

      final error = await _failure(built.service.send(_begin()));

      expect(error, isA<SubmissionRejectedException>());
      expect((error as SubmissionRejectedException).statusCode, 418);
    });

    test('403 and 42501 are forbidden', () async {
      for (final response in [
        _json(403, {'code': '42501'}),
        _json(400, {'code': '42501'}),
        http.Response('', 403),
      ]) {
        final built = _build((_) async => response);

        expect(
          await _failure(built.service.send(_begin())),
          isA<SubmissionForbiddenException>(),
        );
      }
    });

    test('a 401 or an expired JWT is a session error', () async {
      for (final response in [
        http.Response('', 401),
        _json(401, {'code': 'PGRST301', 'message': 'JWT expired'}),
      ]) {
        final built = _build((_) async => response);

        expect(
          await _failure(built.service.send(_begin())),
          isA<SubmissionSessionException>(),
        );
      }
    });
  });

  group('session', () {
    test('without a session nothing is requested', () async {
      final built = _build(
        (_) async => http.Response(_okBody, 200),
        auth: FakeIntakeAuth(),
      );

      expect(
        await _failure(built.service.send(_begin())),
        isA<SubmissionSessionException>(),
      );
      expect(built.requests, isEmpty);
    });

    test('a session of another account requests nothing', () async {
      final built = _build((_) async => http.Response(_okBody, 200));

      expect(
        await _failure(built.service.send(_begin(accountId: 'user-berta'))),
        isA<SubmissionSessionException>(),
      );
      expect(built.requests, isEmpty);
    });

    test('switching account between begin and send requests nothing', () async {
      final auth = FakeIntakeAuth.signedIn();
      final built = _build(
        (_) async => http.Response(_okBody, 200),
        auth: auth,
      );
      final submission = _begin();

      await auth.signIn(email: 'berta@example.com', password: 'x');

      expect(
        await _failure(built.service.send(submission)),
        isA<SubmissionSessionException>(),
      );
      expect(built.requests, isEmpty);
    });
  });

  group('no leaks', () {
    test('exceptions never contain the token or the draft content', () async {
      final secretTitle = submittableTestDraft().title!;
      final handlers = <Future<http.Response> Function(http.Request)>[
        (_) async => throw http.ClientException('sin red'),
        (_) async => throw TimeoutException('lento'),
        (_) async => http.Response('basura', 200),
        (r) async => http.Response('eco: ${r.body} ${r.headers}', 500),
        (r) async => _json(400, {'code': '22023', 'message': r.body}),
        (r) async => _json(403, {'code': '42501', 'message': r.body}),
        (r) async => _json(500, {'code': '55000', 'message': r.body}),
        (r) async => http.Response(r.headers['Authorization']!, 401),
      ];

      for (final handler in handlers) {
        final built = _build(handler);
        final error = await _failure(built.service.send(_begin()));
        final text = error.toString();

        expect(error, isA<DraftSubmissionException>());
        expect(text, isNot(contains('token-user-ivan')));
        expect(text, isNot(contains(secretTitle)));
        expect(text, isNot(contains('Bearer')));
      }
    });
  });
}
