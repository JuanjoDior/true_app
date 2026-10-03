import 'package:flutter/widgets.dart' show Matrix4, Offset, immutable;

@immutable
class DsMapCamera {
  const DsMapCamera({
    required this.translateX,
    required this.translateY,
    required this.scale,
  });

  const DsMapCamera.world() : translateX = 0, translateY = 0, scale = 1;

  factory DsMapCamera.fromFocus({
    required Offset sceneCenter,
    required Offset viewportTarget,
    required double scale,
  }) => DsMapCamera(
    translateX: viewportTarget.dx - scale * sceneCenter.dx,
    translateY: viewportTarget.dy - scale * sceneCenter.dy,
    scale: scale,
  );

  final double translateX;
  final double translateY;
  final double scale;

  Matrix4 toMatrix() => Matrix4.identity()
    ..translateByDouble(translateX, translateY, 0, 1)
    ..scaleByDouble(scale, scale, 1, 1);

  Offset apply(Offset scenePoint) => Offset(
    scale * scenePoint.dx + translateX,
    scale * scenePoint.dy + translateY,
  );

  Offset invert(Offset viewportPoint) => Offset(
    (viewportPoint.dx - translateX) / scale,
    (viewportPoint.dy - translateY) / scale,
  );

  // `t` ya viene con la curva aplicada
  static DsMapCamera lerp(DsMapCamera a, DsMapCamera b, double t) =>
      DsMapCamera(
        translateX: _linear(a.translateX, b.translateX, t),
        translateY: _linear(a.translateY, b.translateY, t),
        scale: _linear(a.scale, b.scale, t),
      );

  static double _linear(double a, double b, double t) => a * (1 - t) + b * t;

  @override
  bool operator ==(Object other) =>
      other is DsMapCamera &&
      other.translateX == translateX &&
      other.translateY == translateY &&
      other.scale == scale;

  @override
  int get hashCode => Object.hash(translateX, translateY, scale);

  @override
  String toString() =>
      'DsMapCamera(translateX: $translateX, translateY: $translateY, '
      'scale: $scale)';
}
