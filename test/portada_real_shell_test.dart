import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/home/presentation/portada/portada_hero.dart';
import 'package:true_app/features/home/presentation/portada/portada_hero_keys.dart';

import 'test_support/portada_test_support.dart';
import 'test_support/sample_cases.dart';

// El héroe llega con el catálogo todavía cargando: el contenido del slide activo
// debe terminar visible, dentro del héroe y con tamaño.
void main() {
  for (final size in [desktopSize, phoneSize]) {
    testWidgets(
      'el contenido del slide activo se ve a ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        await pumpRealShell(tester, size);

        final hero = tester.getRect(find.byType(PortadaHero));
        final active =
            (sampleCases.where((c) => c.featuredRank != null).toList()
                  ..sort((a, b) => a.featuredRank!.compareTo(b.featuredRank!)))
                .first;

        expect(contentOpacity(tester, active.id), 1);
        for (final key in [
          PortadaHeroKeys.title(active.id),
          PortadaHeroKeys.summary(active.id),
          PortadaHeroKeys.coords(active.id),
        ]) {
          final rect = tester.getRect(find.byKey(key));
          expect(rect.width, greaterThan(0), reason: '$key');
          expect(rect.height, greaterThan(0), reason: '$key');
          expect(rect.left, greaterThanOrEqualTo(hero.left), reason: '$key');
          expect(rect.top, greaterThanOrEqualTo(hero.top), reason: '$key');
          expect(rect.right, lessThanOrEqualTo(hero.right), reason: '$key');
          expect(rect.bottom, lessThanOrEqualTo(hero.bottom), reason: '$key');
        }
      },
    );
  }
}
