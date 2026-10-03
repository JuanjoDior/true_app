import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';

import 'test_support/ds_map_scene_test_support.dart';

void main() {
  group('defaults', () {
    test('connections are empty and labels are off', () {
      const scene = DsMapScene(markers: [], camera: world);
      expect(scene.connections, isEmpty);
      expect(scene.showConnectionLabels, isFalse);
    });

    testWidgets('DsMapArc.mapPoints maps every point through the function', (
      tester,
    ) async {
      final arc = DsMapArc.between(alphaScene, bravoScene);
      final mapped = arc.mapPoints(zoomed.apply);
      expect(mapped.start, zoomed.apply(arc.start));
      expect(mapped.end, zoomed.apply(arc.end));
      expect(mapped.control, zoomed.apply(arc.control));
      expect(mapped.labelPoint, zoomed.apply(arc.labelPoint));
    });
  });

  group('layer order', () {
    testWidgets('land, effects, markers, labels from bottom to top', (
      tester,
    ) async {
      await pumpScene(tester, connections: const [alphaBravo]);
      final painters = tester
          .widgetList<CustomPaint>(
            find.descendant(
              of: find.byType(DsMapScene),
              matching: find.byType(CustomPaint),
            ),
          )
          .map((p) => p.painter.runtimeType)
          .where((t) => t != Null)
          .toList();
      expect(painters, [
        DsMapLandLayerPainter,
        DsMapEffectsPainter,
        DsMapMarkerLayerPainter,
        DsMapLabelLayerPainter,
      ]);
    });
  });

  group('pulse rings', () {
    testWidgets('grow from 0.5x to 2.8x of the marker radius and fade', (
      tester,
    ) async {
      await pumpScene(tester, markers: const [markerAlpha]);
      await tester.pump(ms(750));
      var ring = rings(paintEffects(tester)).single;
      expect(ring.center, alphaScene);
      expect(
        ring.radius,
        closeTo(alphaRadius * (0.5 + 2.3 * 0.25), tolerance),
      );
      expect(ring.paint.color.a, closeTo(pulseStartAlpha * 0.75, tolerance));
      expect(ring.paint.style, PaintingStyle.stroke);
      expect(
        ring.paint.color.toARGB32() & 0x00FFFFFF,
        markerAlpha.color.toARGB32() & 0x00FFFFFF,
      );

      await tester.pump(ms(750));
      ring = rings(paintEffects(tester)).single;
      expect(
        ring.radius,
        closeTo(alphaRadius * (0.5 + 2.3 * 0.5), tolerance),
      );
      expect(ring.paint.color.a, closeTo(pulseStartAlpha * 0.5, tolerance));
    });

    testWidgets('start at 0.5x with alpha 0.6 at elapsed 0', (tester) async {
      await pumpScene(tester, markers: const [markerAlpha]);
      final ring = rings(paintEffects(tester)).single;
      expect(ring.radius, closeTo(alphaRadius * 0.5, tolerance));
      expect(ring.paint.color.a, closeTo(pulseStartAlpha, tolerance));
    });

    testWidgets('loop: a full idle cycle returns to the start', (tester) async {
      await pumpScene(tester, markers: const [markerAlpha]);
      await tester.pump(ms(3000));
      final ring = rings(paintEffects(tester)).single;
      expect(ring.radius, closeTo(alphaRadius * 0.5, tolerance));
      expect(ring.paint.color.a, closeTo(pulseStartAlpha, tolerance));
    });

    testWidgets('the selected marker pulses on 1.8 s with its own radius', (
      tester,
    ) async {
      await pumpScene(tester, selectedId: 'alpha');
      await tester.pump(ms(450));
      final ring = ringAt(paintEffects(tester), alphaScene);
      expect(
        ring.radius,
        closeTo(selectedRadius * (0.5 + 2.3 * 0.25), tolerance),
      );
      expect(ring.paint.color.a, closeTo(pulseStartAlpha * 0.75, tolerance));
    });

    testWidgets(
      'use the marker index in the list as delay, not the paint order',
      (tester) async {
        await pumpScene(tester, selectedId: 'alpha');
        await tester.pump(ms(750));
        final canvas = paintEffects(tester);
        // bravo: índice 1, retraso 410 ms, ciclo 3 s; opacidad 0,4 por selección.
        final bravo = ringAt(canvas, bravoScene);
        final progress = (750 - 410) / 3000;
        expect(
          bravo.radius,
          closeTo(alphaRadius * (0.5 + 2.3 * progress), tolerance),
        );
        expect(
          bravo.paint.color.a,
          closeTo(pulseStartAlpha * (1 - progress) * 0.4, tolerance),
        );
        // alpha: índice 0 aunque se pinte el último.
        final alpha = ringAt(canvas, alphaScene);
        expect(
          alpha.radius,
          closeTo(
            selectedRadius * (0.5 + 2.3 * (750 % 1800) / 1800),
            tolerance,
          ),
        );
      },
    );

    testWidgets('one ring per interactive marker, none for hidden ones', (
      tester,
    ) async {
      await pumpScene(tester);
      expect(rings(paintEffects(tester)), hasLength(3));
      await pumpScene(tester, timelineYear: 1990);
      expect(rings(paintEffects(tester)), hasLength(2));
      await pumpScene(tester, timelineYear: 1900);
      expect(rings(paintEffects(tester)), isEmpty);
    });

    testWidgets(
      'are drawn at the projected position, including offset and camera',
      (tester) async {
        await pumpScene(
          tester,
          markers: const [markerCharlie],
          camera: zoomed,
          verticalOffset: 100,
        );
        final ring = rings(paintEffects(tester)).single;
        expect(
          ring.center,
          zoomed.apply(charlieScene + const Offset(0, 100)),
        );
        expect(ring.radius, closeTo(alphaRadius * 0.5, tolerance));
      },
    );
  });
}
