import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:true_app/core/design/design.dart';

const double _tolerance = 1e-9;
const double _fullTurn = 360;
const double _halfTurn = 180;
const double _scaleCover = 1.0;
const double _scaleExplore = 0.78;
const Offset _centerCover = Offset(1010, 520);
const Offset _centerExplore = Offset(640, 455);

double _norm(DsGlobeVector v) => math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z);

double _dot(DsGlobeVector a, DsGlobeVector b) =>
    a.x * b.x + a.y * b.y + a.z * b.z;

DsGlobeVector _cross(DsGlobeVector a, DsGlobeVector b) => DsGlobeVector(
  x: a.y * b.z - a.z * b.y,
  y: a.z * b.x - a.x * b.z,
  z: a.x * b.y - a.y * b.x,
);

DsGlobeVector _unit(double latitude, double longitude) =>
    DsGlobeMath.surfacePoint(
      latitude: latitude,
      longitude: longitude,
      radius: 1,
    );

void _expectVector(DsGlobeVector actual, double x, double y, double z) {
  expect(actual.x, closeTo(x, _tolerance));
  expect(actual.y, closeTo(y, _tolerance));
  expect(actual.z, closeTo(z, _tolerance));
}

void main() {
  group('constants', () {
    test('match the design spec', () {
      expect(DsGlobeMath.radius, 400);
      expect(DsGlobeMath.perspective, 2200);
      expect(DsGlobeMath.markerElevation, 3);
      expect(DsGlobeMath.arcBaseElevation, 4);
      expect(DsGlobeMath.arcLiftFactor, 70);
      expect(DsGlobeMath.visibilityThreshold, 40);
      expect(DsGlobeMath.minLandDotSize, 3.2);
      expect(DsGlobeMath.landDotBase, 0.8);
      expect(DsGlobeMath.landDotLatitudeFactor, 6.4);
    });
  });

  group('DsGlobeVector', () {
    test('has value equality', () {
      const a = DsGlobeVector(x: 1, y: 2, z: 3);
      const b = DsGlobeVector(x: 1, y: 2, z: 3);
      const c = DsGlobeVector(x: 1, y: 2, z: 4);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });
  });

  group('surfacePoint', () {
    test('(0, 0) faces the viewer', () {
      _expectVector(
        DsGlobeMath.surfacePoint(latitude: 0, longitude: 0),
        0,
        0,
        400,
      );
    });

    test('(0, 90) points right', () {
      _expectVector(
        DsGlobeMath.surfacePoint(latitude: 0, longitude: 90),
        400,
        0,
        0,
      );
    });

    test('(90, 0) is the north pole, y down is negative', () {
      _expectVector(
        DsGlobeMath.surfacePoint(latitude: 90, longitude: 0),
        0,
        -400,
        0,
      );
    });

    test('(-90, 0) is the south pole', () {
      _expectVector(
        DsGlobeMath.surfacePoint(latitude: -90, longitude: 0),
        0,
        400,
        0,
      );
    });

    test('honours a custom radius', () {
      final p = DsGlobeMath.surfacePoint(
        latitude: 30,
        longitude: 45,
        radius: DsGlobeMath.radius + DsGlobeMath.markerElevation,
      );
      expect(_norm(p), closeTo(403, _tolerance));
    });
  });

  group('rotate', () {
    test('is the identity at gx = gy = 0', () {
      const p = DsGlobeVector(x: 12, y: -34, z: 56);
      final r = DsGlobeMath.rotate(p, gx: 0, gy: 0);
      expect(r.x, closeTo(12, _tolerance));
      expect(r.y, closeTo(-34, _tolerance));
      expect(r.z, closeTo(56, _tolerance));
    });

    test('gy = 90 sends +x to -z', () {
      const p = DsGlobeVector(x: 100, y: 0, z: 0);
      final r = DsGlobeMath.rotate(p, gx: 0, gy: 90);
      expect(r.x, closeTo(0, _tolerance));
      expect(r.y, closeTo(0, _tolerance));
      expect(r.z, closeTo(-100, _tolerance));
    });

    test('gx = 90 sends +z to -y', () {
      const p = DsGlobeVector(x: 0, y: 0, z: 100);
      final r = DsGlobeMath.rotate(p, gx: 90, gy: 0);
      expect(r.x, closeTo(0, _tolerance));
      expect(r.y, closeTo(-100, _tolerance));
      expect(r.z, closeTo(0, _tolerance));
    });
  });

  group('project', () {
    test(
      'identity orientation puts (0, 0) at the center with factor from z',
      () {
        final p = DsGlobeMath.surfacePoint(latitude: 0, longitude: 0);
        final projection = DsGlobeMath.project(
          p,
          gx: 0,
          gy: 0,
          center: _centerCover,
          scale: _scaleCover,
        );
        expect(projection.screen.dx, closeTo(_centerCover.dx, _tolerance));
        expect(projection.screen.dy, closeTo(_centerCover.dy, _tolerance));
        expect(projection.depth, closeTo(400, _tolerance));
        expect(
          projection.perspectiveFactor,
          closeTo(2200 / (2200 - 1.0 * 400), _tolerance),
        );
        expect(projection.isFront, isTrue);
        expect(projection.isLabelVisible, isTrue);
      },
    );

    test('applies X = cx + s*x1*f and Y = cy + s*y2*f', () {
      final p = DsGlobeMath.surfacePoint(latitude: 0, longitude: 90);
      final projection = DsGlobeMath.project(
        p,
        gx: 0,
        gy: 0,
        center: _centerExplore,
        scale: _scaleExplore,
      );
      final f = 2200 / (2200 - _scaleExplore * projection.depth);
      expect(projection.perspectiveFactor, closeTo(f, _tolerance));
      expect(
        projection.screen.dx,
        closeTo(_centerExplore.dx + _scaleExplore * 400 * f, _tolerance),
      );
      expect(projection.screen.dy, closeTo(_centerExplore.dy, _tolerance));
    });

    test('far side point is not front nor label-visible', () {
      final p = DsGlobeMath.surfacePoint(latitude: 0, longitude: 180);
      final projection = DsGlobeMath.project(
        p,
        gx: 0,
        gy: 0,
        center: _centerCover,
        scale: _scaleCover,
      );
      expect(projection.depth, closeTo(-400, _tolerance));
      expect(projection.isFront, isFalse);
      expect(projection.isLabelVisible, isFalse);
    });

    test('limb points are front but below the label threshold', () {
      // z2 = 400 * sin(5°) ≈ 34.9 < 40 pero > 0
      final p = DsGlobeMath.surfacePoint(latitude: 0, longitude: 85);
      final projection = DsGlobeMath.project(
        p,
        gx: 0,
        gy: 0,
        center: _centerCover,
        scale: _scaleCover,
      );
      expect(projection.depth, greaterThan(0));
      expect(projection.depth, lessThan(DsGlobeMath.visibilityThreshold));
      expect(projection.isFront, isTrue);
      expect(projection.isLabelVisible, isFalse);
    });
  });

  group('orientationFor', () {
    const targets = <(double, double)>[
      (0, 0),
      (40.4, -3.7),
      (-33.9, 151.2),
      (-12, -77),
      (64, 179.5),
      (-45, -179.5),
      (90, 0),
      (-90, 0),
      (90, 120),
      (0, 180),
    ];

    for (final scaleAndCenter in <(double, Offset)>[
      (_scaleCover, _centerCover),
      (_scaleExplore, _centerExplore),
    ]) {
      for (final currentGy in <double>[0, 350, -170, 725, -1000]) {
        test('puts every target at the center (scale ${scaleAndCenter.$1}, '
            'current gy $currentGy)', () {
          for (final (lat, lon) in targets) {
            final orientation = DsGlobeMath.orientationFor(
              latitude: lat,
              longitude: lon,
              currentGy: currentGy,
            );
            final markerRadius =
                DsGlobeMath.radius + DsGlobeMath.markerElevation;
            final marker = DsGlobeMath.surfacePoint(
              latitude: lat,
              longitude: lon,
              radius: markerRadius,
            );
            final projection = DsGlobeMath.project(
              marker,
              gx: orientation.gx,
              gy: orientation.gy,
              center: scaleAndCenter.$2,
              scale: scaleAndCenter.$1,
            );
            expect(
              projection.screen.dx,
              closeTo(scaleAndCenter.$2.dx, _tolerance),
              reason: 'lat $lat lon $lon',
            );
            expect(
              projection.screen.dy,
              closeTo(scaleAndCenter.$2.dy, _tolerance),
              reason: 'lat $lat lon $lon',
            );
            expect(projection.depth, closeTo(markerRadius, _tolerance));
            expect(projection.isFront, isTrue);
            expect(projection.isLabelVisible, isTrue);
          }
        });
      }
    }

    test('gx is the negated latitude', () {
      final o = DsGlobeMath.orientationFor(
        latitude: 35,
        longitude: 0,
        currentGy: 0,
      );
      expect(o.gx, -35);
      expect(o.gy, closeTo(0, _tolerance));
    });

    test('current 350 with target -10 stays near 350 (no spin)', () {
      final o = DsGlobeMath.orientationFor(
        latitude: 0,
        longitude: 10,
        currentGy: 350,
      );
      expect(o.gy, 350);
    });

    test('current -170 with target 170 unwraps to -190', () {
      final o = DsGlobeMath.orientationFor(
        latitude: 0,
        longitude: -170,
        currentGy: -170,
      );
      expect(o.gy, -190);
    });

    test('result is congruent to -lon and within half a turn of current', () {
      for (final lon in <double>[-180, -120.5, -10, 0, 10, 77, 179.9, 180]) {
        for (final current in <double>[-725, -170, 0, 90, 350, 1000]) {
          final o = DsGlobeMath.orientationFor(
            latitude: 12,
            longitude: lon,
            currentGy: current,
          );
          final turns = (o.gy - (-lon)) / _fullTurn;
          expect(turns, closeTo(turns.roundToDouble(), _tolerance));
          expect((o.gy - current).abs(), lessThanOrEqualTo(_halfTurn));
        }
      }
    });

    test('antipodal longitudes pick a finite half-turn either way', () {
      final o = DsGlobeMath.orientationFor(
        latitude: 0,
        longitude: 180,
        currentGy: 0,
      );
      expect(o.gy.abs(), _halfTurn);
    });
  });

  group('landDotSize', () {
    test('is 7.2 at the equator', () {
      expect(DsGlobeMath.landDotSize(0), closeTo(7.2, _tolerance));
    });

    test('is 4.0 at 60 degrees', () {
      expect(DsGlobeMath.landDotSize(60), closeTo(4.0, _tolerance));
    });

    test('clamps to 3.2 at 80 degrees', () {
      expect(DsGlobeMath.landDotSize(80), DsGlobeMath.minLandDotSize);
    });

    test('is symmetric across hemispheres', () {
      expect(
        DsGlobeMath.landDotSize(-30),
        closeTo(DsGlobeMath.landDotSize(30), _tolerance),
      );
    });
  });

  group('arcPoints', () {
    test('returns 27 points by default and honours count', () {
      expect(
        DsGlobeMath.arcPoints(
          latitudeA: 0,
          longitudeA: 0,
          latitudeB: 0,
          longitudeB: 90,
        ),
        hasLength(27),
      );
      expect(
        DsGlobeMath.arcPoints(
          latitudeA: 0,
          longitudeA: 0,
          latitudeB: 0,
          longitudeB: 90,
          count: 5,
        ),
        hasLength(5),
      );
    });

    test('endpoints sit at R + 4 over A and B', () {
      const latA = 40.4;
      const lonA = -3.7;
      const latB = -33.9;
      const lonB = 151.2;
      final points = DsGlobeMath.arcPoints(
        latitudeA: latA,
        longitudeA: lonA,
        latitudeB: latB,
        longitudeB: lonB,
      );
      const baseRadius = DsGlobeMath.radius + DsGlobeMath.arcBaseElevation;
      expect(_norm(points.first), closeTo(baseRadius, _tolerance));
      expect(_norm(points.last), closeTo(baseRadius, _tolerance));
      final a = _unit(latA, lonA);
      final b = _unit(latB, lonB);
      _expectVector(
        points.first,
        a.x * baseRadius,
        a.y * baseRadius,
        a.z * baseRadius,
      );
      _expectVector(
        points.last,
        b.x * baseRadius,
        b.y * baseRadius,
        b.z * baseRadius,
      );
    });

    test('midpoint radius is R + 4 + omega * 70', () {
      final points = DsGlobeMath.arcPoints(
        latitudeA: 0,
        longitudeA: 0,
        latitudeB: 0,
        longitudeB: 90,
        count: 27,
      );
      final mid = points[13];
      expect(
        _norm(mid),
        closeTo(
          DsGlobeMath.radius +
              DsGlobeMath.arcBaseElevation +
              math.pi / 2 * DsGlobeMath.arcLiftFactor,
          _tolerance,
        ),
      );
      final expectedDirection = _unit(0, 45);
      final direction = DsGlobeVector(
        x: mid.x / _norm(mid),
        y: mid.y / _norm(mid),
        z: mid.z / _norm(mid),
      );
      _expectVector(
        direction,
        expectedDirection.x,
        expectedDirection.y,
        expectedDirection.z,
      );
    });

    test('every point lies on the great circle through A and B', () {
      final a = _unit(40.4, -3.7);
      final b = _unit(-33.9, 151.2);
      final normal = _cross(a, b);
      final points = DsGlobeMath.arcPoints(
        latitudeA: 40.4,
        longitudeA: -3.7,
        latitudeB: -33.9,
        longitudeB: 151.2,
      );
      for (final p in points) {
        expect(_dot(p, normal) / _norm(p), closeTo(0, 1e-9));
      }
    });

    test('points advance monotonically from A to B', () {
      final a = _unit(10, -20);
      final points = DsGlobeMath.arcPoints(
        latitudeA: 10,
        longitudeA: -20,
        latitudeB: 50,
        longitudeB: 100,
      );
      var previous = 1.0;
      for (final p in points) {
        final cosine = _dot(a, p) / _norm(p);
        expect(cosine, lessThanOrEqualTo(previous + _tolerance));
        previous = cosine;
      }
    });

    test('coincident points collapse onto A without NaN', () {
      final points = DsGlobeMath.arcPoints(
        latitudeA: 20,
        longitudeA: 30,
        latitudeB: 20,
        longitudeB: 30,
      );
      final expected = DsGlobeMath.surfacePoint(
        latitude: 20,
        longitude: 30,
        radius: DsGlobeMath.radius + DsGlobeMath.arcBaseElevation,
      );
      for (final p in points) {
        expect(p.x.isFinite && p.y.isFinite && p.z.isFinite, isTrue);
        _expectVector(p, expected.x, expected.y, expected.z);
      }
    });

    test(
      'antipodal points are finite, deterministic and on a great circle',
      () {
        final first = DsGlobeMath.arcPoints(
          latitudeA: 10,
          longitudeA: 20,
          latitudeB: -10,
          longitudeB: -160,
        );
        final second = DsGlobeMath.arcPoints(
          latitudeA: 10,
          longitudeA: 20,
          latitudeB: -10,
          longitudeB: -160,
        );
        expect(first, second);
        final a = _unit(10, 20);
        final b = _unit(-10, -160);
        for (final p in first) {
          expect(p.x.isFinite && p.y.isFinite && p.z.isFinite, isTrue);
        }
        _expectVector(first.last, b.x * 404, b.y * 404, b.z * 404);
        final mid = first[13];
        expect(_dot(mid, a) / _norm(mid), closeTo(0, 1e-9));
        expect(
          _norm(mid),
          closeTo(
            DsGlobeMath.radius +
                DsGlobeMath.arcBaseElevation +
                math.pi * DsGlobeMath.arcLiftFactor,
            _tolerance,
          ),
        );
      },
    );
  });

  group('land data', () {
    test('landPoints has one point per land cell at radius 400', () {
      expect(DsGlobeMath.landPoints, hasLength(DsLandGrid.cells.length));
      expect(DsGlobeMath.landPoints, hasLength(884));
      for (final p in DsGlobeMath.landPoints) {
        expect(_norm(p), closeTo(400, _tolerance));
      }
    });

    test('landPoints follow the cell coordinates and are cached', () {
      final cell = DsLandGrid.cells.first;
      final expected = DsGlobeMath.surfacePoint(
        latitude: cell.latitude,
        longitude: cell.longitude,
      );
      expect(DsGlobeMath.landPoints.first, expected);
      expect(identical(DsGlobeMath.landPoints, DsGlobeMath.landPoints), isTrue);
    });

    test('landDotSizes aligns with the cells', () {
      expect(DsGlobeMath.landDotSizes, hasLength(DsLandGrid.cells.length));
      for (var i = 0; i < DsLandGrid.cells.length; i++) {
        expect(
          DsGlobeMath.landDotSizes[i],
          DsGlobeMath.landDotSize(DsLandGrid.cells[i].latitude),
        );
      }
    });
  });
}
