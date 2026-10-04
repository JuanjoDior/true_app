import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/features/home/presentation/portada/portada_hero_background.dart';
import 'package:true_app/features/home/presentation/portada/portada_hero_keys.dart';

import 'test_support/portada_test_support.dart';

const _oneMs = Duration(milliseconds: 1);
const _justBefore = Duration(milliseconds: 6999);
const _shiftIn = 28.0;
const _ghostShift = 60.0;

double _titleY(WidgetTester tester, String id) =>
    tester.getTopLeft(find.byKey(PortadaHeroKeys.title(id))).dy;

double _ghostX(WidgetTester tester, String id) =>
    tester.getTopLeft(find.byKey(PortadaHeroKeys.ghostYear(id))).dx;

String? _selected(WidgetTester tester) => globeScene(tester).selectedId;

void main() {
  group('autoavance', () {
    testWidgets('a los 6999 ms sigue en el mismo slide', (tester) async {
      await pumpPortadaHero(tester);

      await pumpStep(tester, _justBefore);

      expect(_selected(tester), 'zodiac');
      expect(find.byKey(PortadaHeroKeys.content('isdal')), findsNothing);
    });

    testWidgets('a los 7000 ms avanza al siguiente', (tester) async {
      await pumpPortadaHero(tester);

      await pumpStep(tester, _justBefore);
      await tester.pump(_oneMs);

      expect(_selected(tester), 'isdal');
      expect(find.text('2 / 5'), findsOneWidget);
    });

    testWidgets('tras el último vuelve al primero', (tester) async {
      await pumpPortadaHero(tester, initialIndex: 4);

      await pumpStep(tester, slideInterval);

      expect(_selected(tester), 'zodiac');
      expect(find.text('1 / 5'), findsOneWidget);
    });

    testWidgets('recorre todos los slides cada 7 s', (tester) async {
      await pumpPortadaHero(tester);

      final seen = <String?>[];
      for (var i = 0; i < 5; i++) {
        await pumpStep(tester, slideInterval);
        seen.add(_selected(tester));
      }

      expect(seen, ['isdal', 'somerton', 'madeleine', 'dyatlov', 'zodiac']);
    });

    testWidgets('con un solo destacado no avanza', (tester) async {
      await pumpPortadaHero(tester, featured: [portadaCases.first]);

      await pumpStep(tester, const Duration(seconds: 30));

      expect(_selected(tester), 'zodiac');
      expect(tester.takeException(), isNull);
    });
  });

  group('pestañas', () {
    testWidgets('pulsar una pestaña reinicia los 7 s', (tester) async {
      await pumpPortadaHero(tester);
      await pumpStep(tester, const Duration(seconds: 5));

      await tapTab(tester, 3);
      expect(_selected(tester), 'madeleine');

      await pumpStep(tester, _justBefore);
      expect(_selected(tester), 'madeleine');

      await tester.pump(_oneMs);
      expect(_selected(tester), 'dyatlov');
    });

    testWidgets('pulsar la pestaña activa también reinicia el tiempo', (
      tester,
    ) async {
      await pumpPortadaHero(tester);
      await pumpStep(tester, const Duration(seconds: 6));

      await tapTab(tester, 0);
      await pumpStep(tester, _justBefore);

      expect(_selected(tester), 'zodiac');
      expect(tabFill(tester, 0), closeTo(1, 1e-3));
    });

    testWidgets('la barra activa se rellena de 0 a 100 % en 7 s', (
      tester,
    ) async {
      await pumpPortadaHero(tester);

      expect(tabFill(tester, 0), closeTo(0, 1e-9));

      await pumpStep(tester, const Duration(milliseconds: 3500));
      expect(tabFill(tester, 0), closeTo(0.5, 1e-3));

      await pumpStep(tester, const Duration(milliseconds: 3499));
      expect(tabFill(tester, 0), closeTo(1, 1e-3));
    });

    testWidgets('solo rellena la activa: pasadas y futuras van vacías', (
      tester,
    ) async {
      await pumpPortadaHero(tester);
      await pumpStep(tester, slideInterval);
      await pumpStep(tester, const Duration(milliseconds: 3500));

      expect(tabFill(tester, 0), closeTo(0, 1e-9));
      expect(tabFill(tester, 1), closeTo(0.5, 1e-3));
      for (final i in [2, 3, 4]) {
        expect(tabFill(tester, i), closeTo(0, 1e-9));
      }
    });

    testWidgets('al cambiar de slide la barra vuelve a 0', (tester) async {
      await pumpPortadaHero(tester);
      await pumpStep(tester, const Duration(seconds: 4));

      await tapTab(tester, 2);

      expect(tabFill(tester, 2), closeTo(0, 1e-9));
      expect(tabFill(tester, 0), closeTo(0, 1e-9));
    });
  });

  group('transición entre slides', () {
    testWidgets('el contenido saliente desaparece en 350 ms', (tester) async {
      await pumpPortadaHero(tester);
      expect(contentOpacity(tester, 'zodiac'), 1);

      await tapTab(tester, 1);
      var previous = contentOpacity(tester, 'zodiac');
      expect(previous, 1);
      for (var elapsed = 50; elapsed < 350; elapsed += 50) {
        await tester.pump(const Duration(milliseconds: 50));
        final now = contentOpacity(tester, 'zodiac');
        expect(now, lessThanOrEqualTo(previous));
        previous = now;
      }
      expect(previous, inExclusiveRange(0, 1));

      await tester.pump(const Duration(milliseconds: 50));
      expect(contentOf('zodiac'), findsNothing);
    });

    testWidgets('el saliente sube un poco mientras se desvanece', (
      tester,
    ) async {
      await pumpPortadaHero(tester);
      final restingY = _titleY(tester, 'zodiac');

      await tapTab(tester, 1);
      await pumpStep(tester, const Duration(milliseconds: 250));

      final y = _titleY(tester, 'zodiac');
      expect(y, lessThan(restingY));
      expect(restingY - y, lessThan(20));
    });

    testWidgets('el entrante espera 450 ms y entra en 900 ms', (tester) async {
      await pumpPortadaHero(tester);
      await tapTab(tester, 1);

      expect(contentOpacity(tester, 'isdal'), 0);
      await pumpStep(tester, const Duration(milliseconds: 449));
      expect(contentOpacity(tester, 'isdal'), 0);

      await tester.pump(_oneMs);
      expect(contentOpacity(tester, 'isdal'), 0);
      await tester.pump(const Duration(milliseconds: 50));
      expect(contentOpacity(tester, 'isdal'), greaterThan(0));

      await pumpStep(tester, const Duration(milliseconds: 849));
      expect(contentOpacity(tester, 'isdal'), lessThan(1));
      await tester.pump(_oneMs);
      expect(contentOpacity(tester, 'isdal'), 1);
    });

    testWidgets('el entrante sube desde 28 px hasta su sitio', (tester) async {
      await pumpPortadaHero(tester);
      await tapTab(tester, 1);
      final startY = _titleY(tester, 'isdal');

      await pumpStep(tester, enterDelay + enterDuration);
      final restingY = _titleY(tester, 'isdal');

      expect(startY - restingY, closeTo(_shiftIn, 1e-6));
    });

    testWidgets('el año fantasma entra desde −60 px sin esperar', (
      tester,
    ) async {
      await pumpPortadaHero(tester);
      await tapTab(tester, 1);
      final startX = _ghostX(tester, 'isdal');

      await pumpStep(tester, const Duration(milliseconds: 100));
      expect(ghostOpacity(tester, 'isdal'), greaterThan(0));
      expect(_ghostX(tester, 'isdal'), greaterThan(startX));

      await pumpStep(tester, enterDuration);
      expect(ghostOpacity(tester, 'isdal'), 1);
      expect(_ghostX(tester, 'isdal') - startX, closeTo(_ghostShift, 1e-6));
    });

    testWidgets('el globo recibe la nueva cámara al empezar la transición', (
      tester,
    ) async {
      await pumpPortadaHero(tester);
      final before = globeScene(tester).camera;

      await tapTab(tester, 2);

      expect(globeScene(tester).camera, isNot(before));
      expect(
        globeScene(tester).camera,
        expectedCamera(portadaCases[2], before.gy),
      );
    });

    testWidgets('el saliente no recibe toques ni semántica', (tester) async {
      final handle = tester.ensureSemantics();
      final callbacks = await pumpPortadaHero(tester);
      await tapTab(tester, 1);
      await pumpStep(tester, const Duration(milliseconds: 100));

      expect(
        find.ancestor(
          of: find.byKey(PortadaHeroKeys.title('zodiac')),
          matching: find.byWidgetPredicate(
            (w) => w is IgnorePointer && w.ignoring,
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.ancestor(
          of: find.byKey(PortadaHeroKeys.title('zodiac')),
          matching: find.byWidgetPredicate(
            (w) => w is ExcludeSemantics && w.excluding,
          ),
        ),
        findsOneWidget,
      );
      expect(callbacks.opened, isEmpty);
      handle.dispose();
    });

    testWidgets('cambios rápidos no dejan capas colgadas', (tester) async {
      await pumpPortadaHero(tester);

      await tapTab(tester, 1);
      await pumpStep(tester, const Duration(milliseconds: 200));
      await tapTab(tester, 2);
      await pumpStep(tester, const Duration(milliseconds: 200));
      await tapTab(tester, 4);
      await pumpStep(tester, enterDelay + enterDuration + exitDuration);

      expect(tester.takeException(), isNull);
      expect(contentOf('zodiac'), findsNothing);
      expect(contentOf('isdal'), findsNothing);
      expect(contentOf('somerton'), findsNothing);
      expect(contentOpacity(tester, 'dyatlov'), 1);
      expect(_selected(tester), 'dyatlov');
    });

    testWidgets('volver al slide que salía lo recupera sin saltos', (
      tester,
    ) async {
      await pumpPortadaHero(tester);
      await tapTab(tester, 1);
      await pumpStep(tester, const Duration(milliseconds: 150));
      final mid = contentOpacity(tester, 'zodiac');
      expect(mid, inExclusiveRange(0, 1));

      await tapTab(tester, 0);
      expect(contentOpacity(tester, 'zodiac'), closeTo(mid, 0.2));

      await pumpStep(tester, enterDelay + enterDuration + exitDuration);

      expect(contentOpacity(tester, 'zodiac'), 1);
      expect(contentOf('isdal'), findsNothing);
      expect(_selected(tester), 'zodiac');
    });
  });

  group('estrellas', () {
    test('el parpadeo cambia la opacidad y la versión estática no', () {
      double alphaAt(Animation<double>? twinkle) {
        final canvas = TestRecordingCanvas();
        PortadaStarsPainter(
          stars: PortadaStarField.stars,
          twinkle: twinkle,
        ).paint(canvas, const Size(1440, 900));
        final circle = canvas.invocations.firstWhere(
          (i) => i.invocation.memberName == #drawCircle,
        );
        return (circle.invocation.positionalArguments[2] as Paint).color.a;
      }

      expect(
        alphaAt(const AlwaysStoppedAnimation(0)),
        isNot(alphaAt(const AlwaysStoppedAnimation(0.05))),
      );
      expect(alphaAt(null), alphaAt(null));
    });

    testWidgets('con movimiento normal el painter está animado', (
      tester,
    ) async {
      await pumpPortadaHero(tester);

      final painter = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((p) => p.painter)
          .whereType<PortadaStarsPainter>()
          .single;
      expect(painter.twinkle, isNotNull);
      expect(tester.binding.transientCallbackCount, greaterThan(0));
    });
  });

  group('movimiento reducido', () {
    testWidgets('no hay autoavance', (tester) async {
      await pumpPortadaHero(tester, reduceMotion: true);

      await pumpStep(tester, const Duration(seconds: 30));

      expect(_selected(tester), 'zodiac');
      expect(find.text('1 / 5'), findsOneWidget);
    });

    testWidgets('no queda ningún ticker del héroe en marcha', (tester) async {
      await pumpPortadaHero(tester, reduceMotion: true);
      await tester.pump();

      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('las estrellas son estáticas', (tester) async {
      await pumpPortadaHero(tester, reduceMotion: true);

      final painter = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((p) => p.painter)
          .whereType<PortadaStarsPainter>()
          .single;
      expect(painter.twinkle, isNull);
    });

    testWidgets('el contenido cambia al instante con una pestaña', (
      tester,
    ) async {
      await pumpPortadaHero(tester, reduceMotion: true);

      await tapTab(tester, 2);

      expect(contentOf('zodiac'), findsNothing);
      expect(contentOpacity(tester, 'somerton'), 1);
      expect(ghostOpacity(tester, 'somerton'), 1);
      // El contenido va anclado abajo y cada título tiene su altura: lo que
      // importa es que no haya desplazamiento animado tras el cambio.
      final landedY = _titleY(tester, 'somerton');
      await tester.pump(const Duration(seconds: 1));
      expect(_titleY(tester, 'somerton'), landedY);
      expect(_selected(tester), 'somerton');
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('la pestaña activa se marca con la barra llena', (
      tester,
    ) async {
      await pumpPortadaHero(tester, reduceMotion: true);

      // Con el hueco de 14 px el ancho de pestaña ya no es entero: se compara con tolerancia.
      expect(tabFill(tester, 0), closeTo(1, 1e-9));
      expect(tabFill(tester, 1), 0);

      await tapTab(tester, 1);

      expect(tabFill(tester, 0), 0);
      expect(tabFill(tester, 1), closeTo(1, 1e-9));
    });

    testWidgets('pulsar una pestaña no deja timers pendientes', (tester) async {
      await pumpPortadaHero(tester, reduceMotion: true);

      await tapTab(tester, 3);
      await disposePortadaHero(tester);

      expect(tester.takeException(), isNull);
    });
  });
}
