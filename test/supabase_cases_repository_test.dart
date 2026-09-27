import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:true_app/features/cases/application/cases_providers.dart';
import 'package:true_app/features/cases/data/supabase_cases_repository.dart';
import 'package:true_app/features/cases/data/supabase_project.dart';

/// Lectura del catálogo publicado desde Supabase (CRP-02).
///
/// Un fallo nunca se convierte en un catálogo vacío: un archivo vacío que
/// parece real es peor que un error explícito con opción de reintentar.
Map<String, dynamic> _case(String slug, {String? title}) {
  return {
    'id': slug,
    'slug': slug,
    'title': title ?? 'Caso $slug',
    'category': 'unsolved',
    'country': 'Noruega',
    'countryCode': 'NO',
    'regionOrCity': 'Bergen',
    'year': 1970,
    'latitude': 60.39,
    'longitude': 5.32,
    'summary': 'Resumen.',
    'tags': <String>[],
    'sources': <Map<String, dynamic>>[],
  };
}

String _rows(List<Map<String, dynamic>> cases) {
  return jsonEncode([
    for (final c in cases) {'payload': c},
  ]);
}

http.Response _ok(String body) {
  return http.Response.bytes(
    utf8.encode(body),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

void main() {
  test(
    'asks for the payloads ordered by sort_order with the public key',
    () async {
      late http.Request sent;
      final repository = SupabaseCasesRepository(
        client: MockClient((request) async {
          sent = request;
          return _ok('[]');
        }),
      );

      await repository.getCases();

      expect(sent.method, 'GET');
      expect(sent.url.origin, supabaseUrl);
      expect(sent.url.path, '/rest/v1/cases');
      expect(sent.url.queryParameters, {
        'select': 'payload',
        'order': 'sort_order.asc',
      });
      expect(sent.headers['apikey'], supabasePublishableKey);
    },
  );

  test('returns the published cases in the order served', () async {
    final repository = SupabaseCasesRepository(
      client: MockClient(
        (_) async => _ok(
          _rows([
            _case('zodiac'),
            _case('caso-asunta', title: 'Asunta Basterra'),
          ]),
        ),
      ),
    );

    final cases = await repository.getCases();

    expect(cases.map((c) => c.slug), ['zodiac', 'caso-asunta']);
    expect(cases.last.title, 'Asunta Basterra');
  });

  test('keeps accents in UTF-8 bodies', () async {
    final repository = SupabaseCasesRepository(
      client: MockClient(
        (_) async => _ok(
          _rows([_case('isdal', title: 'La mujer de Isdal · Noruega ñ')]),
        ),
      ),
    );

    final cases = await repository.getCases();

    expect(cases.single.title, 'La mujer de Isdal · Noruega ñ');
  });

  test('fails loudly on a non-200 response', () async {
    final repository = SupabaseCasesRepository(
      client: MockClient((_) async => http.Response('{"message":"down"}', 503)),
    );

    await expectLater(
      repository.getCases(),
      throwsA(isA<CasesUnavailableException>()),
    );
  });

  test('fails loudly on a malformed body', () async {
    final repository = SupabaseCasesRepository(
      client: MockClient((_) async => _ok('{"not": "a list"}')),
    );

    await expectLater(repository.getCases(), throwsA(anything));
  });

  test('fails loudly when the network fails', () async {
    final repository = SupabaseCasesRepository(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );

    await expectLater(repository.getCases(), throwsA(anything));
  });

  test('fails when the server does not answer in time', () async {
    final never = Completer<http.Response>();
    final repository = SupabaseCasesRepository(
      client: MockClient((_) => never.future),
      timeout: const Duration(milliseconds: 10),
    );

    await expectLater(repository.getCases(), throwsA(isA<TimeoutException>()));
  });

  test('the app reads the catalog from Supabase', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(casesRepositoryProvider),
      isA<SupabaseCasesRepository>(),
    );
  });
}
