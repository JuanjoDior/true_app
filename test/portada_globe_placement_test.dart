import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/home/presentation/portada/portada_hero.dart';
import 'package:true_app/features/home/presentation/portada/portada_shell.dart';

import 'test_support/portada_test_support.dart';

// Alturas reales del héroe dentro de la carcasa (740 en escritorio, 640 en estrecho).
const Size _desktopHero = Size(1440, PortadaShell.desktopHeroHeight);
const Size _phoneHero = Size(390, PortadaShell.mobileHeroHeight);

void _expectInside(Rect hero, ({Offset center, double radius}) globe) {
  final sphere = Rect.fromCircle(center: globe.center, radius: globe.radius);
  expect(sphere.left, greaterThanOrEqualTo(hero.left), reason: '$sphere');
  expect(sphere.right, lessThanOrEqualTo(hero.right), reason: '$sphere');
  expect(sphere.top, greaterThanOrEqualTo(hero.top), reason: '$sphere');
  expect(sphere.bottom, lessThanOrEqualTo(hero.bottom), reason: '$sphere');
}

void main() {
  group('globo del héroe de escritorio', () {
    for (final size in [_desktopHero, desktopSize]) {
      testWidgets(
        'cabe en el héroe de ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await pumpPortadaHero(tester, size: size);

          final globe = globeCircle(tester);
          _expectInside(Offset.zero & size, globe);
          expect(globe.center.dx, greaterThan(size.width / 2));
          expect(globe.radius, greaterThan(size.height * 0.35));
        },
      );
    }
  });

  group('globo del héroe estrecho', () {
    for (final size in [_phoneHero, phoneSize]) {
      testWidgets(
        'cabe en el héroe de ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await pumpPortadaHero(tester, size: size);

          final globe = globeCircle(tester);
          _expectInside(Offset.zero & size, globe);
          expect(globe.radius, greaterThan(size.width * 0.3));
        },
      );
    }
  });

  group('por la carcasa real', () {
    for (final size in [desktopSize, phoneSize]) {
      testWidgets(
        'el globo cabe en el héroe a ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await pumpRealShell(tester, size);

          final hero = tester.getRect(find.byType(PortadaHero));
          expect(hero.height, size.width >= 1200 ? 740 : 640);
          _expectInside(hero, globeCircle(tester));
        },
      );
    }
  });
}
