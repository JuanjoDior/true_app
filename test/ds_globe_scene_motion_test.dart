import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';

import 'test_support/ds_globe_scene_test_support.dart';

const double _degreesPerSecond = driftDegreesPerStep / 0.07;
const double _epsilon = 1e-9;
const String _selected = 'facing';
const Offset _emptySpot = Offset(60, 860);

DsGlobeCamera get _target =>
    DsGlobeCameraTargets.explore(latitude: 30, longitude: 40, currentGy: 0);

Duration _ms(int value) => Duration(milliseconds: value);

double _gy(WidgetTester tester) => displayedCamera(tester).gy;

// El ticker toma su origen en el primer fotograma, así que el primer pump no cuenta.
Future<void> _pumpDrifting(
  WidgetTester tester, {
  List<DsMapConnection> connections = const [],
  ValueChanged<String>? onMarkerTap,
  Size size = desktop,
  double textScale = 1,
}) async {
  await pumpGlobeScene(
    tester,
    connections: connections,
    onMarkerTap: onMarkerTap,
    size: size,
    textScale: textScale,
  );
  await tester.pump();
}

void main() {
  group('drift', () {
    testWidgets('moves gy by 0.22 degrees every 70 ms', (tester) async {
      await _pumpDrifting(tester);
      final start = _gy(tester);
      expect(start, coverCamera.gy);
      await tester.pump(driftStep);
      expect(_gy(tester), closeTo(start - driftDegreesPerStep, _epsilon));
      await tester.pump(driftStep);
      expect(_gy(tester), closeTo(start - 2 * driftDegreesPerStep, _epsilon));
    });

    testWidgets('is linear: about 3.14 degrees after one second', (
      tester,
    ) async {
      await _pumpDrifting(tester);
      final start = _gy(tester);
      await tester.pump(_ms(35));
      expect(
        _gy(tester),
        closeTo(start - driftDegreesPerStep / 2, _epsilon),
        reason: 'no stepping: half a step is half the degrees',
      );
      await tester.pump(_ms(965));
      expect(_gy(tester), closeTo(start - _degreesPerSecond, 1e-6));
      expect(_degreesPerSecond, closeTo(3.142857, 1e-6));
    });

    testWidgets('only gy changes and the markers follow the drift', (
      tester,
    ) async {
      await _pumpDrifting(tester);
      await tester.pump(_ms(500));
      final shown = displayedCamera(tester);
      expect(shown.gx, coverCamera.gx);
      expect(shown.scale, coverCamera.scale);
      expect(shown.center, coverCamera.center);
      expect(painterOf<DsGlobeBodyPainter>(tester).camera, shown);
      expect(painterOf<DsGlobeHaloPainter>(tester).camera, shown);
      expect(
        placementOf(tester, 'facing').center,
        projectMarker(facing, shown).screen,
      );
    });

    testWidgets('does not run with a selection', (tester) async {
      await pumpGlobeScene(tester, selectedId: _selected);
      await tester.pump();
      await tester.pump(_ms(1000));
      expect(_gy(tester), coverCamera.gy);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('also runs without markers', (tester) async {
      await pumpGlobeScene(tester, markers: const []);
      await tester.pump();
      await tester.pump(driftStep);
      expect(
        _gy(tester),
        closeTo(coverCamera.gy - driftDegreesPerStep, _epsilon),
      );
      expect(tester.hasRunningAnimations, isTrue);
    });

    testWidgets('a selection stops it at once and keeps the camera', (
      tester,
    ) async {
      await _pumpDrifting(tester);
      await tester.pump(_ms(700));
      final drifted = displayedCamera(tester);
      expect(drifted.gy, lessThan(coverCamera.gy));

      await tester.pumpWidget(buildGlobeScene(selectedId: _selected));
      expect(tester.hasRunningAnimations, isFalse);
      expect(displayedCamera(tester), drifted);
      await tester.pump(_ms(1000));
      expect(displayedCamera(tester), drifted);
    });

    testWidgets('clearing the selection resumes from the same camera', (
      tester,
    ) async {
      await _pumpDrifting(tester);
      await tester.pump(_ms(700));
      await tester.pumpWidget(buildGlobeScene(selectedId: _selected));
      final stopped = _gy(tester);
      await tester.pumpWidget(buildGlobeScene());
      await tester.pump();
      expect(_gy(tester), stopped);
      await tester.pump(driftStep);
      expect(_gy(tester), closeTo(stopped - driftDegreesPerStep, _epsilon));
    });

    testWidgets('does not run during a flight', (tester) async {
      await _pumpDrifting(tester);
      await tester.pump(_ms(700));
      final from = displayedCamera(tester);
      await tester.pumpWidget(buildGlobeScene(camera: _target));
      await tester.pump();
      await tester.pump(flyDuration ~/ 2);
      final expected = DsGlobeCamera.lerp(
        from,
        _target,
        DsMotion.easeGlobe.transform(0.5),
      );
      final mid = displayedCamera(tester);
      expect(mid.gy, closeTo(expected.gy, _epsilon));
      expect(mid.gx, closeTo(expected.gx, _epsilon));
      expect(mid.scale, closeTo(expected.scale, _epsilon));
    });

    testWidgets('a flight starting mid-drift begins from the drifted camera', (
      tester,
    ) async {
      await _pumpDrifting(tester);
      await tester.pump(_ms(700));
      final drifted = displayedCamera(tester);
      expect(drifted.gy, lessThan(coverCamera.gy));

      await tester.pumpWidget(buildGlobeScene(camera: _target));
      expect(displayedCamera(tester), drifted);
      await tester.pump();
      expect(displayedCamera(tester), drifted);

      await tester.pump(flyDuration);
      expect(displayedCamera(tester), _target);
    });

    testWidgets('resumes after the flight ends if there is no selection', (
      tester,
    ) async {
      await _pumpDrifting(tester);
      await tester.pumpWidget(buildGlobeScene(camera: _target));
      await tester.pump();
      await tester.pump(flyDuration);
      expect(displayedCamera(tester), _target);
      // El vuelo termina estrictamente después de su duración.
      await tester.pump(_ms(1));
      await tester.pump(driftStep);
      expect(_gy(tester), closeTo(_target.gy - driftDegreesPerStep, _epsilon));
      expect(displayedCamera(tester).scale, _target.scale);
    });

    testWidgets('does not resume after a flight while a case is selected', (
      tester,
    ) async {
      await pumpGlobeScene(tester, selectedId: _selected);
      await tester.pumpWidget(
        buildGlobeScene(camera: _target, selectedId: _selected),
      );
      await tester.pump();
      await tester.pump(flyDuration);
      await tester.pump(_ms(500));
      expect(displayedCamera(tester), _target);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('resumes after the flight when the selection is cleared', (
      tester,
    ) async {
      await pumpGlobeScene(tester, selectedId: _selected);
      await tester.pumpWidget(
        buildGlobeScene(camera: _target, selectedId: _selected),
      );
      await tester.pump();
      await tester.pump(flyDuration);
      await tester.pump(_ms(1));
      await tester.pumpWidget(buildGlobeScene(camera: _target));
      await tester.pump();
      await tester.pump(driftStep);
      expect(_gy(tester), closeTo(_target.gy - driftDegreesPerStep, _epsilon));
    });

    testWidgets('a camera change mid-flight keeps the drift reset', (
      tester,
    ) async {
      await _pumpDrifting(tester);
      await tester.pump(_ms(300));
      await tester.pumpWidget(buildGlobeScene(camera: _target));
      await tester.pump();
      await tester.pump(_ms(400));
      final current = displayedCamera(tester);
      await tester.pumpWidget(buildGlobeScene(camera: coverCamera));
      await tester.pump();
      expect(displayedCamera(tester), current);
      await tester.pump(flyDuration);
      expect(displayedCamera(tester), coverCamera);
    });
  });

  group('reduced motion', () {
    testWidgets('has no ticker, no drift and no scheduled frames', (
      tester,
    ) async {
      await pumpGlobeScene(
        tester,
        disableAnimations: true,
        connections: const [facingEast],
      );
      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pump(_ms(1000));
      expect(displayedCamera(tester), coverCamera);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('shows every arc dot at once', (tester) async {
      await pumpGlobeScene(
        tester,
        disableAnimations: true,
        selectedId: _selected,
        connections: const [facingEast],
      );
      expect(arcPainter(tester).elapsedOf('facing>east'), arcRevealTotal);
      final canvas = TestRecordingCanvas();
      arcPainter(tester).paint(canvas, desktop);
      expect(calls(canvas, #drawCircle), hasLength(27 * 2));
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('a connection added later also appears at once', (
      tester,
    ) async {
      await pumpGlobeScene(tester, disableAnimations: true);
      await tester.pumpWidget(
        buildGlobeScene(
          disableAnimations: true,
          connections: const [facingEast],
        ),
      );
      expect(arcPainter(tester).elapsedOf('facing>east'), arcRevealTotal);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('turning it on mid-drift stops the drift', (tester) async {
      await _pumpDrifting(tester);
      await tester.pump(_ms(700));
      final drifted = displayedCamera(tester);
      await tester.pumpWidget(buildGlobeScene(disableAnimations: true));
      expect(tester.hasRunningAnimations, isFalse);
      await tester.pump(_ms(1000));
      expect(displayedCamera(tester), drifted);
    });

    testWidgets('turning it on mid-reveal shows the arc in full', (
      tester,
    ) async {
      await pumpGlobeScene(
        tester,
        selectedId: _selected,
        connections: const [facingEast],
      );
      await tester.pump();
      await tester.pump(_ms(500));
      await tester.pumpWidget(
        buildGlobeScene(
          selectedId: _selected,
          disableAnimations: true,
          connections: const [facingEast],
        ),
      );
      expect(arcPainter(tester).elapsedOf('facing>east'), arcRevealTotal);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('cuts the flight and keeps the camera still', (tester) async {
      await pumpGlobeScene(tester, disableAnimations: true);
      await tester.pumpWidget(
        buildGlobeScene(camera: _target, disableAnimations: true),
      );
      expect(displayedCamera(tester), _target);
      await tester.pump(_ms(1000));
      expect(displayedCamera(tester), _target);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('settling', () {
    testWidgets('pumpAndSettle terminates with a selection', (tester) async {
      await pumpGlobeScene(
        tester,
        selectedId: _selected,
        connections: const [facingEast],
      );
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('pumpAndSettle terminates under reduced motion', (
      tester,
    ) async {
      await pumpGlobeScene(
        tester,
        disableAnimations: true,
        connections: const [facingEast],
      );
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('pumpAndSettle terminates after a flight with a selection', (
      tester,
    ) async {
      await pumpGlobeScene(tester, selectedId: _selected);
      await tester.pumpWidget(
        buildGlobeScene(camera: _target, selectedId: _selected),
      );
      await tester.pumpAndSettle();
      expect(displayedCamera(tester), _target);
    });

    testWidgets('drifting keeps the scene animating until a selection', (
      tester,
    ) async {
      await _pumpDrifting(tester);
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpWidget(buildGlobeScene(selectedId: _selected));
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('interaction while the effects run', () {
    testWidgets('a tap hits the marker where the drift put it', (tester) async {
      final taps = <String>[];
      await _pumpDrifting(tester, onMarkerTap: taps.add);
      await tester.pump(_ms(2000));
      final at = placementOf(tester, 'facing').center;
      expect(at, isNot(projectMarker(facing, coverCamera).screen));
      await tester.tapAt(at);
      expect(taps, ['facing']);
    });

    testWidgets('arc dots do not intercept taps', (tester) async {
      final taps = <String>[];
      await pumpGlobeScene(
        tester,
        selectedId: _selected,
        connections: const [facingEast],
        onMarkerTap: taps.add,
      );
      await tester.pump(arcRevealTotal);
      await tester.tapAt(projectMarker(east, coverCamera).screen);
      await tester.tapAt(projectMarker(facing, coverCamera).screen);
      await tester.tapAt(_emptySpot);
      expect(taps, ['east', 'facing']);
    });

    testWidgets('the arc layer ignores pointers and semantics', (tester) async {
      await pumpGlobeScene(tester, connections: const [facingEast]);
      final finder = painterFinder<DsGlobeArcPainter>();
      expect(finder, findsOneWidget);
      expect(
        find.ancestor(of: finder, matching: find.byType(IgnorePointer)),
        findsWidgets,
      );
      expect(
        find.ancestor(of: finder, matching: find.byType(ExcludeSemantics)),
        findsWidgets,
      );
    });

    testWidgets('semantics are the same with and without effects', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpGlobeScene(tester, onMarkerTap: (_) {});
      final reference = [for (final node in buttonNodes(tester)) node.label];
      await pumpGlobeScene(
        tester,
        connections: const [facingEast, eastNearLimb],
        onMarkerTap: (_) {},
      );
      await tester.pump();
      await tester.pump(_ms(1500));
      expect([for (final node in buttonNodes(tester)) node.label], reference);
      expect(reference, isNotEmpty);
      handle.dispose();
    });
  });

  group('robustness', () {
    for (final size in [desktop, fullHd]) {
      testWidgets('runs the effects at ${size.width}x${size.height}', (
        tester,
      ) async {
        await _pumpDrifting(
          tester,
          size: size,
          connections: const [facingEast, eastNearLimb],
        );
        await tester.pump(_ms(3000));
        expect(tester.takeException(), isNull);
        expect(tester.getSize(find.byType(DsGlobeScene)), size);
      });
    }

    testWidgets('ignores the text scale 2.0', (tester) async {
      await _pumpDrifting(
        tester,
        connections: const [facingEast],
        textScale: 2,
      );
      await tester.pump(_ms(3000));
      expect(tester.takeException(), isNull);
      final canvas = TestRecordingCanvas();
      arcPainter(tester).paint(canvas, desktop);
      expect(calls(canvas, #drawCircle), isNotEmpty);
    });
  });
}
