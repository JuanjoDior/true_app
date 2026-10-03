import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';

import 'test_support/ds_map_scene_test_support.dart';

void main() {
  group('semantics and taps', () {
    testWidgets('effects add no semantics: one node per interactive marker', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpScene(
        tester,
        connections: const [alphaBravo, bravoCharlie],
        showConnectionLabels: true,
        selectedId: 'alpha',
        relatedIds: const {'bravo'},
        onMarkerTap: (_) {},
      );
      await tester.pump(ms(1500));
      expect(
        semanticLabels(tester),
        unorderedEquals(['Alpha', 'Bravo', 'Charlie']),
      );
      handle.dispose();
    });

    testWidgets('a tap on the related label reaches the marker below', (
      tester,
    ) async {
      final taps = <String>[];
      await pumpScene(
        tester,
        selectedId: 'alpha',
        relatedIds: const {'bravo'},
        onMarkerTap: taps.add,
      );
      final spec = painterOf<DsMapLabelLayerPainter>(tester).specs().single;
      await tester.tapAt(spec.anchor + const Offset(2, 0));
      expect(taps, ['bravo']);
    });

    testWidgets('a tap on a relation label far from markers does nothing', (
      tester,
    ) async {
      final taps = <String>[];
      await pumpScene(
        tester,
        markers: const [markerAlpha, markerCharlie],
        connections: const [
          DsMapConnection(fromId: 'alpha', toId: 'charlie', label: 'Far'),
        ],
        showConnectionLabels: true,
        onMarkerTap: taps.add,
      );
      await tester.pump(ms(1500));
      final spec = painterOf<DsMapLabelLayerPainter>(tester).specs().single;
      await tester.tapAt(spec.anchor);
      expect(taps, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('markers still receive taps with arcs on screen', (
      tester,
    ) async {
      final taps = <String>[];
      await pumpScene(
        tester,
        connections: const [alphaBravo],
        onMarkerTap: taps.add,
      );
      await tester.pump(ms(1500));
      await tester.tapAt(alphaScene);
      expect(taps, ['alpha']);
    });
  });

  group('reduced motion', () {
    testWidgets('schedules no frames after settling', (tester) async {
      await pumpScene(
        tester,
        disableAnimations: true,
        connections: const [alphaBravo],
      );
      await tester.pump(const Duration(seconds: 2));
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('shows arcs at full opacity at once, with dash phase 0', (
      tester,
    ) async {
      await pumpScene(
        tester,
        disableAnimations: true,
        connections: const [alphaBravo],
        showConnectionLabels: true,
      );
      final canvas = paintEffects(tester);
      final paints = arcPaints(canvas);
      expect(paints, hasLength(1));
      expect(paints.single.color.a, 1);
      expect(
        contourLengths(arcPaths(canvas).single),
        contourLengths(
          screenArc(alphaScene, bravoScene).dashedPath(phase: 0),
        ),
      );
      expect(
        painterOf<DsMapLabelLayerPainter>(tester).specs().single.opacity,
        1,
      );
    });

    testWidgets('draws no pulse rings', (tester) async {
      await pumpScene(tester, disableAnimations: true, selectedId: 'alpha');
      await tester.pump(ms(750));
      expect(rings(paintEffects(tester)), isEmpty);
    });

    testWidgets('switching the setting at runtime stops and starts motion', (
      tester,
    ) async {
      await pumpScene(tester, connections: const [alphaBravo]);
      await tester.pump(ms(300));
      expect(tester.binding.hasScheduledFrame, isTrue);
      expect(rings(paintEffects(tester)), isNotEmpty);

      await tester.pumpWidget(
        buildScene(disableAnimations: true, connections: const [alphaBravo]),
      );
      await tester.pump(ms(100));
      await tester.pump(ms(100));
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(rings(paintEffects(tester)), isEmpty);
      expect(arcPaints(paintEffects(tester)).single.color.a, 1);

      await tester.pumpWidget(buildScene(connections: const [alphaBravo]));
      await tester.pump(ms(750));
      expect(tester.binding.hasScheduledFrame, isTrue);
      expect(rings(paintEffects(tester)), isNotEmpty);
    });
  });

  group('ticker lifecycle', () {
    testWidgets('pumpAndSettle ends with no markers and no connections', (
      tester,
    ) async {
      await pumpScene(tester, markers: const []);
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('pumpAndSettle ends when every marker is hidden by the year', (
      tester,
    ) async {
      await pumpScene(tester, timelineYear: 1900, connections: const [alphaBravo]);
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('keeps running while something pulses', (tester) async {
      await pumpScene(tester, markers: const [markerAlpha]);
      await tester.pump(const Duration(seconds: 5));
      expect(tester.binding.hasScheduledFrame, isTrue);
    });

    testWidgets('runs for arcs alone and stops when they go away', (
      tester,
    ) async {
      await pumpScene(tester, timelineYear: 1900, connections: const [alphaBravo]);
      await tester.pumpWidget(
        buildScene(timelineYear: 1990, connections: const [alphaBravo]),
      );
      await tester.pump(ms(500));
      expect(tester.binding.hasScheduledFrame, isTrue);
      await tester.pumpWidget(buildScene(timelineYear: 1900));
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('stops when the last marker disappears at runtime', (
      tester,
    ) async {
      await pumpScene(tester, markers: const [markerAlpha]);
      await tester.pump(ms(500));
      await tester.pumpWidget(buildScene(markers: const []));
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('restarts when a marker appears again', (tester) async {
      await pumpScene(tester, markers: const []);
      await tester.pumpAndSettle();
      await tester.pumpWidget(buildScene(markers: const [markerAlpha]));
      await tester.pump(ms(750));
      expect(tester.binding.hasScheduledFrame, isTrue);
      expect(rings(paintEffects(tester)), hasLength(1));
    });

    testWidgets('disposes both controllers with the widget', (tester) async {
      await pumpScene(
        tester,
        selectedId: 'alpha',
        connections: const [alphaBravo],
      );
      await tester.pump(ms(300));
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  group('robustness', () {
    testWidgets('renders at 1440x900 with every effect on', (tester) async {
      await pumpScene(
        tester,
        connections: const [alphaBravo, bravoCharlie],
        showConnectionLabels: true,
        selectedId: 'alpha',
        relatedIds: const {'bravo', 'charlie'},
        verticalOffset: 180,
        onMarkerTap: (_) {},
      );
      await tester.pump(ms(1500));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders at 390x844 mobile with a zoomed camera', (
      tester,
    ) async {
      await pumpScene(
        tester,
        size: phone,
        mobile: true,
        camera: zoomed,
        connections: const [alphaBravo],
        showConnectionLabels: true,
        selectedId: 'bravo',
        relatedIds: const {'alpha'},
      );
      await tester.pump(ms(1500));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders with text scale 2.0', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpScene(
        tester,
        size: phone,
        mobile: true,
        textScale: 2,
        connections: const [alphaBravo],
        showConnectionLabels: true,
        selectedId: 'alpha',
        relatedIds: const {'bravo'},
        onMarkerTap: (_) {},
      );
      await tester.pump(ms(1500));
      expect(tester.takeException(), isNull);
      handle.dispose();
    });
  });
}
