import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/home/presentation/portada/portada_hero_keys.dart';

import 'test_support/portada_test_support.dart';

// Gap del prototipo entre pestañas (Globo.dc.html: gap 14).
const double _tabGap = 14;

Rect _tab(WidgetTester tester, int i) =>
    tester.getRect(find.byKey(PortadaHeroKeys.tab(i)));

void main() {
  group('pestañas de escritorio', () {
    testWidgets('todas miden lo mismo y están separadas por 14 px', (
      tester,
    ) async {
      await pumpPortadaHero(tester);

      final first = _tab(tester, 0);
      for (var i = 1; i < portadaCases.length; i++) {
        final tab = _tab(tester, i);
        expect(tab.width, closeTo(first.width, 1e-6));
        expect(tab.left - _tab(tester, i - 1).right, closeTo(_tabGap, 1e-6));
      }
    });

    testWidgets('el nombre empieza en el borde izquierdo de su barra', (
      tester,
    ) async {
      await pumpPortadaHero(tester);

      for (var i = 0; i < portadaCases.length; i++) {
        final name = tester.getRect(find.byKey(PortadaHeroKeys.tabName(i)));
        final bar = tester.getRect(find.byKey(PortadaHeroKeys.tabTrack(i)));
        expect(name.left, closeTo(bar.left, 1e-6), reason: 'pestaña $i');
        expect(bar.left, closeTo(_tab(tester, i).left, 1e-6));
        expect(bar.width, closeTo(_tab(tester, i).width, 1e-6));
        expect(name.bottom, lessThanOrEqualTo(bar.top), reason: 'pestaña $i');
      }
    });

    testWidgets('un nombre largo se recorta dentro de su pestaña', (
      tester,
    ) async {
      final long = portadaCase(
        id: 'largo',
        title: 'Un nombre de caso muy pero muy largo para su pestaña',
      );
      await pumpPortadaHero(tester, featured: [long, ...portadaCases]);

      final widths = {
        for (var i = 0; i < 6; i++) _tab(tester, i).width.toStringAsFixed(3),
      };
      expect(widths, hasLength(1));
      for (var i = 0; i < 6; i++) {
        final name = tester.getRect(find.byKey(PortadaHeroKeys.tabName(i)));
        expect(name.right, lessThanOrEqualTo(_tab(tester, i).right + 1e-6));
      }
    });

    testWidgets(
      'el relleno de la pestaña activa se dibuja con el alto de la barra',
      (tester) async {
        await pumpPortadaHero(tester);
        await pumpStep(tester, const Duration(seconds: 3));

        final fill = tester.getRect(find.byKey(PortadaHeroKeys.tabFill(0)));
        final bar = tester.getRect(find.byKey(PortadaHeroKeys.tabTrack(0)));
        expect(fill.width, greaterThan(0));
        expect(fill.height, closeTo(bar.height, 1e-6));
        expect(bar.height, 3);
      },
    );
  });

  group('pestañas en 390 px', () {
    testWidgets('ninguna se sale de la pantalla y todas miden lo mismo', (
      tester,
    ) async {
      await pumpPortadaHero(tester, size: phoneSize);

      final first = _tab(tester, 0);
      for (var i = 0; i < portadaCases.length; i++) {
        final tab = _tab(tester, i);
        expect(tab.left, greaterThanOrEqualTo(0), reason: 'pestaña $i');
        expect(
          tab.right,
          lessThanOrEqualTo(phoneSize.width),
          reason: 'pestaña $i',
        );
        expect(tab.width, closeTo(first.width, 1e-6));
        expect(tab.height, greaterThanOrEqualTo(24));
      }
    });

    testWidgets(
      'son barras tipo historias bajo la cabecera, de 16 px a 16 px',
      (tester) async {
        await pumpPortadaHero(tester, size: phoneSize);

        expect(_tab(tester, 0).left, 16);
        expect(
          _tab(tester, portadaCases.length - 1).right,
          phoneSize.width - 16,
        );
        expect(_tab(tester, 1).left - _tab(tester, 0).right, 6);
        expect(tester.getRect(find.byKey(PortadaHeroKeys.tab(0))).top, 72);
        expect(find.byKey(PortadaHeroKeys.tabName(0)), findsNothing);
      },
    );

    testWidgets('conservan nombre accesible y se pueden tocar', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpPortadaHero(tester, size: phoneSize);

      expect(
        tester.getSemantics(find.byKey(PortadaHeroKeys.tab(1))).label,
        portadaCases[1].title,
      );
      await tapTab(tester, 1);
      expect(find.byKey(PortadaHeroKeys.title('isdal')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('por la carcasa real tampoco se salen', (tester) async {
      await pumpRealShell(tester, phoneSize);

      for (var i = 0; i < 4; i++) {
        final tab = _tab(tester, i);
        expect(tab.left, greaterThanOrEqualTo(0));
        expect(tab.right, lessThanOrEqualTo(phoneSize.width));
      }
    });
  });
}
