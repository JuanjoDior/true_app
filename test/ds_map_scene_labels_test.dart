import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';

import 'test_support/ds_map_scene_test_support.dart';

void main() {
  group('labels', () {
    testWidgets('only related markers show their name', (tester) async {
      await pumpScene(tester, selectedId: 'alpha', relatedIds: const {'bravo'});
      final specs = painterOf<DsMapLabelLayerPainter>(tester).specs();
      expect(specs.map((s) => s.text), ['Bravo']);
      expect(specs.single.kind, DsMapLabelKind.marker);
    });

    testWidgets('without related markers there are no labels at all', (
      tester,
    ) async {
      await pumpScene(tester, selectedId: 'alpha');
      expect(painterOf<DsMapLabelLayerPainter>(tester).specs(), isEmpty);
      expect(calls(paintLabels(tester), #drawParagraph), isEmpty);
    });

    testWidgets('a related marker hidden by the year has no label', (
      tester,
    ) async {
      await pumpScene(
        tester,
        selectedId: 'alpha',
        relatedIds: const {'charlie'},
        timelineYear: 1990,
      );
      expect(painterOf<DsMapLabelLayerPainter>(tester).specs(), isEmpty);
    });

    testWidgets('the name sits on the right of the marker in a glass pill', (
      tester,
    ) async {
      await pumpScene(
        tester,
        camera: zoomed,
        selectedId: 'alpha',
        relatedIds: const {'bravo'},
      );
      final bravo = zoomed.apply(bravoScene);
      final spec = painterOf<DsMapLabelLayerPainter>(tester).specs().single;
      expect(
        spec.anchor,
        Offset(
          bravo.dx + alphaRadius + DsMapLabelLayerPainter.markerLabelGap,
          bravo.dy,
        ),
      );
      expect(spec.style.fontSize, 12);
      expect(spec.style.fontFamily, DsFontFamilies.mono);
      expect(spec.style.color, DsColors.textStrong);

      final canvas = paintLabels(tester);
      final pill = fillRects(canvas).single;
      expect(pill.left, closeTo(spec.anchor.dx, tolerance));
      expect(pill.center.dy, closeTo(spec.anchor.dy, tolerance));
      expect(pill.width, greaterThan(0));
      final fill =
          calls(canvas, #drawRRect).firstWhere(
                (a) => (a[1]! as Paint).style == PaintingStyle.fill,
              )[1]!
              as Paint;
      expect(fill.color.toARGB32(), DsColors.surfaceGlass.toARGB32());
      expect(calls(canvas, #drawParagraph), hasLength(1));
    });

    testWidgets('use plain paint: no layers or blur filters', (tester) async {
      await pumpScene(
        tester,
        connections: const [alphaBravo],
        showConnectionLabels: true,
        selectedId: 'alpha',
        relatedIds: const {'bravo'},
      );
      await tester.pump(ms(1000));
      final canvas = paintLabels(tester);
      expect(calls(canvas, #saveLayer), isEmpty);
      for (final args in calls(canvas, #drawRRect)) {
        expect((args[1]! as Paint).maskFilter, isNull);
        expect((args[1]! as Paint).imageFilter, isNull);
      }
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('relation labels are off by default', (tester) async {
      await pumpScene(tester, connections: const [alphaBravo]);
      await tester.pump(ms(1500));
      expect(painterOf<DsMapLabelLayerPainter>(tester).specs(), isEmpty);
      expect(fillRects(paintLabels(tester)), isEmpty);
    });

    testWidgets('relation labels show on the transformed label point', (
      tester,
    ) async {
      await pumpScene(
        tester,
        camera: zoomed,
        verticalOffset: 100,
        connections: const [alphaBravo],
        showConnectionLabels: true,
      );
      await tester.pump(ms(1500));
      final expected = screenArc(
        alphaScene,
        bravoScene,
        camera: zoomed,
        verticalOffset: 100,
      ).labelPoint;
      final spec = painterOf<DsMapLabelLayerPainter>(tester).specs().single;
      expect(spec.text, 'Same region');
      expect(spec.kind, DsMapLabelKind.connection);
      expect((spec.anchor - expected).distance, lessThan(0.01));
      expect(spec.style.fontSize, 12);
      expect(spec.style.fontFamily, DsFontFamilies.mono);
      expect(spec.style.color, DsColors.accentGold);

      final pill = fillRects(paintLabels(tester)).single;
      expect((pill.center - expected).distance, lessThan(0.01));
    });

    testWidgets('relation labels follow the arc reveal', (tester) async {
      await pumpScene(
        tester,
        connections: const [alphaBravo],
        showConnectionLabels: true,
      );
      await tester.pump(ms(300));
      expect(painterOf<DsMapLabelLayerPainter>(tester).specs(), isEmpty);
      expect(fillRects(paintLabels(tester)), isEmpty);
      await tester.pump(ms(500));
      final spec = painterOf<DsMapLabelLayerPainter>(tester).specs().single;
      expect(spec.opacity, closeTo(0.5, 0.02));
    });

    testWidgets('relation labels of hidden arcs are not drawn', (tester) async {
      await pumpScene(
        tester,
        connections: const [bravoCharlie],
        showConnectionLabels: true,
        timelineYear: 1990,
      );
      await tester.pump(ms(1500));
      expect(painterOf<DsMapLabelLayerPainter>(tester).specs(), isEmpty);
    });

    testWidgets('are excluded from semantics and ignore pointers', (
      tester,
    ) async {
      await pumpScene(
        tester,
        connections: const [alphaBravo],
        showConnectionLabels: true,
        selectedId: 'alpha',
        relatedIds: const {'bravo'},
      );
      final labelPaint = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is DsMapLabelLayerPainter,
      );
      expect(
        find.ancestor(of: labelPaint, matching: find.byType(ExcludeSemantics)),
        findsWidgets,
      );
      expect(
        find.ancestor(of: labelPaint, matching: find.byType(IgnorePointer)),
        findsWidgets,
      );
    });
  });
}
