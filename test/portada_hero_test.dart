import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';
import 'package:true_app/features/cases/domain/case_category.dart';
import 'package:true_app/features/cases/presentation/case_category_presentation.dart';
import 'package:true_app/features/cases/presentation/design/case_design_mapping.dart';
import 'package:true_app/features/home/presentation/portada/portada_hero_background.dart';
import 'package:true_app/features/home/presentation/portada/portada_hero_keys.dart';
import 'package:true_app/features/home/presentation/portada/portada_hero_layout.dart';

import 'test_support/portada_test_support.dart';

const _settle = Duration(milliseconds: 1400);
const _sizes = [laptopSize, desktopSize, fullHdSize];

void main() {
  group('contenido del slide', () {
    testWidgets('muestra kicker, contador, título, lugar, estado y resumen', (
      tester,
    ) async {
      await pumpPortadaHero(tester);

      expect(find.text('EN EL FOCO'), findsOneWidget);
      expect(find.text('1 / 5'), findsOneWidget);
      expect(find.byKey(PortadaHeroKeys.title('zodiac')), findsOneWidget);
      expect(
        find.text(CaseCategory.serialKiller.presentation.label),
        findsOneWidget,
      );
      expect(find.text('San Francisco, United States · 1968'), findsOneWidget);
      expect(find.byType(DsStatusLabel), findsOneWidget);
      expect(find.text('Sin resolver'), findsOneWidget);
      expect(find.text('Resumen breve del caso.'), findsOneWidget);
      expect(find.text('37.77° N · 122.42° O'), findsOneWidget);
    });

    testWidgets('initialIndex abre en ese slide', (tester) async {
      await pumpPortadaHero(tester, initialIndex: 2);

      expect(find.text('3 / 5'), findsOneWidget);
      expect(find.byKey(PortadaHeroKeys.title('somerton')), findsOneWidget);
      expect(find.byKey(PortadaHeroKeys.title('zodiac')), findsNothing);
    });

    testWidgets('el estado prefiere el statusLabel editorial', (tester) async {
      await pumpPortadaHero(tester, initialIndex: 3);

      expect(find.text('Reabierto (2020)'), findsOneWidget);
      expect(find.text('En investigación'), findsNothing);
    });

    testWidgets('colores: kicker, insignia y estado usan los del diseño', (
      tester,
    ) async {
      await pumpPortadaHero(tester);

      final kicker = tester.widget<Text>(find.text('EN EL FOCO'));
      expect(kicker.style!.color, DsCategoryColors.serialKiller.dot);
      final badge = tester.widget<DsBadge>(find.byType(DsBadge));
      expect(badge.color, DsCategoryColors.serialKiller.dot);
      final status = tester.widget<DsStatusLabel>(find.byType(DsStatusLabel));
      expect(status.color, DsStatusColors.open);
    });

    testWidgets('título serif de 88 px con interlineado 0,96', (tester) async {
      await pumpPortadaHero(tester);

      final title = tester.widget<Text>(
        find.byKey(PortadaHeroKeys.title('zodiac')),
      );
      expect(title.style!.fontFamily, DsFontFamilies.display);
      expect(title.style!.fontSize, 88);
      expect(title.style!.height, 0.96);
      expect(
        tester.getTopLeft(find.byKey(PortadaHeroKeys.title('zodiac'))).dx,
        80,
      );
    });

    testWidgets(
      'resumen 18/1,6, máx. 540 px y 4 líneas con puntos suspensivos',
      (tester) async {
        final long = portadaCase(
          id: 'long',
          title: 'Caso con resumen largo',
          summary: List.filled(60, 'palabra').join(' '),
        );
        await pumpPortadaHero(tester, featured: [long]);

        final finder = find.byKey(PortadaHeroKeys.summary('long'));
        final summary = tester.widget<Text>(finder);
        expect(summary.style!.fontSize, 18);
        expect(summary.style!.height, 1.6);
        expect(summary.maxLines, 4);
        expect(summary.overflow, TextOverflow.ellipsis);
        expect(tester.getSize(finder).width, lessThanOrEqualTo(540));
        // El motor redondea cada línea (28,8 → 29 px): se comprueba que no
        // aparezca una quinta línea, no la altura exacta.
        expect(tester.getSize(finder).height, lessThan(5 * 18 * 1.6));
      },
    );

    testWidgets('el año fantasma de 460 px queda fuera de la semántica', (
      tester,
    ) async {
      await pumpPortadaHero(tester);

      final ghost = find.descendant(
        of: find.byKey(PortadaHeroKeys.ghostYear('zodiac')),
        matching: find.text('1968'),
      );
      expect(ghost, findsOneWidget);
      final style = tester.widget<Text>(ghost).style!;
      expect(style.fontSize, 460);
      expect(style.fontFamily, DsFontFamilies.display);
      expect(style.color!.a, lessThan(0.06));
      expect(
        find.ancestor(of: ghost, matching: find.byType(ExcludeSemantics)),
        findsWidgets,
      );
    });

    testWidgets('las coordenadas quedan abajo a la derecha a 80 px', (
      tester,
    ) async {
      await pumpPortadaHero(tester);

      final rect = tester.getRect(find.byKey(PortadaHeroKeys.coords('zodiac')));
      expect(rect.right, desktopSize.width - 80);
      expect(rect.bottom, lessThan(desktopSize.height));
      expect(rect.bottom, greaterThan(desktopSize.height - 100));
    });
  });

  group('botones', () {
    testWidgets('«Abrir expediente» entrega el caso activo', (tester) async {
      final callbacks = await pumpPortadaHero(tester);

      await tester.tap(find.text('Abrir expediente'));

      expect(callbacks.opened.map((c) => c.id), ['zodiac']);
      expect(callbacks.explored, isEmpty);
    });

    testWidgets('«Explorar el globo» entrega el caso activo', (tester) async {
      final callbacks = await pumpPortadaHero(tester);

      await tester.tap(find.text('Explorar el globo'));

      expect(callbacks.explored.map((c) => c.id), ['zodiac']);
      expect(callbacks.opened, isEmpty);
    });

    testWidgets('son un primario y uno de cristal', (tester) async {
      await pumpPortadaHero(tester);

      final buttons = tester
          .widgetList<DsButton>(find.byType(DsButton))
          .toList();
      expect(buttons.map((b) => (b.label, b.variant)), [
        ('Abrir expediente', DsButtonVariant.primary),
        ('Explorar el globo', DsButtonVariant.glass),
      ]);
    });

    testWidgets('sin onExploreCase solo queda «Abrir expediente»', (
      tester,
    ) async {
      await pumpPortadaHero(tester, explorable: false);

      expect(find.text('Explorar el globo'), findsNothing);
      expect(
        tester.widgetList<DsButton>(find.byType(DsButton)).map((b) => b.label),
        ['Abrir expediente'],
      );
    });

    testWidgets('tras cambiar de slide los botones entregan el nuevo caso', (
      tester,
    ) async {
      final callbacks = await pumpPortadaHero(tester);

      await tapTab(tester, 3);
      await pumpStep(tester, _settle);
      await tester.tap(find.text('Abrir expediente'));
      await tester.tap(find.text('Explorar el globo'));

      expect(callbacks.opened.map((c) => c.id), ['madeleine']);
      expect(callbacks.explored.map((c) => c.id), ['madeleine']);
    });
  });

  group('pestañas', () {
    testWidgets('hay una por destacado, a 80 px y en 680 px de ancho', (
      tester,
    ) async {
      await pumpPortadaHero(tester);

      for (var i = 0; i < portadaCases.length; i++) {
        expect(find.byKey(PortadaHeroKeys.tab(i)), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(PortadaHeroKeys.tab(i)),
            matching: find.text(portadaCases[i].title),
          ),
          findsOneWidget,
        );
      }
      expect(tester.getTopLeft(find.byKey(PortadaHeroKeys.tab(0))).dx, 80);
      expect(tester.getBottomRight(find.byKey(PortadaHeroKeys.tab(4))).dx, 760);
    });

    testWidgets('cada pestaña mide al menos 44 px de alto', (tester) async {
      await pumpPortadaHero(tester);

      for (var i = 0; i < portadaCases.length; i++) {
        expect(
          tester.getSize(find.byKey(PortadaHeroKeys.tab(i))).height,
          greaterThanOrEqualTo(44),
        );
      }
    });

    testWidgets('nombre 13/600, una línea y con elipsis', (tester) async {
      await pumpPortadaHero(tester);

      final name = tester.widget<Text>(find.byKey(PortadaHeroKeys.tabName(3)));
      expect(name.style!.fontSize, 13);
      expect(name.style!.fontWeight, FontWeight.w600);
      expect(name.maxLines, 1);
      expect(name.overflow, TextOverflow.ellipsis);
    });

    testWidgets('semántica: botón con el nombre y seleccionada la activa', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpPortadaHero(tester);

      final first = tester.getSemantics(find.byKey(PortadaHeroKeys.tab(0)));
      final second = tester.getSemantics(find.byKey(PortadaHeroKeys.tab(1)));
      expect(first.label, 'Zodiac Killer');
      expect(first.flagsCollection.isButton, isTrue);
      expect(first.flagsCollection.isSelected, Tristate.isTrue);
      expect(second.label, 'La mujer de Isdal');
      expect(second.flagsCollection.isButton, isTrue);
      expect(second.flagsCollection.isSelected, Tristate.isFalse);

      await tapTab(tester, 1);
      expect(
        tester
            .getSemantics(find.byKey(PortadaHeroKeys.tab(1)))
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
      handle.dispose();
    });

    testWidgets('pulsar una pestaña cambia el slide', (tester) async {
      await pumpPortadaHero(tester);

      await tapTab(tester, 2);
      await pumpStep(tester, _settle);

      expect(find.text('3 / 5'), findsOneWidget);
      expect(find.byKey(PortadaHeroKeys.title('somerton')), findsOneWidget);
      expect(find.byKey(PortadaHeroKeys.title('zodiac')), findsNothing);
    });

    testWidgets('Enter sobre una pestaña con foco la activa', (tester) async {
      await pumpPortadaHero(tester);

      final focus = find
          .descendant(
            of: find.byKey(PortadaHeroKeys.tab(1)),
            matching: find.byType(Focus),
          )
          .first;
      Focus.of(tester.element(focus)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(find.text('2 / 5'), findsOneWidget);
    });
  });

  group('globo', () {
    testWidgets('recibe todos los casos como marcadores y el activo', (
      tester,
    ) async {
      await pumpPortadaHero(tester);

      final scene = globeScene(tester);
      expect(scene.markers.map((m) => m.id), portadaAllCases.map((c) => c.id));
      expect(scene.selectedId, 'zodiac');
      expect(scene.onMarkerTap, isNull);
      expect(scene.showLabels, isFalse);
      expect(scene.connections, isEmpty);
    });

    testWidgets('cámara de portada del caso activo y halo de su categoría', (
      tester,
    ) async {
      await pumpPortadaHero(tester);

      final scene = globeScene(tester);
      expect(scene.camera, expectedCamera(portadaCases[0], 0));
      expect(scene.camera.center, const Offset(1010, 520));
      expect(scene.camera.scale, 1);
      expect(scene.haloColor, CaseCategory.serialKiller.designColor.dot);
    });

    testWidgets('al cambiar de slide gira al nuevo caso y cambia el halo', (
      tester,
    ) async {
      await pumpPortadaHero(tester);
      final before = globeScene(tester).camera;

      await tapTab(tester, 1);

      final scene = globeScene(tester);
      expect(scene.selectedId, 'isdal');
      expect(scene.camera, expectedCamera(portadaCases[1], before.gy));
      expect(scene.haloColor, CaseCategory.unsolved.designColor.dot);
    });

    testWidgets('conserva gy para girar por el camino corto', (tester) async {
      await pumpPortadaHero(tester, featured: antimeridianCases);
      expect(globeScene(tester).camera.gy, -170);

      await tapTab(tester, 1);

      // Sin el gy previo saldría +170 (340° de giro) en vez de −190 (20°)
      expect(globeScene(tester).camera.gy, -190);
    });

    testWidgets('initialIndex orienta el globo a ese caso', (tester) async {
      await pumpPortadaHero(tester, initialIndex: 2);

      final scene = globeScene(tester);
      expect(scene.selectedId, 'somerton');
      expect(scene.camera, expectedCamera(portadaCases[2], 0));
    });

    for (final size in _sizes) {
      testWidgets('la esfera cabe entera en el héroe de ${size.width.toInt()}', (
        tester,
      ) async {
        await pumpPortadaHero(tester, size: size);

        final globe = globeCircle(tester);
        final expected = PortadaLayout.globePlacement(size);
        expect(globe.center.dx, closeTo(expected.center.dx, 1e-6));
        expect(globe.center.dy, closeTo(expected.center.dy, 1e-6));
        expect(globe.radius, closeTo(expected.radius, 1e-6));
        // La cámara de portada no cambia: solo se traslada y escala la escena.
        expect(globeScene(tester).camera.center, const Offset(1010, 520));
        expect(globeScene(tester).camera.scale, 1);
      });
    }
  });

  group('fondo', () {
    testWidgets('degradado radial #0B1220 → #05070B', (tester) async {
      await pumpPortadaHero(tester);

      final gradient = _backgroundGradient(tester);
      expect(gradient, isA<RadialGradient>());
      expect(gradient.colors.first, const Color(0xFF0B1220));
      expect(gradient.colors.last, DsColors.bgBase);
    });

    testWidgets('velo lateral de 980 px de rgba(5,7,11,.95) a transparente', (
      tester,
    ) async {
      await pumpPortadaHero(tester);

      expect(tester.getSize(find.byKey(PortadaHeroKeys.veil)).width, 980);
      expect(tester.getTopLeft(find.byKey(PortadaHeroKeys.veil)).dx, 0);
      final decoration =
          tester
                  .widget<DecoratedBox>(find.byKey(PortadaHeroKeys.veil))
                  .decoration
              as BoxDecoration;
      final gradient = decoration.gradient! as LinearGradient;
      expect(gradient.colors.first, DsColors.bgBase.withValues(alpha: 0.95));
      expect(gradient.colors.last.a, 0);
    });

    test('70 estrellas deterministas de 1 y 2 px dentro del lienzo', () {
      final stars = PortadaStarField.stars;

      expect(stars, hasLength(70));
      expect(PortadaStarField.stars, same(stars));
      for (final star in stars) {
        expect(star.diameter, anyOf(1, 2));
        expect(star.x, inInclusiveRange(0, 1));
        expect(star.y, inInclusiveRange(0, 1));
      }
      expect(stars.map((s) => (s.x, s.y)).toSet(), hasLength(70));
    });

    testWidgets('un solo painter dibuja las 70 estrellas', (tester) async {
      await pumpPortadaHero(tester);

      final painters = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .where((p) => p.painter is PortadaStarsPainter);
      expect(painters, hasLength(1));
      final canvas = TestRecordingCanvas();
      painters.single.painter!.paint(canvas, desktopSize);
      expect(
        canvas.invocations.where((i) => i.invocation.memberName == #drawCircle),
        hasLength(70),
      );
    });
  });

  group('lista vacía', () {
    testWidgets('solo pinta el fondo, sin globo ni pestañas', (tester) async {
      await pumpPortadaHero(tester, featured: const []);

      expect(tester.takeException(), isNull);
      expect(find.byKey(PortadaHeroKeys.stars), findsOneWidget);
      expect(find.byType(DsGlobeScene), findsNothing);
      expect(find.byType(DsButton), findsNothing);
      expect(find.text('EN EL FOCO'), findsNothing);
      expect(find.byKey(PortadaHeroKeys.tab(0)), findsNothing);
    });

    testWidgets('no avanza ni deja tickers del carrusel', (tester) async {
      await pumpPortadaHero(tester, featured: const []);

      await tester.pump(const Duration(seconds: 30));

      expect(tester.takeException(), isNull);
    });
  });

  group('héroe móvil legible', () {
    testWidgets(
      'a 360 px el texto no se reduce y los controles se pueden pulsar',
      (tester) async {
        final callbacks = await pumpPortadaHero(
          tester,
          size: const Size(360, 640),
          reduceMotion: true,
        );
        final summary = find.byKey(PortadaHeroKeys.summary('zodiac'));
        final data = find.text('0 casos conectados');
        final action = find.text('Abrir expediente');
        for (final finder in [summary, data, action]) {
          final box = tester.renderObject<RenderBox>(finder);
          expect(
            (box.localToGlobal(const Offset(100, 0)) -
                        box.localToGlobal(Offset.zero))
                    .distance /
                100,
            closeTo(1, 0.001),
          );
          expect(
            tester.widget<Text>(finder).style!.fontSize,
            greaterThanOrEqualTo(12),
          );
        }
        final button = find.ancestor(
          of: action,
          matching: find.byType(DsButton),
        );
        expect(tester.getSize(button).height, greaterThanOrEqualTo(44));
        for (var i = 0; i < portadaCases.length; i++) {
          expect(
            tester.getSize(find.byKey(PortadaHeroKeys.tab(i))).height,
            greaterThanOrEqualTo(44),
          );
        }
        await tester.tap(action);
        expect(callbacks.opened.map((c) => c.id), ['zodiac']);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('contenido largo no desborda a 360 px', (tester) async {
      final long = portadaCase(
        id: 'mobile-long',
        title: 'Un título largo para un caso documentado',
        city: 'Una localidad con un nombre extraordinariamente largo',
        statusLabel: 'Un estado editorial bastante largo',
        summary: List.filled(80, 'palabra').join(' '),
      );
      await pumpPortadaHero(
        tester,
        size: const Size(360, 640),
        featured: [long],
        reduceMotion: true,
      );
      expect(tester.takeException(), isNull);
      final summary = find.byKey(PortadaHeroKeys.summary('mobile-long'));
      expect(
        (tester.getBottomRight(summary).dx - tester.getTopLeft(summary).dx) /
            tester.getSize(summary).width,
        closeTo(1, 0.001),
      );
    });
  });

  group('sin desbordes', () {
    final longTitle = portadaCase(
      id: 'long',
      title:
          'Un título larguísimo que ocupa muchas líneas del héroe '
          'para comprobar que nada desborda en ningún tamaño',
      city: 'Una localidad con un nombre extraordinariamente largo',
      country: 'País de nombre también muy largo',
      statusLabel: 'Un estado editorial bastante largo (2024)',
      summary: List.filled(120, 'texto').join(' '),
    );

    for (final size in _sizes) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('${size.width.toInt()}x${size.height.toInt()} '
            'con texto x$scale', (tester) async {
          await pumpPortadaHero(
            tester,
            size: size,
            textScale: scale,
            featured: [longTitle, ...portadaCases],
          );
          await pumpStep(tester, const Duration(milliseconds: 200));

          expect(tester.takeException(), isNull);
          final hero = Offset.zero & size;
          final content = tester.getRect(contentOf('long'));
          expect(hero.contains(content.topLeft), isTrue);
          expect(content.bottom, lessThanOrEqualTo(size.height));
          for (var i = 0; i < 6; i++) {
            expect(
              tester.getRect(find.byKey(PortadaHeroKeys.tab(i))).bottom,
              lessThanOrEqualTo(size.height),
            );
          }
        });
      }
    }
  });

  group('ciclo de vida', () {
    testWidgets('al retirar el héroe no quedan timers ni tickers', (
      tester,
    ) async {
      await pumpPortadaHero(tester);
      await tapTab(tester, 1);

      await disposePortadaHero(tester);

      expect(tester.takeException(), isNull);
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('cambiar la lista de destacados actualiza pestañas y globo', (
      tester,
    ) async {
      final callbacks = await pumpPortadaHero(tester);
      await tester.pumpWidget(
        buildPortadaHero(
          callbacks: callbacks,
          featured: portadaCases.take(2).toList(),
        ),
      );

      expect(find.byKey(PortadaHeroKeys.tab(1)), findsOneWidget);
      expect(find.byKey(PortadaHeroKeys.tab(2)), findsNothing);
      expect(find.text('1 / 2'), findsOneWidget);

      await disposePortadaHero(tester);
    });
  });
}

Gradient _backgroundGradient(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byKey(PortadaHeroKeys.background),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
  return (box.decoration as BoxDecoration).gradient!;
}
