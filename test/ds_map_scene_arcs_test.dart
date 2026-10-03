import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';

import 'test_support/ds_map_scene_test_support.dart';

void main() {
  group('arcs', () {
    testWidgets('draw a gold dashed stroke of constant width at scale 1', (
      tester,
    ) async {
      await pumpScene(tester, connections: const [alphaBravo]);
      await tester.pump(ms(1000));
      final paint = arcPaints(paintEffects(tester)).single;
      expect(paint.strokeWidth, closeTo(DsMapArc.strokeWidth, 1e-6));
      expect(paint.style, PaintingStyle.stroke);
      expect(paint.color.toARGB32(), DsColors.accentGold.toARGB32());
    });

    testWidgets('keep the 1.8 stroke and 7 px dashes at scale 3.4', (
      tester,
    ) async {
      await pumpScene(tester, camera: zoomed, connections: const [alphaBravo]);
      await tester.pump(ms(1000));
      final canvas = paintEffects(tester);
      expect(arcPaints(canvas).single.strokeWidth, closeTo(1.8, 1e-6));
      final lengths = contourLengths(arcPaths(canvas).single);
      expect(lengths.length, greaterThan(3));
      for (final length in lengths) {
        expect(length, lessThanOrEqualTo(dashOn + dashTolerance));
      }
      expect(
        lengths.where((l) => (l - dashOn).abs() < dashTolerance).length,
        greaterThan(lengths.length - 2),
      );
    });

    testWidgets('start and end at the transformed marker centers', (
      tester,
    ) async {
      await pumpScene(
        tester,
        camera: zoomed,
        verticalOffset: 100,
        connections: const [alphaBravo],
      );
      await tester.pump(ms(1200));
      final path = arcPaths(paintEffects(tester)).single;
      final expected = screenArc(
        alphaScene,
        bravoScene,
        camera: zoomed,
        verticalOffset: 100,
      );
      final first = path.computeMetrics().first;
      expect(
        (first.getTangentForOffset(0)!.position - expected.start).distance,
        lessThan(0.01),
      );
      final bounds = path.getBounds();
      final hull = Rect.fromPoints(
        expected.start,
        expected.end,
      ).expandToInclude(Rect.fromCircle(center: expected.control, radius: 0));
      expect(hull.inflate(0.01).contains(bounds.topLeft), isTrue);
      expect(hull.inflate(0.01).contains(bounds.bottomRight), isTrue);
    });

    testWidgets('the dash phase follows the 1.2 s clock', (tester) async {
      await pumpScene(tester, connections: const [alphaBravo]);
      final screen = screenArc(alphaScene, bravoScene);

      List<double> expectedAt(int elapsedMs) => contourLengths(
        screen.dashedPath(
          phase: DsMapArc.dashPhase(
            DsMapMotionClock.dashProgress(ms(elapsedMs)),
          ),
        ),
      );

      await tester.pump(ms(1000));
      final at1000 = contourLengths(arcPaths(paintEffects(tester)).single);
      expect(at1000, expectedAt(1000));

      await tester.pump(ms(600));
      final at1600 = contourLengths(arcPaths(paintEffects(tester)).single);
      expect(at1600, expectedAt(1600));
      expect(at1600, isNot(at1000));

      await tester.pump(ms(600));
      final at2200 = contourLengths(arcPaths(paintEffects(tester)).single);
      expect(at2200, at1000);
    });

    testWidgets(
      'the arc passes behind marker bodies: it is not in the marker layer',
      (tester) async {
        await pumpScene(tester, connections: const [alphaBravo]);
        await tester.pump(ms(1000));
        final canvas = TestRecordingCanvas();
        painterOf<DsMapMarkerLayerPainter>(tester).paint(canvas, desktop);
        expect(calls(canvas, #drawPath), isEmpty);
      },
    );

    testWidgets('an arc whose endpoint is hidden by the year is not drawn', (
      tester,
    ) async {
      const toCharlie = DsMapConnection(
        fromId: 'alpha',
        toId: 'charlie',
        label: 'Far',
      );
      await pumpScene(tester, connections: const [toCharlie], timelineYear: 1990);
      await tester.pump(ms(1500));
      expect(arcPaths(paintEffects(tester)), isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('appears when the year reveals the endpoint', (tester) async {
      const toCharlie = DsMapConnection(
        fromId: 'alpha',
        toId: 'charlie',
        label: 'Far',
      );
      await pumpScene(tester, connections: const [toCharlie], timelineYear: 1990);
      await tester.pump(ms(1500));
      await tester.pumpWidget(
        buildScene(connections: const [toCharlie], timelineYear: 2020),
      );
      await tester.pump(ms(300));
      expect(arcPaths(paintEffects(tester)), isEmpty);
      await tester.pump(ms(700));
      expect(arcPaints(paintEffects(tester)).single.color.a, 1);
    });

    testWidgets('unknown ids are skipped without throwing', (tester) async {
      const ghostFrom = DsMapConnection(
        fromId: 'ghost',
        toId: 'bravo',
        label: 'x',
      );
      const ghostTo = DsMapConnection(
        fromId: 'alpha',
        toId: 'ghost',
        label: 'y',
      );
      const bothGhosts = DsMapConnection(
        fromId: 'ghost',
        toId: 'ghost',
        label: 'z',
      );
      await pumpScene(
        tester,
        connections: const [ghostFrom, ghostTo, bothGhosts, alphaBravo],
        showConnectionLabels: true,
      );
      await tester.pump(ms(1500));
      expect(arcPaths(paintEffects(tester)), hasLength(1));
      expect(
        painterOf<DsMapLabelLayerPainter>(tester).specs().map((s) => s.text),
        ['Same region'],
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('arc reveal', () {
    testWidgets('is invisible before 600 ms', (tester) async {
      await pumpScene(tester, connections: const [alphaBravo]);
      expect(arcPaths(paintEffects(tester)), isEmpty);
      await tester.pump(ms(300));
      expect(arcPaths(paintEffects(tester)), isEmpty);
      await tester.pump(ms(300));
      expect(arcPaths(paintEffects(tester)), isEmpty);
    });

    testWidgets('fades in between 600 and 1000 ms', (tester) async {
      await pumpScene(tester, connections: const [alphaBravo]);
      await tester.pump(ms(800));
      expect(
        arcPaints(paintEffects(tester)).single.color.a,
        closeTo(0.5, 0.02),
      );
      await tester.pump(ms(100));
      expect(
        arcPaints(paintEffects(tester)).single.color.a,
        closeTo(0.75, 0.02),
      );
    });

    testWidgets('is fully opaque from 1000 ms on', (tester) async {
      await pumpScene(tester, connections: const [alphaBravo]);
      await tester.pump(ms(1000));
      expect(arcPaints(paintEffects(tester)).single.color.a, 1);
      await tester.pump(ms(5000));
      expect(arcPaints(paintEffects(tester)).single.color.a, 1);
    });

    testWidgets('a new connection reveals alone and keeps the old one solid', (
      tester,
    ) async {
      await pumpScene(tester, connections: const [alphaBravo]);
      await tester.pump(ms(1500));
      await tester.pumpWidget(
        buildScene(connections: const [alphaBravo, bravoCharlie]),
      );
      await tester.pump(ms(300));
      var paints = arcPaints(paintEffects(tester));
      expect(paints, hasLength(1));
      expect(paints.single.color.a, 1);
      await tester.pump(ms(700));
      paints = arcPaints(paintEffects(tester));
      expect(paints, hasLength(2));
      expect(paints.every((p) => p.color.a == 1), isTrue);
    });

    testWidgets('moving an endpoint restarts the reveal', (tester) async {
      await pumpScene(tester, connections: const [alphaBravo]);
      await tester.pump(ms(1500));
      await tester.pumpWidget(
        buildScene(
          markers: const [markerAlpha, markerBravoMoved, markerCharlie],
          connections: const [alphaBravo],
        ),
      );
      await tester.pump(ms(300));
      expect(arcPaths(paintEffects(tester)), isEmpty);
      await tester.pump(ms(700));
      expect(arcPaints(paintEffects(tester)).single.color.a, 1);
    });

    testWidgets('moving the camera does not restart the reveal', (
      tester,
    ) async {
      await pumpScene(tester, connections: const [alphaBravo]);
      await tester.pump(ms(1500));
      await tester.pumpWidget(
        buildScene(camera: zoomed, connections: const [alphaBravo]),
      );
      await tester.pump(ms(200));
      expect(arcPaints(paintEffects(tester)).single.color.a, 1);
    });

    testWidgets('rebuilding with the same connections does not restart it', (
      tester,
    ) async {
      await pumpScene(tester, connections: const [alphaBravo]);
      await tester.pump(ms(1500));
      await tester.pumpWidget(buildScene(connections: const [alphaBravo]));
      await tester.pump(ms(16));
      expect(arcPaints(paintEffects(tester)).single.color.a, 1);
    });
  });
}
