import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';

import 'test_support/ds_globe_scene_test_support.dart';

const String _selected = 'facing';
const Set<String> _related = {'east'};
const String _facingEastKey = 'facing>east';
const String _eastNearLimbKey = 'east>near-limb';
const double _halfFade = 0.5;

DsGlobeCamera get _target =>
    DsGlobeCameraTargets.explore(latitude: 30, longitude: 40, currentGy: 0);
DsGlobeCamera get _interrupting =>
    DsGlobeCameraTargets.cover(latitude: -20, longitude: -60, currentGy: 0);
// Deja a la vista `back` y `near-limb`, y oculta `facing`.
DsGlobeCamera get _turnedAway =>
    DsGlobeCameraTargets.cover(latitude: 15, longitude: 120, currentGy: 0);

Duration _ms(int value) => Duration(milliseconds: value);

Duration _elapsedOf(WidgetTester tester, String key) =>
    arcPainter(tester).elapsedOf(key);

int _paintedDots(WidgetTester tester) {
  final canvas = TestRecordingCanvas();
  arcPainter(tester).paint(canvas, desktop);
  return calls(
    canvas,
    #drawCircle,
  ).where((args) => (args[2]! as Paint).maskFilter == null).length;
}

Future<void> _pumpArcs(
  WidgetTester tester, {
  List<DsMapConnection> connections = const [facingEast],
  bool disableAnimations = false,
}) async {
  await pumpGlobeScene(
    tester,
    selectedId: _selected,
    connections: connections,
    disableAnimations: disableAnimations,
  );
  await tester.pump();
}

Widget _scene({
  List<DsMapConnection> connections = const [facingEast],
  DsGlobeCamera? camera,
  Color? haloColor,
}) => buildGlobeScene(
  selectedId: _selected,
  connections: connections,
  camera: camera,
  haloColor: haloColor,
);

