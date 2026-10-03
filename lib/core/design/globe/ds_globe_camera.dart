import 'dart:ui';

class DsGlobeCamera {
  const DsGlobeCamera({
    required this.gx,
    required this.gy,
    required this.scale,
    required this.center,
  });

  static const double driftDegreesPerStep = 0.22;

  final double gx;
  final double gy;
  final double scale;
  final Offset center;

  static DsGlobeCamera lerp(DsGlobeCamera a, DsGlobeCamera b, double t) =>
      DsGlobeCamera(
        gx: _mix(a.gx, b.gx, t),
        gy: _mix(a.gy, b.gy, t),
        scale: _mix(a.scale, b.scale, t),
        center: Offset(
          _mix(a.center.dx, b.center.dx, t),
          _mix(a.center.dy, b.center.dy, t),
        ),
      );

  DsGlobeCamera copyWith({
    double? gx,
    double? gy,
    double? scale,
    Offset? center,
  }) => DsGlobeCamera(
    gx: gx ?? this.gx,
    gy: gy ?? this.gy,
    scale: scale ?? this.scale,
    center: center ?? this.center,
  );

  DsGlobeCamera drifted({double degrees = driftDegreesPerStep}) =>
      copyWith(gy: gy - degrees);

  // a*(1-t)+b*t garantiza extremos exactos en t=0 y t=1
  static double _mix(double a, double b, double t) => a * (1 - t) + b * t;

  @override
  bool operator ==(Object other) =>
      other is DsGlobeCamera &&
      other.gx == gx &&
      other.gy == gy &&
      other.scale == scale &&
      other.center == center;

  @override
  int get hashCode => Object.hash(gx, gy, scale, center);

  @override
  String toString() =>
      'DsGlobeCamera(gx: $gx, gy: $gy, scale: $scale, center: $center)';
}
