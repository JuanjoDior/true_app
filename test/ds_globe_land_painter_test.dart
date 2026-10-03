import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';

import 'test_support/ds_globe_scene_test_support.dart';

const double _quantum = 0.5;
// "Unas pocas docenas" de llamadas de dibujo como máximo.
const int _maxBuckets = 80;
// Valores observados: 6 opacidades por unos 12 diámetros de 0,5 px.
const int _coverBuckets = 73;
const int _exploreBuckets = 54;

// Independiente del painter: proyecta cada celda con DsGlobeMath.project.
List<({DsLandCell cell, DsGlobeProjection projection})> _projected(
  DsGlobeCamera camera,
) => [
  for (final cell in DsLandGrid.cells)
    (
      cell: cell,
      projection: DsGlobeMath.project(
        DsGlobeMath.surfacePoint(
          latitude: cell.latitude,
          longitude: cell.longitude,
        ),
        gx: camera.gx,
        gy: camera.gy,
        center: camera.center,
        scale: camera.scale,
      ),
    ),
];

int _frontCount(DsGlobeCamera camera) =>
    _projected(camera).where((p) => p.projection.isFront).length;

double _quantized(double diameter) => (diameter / _quantum).round() * _quantum;

int _dotCount(List<DsGlobeLandBucket> buckets) =>
    buckets.fold(0, (sum, b) => sum + b.points.length);

DsGlobeCamera _facing(double latitude, double longitude) =>
    DsGlobeCameraTargets.cover(
      latitude: latitude,
      longitude: longitude,
      currentGy: 0,
    );

