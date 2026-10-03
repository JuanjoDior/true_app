import 'package:flutter/animation.dart';

import '../tokens/ds_motion.dart';
import 'ds_globe_camera.dart';

class DsGlobeCameraTween extends Tween<DsGlobeCamera> {
  DsGlobeCameraTween({super.begin, super.end});

  @override
  DsGlobeCamera lerp(double t) => DsGlobeCamera.lerp(begin!, end!, t);
}

abstract final class DsGlobeCameraAnimation {
  static Duration duration({required bool reduceMotion}) =>
      DsMotion.resolve(DsMotion.globeFly, reduceMotion: reduceMotion);

  /// La deriva sólo corre sin selección y tras terminar el vuelo; con
  /// movimiento reducido se detiene.
  static bool driftEnabled({
    required bool reduceMotion,
    required bool hasSelection,
    required bool flightFinished,
  }) => !reduceMotion && !hasSelection && flightFinished;
}
