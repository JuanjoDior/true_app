import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/resolved_place.dart';

/// Traduce unas coordenadas al lugar que las contiene.
///
/// Nunca lanza ni bloquea: si el servicio falla, tarda o devuelve algo
/// inesperado, resuelve a `null` y el formulario sigue admitiendo que el
/// nombre del lugar se escriba a mano.
abstract class ReverseGeocoder {
  Future<ResolvedPlace?> resolve(double latitude, double longitude);
}

/// Campos de `address` que Nominatim usa para nombrar un lugar, de lo más
/// específico a lo más general. La clave cambia según el tamaño del
/// municipio, así que hay que recorrerlos en orden.
const List<String> _placeNameFields = [
  'city',
  'town',
  'village',
  'municipality',
  'county',
  'state',
];

/// Endpoint de geocodificación inversa de Nominatim (OpenStreetMap).
Uri nominatimReverseUri(double latitude, double longitude) {
  return Uri.https('nominatim.openstreetmap.org', '/reverse', {
    'format': 'jsonv2',
    'lat': '$latitude',
    'lon': '$longitude',
    // Los topónimos, en el idioma de la app.
    'accept-language': 'es',
  });
}

/// Extrae el lugar del cuerpo devuelto por Nominatim.
///
/// Devuelve `null` ante un error, un cuerpo malformado o una respuesta sin
/// país: sin país no hay ubicación que rellenar.
ResolvedPlace? parseNominatimPlace(String body) {
  final Object? decoded;
  try {
    decoded = jsonDecode(body);
  } on FormatException {
    return null;
  }
  if (decoded is! Map<String, dynamic>) {
    return null;
  }

  final address = decoded['address'];
  if (address is! Map<String, dynamic>) {
    return null;
  }

  String? valueOf(String field) {
    final value = address[field];
    if (value is! String) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  final country = valueOf('country');
  final countryCode = valueOf('country_code');
  if (country == null || countryCode == null) {
    return null;
  }

  String? regionOrCity;
  for (final field in _placeNameFields) {
    regionOrCity = valueOf(field);
    if (regionOrCity != null) {
      break;
    }
  }

  return ResolvedPlace(
    country: country,
    countryCode: countryCode.toUpperCase(),
    regionOrCity: regionOrCity,
  );
}

/// Implementación sobre Nominatim, el servicio público de OpenStreetMap.
///
/// Su política de uso pide un volumen bajo y una identificación del cliente.
/// Encaja aquí porque el alta de casos es manual, esporádica y va detrás de
/// una clave de acceso. En web el navegador no deja fijar `User-Agent`, así
/// que la identificación efectiva es el `Referer` de la propia página.
class NominatimReverseGeocoder implements ReverseGeocoder {
  const NominatimReverseGeocoder({
    http.Client? client,
    this.timeout = const Duration(seconds: 8),
  }) : _client = client;

  final http.Client? _client;
  final Duration timeout;

  @override
  Future<ResolvedPlace?> resolve(double latitude, double longitude) async {
    final client = _client ?? http.Client();
    try {
      final response = await client
          .get(
            nominatimReverseUri(latitude, longitude),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(timeout);
      if (response.statusCode != 200) {
        return null;
      }
      return parseNominatimPlace(utf8.decode(response.bodyBytes));
    } catch (_) {
      // Sin red, con el servicio caído o fuera de tiempo: el formulario
      // sigue funcionando a mano.
      return null;
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }
}
