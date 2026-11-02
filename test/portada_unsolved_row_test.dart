import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/home/presentation/portada/portada_unsolved_keys.dart';

import 'test_support/portada_test_support.dart';

Finder _poster(String id) => find.byKey(PortadaUnsolvedKeys.poster(id));

double _dimOf(WidgetTester tester, String id) => tester
    .widget<AnimatedOpacity>(
      find
          .ancestor(of: _poster(id), matching: find.byType(AnimatedOpacity))
          .first,
    )
    .opacity;

void main() {
  group('encabezado', () {
    testWidgets('título y subtítulo del prototipo', (tester) async {
      await pumpPortadaUnsolved(tester);

      expect(find.text('Sin resolver').first, findsOneWidget);
      expect(
        find.text('CASOS ABIERTOS QUE SIGUEN ESPERANDO RESPUESTA'),
        findsOneWidget,
      );
    });

    testWidgets('el título es un encabezado semántico', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpPortadaUnsolved(tester);

      expect(
        tester.getSemantics(find.text('Sin resolver').first),
        matchesSemantics(label: 'Sin resolver', isHeader: true),
      );
      handle.dispose();
    });

    testWidgets('sin casos no pinta nada', (tester) async {
      await pumpPortadaUnsolved(tester, cases: const []);

      expect(find.text('Sin resolver'), findsNothing);
      expect(find.byKey(PortadaUnsolvedKeys.row), findsNothing);
    });
  });

  group('disposición', () {
    testWidgets('escritorio: margen 80, hueco 16 y orden recibido', (
      tester,
    ) async {
      await pumpPortadaUnsolved(tester);

      final ids = [for (final c in unsolvedPortadaCases) c.id];
      expect(tester.getTopLeft(_poster(ids.first)).dx, 80);
      for (var i = 1; i < ids.length; i++) {
        final previous = tester.getTopRight(_poster(ids[i - 1])).dx;
        expect(tester.getTopLeft(_poster(ids[i])).dx, previous + 16);
      }
    });

    testWidgets('móvil: margen 16, hueco 12 y pósters de 290 × 168', (
      tester,
    ) async {
      await pumpPortadaUnsolved(tester, size: phoneSize);

      expect(tester.getTopLeft(_poster('zodiac')).dx, 16);
      expect(tester.getSize(_poster('zodiac')), const Size(290, 168));
      expect(
        tester.getTopLeft(_poster('ripper')).dx,
        tester.getTopRight(_poster('zodiac')).dx + 12,
      );
    });

    testWidgets('desplaza en horizontal hasta el último póster', (
      tester,
    ) async {
      await pumpPortadaUnsolved(tester, size: phoneSize);
      expect(tester.getTopLeft(_poster('jonbenet')).dx, greaterThan(390));

      await tester.drag(
        find.byKey(PortadaUnsolvedKeys.row),
        const Offset(-900, 0),
      );
      await tester.pump();

      expect(tester.getTopLeft(_poster('jonbenet')).dx, lessThan(390));
    });

    for (final size in [desktopSize, phoneSize]) {
      testWidgets('con texto al doble no desborda a ${size.width.toInt()}', (
        tester,
      ) async {
        await pumpPortadaUnsolved(tester, size: size, textScale: 2);

        expect(tester.takeException(), isNull);
      });
    }
  });

  group('controles de desplazamiento', () {
    testWidgets('flechas accesibles recorren la fila en ambos sentidos', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpPortadaUnsolved(tester, size: phoneSize);
      final previous = find.bySemanticsLabel('Casos anteriores');
      final next = find.bySemanticsLabel('Más casos');
      expect(previous, findsOneWidget);
      expect(next, findsOneWidget);
      expect(tester.getSize(next).shortestSide, greaterThanOrEqualTo(52));
      final initial = tester.getTopLeft(_poster('zodiac')).dx;
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(_poster('zodiac')).dx, lessThan(initial));
      await tester.tap(previous);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(_poster('zodiac')).dx, closeTo(initial, 0.1));
      handle.dispose();
    });

    testWidgets('movimiento reducido desplaza inmediatamente', (tester) async {
      await pumpPortadaUnsolved(tester, size: phoneSize, reduceMotion: true);
      final initial = tester.getTopLeft(_poster('zodiac')).dx;
      await tester.tap(find.bySemanticsLabel('Más casos'));
      await tester.pump();
      expect(tester.getTopLeft(_poster('zodiac')).dx, lessThan(initial));
    });
  });

  group('interacción', () {
    testWidgets('tocar un póster entrega su caso', (tester) async {
      final callbacks = await pumpPortadaUnsolved(tester);

      await tester.tap(_poster('ripper'));

      expect(callbacks.opened.map((c) => c.id), ['ripper']);
    });

    testWidgets('con ratón sobre uno, los demás bajan a 0,45', (tester) async {
      await pumpPortadaUnsolved(tester);

      final gesture = await hoverOver(tester, _poster('zodiac'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(_dimOf(tester, 'zodiac'), 1);
      expect(_dimOf(tester, 'ripper'), 0.45);
      expect(_dimOf(tester, 'tylenol'), 0.45);

      await gesture.moveTo(const Offset(5, 880));
      await tester.pump(const Duration(milliseconds: 500));

      expect(_dimOf(tester, 'ripper'), 1);
    });
  });
}
