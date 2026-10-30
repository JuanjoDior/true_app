import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';
import 'package:true_app/features/cases/presentation/design/case_design_mapping.dart';
import 'package:true_app/features/home/presentation/portada/portada_closing_keys.dart';

import 'test_support/portada_test_support.dart';

const String _body =
    'Cada caso tiene su lugar. Acércate, sigue las conexiones entre casos y '
    'recorre décadas con la línea de tiempo.';

DsMapScene _scene(WidgetTester tester) =>
    tester.widget<DsMapScene>(find.byType(DsMapScene));

void main() {
  group('copy', () {
    testWidgets('kicker, título, texto y botón del prototipo', (tester) async {
      await pumpPortadaMapInvite(tester);

      expect(find.text('EL MAPA'), findsOneWidget);
      expect(find.text('El archivo, punto por punto'), findsOneWidget);
      expect(find.text(_body), findsOneWidget);
      expect(find.text('Abrir el mapa'), findsOneWidget);
    });

    testWidgets('el título es un encabezado semántico', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpPortadaMapInvite(tester);

      expect(
        tester.getSemantics(find.text('El archivo, punto por punto')),
        matchesSemantics(label: 'El archivo, punto por punto', isHeader: true),
      );
      handle.dispose();
    });
  });

  group('acción', () {
    testWidgets('solo el botón abre el mapa', (tester) async {
      final callbacks = await pumpPortadaMapInvite(tester);

      await tester.tap(find.text('Abrir el mapa'));
      expect(callbacks.openMapTaps, 1);
    });

    testWidgets('sin onOpenMap no hay botón, pero sí mapa y textos', (
      tester,
    ) async {
      await pumpPortadaMapInvite(tester, openable: false);

      expect(find.text('Abrir el mapa'), findsNothing);
      expect(find.byType(DsButton), findsNothing);
      expect(find.byType(DsMapScene), findsOneWidget);
      expect(find.text('EL MAPA'), findsOneWidget);
      expect(find.text('El archivo, punto por punto'), findsOneWidget);
    });

    testWidgets('tocar el mapa decorativo no hace nada', (tester) async {
      final callbacks = await pumpPortadaMapInvite(tester);

      final scene = find.byType(DsMapScene);
      await tester.tapAt(tester.getCenter(scene));
      await tester.tapAt(tester.getTopRight(scene));

      expect(callbacks.openMapTaps, 0);
      expect(_scene(tester).onMarkerTap, isNull);
    });
  });

  group('mapa decorativo', () {
    testWidgets('recibe los marcadores del adaptador, en el mismo orden', (
      tester,
    ) async {
      await pumpPortadaMapInvite(tester);

      expect(_scene(tester).markers, [
        for (final c in portadaAllCases) c.toMapMarker(),
      ]);
      expect(_scene(tester).camera, const DsMapCamera.world());
    });

    testWidgets('ignora el puntero y queda fuera de la semántica', (
      tester,
    ) async {
      await pumpPortadaMapInvite(tester);

      final layer = find.byKey(PortadaClosingKeys.mapLayer);
      expect(tester.widget<IgnorePointer>(layer).ignoring, isTrue);
      expect(
        find.descendant(
          of: find.ancestor(of: layer, matching: find.byType(ExcludeSemantics)),
          matching: find.byType(DsMapScene),
        ),
        findsOneWidget,
      );
    });

    testWidgets('sin casos sigue pintando el mapa, sin marcadores', (
      tester,
    ) async {
      await pumpPortadaMapInvite(tester, cases: const []);

      expect(_scene(tester).markers, isEmpty);
      expect(find.text('Abrir el mapa'), findsOneWidget);
    });

    testWidgets('con movimiento reducido no deja animaciones en curso', (
      tester,
    ) async {
      await pumpPortadaMapInvite(tester, reduceMotion: true);

      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('con casos nuevos se actualizan los marcadores', (
      tester,
    ) async {
      await pumpPortadaMapInvite(tester, cases: portadaCases);
      await pumpPortadaMapInvite(tester, cases: portadaAllCases);

      expect(_scene(tester).markers.length, portadaAllCases.length);
    });
  });

  group('medidas', () {
    testWidgets('escritorio: 540 de alto y texto a 80 px del borde', (
      tester,
    ) async {
      await pumpPortadaMapInvite(tester);

      expect(
        tester.getSize(find.byKey(PortadaClosingKeys.mapInvite)).height,
        540,
      );
      expect(tester.getTopLeft(find.text('EL MAPA')).dx, 80);
      expect(_scene(tester).mobile, isFalse);
    });

    testWidgets('móvil: tarjeta de 250 de alto con margen de 16', (
      tester,
    ) async {
      await pumpPortadaMapInvite(tester, size: phoneSize);

      final card = find.byKey(PortadaClosingKeys.mapInviteCard);
      expect(tester.getSize(card).height, 250);
      expect(tester.getTopLeft(card).dx, 16);
      expect(tester.getSize(card).width, phoneSize.width - 32);
      expect(_scene(tester).mobile, isTrue);
    });

    testWidgets(
      'con texto muy grande el botón sigue dentro y se puede pulsar',
      (tester) async {
        final callbacks = await pumpPortadaMapInvite(tester, textScale: 2);

        final section = tester.getRect(
          find.byKey(PortadaClosingKeys.mapInvite),
        );
        final button = tester.getRect(find.text('Abrir el mapa'));
        expect(section.contains(button.bottomRight), isTrue);
        await tester.tap(find.text('Abrir el mapa'));
        expect(callbacks.openMapTaps, 1);
      },
    );

    testWidgets('móvil: título y botón caben en la tarjeta', (tester) async {
      await pumpPortadaMapInvite(tester, size: phoneSize);

      final card = tester.getRect(find.byKey(PortadaClosingKeys.mapInviteCard));
      final title = tester.getRect(find.text('El archivo, punto por punto'));
      final button = tester.getRect(find.text('Abrir el mapa'));
      expect(card.contains(title.topLeft), isTrue);
      expect(card.contains(button.bottomRight), isTrue);
      expect(tester.takeException(), isNull);
    });
  });
}
