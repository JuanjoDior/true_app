import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';
import 'package:true_app/features/cases/domain/case_category.dart';
import 'package:true_app/features/cases/presentation/design/case_design_mapping.dart';
import 'package:true_app/features/home/presentation/portada/portada_unsolved_keys.dart';

import 'test_support/portada_test_support.dart';

final _zodiac = unsolvedPortadaCases.first;
final _face = find.byKey(PortadaUnsolvedKeys.poster('zodiac'));

double _opacityOf(WidgetTester tester, Key layer) =>
    tester.widget<AnimatedOpacity>(find.byKey(layer)).opacity;

void main() {
  group('medidas', () {
    testWidgets('en escritorio mide 400 × 225', (tester) async {
      await pumpPortadaPoster(tester, _zodiac);

      expect(tester.getSize(_face), const Size(400, 225));
    });

    testWidgets('en móvil mide 290 × 168', (tester) async {
      await pumpPortadaPoster(tester, _zodiac, size: phoneSize);

      expect(tester.getSize(_face), const Size(290, 168));
    });

    testWidgets('la zona pulsable alcanza 44 px', (tester) async {
      await pumpPortadaPoster(tester, _zodiac, size: phoneSize);

      final size = tester.getSize(find.byType(DsPressable));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    });
  });

  group('contenido', () {
    testWidgets('categoría visible en reposo', (tester) async {
      await pumpPortadaPoster(tester, _zodiac);
      expect(find.text('ASESINOS EN SERIE'), findsOneWidget);
    });

    testWidgets('estado editorial y respaldo visibles en reposo', (
      tester,
    ) async {
      await pumpPortadaPoster(tester, unsolvedPortadaCases.last);
      expect(find.text('Sin condena'), findsOneWidget);
      await pumpPortadaPoster(tester, _zodiac);
      expect(find.text('Sin resolver'), findsOneWidget);
    });

    testWidgets('muestra título, lugar y año en la capa base', (tester) async {
      await pumpPortadaPoster(tester, _zodiac);

      final base = find.byKey(PortadaUnsolvedKeys.posterBase('zodiac'));
      expect(
        find.descendant(of: base, matching: find.text('Zodiac Killer')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: base, matching: find.text('San Francisco · 1968')),
        findsOneWidget,
      );
    });

    testWidgets('la capa «más» lleva título y resumen', (tester) async {
      await pumpPortadaPoster(tester, _zodiac);

      final more = find.byKey(PortadaUnsolvedKeys.posterMore('zodiac'));
      expect(
        find.descendant(of: more, matching: find.text('Zodiac Killer')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: more, matching: find.text(_zodiac.summary)),
        findsOneWidget,
      );
    });

    testWidgets('sin foto, el fondo es el color base de la categoría', (
      tester,
    ) async {
      for (final category in CaseCategory.values) {
        final crimeCase = portadaCase(
          id: 'zodiac',
          title: 'Zodiac Killer',
          category: category,
        );
        await pumpPortadaPoster(tester, crimeCase);

        final backdrop = tester.widget<DecoratedBox>(
          find.byKey(PortadaUnsolvedKeys.posterBackdrop('zodiac')),
        );
        final decoration = backdrop.decoration as BoxDecoration;
        expect(
          (decoration.gradient! as LinearGradient).colors.first,
          category.designColor.posterBase,
          reason: '$category',
        );
        expect(find.byType(Image), findsNothing);
      }
    });

    testWidgets('sin foto muestra el año fantasma', (tester) async {
      await pumpPortadaPoster(tester, _zodiac);

      expect(
        find.byKey(PortadaUnsolvedKeys.posterGhostYear('zodiac')),
        findsOneWidget,
      );
    });
  });

  group('foto', () {
    testWidgets('usa photos.first y no la segunda', (tester) async {
      final crimeCase = unsolvedCaseWithPhoto(
        'https://example.com/primera.jpg',
      );
      await pumpPortadaPoster(tester, crimeCase);

      expect(find.byType(Image), findsOneWidget);
      final image = tester.widget<Image>(find.byType(Image));
      expect(
        (image.image as NetworkImage).url,
        'https://example.com/primera.jpg',
      );
      expect(image.fit, BoxFit.cover);
    });

    testWidgets('con foto cargando no muestra el año fantasma', (tester) async {
      final crimeCase = unsolvedCaseWithPhoto(
        'https://example.com/primera.jpg',
      );
      await pumpPortadaPoster(tester, crimeCase);

      expect(
        find.byKey(PortadaUnsolvedKeys.posterGhostYear('foto')),
        findsNothing,
      );
      expect(
        find.byKey(PortadaUnsolvedKeys.posterPhoto('foto')),
        findsOneWidget,
      );
    });

    testWidgets('si la imagen falla vuelve al color de categoría', (
      tester,
    ) async {
      final crimeCase = unsolvedCaseWithPhoto('https://example.com/rota.jpg');
      await pumpPortadaPoster(tester, crimeCase);
      // En test toda petición de red falla: este es el camino del errorBuilder.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(PortadaUnsolvedKeys.posterBackdrop('foto')),
        findsOneWidget,
      );
      expect(
        find.byKey(PortadaUnsolvedKeys.posterGhostYear('foto')),
        findsOneWidget,
      );
    });
  });

  group('semántica y teclado', () {
    testWidgets('expone una sola etiqueta por póster', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpPortadaPoster(tester, _zodiac);

      final labelled = find.bySemanticsLabel(RegExp('Zodiac Killer'));
      expect(labelled, findsOneWidget);
      expect(
        tester.getSemantics(labelled).label,
        'Zodiac Killer. San Francisco, 1968. Sin resolver',
      );
      handle.dispose();
    });

    testWidgets('la etiqueta usa el estado libre del caso', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpPortadaPoster(tester, unsolvedPortadaCases.last);

      expect(
        find.bySemanticsLabel('JonBenét Ramsey. Boulder, 1996. Sin condena'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('un toque abre el caso', (tester) async {
      final callbacks = await pumpPortadaPoster(tester, _zodiac);

      await tester.tap(_face);

      expect(callbacks.opened, [_zodiac]);
    });

    testWidgets('Enter con foco abre el caso y se ve el aro', (tester) async {
      final callbacks = await pumpPortadaPoster(tester, _zodiac);

      Focus.of(tester.element(_face)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(callbacks.opened, [_zodiac]);
      expect(find.byKey(DsPressable.focusRingKey), findsOneWidget);
    });
  });

  group('interacción', () {
    testWidgets('al pulsar escala a 0,97', (tester) async {
      await pumpPortadaPoster(tester, _zodiac);

      final gesture = await tester.startGesture(tester.getCenter(_face));
      await tester.pump(DsMotion.press);

      final scale = tester.widget<AnimatedScale>(
        find.ancestor(of: _face, matching: find.byType(AnimatedScale)).first,
      );
      expect(scale.scale, DsPressable.pressScale);
      await gesture.up();
    });

    testWidgets('con ratón sube 12 px, escala 1,06 y cambia de capa', (
      tester,
    ) async {
      await pumpPortadaPoster(tester, _zodiac);
      final restTop = tester.getTopLeft(_face).dy;
      final restHeight = tester.getSize(_face).height;

      await hoverOver(tester, _face);
      await tester.pump(const Duration(milliseconds: 500));

      final scaledGrowth = restHeight * 0.06 / 2;
      expect(
        restTop - tester.getTopLeft(_face).dy,
        closeTo(12 + scaledGrowth, 0.5),
      );
      final scaledHeight =
          tester.getBottomRight(_face).dy - tester.getTopLeft(_face).dy;
      expect(scaledHeight, closeTo(restHeight * 1.06, 0.5));
      expect(_opacityOf(tester, PortadaUnsolvedKeys.posterMore('zodiac')), 1);
      expect(_opacityOf(tester, PortadaUnsolvedKeys.posterBase('zodiac')), 0);
    });

    testWidgets('con movimiento reducido no se desplaza, solo cambia de capa', (
      tester,
    ) async {
      await pumpPortadaPoster(tester, _zodiac, reduceMotion: true);
      final restTop = tester.getTopLeft(_face).dy;

      await hoverOver(tester, _face);
      await tester.pump();

      expect(tester.getTopLeft(_face).dy, restTop);
      expect(_opacityOf(tester, PortadaUnsolvedKeys.posterMore('zodiac')), 1);
    });

    testWidgets('atenuado baja a opacidad 0,45', (tester) async {
      await pumpPortadaPoster(tester, _zodiac, dimmed: true);
      await tester.pump(const Duration(milliseconds: 500));

      final opacity = tester.widget<AnimatedOpacity>(
        find.ancestor(of: _face, matching: find.byType(AnimatedOpacity)).first,
      );
      expect(opacity.opacity, 0.45);
    });

    for (final size in [desktopSize, phoneSize]) {
      testWidgets('con texto al doble no desborda a ${size.width.toInt()}', (
        tester,
      ) async {
        await pumpPortadaPoster(
          tester,
          portadaCase(
            id: 'zodiac',
            title: 'Envenenamientos de Tylenol en Chicago y alrededores',
            summary: 'Un resumen largo ' * 30,
          ),
          size: size,
          textScale: 2,
        );
        await hoverOver(tester, _face);
        await tester.pump(const Duration(milliseconds: 500));

        expect(tester.takeException(), isNull);
      });
    }
  });
}
