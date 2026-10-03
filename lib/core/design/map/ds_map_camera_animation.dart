import 'package:flutter/animation.dart';

import '../tokens/ds_motion.dart';
import 'ds_map_camera.dart';

class DsMapCameraTween extends Tween<DsMapCamera> {
  DsMapCameraTween({super.begin, super.end});

  @override
  DsMapCamera lerp(double t) => DsMapCamera.lerp(begin!, end!, t);
}

abstract final class DsMapCameraAnimation {
  static Duration duration({required bool reduceMotion}) =>
      DsMotion.resolve(DsMotion.fly, reduceMotion: reduceMotion);
}
