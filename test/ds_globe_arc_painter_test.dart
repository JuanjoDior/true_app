import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';

import 'test_support/ds_globe_scene_test_support.dart';

const int _dotCount = 27;
const int _firstDelayMs = 900;
const int _intervalMs = 35;
const int _fadeMs = 200;
const double _dotDiameter = 5;
const double _sigmaPerRadius = 0.5;
const int _lateYear = 1980;

const DsGlobeArcSpec _arc = DsGlobeArcSpec(
  key: 'facing>east',
  from: facing,
  to: east,
);

Duration _ms(int value) => Duration(milliseconds: value);

Duration _full(String key) => arcRevealTotal;

DsGlobeArcPainter _painter({
  DsGlobeCamera? camera,
  List<DsGlobeArcSpec> arcs = const [_arc],
  Duration? elapsed,
}) => DsGlobeArcPainter(
  camera: camera ?? coverCamera,
  arcs: arcs,
  elapsedOf: elapsed == null ? _full : (_) => elapsed,
);

typedef _Dot = ({Offset center, double radius, Paint paint});

List<_Dot> _circles(DsGlobeArcPainter painter, {required bool glow}) {
  final canvas = TestRecordingCanvas();
  painter.paint(canvas, desktop);
  return [
    for (final args in calls(canvas, #drawCircle))
      if (((args[2]! as Paint).maskFilter != null) == glow)
        (
          center: args[0]! as Offset,
          radius: args[1]! as double,
          paint: args[2]! as Paint,
        ),
  ];
}

List<DsGlobeVector> _arcPoints(DsMapMarker a, DsMapMarker b) =>
    DsGlobeMath.arcPoints(
      latitudeA: a.latitude,
      longitudeA: a.longitude,
      latitudeB: b.latitude,
      longitudeB: b.longitude,
    );

DsGlobeProjection _project(DsGlobeVector point, DsGlobeCamera camera) =>
    DsGlobeMath.project(
      point,
      gx: camera.gx,
      gy: camera.gy,
      center: camera.center,
      scale: camera.scale,
    );

void main() {
  group('dotOpacity', () {
    test('dot 0 is hidden up to 900 ms and full at 1100 ms', () {
      expect(DsGlobeArcReveal.dotOpacity(0, _ms(899)), 0);
      expect(DsGlobeArcReveal.dotOpacity(0, _ms(900)), 0);
      expect(DsGlobeArcReveal.dotOpacity(0, _ms(1000)), closeTo(0.5, 1e-9));
      expect(DsGlobeArcReveal.dotOpacity(0, _ms(1100)), 1);
    });

    test('dot 26 is hidden up to 1810 ms and full at 2010 ms', () {
      expect(DsGlobeArcReveal.dotOpacity(26, _ms(1809)), 0);
      expect(DsGlobeArcReveal.dotOpacity(26, _ms(1810)), 0);
      expect(DsGlobeArcReveal.dotOpacity(26, _ms(1910)), closeTo(0.5, 1e-9));
      expect(DsGlobeArcReveal.dotOpacity(26, _ms(2010)), 1);
    });

    test('every dot starts at 900 + k * 35 ms and fades in 200 ms', () {
      for (var k = 0; k < _dotCount; k++) {
        final start = _firstDelayMs + _intervalMs * k;
        expect(DsGlobeArcReveal.dotOpacity(k, _ms(start - 1)), 0, reason: '$k');
        expect(DsGlobeArcReveal.dotOpacity(k, _ms(start)), 0, reason: '$k');
        expect(
          DsGlobeArcReveal.dotOpacity(k, _ms(start + _fadeMs ~/ 2)),
          closeTo(0.5, 1e-9),
          reason: '$k',
        );
        expect(
          DsGlobeArcReveal.dotOpacity(k, _ms(start + _fadeMs)),
          1,
          reason: '$k',
        );
        expect(DsGlobeArcReveal.dotOpacity(k, _ms(start + 5000)), 1);
      }
    });

    test('later dots are never more visible than earlier ones', () {
      for (var ms = 0; ms <= 2100; ms += 7) {
        for (var k = 1; k < _dotCount; k++) {
          expect(
            DsGlobeArcReveal.dotOpacity(k, _ms(ms)),
            lessThanOrEqualTo(DsGlobeArcReveal.dotOpacity(k - 1, _ms(ms))),
            reason: 'k=$k at $ms ms',
          );
        }
      }
    });

    test('is always within 0..1 and rises monotonically with time', () {
      for (var k = 0; k < _dotCount; k++) {
        var previous = 0.0;
        for (var ms = 0; ms <= 2100; ms += 5) {
          final value = DsGlobeArcReveal.dotOpacity(k, _ms(ms));
          expect(value, inInclusiveRange(0, 1));
          expect(value, greaterThanOrEqualTo(previous));
          previous = value;
        }
      }
    });

    test('nothing is visible at zero and everything at the total', () {
      for (var k = 0; k < _dotCount; k++) {
        expect(DsGlobeArcReveal.dotOpacity(k, Duration.zero), 0);
        expect(DsGlobeArcReveal.dotOpacity(k, DsGlobeArcReveal.total), 1);
      }
      expect(DsGlobeArcReveal.total, arcRevealTotal);
    });
  });

  group('layout', () {
    List<DsGlobePlacedMarker> placedAt({int? year}) =>
        DsGlobeMarkerProjection.place(
          markers: sampleMarkers,
          camera: coverCamera,
          selectedId: null,
          relatedIds: const {},
          matchingIds: null,
          timelineYear: year,
        );

    test('builds one arc per connection between front markers', () {
      final arcs = DsGlobeArcLayout.visible(
        connections: const [facingEast, eastNearLimb],
        placed: placedAt(),
      );
      expect(
        [for (final arc in arcs) arc.key],
        ['facing>east', 'east>near-limb'],
      );
      expect(arcs.first.from, facing);
      expect(arcs.first.to, east);
    });

    test('skips unknown ids silently', () {
      final arcs = DsGlobeArcLayout.visible(
        connections: const [
          DsMapConnection(fromId: 'facing', toId: 'ghost', label: ''),
          DsMapConnection(fromId: 'ghost', toId: 'east', label: ''),
        ],
        placed: placedAt(),
      );
      expect(arcs, isEmpty);
    });

    test('skips an endpoint on the back face', () {
      final arcs = DsGlobeArcLayout.visible(
        connections: const [
          DsMapConnection(fromId: 'facing', toId: 'back', label: ''),
        ],
        placed: placedAt(),
      );
      expect(arcs, isEmpty);
    });

    test('skips an endpoint hidden by the timeline year', () {
      final arcs = DsGlobeArcLayout.visible(
        connections: const [facingEast],
        placed: placedAt(year: _lateYear),
      );
      expect(arcs, isEmpty);
    });

    test('skips a connection from a marker to itself', () {
      final arcs = DsGlobeArcLayout.visible(
        connections: const [
          DsMapConnection(fromId: 'east', toId: 'east', label: ''),
        ],
        placed: placedAt(),
      );
      expect(arcs, isEmpty);
    });

    test('returns nothing without connections', () {
      expect(
        DsGlobeArcLayout.visible(connections: const [], placed: placedAt()),
        isEmpty,
      );
    });

    test('reveal keys cover every known pair regardless of visibility', () {
      final keys = DsGlobeArcLayout.keys(
        connections: const [
          facingEast,
          DsMapConnection(fromId: 'facing', toId: 'back', label: ''),
          DsMapConnection(fromId: 'facing', toId: 'ghost', label: ''),
          DsMapConnection(fromId: 'east', toId: 'east', label: ''),
        ],
        markers: sampleMarkers,
      );
      expect(keys, {'facing>east', 'facing>back'});
    });

    test('keys are ordered by endpoint', () {
      final keys = DsGlobeArcLayout.keys(
        connections: const [
          DsMapConnection(fromId: 'east', toId: 'facing', label: ''),
        ],
        markers: sampleMarkers,
      );
      expect(keys, {'east>facing'});
    });
  });

  group('painter', () {
    test('draws 27 dots at the projected arc points', () {
      final dots = _circles(_painter(), glow: false);
      final points = _arcPoints(facing, east);
      expect(dots, hasLength(_dotCount));
      for (var k = 0; k < _dotCount; k++) {
        final expected = _project(points[k], coverCamera);
        expect(dots[k].center.dx, closeTo(expected.screen.dx, tolerance));
        expect(dots[k].center.dy, closeTo(expected.screen.dy, tolerance));
      }
    });

    test('the first and last dots sit on the endpoint markers directions', () {
      final dots = _circles(_painter(), glow: false);
      // En el centro de la cámara de portada x = y = 0, así que el primer punto cae sobre el marcador.
      expect(dots.first.center.dx, closeTo(1010, tolerance));
      expect(dots.first.center.dy, closeTo(520, tolerance));
      expect(
        dots.first.center,
        offsetMoreOrLessEquals(
          projectMarker(facing, coverCamera).screen,
          epsilon: tolerance,
        ),
      );
      final lastDirection = _project(
        DsGlobeMath.surfacePoint(
          latitude: east.latitude,
          longitude: east.longitude,
          radius: DsGlobeMath.radius + DsGlobeMath.arcBaseElevation,
        ),
        coverCamera,
      );
      expect(dots.last.center.dx, closeTo(lastDirection.screen.dx, tolerance));
      expect(dots.last.center.dy, closeTo(lastDirection.screen.dy, tolerance));
    });

    test('paints a glow under each dot, in that order', () {
      final canvas = TestRecordingCanvas();
      _painter().paint(canvas, desktop);
      final circles = calls(canvas, #drawCircle);
      expect(circles, hasLength(_dotCount * 2));
      for (var k = 0; k < _dotCount; k++) {
        expect((circles[2 * k][2]! as Paint).maskFilter, isNotNull);
        expect((circles[2 * k + 1][2]! as Paint).maskFilter, isNull);
        expect(circles[2 * k][0], circles[2 * k + 1][0]);
      }
    });

    test('dots are gold and fully opaque once revealed', () {
      for (final dot in _circles(_painter(), glow: false)) {
        expect(dot.paint.color.a, 1);
        // Paint guarda los canales en float32.
        expect(dot.paint.color.r, closeTo(DsColors.accentGold.r, tolerance));
        expect(dot.paint.color.g, closeTo(DsColors.accentGold.g, tolerance));
        expect(dot.paint.color.b, closeTo(DsColors.accentGold.b, tolerance));
      }
      for (final glow in _circles(_painter(), glow: true)) {
        expect(glow.paint.color.a, inExclusiveRange(0, 1));
        expect(glow.paint.color.r, closeTo(DsColors.accentGold.r, tolerance));
      }
    });

    test('draws nothing for the dots behind the sphere', () {
      const behind = DsMapMarker(
        id: 'a',
        label: 'A',
        latitude: 0,
        longitude: 150,
        color: Color(0xFFFFFFFF),
        year: 2000,
      );
      const farBehind = DsMapMarker(
        id: 'b',
        label: 'B',
        latitude: 20,
        longitude: 200,
        color: Color(0xFFFFFFFF),
        year: 2000,
      );
      final dots = _circles(
        _painter(
          arcs: const [DsGlobeArcSpec(key: 'a>b', from: behind, to: farBehind)],
        ),
        glow: false,
      );
      expect(dots, isEmpty);
    });

    test('draws only the dots with z2 > 0 on an arc that crosses the limb', () {
      final points = _arcPoints(facing, back);
      final expected = [
        for (final point in points)
          if (_project(point, coverCamera).isFront) point,
      ];
      expect(expected.length, inExclusiveRange(0, _dotCount));
      final dots = _circles(
        _painter(
          arcs: const [DsGlobeArcSpec(key: 'f>b', from: facing, to: back)],
        ),
        glow: false,
      );
      expect(dots, hasLength(expected.length));
      for (var k = 0; k < expected.length; k++) {
        final projected = _project(expected[k], coverCamera).screen;
        expect(dots[k].center.dx, closeTo(projected.dx, tolerance));
      }
    });

    test('dot size follows camera scale and perspective', () {
      for (final camera in [coverCamera, exploreCamera]) {
        final dots = _circles(_painter(camera: camera), glow: false);
        final points = _arcPoints(facing, east);
        for (var k = 0; k < dots.length; k++) {
          final projection = _project(points[k], camera);
          expect(
            dots[k].radius,
            closeTo(
              _dotDiameter / 2 * camera.scale * projection.perspectiveFactor,
              tolerance,
            ),
          );
        }
      }
      expect(exploreCamera.scale, lessThan(coverCamera.scale));
    });

    test('glow blur follows camera scale and perspective', () {
      for (final camera in [coverCamera, exploreCamera]) {
        final glows = _circles(_painter(camera: camera), glow: true);
        final points = _arcPoints(facing, east);
        for (var k = 0; k < glows.length; k++) {
          final projection = _project(points[k], camera);
          final sigma =
              DsGlobeStyle.arcGlowRadius *
              _sigmaPerRadius *
              camera.scale *
              projection.perspectiveFactor;
          // Paint guarda sigma en float32: se compara contra el mismo recorrido.
          final expected =
              (Paint()..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma))
                  .maskFilter;
          expect(glows[k].paint.maskFilter, expected);
          expect(
            glows[k].radius,
            closeTo(
              _dotDiameter / 2 * camera.scale * projection.perspectiveFactor,
              tolerance,
            ),
          );
        }
      }
    });

    test('nothing is drawn before the first dot appears', () {
      expect(_circles(_painter(elapsed: _ms(899)), glow: false), isEmpty);
      expect(_circles(_painter(elapsed: _ms(900)), glow: false), isEmpty);
      expect(_circles(_painter(elapsed: _ms(899)), glow: true), isEmpty);
    });

    test('dots appear sequentially with the opacity of the reveal', () {
      final dots = _circles(_painter(elapsed: _ms(1000)), glow: false);
      expect(dots, hasLength(3));
      expect(dots[0].paint.color.a, closeTo(0.5, tolerance));
      expect(dots[1].paint.color.a, closeTo(0.325, tolerance));
      expect(dots[2].paint.color.a, closeTo(0.15, tolerance));
      final glows = _circles(_painter(elapsed: _ms(1000)), glow: true);
      expect(glows[0].paint.color.a, lessThan(dots[0].paint.color.a));
    });

    test('each arc reads its own elapsed time by key', () {
      final painter = DsGlobeArcPainter(
        camera: coverCamera,
        arcs: const [
          _arc,
          DsGlobeArcSpec(key: 'east>near-limb', from: east, to: nearLimb),
        ],
        elapsedOf: (key) => key == 'facing>east' ? arcRevealTotal : _ms(1000),
      );
      expect(_circles(painter, glow: false), hasLength(_dotCount + 3));
    });

    test('with no arcs it draws nothing', () {
      final canvas = TestRecordingCanvas();
      _painter(arcs: const []).paint(canvas, desktop);
      expect(canvas.invocations, isEmpty);
    });

    test('repaints when the camera, arcs or clock source change', () {
      final base = _painter();
      expect(base.shouldRepaint(_painter()), isFalse);
      expect(base.shouldRepaint(_painter(camera: exploreCamera)), isTrue);
      expect(base.shouldRepaint(_painter(arcs: const [])), isTrue);
      expect(
        base.shouldRepaint(
          DsGlobeArcPainter(
            camera: coverCamera,
            arcs: const [_arc],
            elapsedOf: (_) => Duration.zero,
          ),
        ),
        isTrue,
      );
    });
  });
}