void main() {
  final cameras = <String, DsGlobeCamera>{
    'cover': coverCamera,
    'explore': exploreCamera,
    'north': _facing(60, -100),
    'south': _facing(-45, 120),
  };

  group('front cells', () {
    for (final entry in cameras.entries) {
      test('dot count equals the independently projected front cells '
          '(${entry.key})', () {
        final buckets = DsGlobeLandPainter.buckets(entry.value);
        expect(_dotCount(buckets), _frontCount(entry.value));
        expect(_dotCount(buckets), lessThan(DsLandGrid.cells.length));
        expect(_dotCount(buckets), greaterThan(0));
      });
    }

    test('no back-face cell is drawn', () {
      final camera = cameras['north']!;
      final projected = _projected(camera);
      final drawn = <Offset>{
        for (final bucket in DsGlobeLandPainter.buckets(camera))
          ...bucket.points,
      };
      final front = {
        for (final p in projected)
          if (p.projection.isFront) p.projection.screen,
      };
      expect(drawn, front);
      final back = projected.where((p) => !p.projection.isFront);
      expect(back, isNotEmpty);
      expect(back.where((p) => drawn.contains(p.projection.screen)), isEmpty);
    });

    test('points are screen positions of the projected cells', () {
      final first = _projected(
        coverCamera,
      ).firstWhere((p) => p.projection.isFront);
      final points = [
        for (final b in DsGlobeLandPainter.buckets(coverCamera)) ...b.points,
      ];
      expect(points, contains(first.projection.screen));
    });
  });

  group('buckets', () {
    for (final entry in cameras.entries) {
      test('are keyed by opacity and a 0.5 px diameter (${entry.key})', () {
        final buckets = DsGlobeLandPainter.buckets(entry.value);
        final keys = {for (final b in buckets) (b.opacity, b.diameter)};
        expect(keys, hasLength(buckets.length));
        final opacities = {for (final cell in DsLandGrid.cells) cell.opacity};
        for (final bucket in buckets) {
          expect(opacities, contains(bucket.opacity));
          expect(
            bucket.diameter / _quantum,
            closeTo((bucket.diameter / _quantum).roundToDouble(), 1e-9),
          );
          expect(bucket.points, isNotEmpty);
        }
      });

      test('stay bounded at the ${entry.key} camera', () {
        final count = DsGlobeLandPainter.buckets(entry.value).length;
        expect(count, lessThanOrEqualTo(_maxBuckets));
        expect(count, greaterThan(1));
      });
    }

    test('are sorted by opacity then diameter', () {
      final buckets = DsGlobeLandPainter.buckets(coverCamera);
      for (var i = 1; i < buckets.length; i++) {
        final a = buckets[i - 1];
        final b = buckets[i];
        expect(
          a.opacity < b.opacity ||
              (a.opacity == b.opacity && a.diameter < b.diameter),
          isTrue,
        );
      }
    });

    test('every dot lands in the bucket of its own opacity and diameter', () {
      final camera = coverCamera;
      final buckets = DsGlobeLandPainter.buckets(camera);
      for (final p in _projected(camera).where((p) => p.projection.isFront)) {
        final diameter = _quantized(
          DsGlobeMath.landDotSize(p.cell.latitude) *
              camera.scale *
              p.projection.perspectiveFactor,
        );
        final bucket = buckets.singleWhere(
          (b) => b.opacity == p.cell.opacity && b.diameter == diameter,
        );
        expect(bucket.points, contains(p.projection.screen));
      }
    });
  });

  group('dot size', () {
    test('equator dots are larger than near-pole dots at the same depth', () {
      final camera = coverCamera;
      final projected = _projected(camera).where((p) => p.projection.isFront);
      final equator = projected.reduce(
        (a, b) => a.cell.latitude.abs() <= b.cell.latitude.abs() ? a : b,
      );
      final polar = projected.reduce(
        (a, b) => a.cell.latitude.abs() >= b.cell.latitude.abs() ? a : b,
      );
      double diameterOf(({DsLandCell cell, DsGlobeProjection projection}) p) =>
          DsGlobeLandPainter.buckets(camera)
              .singleWhere(
                (b) =>
                    b.opacity == p.cell.opacity &&
                    b.points.contains(p.projection.screen),
              )
              .diameter;
      expect(diameterOf(equator), greaterThan(diameterOf(polar)));
      expect(
        diameterOf(equator),
        _quantized(
          DsGlobeMath.landDotSize(equator.cell.latitude) *
              equator.projection.perspectiveFactor,
        ),
      );
      expect(polar.cell.latitude.abs(), greaterThan(60));
    });

    test('hand-computed: a 0 deg cell facing the camera is 8.8 px', () {
      // 7.2 * f, con f = 2200 / (2200 - 400) = 1.2222 (celda de radio R).
      final equator = _projected(coverCamera)
          .where((p) => p.projection.isFront)
          .reduce(
            (a, b) => a.cell.latitude.abs() <= b.cell.latitude.abs() ? a : b,
          );
      final expected = _quantized(
        (6.4 * math.cos(equator.cell.latitude * math.pi / 180) + 0.8) *
            2200 /
            (2200 - equator.projection.depth),
      );
      final bucket = DsGlobeLandPainter.buckets(
        coverCamera,
      ).singleWhere((b) => b.points.contains(equator.projection.screen));
      expect(bucket.diameter, expected);
    });

    test('scales with camera.scale', () {
      final full = DsGlobeLandPainter.buckets(coverCamera);
      final half = DsGlobeLandPainter.buckets(
        coverCamera.copyWith(scale: coverCamera.scale / 2),
      );
      double mean(List<DsGlobeLandBucket> buckets) {
        var weighted = 0.0;
        for (final b in buckets) {
          weighted += b.diameter * b.points.length;
        }
        return weighted / _dotCount(buckets);
      }

      expect(mean(half), lessThan(mean(full)));
    });
  });

  group('paint', () {
    test('issues one drawPoints per bucket and nothing else', () {
      final canvas = TestRecordingCanvas();
      DsGlobeLandPainter(camera: coverCamera).paint(canvas, desktop);
      final buckets = DsGlobeLandPainter.buckets(coverCamera);
      final draws = calls(canvas, #drawPoints);
      expect(draws, hasLength(buckets.length));
      expect(calls(canvas, #drawCircle), isEmpty);
      expect(calls(canvas, #transform), isEmpty);
      expect(_dotCount(buckets), _frontCount(coverCamera));
    });

    test('each bucket is a round stroke of its diameter and opacity', () {
      final canvas = TestRecordingCanvas();
      DsGlobeLandPainter(camera: coverCamera).paint(canvas, desktop);
      final buckets = DsGlobeLandPainter.buckets(coverCamera);
      final draws = calls(canvas, #drawPoints);
      for (var i = 0; i < buckets.length; i++) {
        final args = draws[i];
        expect(args[0], PointMode.points);
        expect(args[1], buckets[i].points);
        final paint = args[2]! as Paint;
        expect(paint.strokeWidth, buckets[i].diameter);
        expect(paint.strokeCap, StrokeCap.round);
        expect(paint.style, PaintingStyle.stroke);
        expect(paint.color.toARGB32() & 0x00FFFFFF, 0x0033405A);
        expect(paint.color.a, closeTo(buckets[i].opacity, 0.005));
      }
    });

    test('uses the flat land color token', () {
      final canvas = TestRecordingCanvas();
      DsGlobeLandPainter(camera: coverCamera).paint(canvas, desktop);
      final paint = calls(canvas, #drawPoints).first[2]! as Paint;
      expect(
        paint.color.withValues(alpha: 1).toARGB32(),
        DsColors.landDotFlat.toARGB32(),
      );
    });

    test('repaints only when the camera changes', () {
      final base = DsGlobeLandPainter(camera: coverCamera);
      expect(
        base.shouldRepaint(DsGlobeLandPainter(camera: coverCamera)),
        isFalse,
      );
      expect(
        base.shouldRepaint(DsGlobeLandPainter(camera: exploreCamera)),
        isTrue,
      );
    });
  });

  test('draw calls recorded at the cover and explore cameras', () {
    expect(DsGlobeLandPainter.buckets(coverCamera), hasLength(_coverBuckets));
    expect(
      DsGlobeLandPainter.buckets(exploreCamera),
      hasLength(_exploreBuckets),
    );
  });
}
