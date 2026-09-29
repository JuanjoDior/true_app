import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/true_crime_case.dart';
import 'cases_repository.dart';
import 'supabase_project.dart';

/// El catálogo publicado no se pudo leer de Supabase.
class CasesUnavailableException implements Exception {
  const CasesUnavailableException(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'CasesUnavailableException(status: $statusCode)';
}

/// Lee los casos publicados de la tabla `cases` de Supabase.
///
/// Es una lectura anónima con la clave publicable, así que basta una petición
/// a la API REST sin el SDK de Supabase. El orden es `sort_order`, que conserva
/// la posición de un caso aunque se sustituya.
///
/// A diferencia del geocodificador, aquí un fallo SE PROPAGA: la pantalla tiene
/// que mostrar el error y dejar reintentar, nunca un archivo vacío como si
/// fuera real.
class SupabaseCasesRepository implements CasesRepository {
  const SupabaseCasesRepository({
    http.Client? client,
    this.timeout = kSupabaseNetworkTimeout,
  }) : _client = client;

  final http.Client? _client;
  final Duration timeout;

  static final Uri casesUri = Uri.parse('$supabaseUrl/rest/v1/cases').replace(
    queryParameters: const {'select': 'payload', 'order': 'sort_order.asc'},
  );

  @override
  Future<List<TrueCrimeCase>> getCases() async {
    final client = _client ?? http.Client();
    try {
      final response = await client
          .get(
            casesUri,
            headers: const {
              'apikey': supabasePublishableKey,
              'Accept': 'application/json',
            },
          )
          .timeout(timeout);
      if (response.statusCode != 200) {
        throw CasesUnavailableException(response.statusCode);
      }
      return parseCaseRows(utf8.decode(response.bodyBytes));
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }

  /// Convierte las filas `[{"payload": {...}}]` en casos, en el mismo orden.
  static List<TrueCrimeCase> parseCaseRows(String body) {
    final rows = jsonDecode(body) as List<dynamic>;
    return [
      for (final row in rows)
        TrueCrimeCase.fromJson(
          (row as Map<String, dynamic>)['payload'] as Map<String, dynamic>,
        ),
    ];
  }
}
