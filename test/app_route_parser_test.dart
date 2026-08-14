import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/app/navigation/app_route_information_parser.dart';
import 'package:true_app/app/navigation/app_route_path.dart';

/// El parser de rutas [diseño §7.2].
///
/// Sólo traduce entre URI y estado de ruta. No sabe de mapa, de catálogo ni de
/// workspace, y por eso se prueba sin montar nada.

final _parser = AppRouteInformationParser();

Future<AppRoutePath> _parse(String location) {
  return _parser.parseRouteInformation(
    RouteInformation(uri: Uri.parse(location)),
  );
}

String? _restore(AppRoutePath path) =>
    _parser.restoreRouteInformation(path)?.uri.toString();

void main() {
  group('reconocer la raíz', () {
    test('an empty location is the Situation Room', () async {
      expect(await _parse(''), isA<SituationRoomPath>());
    });

    test('a bare slash is the Situation Room', () async {
      expect(await _parse('/'), isA<SituationRoomPath>());
    });
  });

  group('reconocer un expediente', () {
    test('a case route yields its slug', () async {
      final path = await _parse('/casos/mujer-de-isdal');

      expect((path as CaseDetailPath).slug, 'mujer-de-isdal');
    });

    test('a percent-encoded slug is decoded', () async {
      final path = await _parse('/casos/caso%20del%20faro');

      expect((path as CaseDetailPath).slug, 'caso del faro');
    });

    test('a trailing slash still resolves the case', () async {
      // `/casos/slug/` produce un segmento final vacío que hay que descartar,
      // no un slug distinto.
      final path = await _parse('/casos/mujer-de-isdal/');

      expect((path as CaseDetailPath).slug, 'mujer-de-isdal');
    });
  });

  group('todo lo demás es desconocido', () {
    test('a case route without a slug is unknown', () async {
      expect(await _parse('/casos'), isA<UnknownAppPath>());
    });

    test('a case route with an empty slug is unknown', () async {
      expect(await _parse('/casos/'), isA<UnknownAppPath>());
    });

    test('a deeper case route is unknown', () async {
      // Un segmento de más NO es un slug: `/casos/a/b` no abre el caso 'a'.
      expect(await _parse('/casos/a/b'), isA<UnknownAppPath>());
    });

    test('an unrelated route is unknown', () async {
      expect(await _parse('/ajustes'), isA<UnknownAppPath>());
    });

    test('an unknown route keeps its original uri', () async {
      final path = await _parse('/ajustes/avanzados');

      // Se conserva para poder devolverla intacta: la barra de direcciones no
      // debe cambiar sola bajo los pies de quien la escribió.
      expect((path as UnknownAppPath).uri.toString(), '/ajustes/avanzados');
    });
  });

  group('restaurar la uri', () {
    test('the Situation Room restores to the root', () {
      expect(_restore(const SituationRoomPath()), '/');
    });

    test('a case restores to its route', () {
      expect(
        _restore(const CaseDetailPath('mujer-de-isdal')),
        '/casos/mujer-de-isdal',
      );
    });

    test('a slug with a slash is encoded, not split', () {
      // Sin codificar, el propio slug inventaría un segmento y la ruta dejaría
      // de reconocerse a sí misma.
      expect(_restore(const CaseDetailPath('a/b')), '/casos/a%2Fb');
    });

    test('an unknown path restores its original uri untouched', () {
      expect(
        _restore(UnknownAppPath(Uri.parse('/ajustes/avanzados'))),
        '/ajustes/avanzados',
      );
    });
  });

  group('ida y vuelta', () {
    test('an encoded slug survives a full round trip', () async {
      const original = CaseDetailPath('a/b');

      final restored = await _parse(_restore(original)!);

      expect((restored as CaseDetailPath).slug, 'a/b');
    });

    test('an accented slug survives a full round trip', () async {
      const original = CaseDetailPath('el-caso-del-farero-gallego-ñ');

      final restored = await _parse(_restore(original)!);

      expect((restored as CaseDetailPath).slug, original.slug);
    });
  });

  group('igualdad de rutas', () {
    // El controlador compara rutas para no duplicar historial, así que la
    // igualdad por valor no es un detalle: es lo que hace que Atrás funcione.
    test('two case paths with the same slug are equal', () {
      expect(const CaseDetailPath('a'), const CaseDetailPath('a'));
    });

    test('two case paths with different slugs are not equal', () {
      expect(const CaseDetailPath('a'), isNot(const CaseDetailPath('b')));
    });

    test('two unknown paths with the same uri are equal', () {
      expect(UnknownAppPath(Uri.parse('/x')), UnknownAppPath(Uri.parse('/x')));
    });

    test('the Situation Room is equal to itself', () {
      expect(const SituationRoomPath(), const SituationRoomPath());
    });
  });
}
