import 'dart:math' as math;
import 'dart:ui';

import '../map/ds_land_grid.dart';

class DsGlobeVector {
  const DsGlobeVector({required this.x, required this.y, required this.z});

  final double x;
  final double y;
  final double z;

  @override
  bool operator ==(Object other) =>
      other is DsGlobeVector && other.x == x && other.y == y && other.z == z;

  @override
  int get hashCode => Object.hash(x, y, z);

  @override
  String toString() => 'DsGlobeVector($x, $y, $z)';
}

class DsGlobeProjection {
  const DsGlobeProjection({
    required this.screen,
    required this.depth,
    required this.perspectiveFactor,
    required this.isFront,
    required this.isLabelVisible,
  });

  final Offset screen;
  final double depth;
  final double perspectiveFactor;
  final bool isFront;
  final bool isLabelVisible;
}

abstract final class DsGlobeMath {
  static const double radius = 400;
  static const double perspective = 2200;
  static const double markerElevation = 3;
  static const double arcBaseElevation = 4;
  static const double arcLiftFactor = 70;
  static const double visibilityThreshold = 40;
  static const double minLandDotSize = 3.2;
  static const double landDotBase = 0.8;
  static const double landDotLatitudeFactor = 6.4;
  static const int defaultArcPointCount = 27;

  static const double _degreesToRadians = math.pi / 180;
  static const double _fullTurnDegrees = 360;
  static const double _degenerateArcEpsilon = 1e-12;
  static const double _referenceAxisLimit = 0.9;
  static const int _minArcPointCount = 2;

  static DsGlobeVector surfacePoint({
    required double latitude,
    required double longitude,
    double radius = DsGlobeMath.radius,
  }) {
    final phi = latitude * _degreesToRadians;
    final lambda = longitude * _degreesToRadians;
    return DsGlobeVector(
      x: radius * math.cos(phi) * math.sin(lambda),
      y: -radius * math.sin(phi),
      z: radius * math.cos(phi) * math.cos(lambda),
    );
  }

  static ({double x, double y, double z}) rotate(
    DsGlobeVector p, {
    required double gx,
    required double gy,
  }) {
    final cosGy = math.cos(gy * _degreesToRadians);
    final sinGy = math.sin(gy * _degreesToRadians);
    final cosGx = math.cos(gx * _degreesToRadians);
    final sinGx = math.sin(gx * _degreesToRadians);
    final x1 = p.x * cosGy + p.z * sinGy;
    final z1 = -p.x * sinGy + p.z * cosGy;
    final y2 = p.y * cosGx - z1 * sinGx;
    final z2 = p.y * sinGx + z1 * cosGx;
    return (x: x1, y: y2, z: z2);
  }

  static DsGlobeProjection project(
    DsGlobeVector p, {
    required double gx,
    required double gy,
    required Offset center,
    required double scale,
  }) {
    final rotated = rotate(p, gx: gx, gy: gy);
    final factor = perspective / (perspective - scale * rotated.z);
    return DsGlobeProjection(
      screen: Offset(
        center.dx + scale * rotated.x * factor,
        center.dy + scale * rotated.y * factor,
      ),
      depth: rotated.z,
      perspectiveFactor: factor,
      isFront: rotated.z > 0,
      isLabelVisible: rotated.z > visibilityThreshold,
    );
  }

  static double landDotSize(double latitude) => math.max(
    minLandDotSize,
    landDotLatitudeFactor * math.cos(latitude * _degreesToRadians) +
        landDotBase,
  );

  static ({double gx, double gy}) orientationFor({
    required double latitude,
    required double longitude,
    required double currentGy,
  }) {
    final targetGy = -longitude;
    final turns = ((currentGy - targetGy) / _fullTurnDegrees).round();
    return (gx: -latitude, gy: targetGy + _fullTurnDegrees * turns);
  }

  static List<DsGlobeVector> arcPoints({
    required double latitudeA,
    required double longitudeA,
    required double latitudeB,
    required double longitudeB,
    int count = defaultArcPointCount,
  }) {
    assert(count >= _minArcPointCount, 'An arc needs at least two points');
    final a = surfacePoint(
      latitude: latitudeA,
      longitude: longitudeA,
      radius: 1,
    );
    final b = surfacePoint(
      latitude: latitudeB,
      longitude: longitudeB,
      radius: 1,
    );
    final cross = _cross(a, b);
    final sinOmega = _norm(cross);
    final cosOmega = _dot(a, b);

    late final double omega;
    late final DsGlobeVector u;
    if (sinOmega > _degenerateArcEpsilon) {
      omega = math.atan2(sinOmega, cosOmega);
      u = _scale(_cross(cross, a), 1 / sinOmega);
    } else if (cosOmega > 0) {
      omega = 0;
      u = const DsGlobeVector(x: 0, y: 0, z: 0);
    } else {
      // Antípodas: cualquier círculo máximo sirve; se fija uno por determinismo.
      omega = math.pi;
      final axis = a.y.abs() < _referenceAxisLimit
          ? const DsGlobeVector(x: 0, y: 1, z: 0)
          : const DsGlobeVector(x: 1, y: 0, z: 0);
      final perpendicular = _cross(axis, a);
      u = _scale(perpendicular, 1 / _norm(perpendicular));
    }

    return List<DsGlobeVector>.generate(count, (k) {
      final t = k / (count - 1);
      final theta = t * omega;
      final pointRadius =
          radius +
          arcBaseElevation +
          math.sin(math.pi * t) * omega * arcLiftFactor;
      final cosTheta = math.cos(theta);
      final sinTheta = math.sin(theta);
      return DsGlobeVector(
        x: pointRadius * (a.x * cosTheta + u.x * sinTheta),
        y: pointRadius * (a.y * cosTheta + u.y * sinTheta),
        z: pointRadius * (a.z * cosTheta + u.z * sinTheta),
      );
    }, growable: false);
  }

  static final List<DsGlobeVector> landPoints = List.unmodifiable(
    DsLandGrid.cells.map(
      (cell) =>
          surfacePoint(latitude: cell.latitude, longitude: cell.longitude),
    ),
  );

  static final List<double> landDotSizes = List.unmodifiable(
    DsLandGrid.cells.map((cell) => landDotSize(cell.latitude)),
  );

  static DsGlobeVector _cross(DsGlobeVector a, DsGlobeVector b) =>
      DsGlobeVector(
        x: a.y * b.z - a.z * b.y,
        y: a.z * b.x - a.x * b.z,
        z: a.x * b.y - a.y * b.x,
      );

  static double _dot(DsGlobeVector a, DsGlobeVector b) =>
      a.x * b.x + a.y * b.y + a.z * b.z;

  static double _norm(DsGlobeVector v) => math.sqrt(_dot(v, v));

  static DsGlobeVector _scale(DsGlobeVector v, double factor) =>
      DsGlobeVector(x: v.x * factor, y: v.y * factor, z: v.z * factor);
}
