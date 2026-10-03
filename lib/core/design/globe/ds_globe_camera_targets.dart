import 'dart:ui';

import 'ds_globe_camera.dart';
import 'ds_globe_math.dart';

abstract final class DsGlobeCameraTargets {
  static const Offset coverCenter = Offset(1010, 520);
  static const double coverScale = 1.0;
  static const Offset exploreCenter = Offset(640, 455);
  static const double exploreScale = 0.78;

  static DsGlobeCamera cover({
    required double latitude,
    required double longitude,
    required double currentGy,
  }) => _facing(
    latitude: latitude,
    longitude: longitude,
    currentGy: currentGy,
    center: coverCenter,
    scale: coverScale,
  );

  static DsGlobeCamera explore({
    required double latitude,
    required double longitude,
    required double currentGy,
  }) => _facing(
    latitude: latitude,
    longitude: longitude,
    currentGy: currentGy,
    center: exploreCenter,
    scale: exploreScale,
  );

  static DsGlobeCamera exploreIdle({required DsGlobeCamera current}) =>
      current.copyWith(center: exploreCenter, scale: exploreScale);

  static DsGlobeCamera _facing({
    required double latitude,
    required double longitude,
    required double currentGy,
    required Offset center,
    required double scale,
  }) {
    final orientation = DsGlobeMath.orientationFor(
      latitude: latitude,
      longitude: longitude,
      currentGy: currentGy,
    );
    return DsGlobeCamera(
      gx: orientation.gx,
      gy: orientation.gy,
      scale: scale,
      center: center,
    );
  }
}
