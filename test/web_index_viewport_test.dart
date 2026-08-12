import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guard del documento anfitrión de la web.
///
/// Sin `<meta name="viewport" content="width=device-width...">` un navegador
/// móvil no adopta el ancho del dispositivo: reporta un viewport de ancho de
/// escritorio, `MediaQuery.sizeOf(context).width` sale por encima de
/// `Breakpoints.intakeThreePane` y el workspace de intake elige la rama de
/// tres columnas dentro de una pantalla de 390px, desbordando en horizontal.
///
/// Ningún widget test puede detectar esto: `tester.view.physicalSize` inyecta
/// el tamaño directamente y salta por encima de la negociación de viewport del
/// navegador. Toda la suite responsive puede estar verde mientras el sitio
/// publicado renderiza el layout de escritorio en un teléfono. Este archivo es
/// la única capa que mira el HTML real que `flutter build web` copia a
/// `build/web/` y que el workflow de Pages publica.
void main() {
  group('web/index.html', () {
    late String html;

    setUpAll(() {
      html = File('web/index.html').readAsStringSync();
    });

    test('declara un meta viewport', () {
      expect(
        RegExp(r'<meta\s+name="viewport"', caseSensitive: false).hasMatch(html),
        isTrue,
        reason: 'web/index.html debe declarar <meta name="viewport">; sin él '
            'el móvil renderiza el layout de escritorio.',
      );
    });

    test('el meta viewport adopta el ancho del dispositivo', () {
      final meta = RegExp(
        r'<meta\s+name="viewport"[^>]*content="([^"]*)"',
        caseSensitive: false,
      ).firstMatch(html);

      expect(meta, isNotNull, reason: 'el meta viewport no tiene content');
      final content = meta!.group(1)!.replaceAll(' ', '');

      expect(
        content,
        contains('width=device-width'),
        reason: 'sin width=device-width el navegador cae a un ancho de '
            'escritorio por defecto y el layout responsive nunca se activa.',
      );
      expect(
        content,
        contains('initial-scale=1'),
        reason: 'sin initial-scale=1 el navegador puede aplicar '
            'shrink-to-fit y renderizar la app escalada.',
      );
    });

    test('el meta viewport no bloquea el zoom del navegador', () {
      final meta = RegExp(
        r'<meta\s+name="viewport"[^>]*content="([^"]*)"',
        caseSensitive: false,
      ).firstMatch(html);

      expect(meta, isNotNull, reason: 'el meta viewport no tiene content');
      final content = meta!.group(1)!.replaceAll(' ', '').toLowerCase();

      // La plantilla de Flutter trae ambos; se omiten a propósito. Bloquear
      // el pinch-zoom es una regresión de accesibilidad (WCAG 1.4.4).
      expect(
        content,
        isNot(contains('maximum-scale')),
        reason: 'maximum-scale limita el zoom nativo del navegador.',
      );
      expect(
        content,
        isNot(contains('user-scalable=no')),
        reason: 'user-scalable=no desactiva el zoom nativo del navegador.',
      );
    });
  });
}
