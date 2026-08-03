import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/cases/data/reverse_geocoder.dart';

String nominatimBody(Map<String, dynamic> address) {
  return jsonEncode({'address': address});
}

void main() {
  group('parseNominatimPlace', () {
    test('reads country, ISO code and city from a full response', () {
      final place = parseNominatimPlace(
        nominatimBody({
          'city': 'A Coruña',
          'state': 'Galicia',
          'country': 'España',
          'country_code': 'es',
        }),
      );

      expect(place, isNotNull);
      expect(place!.country, 'España');
      expect(place.regionOrCity, 'A Coruña');
      // El catálogo guarda el código en mayúsculas.
      expect(place.countryCode, 'ES');
    });

    test('falls back through the place-name fields in order', () {
      // Nominatim usa una clave distinta según el tamaño del municipio, así
      // que hay que recorrerlas de la más específica a la más general.
      String? cityOf(Map<String, dynamic> address) {
        return parseNominatimPlace(nominatimBody({
          'country': 'España',
          'country_code': 'es',
          ...address,
        }))?.regionOrCity;
      }

      expect(cityOf({'city': 'Ciudad', 'town': 'Pueblo'}), 'Ciudad');
      expect(cityOf({'town': 'Pueblo', 'village': 'Aldea'}), 'Pueblo');
      expect(cityOf({'village': 'Aldea', 'municipality': 'Concello'}), 'Aldea');
      expect(cityOf({'municipality': 'Concello', 'county': 'Comarca'}),
          'Concello');
      expect(cityOf({'county': 'Comarca', 'state': 'Galicia'}), 'Comarca');
      expect(cityOf({'state': 'Galicia'}), 'Galicia');
    });

    test('still resolves when only the country is known', () {
      // Un punto en mitad del océano o en un desierto no trae municipio.
      final place = parseNominatimPlace(
        nominatimBody({'country': 'España', 'country_code': 'es'}),
      );

      expect(place, isNotNull);
      expect(place!.country, 'España');
      expect(place.regionOrCity, isNull);
    });

    test('returns null when there is no country to anchor the place', () {
      expect(
        parseNominatimPlace(nominatimBody({'city': 'Sin país'})),
        isNull,
      );
    });

    test('returns null for an error payload or a point in the sea', () {
      expect(parseNominatimPlace('{"error":"Unable to geocode"}'), isNull);
      expect(parseNominatimPlace('{}'), isNull);
    });

    test('returns null instead of throwing on a malformed body', () {
      // Una respuesta rota nunca debe tumbar el formulario.
      expect(parseNominatimPlace('no es json'), isNull);
      expect(parseNominatimPlace(''), isNull);
      expect(parseNominatimPlace('[]'), isNull);
    });

    test('trims surrounding whitespace in the returned names', () {
      final place = parseNominatimPlace(
        nominatimBody({
          'city': '  A Coruña  ',
          'country': '  España ',
          'country_code': ' es ',
        }),
      );

      expect(place!.regionOrCity, 'A Coruña');
      expect(place.country, 'España');
      expect(place.countryCode, 'ES');
    });

    test('ignores blank fields instead of treating them as values', () {
      final place = parseNominatimPlace(
        nominatimBody({
          'city': '   ',
          'town': 'Pueblo',
          'country': 'España',
          'country_code': 'es',
        }),
      );

      expect(place!.regionOrCity, 'Pueblo');
    });
  });

  group('nominatimReverseUri', () {
    test('builds the reverse endpoint with the coordinates and language', () {
      final uri = nominatimReverseUri(43.39, -8.41);

      expect(uri.host, 'nominatim.openstreetmap.org');
      expect(uri.path, '/reverse');
      expect(uri.queryParameters['format'], 'jsonv2');
      expect(uri.queryParameters['lat'], '43.39');
      expect(uri.queryParameters['lon'], '-8.41');
      // La app está en castellano, así que los topónimos también.
      expect(uri.queryParameters['accept-language'], 'es');
    });
  });
}