void main() {
  group('arc reveal', () {
    testWidgets('dots appear one by one from 900 ms and finish at 2010 ms', (
      tester,
    ) async {
      await _pumpArcs(tester);
      expect(_paintedDots(tester), 0);
      await tester.pump(_ms(899));
      expect(_paintedDots(tester), 0);
      await tester.pump(_ms(101));
      expect(_paintedDots(tester), 3);
      await tester.pump(_ms(1010));
      expect(_paintedDots(tester), 27);
      expect(_elapsedOf(tester, _facingEastKey), arcRevealTotal);
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('a second connection added later reveals alone', (
      tester,
    ) async {
      await _pumpArcs(tester);
      await tester.pump(arcRevealTotal);
      await tester.pumpWidget(
        _scene(connections: const [facingEast, eastNearLimb]),
      );
      await tester.pump();
      expect(_elapsedOf(tester, _facingEastKey), arcRevealTotal);
      expect(_elapsedOf(tester, _eastNearLimbKey), Duration.zero);
      expect(_paintedDots(tester), 27);

      await tester.pump(_ms(1000));
      expect(_elapsedOf(tester, _facingEastKey), arcRevealTotal);
      expect(_elapsedOf(tester, _eastNearLimbKey), _ms(1000));
      expect(_paintedDots(tester), 27 + 3);

      await tester.pump(_ms(1010));
      expect(_elapsedOf(tester, _eastNearLimbKey), arcRevealTotal);
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('an arc revealing keeps its progress when another is added', (
      tester,
    ) async {
      await _pumpArcs(tester);
      await tester.pump(_ms(1000));
      await tester.pumpWidget(
        _scene(connections: const [facingEast, eastNearLimb]),
      );
      await tester.pump();
      expect(_elapsedOf(tester, _facingEastKey), _ms(1000));
      expect(_elapsedOf(tester, _eastNearLimbKey), Duration.zero);

      await tester.pump(_ms(500));
      expect(_elapsedOf(tester, _facingEastKey), _ms(1500));
      expect(_elapsedOf(tester, _eastNearLimbKey), _ms(500));

      await tester.pump(_ms(1000));
      expect(_elapsedOf(tester, _facingEastKey), arcRevealTotal);
      expect(_elapsedOf(tester, _eastNearLimbKey), _ms(1500));
      await tester.pumpAndSettle();
      expect(_elapsedOf(tester, _eastNearLimbKey), arcRevealTotal);
    });

    testWidgets('a changed connection reveals alone and the old one is gone', (
      tester,
    ) async {
      await _pumpArcs(tester);
      await tester.pump(arcRevealTotal);
      await tester.pumpWidget(_scene(connections: const [eastNearLimb]));
      await tester.pump();
      expect(arcPainter(tester).arcs.map((arc) => arc.key), [_eastNearLimbKey]);
      expect(_elapsedOf(tester, _eastNearLimbKey), Duration.zero);
      expect(_paintedDots(tester), 0);
    });

    testWidgets('rebuilding with the same connections does not restart', (
      tester,
    ) async {
      await _pumpArcs(tester);
      await tester.pump(_ms(1000));
      await tester.pumpWidget(
        _scene(
          connections: [
            DsMapConnection(
              fromId: facingEast.fromId,
              toId: facingEast.toId,
              label: facingEast.label,
            ),
          ],
          haloColor: const Color(0xFFE5484D),
        ),
      );
      await tester.pump();
      expect(_elapsedOf(tester, _facingEastKey), _ms(1000));
      await tester.pump(_ms(100));
      expect(_elapsedOf(tester, _facingEastKey), _ms(1100));
    });

    testWidgets('moving the camera does not restart the reveal', (
      tester,
    ) async {
      await _pumpArcs(tester);
      await tester.pump(_ms(1000));
      await tester.pumpWidget(_scene(camera: _target));
      await tester.pump();
      await tester.pump(_ms(500));
      expect(_elapsedOf(tester, _facingEastKey), _ms(1500));
      await tester.pump(flyDuration);
      expect(_elapsedOf(tester, _facingEastKey), arcRevealTotal);
    });

    testWidgets('an arc coming from behind the limb is not revealed again', (
      tester,
    ) async {
      const hidden = DsMapConnection(
        fromId: 'back',
        toId: 'near-limb',
        label: 'Hidden at first',
      );
      await _pumpArcs(tester, connections: const [hidden]);
      expect(arcPainter(tester).arcs, isEmpty);
      await tester.pumpWidget(
        _scene(connections: const [hidden], camera: _turnedAway),
      );
      await tester.pump();
      await tester.pump(flyDuration);
      await tester.pump(_ms(200));
      expect(arcPainter(tester).arcs, hasLength(1));
      expect(_elapsedOf(tester, 'back>near-limb'), arcRevealTotal);
      expect(_paintedDots(tester), greaterThan(0));
    });

    testWidgets('unknown ids are skipped silently and start no clock', (
      tester,
    ) async {
      await _pumpArcs(
        tester,
        connections: const [
          DsMapConnection(fromId: 'facing', toId: 'ghost', label: ''),
          DsMapConnection(fromId: 'ghost', toId: 'east', label: ''),
        ],
      );
      expect(arcPainter(tester).arcs, isEmpty);
      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('back-hidden and year-hidden endpoints are skipped', (
      tester,
    ) async {
      await pumpGlobeScene(
        tester,
        selectedId: _selected,
        connections: const [
          DsMapConnection(fromId: 'facing', toId: 'back', label: ''),
          facingEast,
        ],
        timelineYear: 1980,
      );
      expect(arcPainter(tester).arcs, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the arcs painter receives the visible arcs by key', (
      tester,
    ) async {
      await _pumpArcs(
        tester,
        connections: const [
          facingEast,
          DsMapConnection(fromId: 'facing', toId: 'back', label: ''),
        ],
      );
      expect(
        [for (final arc in arcPainter(tester).arcs) arc.key],
        [_facingEastKey],
      );
      expect(arcPainter(tester).camera, coverCamera);
    });

    testWidgets('a fraction of the fade shows as partial opacity', (
      tester,
    ) async {
      await _pumpArcs(tester);
      await tester.pump(_ms(1000));
      final canvas = TestRecordingCanvas();
      arcPainter(tester).paint(canvas, desktop);
      final first = calls(canvas, #drawCircle)
          .map((args) => args[2]! as Paint)
          .firstWhere((paint) => paint.maskFilter == null);
      expect(first.color.a, closeTo(_halfFade, 1e-6));
    });
  });

  group('delayed labels', () {
    Future<void> pumpLabels(WidgetTester tester) =>
        pumpGlobeScene(tester, selectedId: _selected, relatedIds: _related);

    Widget labelScene({
      DsGlobeCamera? camera,
      bool showLabels = true,
      bool disableAnimations = false,
    }) => buildGlobeScene(
      selectedId: _selected,
      relatedIds: _related,
      camera: camera,
      showLabels: showLabels,
      disableAnimations: disableAnimations,
    );

    testWidgets('the first build shows them immediately', (tester) async {
      await pumpLabels(tester);
      expect(labelsShown(tester), isTrue);
      expect(painterOf<DsGlobeLabelPainter>(tester).specs(), isNotEmpty);
    });

    testWidgets('hide when a flight starts and return 1700 ms later', (
      tester,
    ) async {
      await pumpLabels(tester);
      await tester.pumpWidget(labelScene(camera: _target));
      await tester.pump();
      expect(labelsShown(tester), isFalse);
      expect(painterOf<DsGlobeLabelPainter>(tester).specs(), isEmpty);
      await tester.pump(labelDelay - _ms(1));
      expect(labelsShown(tester), isFalse);
      await tester.pump(_ms(1));
      expect(labelsShown(tester), isTrue);
      expect(painterOf<DsGlobeLabelPainter>(tester).specs(), isNotEmpty);
      await tester.pump(flyDuration);
      expect(labelsShown(tester), isTrue);
    });

    testWidgets('a new flight restarts the 1700 ms', (tester) async {
      await pumpLabels(tester);
      await tester.pumpWidget(labelScene(camera: _target));
      await tester.pump();
      await tester.pump(_ms(1000));
      await tester.pumpWidget(labelScene(camera: _interrupting));
      await tester.pump();
      expect(labelsShown(tester), isFalse);
      await tester.pump(labelDelay - _ms(1));
      expect(labelsShown(tester), isFalse);
      await tester.pump(_ms(1));
      expect(labelsShown(tester), isTrue);
    });

    testWidgets('showLabels false stays hidden after the delay', (
      tester,
    ) async {
      await pumpLabels(tester);
      await tester.pumpWidget(labelScene(camera: _target, showLabels: false));
      await tester.pump();
      await tester.pump(labelDelay);
      expect(labelsShown(tester), isFalse);
    });

    testWidgets('hiding and showing with showLabels is immediate', (
      tester,
    ) async {
      await pumpLabels(tester);
      await tester.pumpWidget(labelScene(showLabels: false));
      expect(labelsShown(tester), isFalse);
      await tester.pumpWidget(labelScene());
      expect(labelsShown(tester), isTrue);
    });

    testWidgets('reduced motion shows them immediately after a cut', (
      tester,
    ) async {
      await pumpGlobeScene(
        tester,
        selectedId: _selected,
        relatedIds: _related,
        disableAnimations: true,
      );
      await tester.pumpWidget(
        labelScene(camera: _target, disableAnimations: true),
      );
      expect(labelsShown(tester), isTrue);
      await tester.pump();
      expect(labelsShown(tester), isTrue);
    });

    testWidgets('turning reduced motion on mid-delay shows them at once', (
      tester,
    ) async {
      await pumpLabels(tester);
      await tester.pumpWidget(labelScene(camera: _target));
      await tester.pump();
      expect(labelsShown(tester), isFalse);
      await tester.pumpWidget(
        labelScene(camera: _target, disableAnimations: true),
      );
      expect(labelsShown(tester), isTrue);
    });

    testWidgets('the timer is cancelled on dispose', (tester) async {
      await pumpLabels(tester);
      await tester.pumpWidget(labelScene(camera: _target));
      await tester.pump();
      await tester.pump(_ms(500));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(labelDelay * 2);
      expect(tester.takeException(), isNull);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('lifecycle', () {
    testWidgets('disposing mid-reveal leaves no running animations', (
      tester,
    ) async {
      await _pumpArcs(tester);
      await tester.pump(_ms(500));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('disposing mid-drift leaves no running animations', (
      tester,
    ) async {
      await pumpGlobeScene(tester);
      await tester.pump();
      await tester.pump(driftStep * 3);
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.takeException(), isNull);
    });
  });
}
