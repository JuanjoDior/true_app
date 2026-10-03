import 'ds_globe_math.dart';

/// Aparición secuencial de los 27 puntos de un arco (doc 3.3).
abstract final class DsGlobeArcReveal {
  static const Duration firstDotDelay = Duration(milliseconds: 900);
  static const Duration dotInterval = Duration(milliseconds: 35);
  static const Duration dotFade = Duration(milliseconds: 200);

  static Duration get total =>
      firstDotDelay +
      dotInterval * (DsGlobeMath.defaultArcPointCount - 1) +
      dotFade;

  /// Opacidad 0..1 del punto [k] tras [elapsed] desde que el arco apareció.
  static double dotOpacity(int k, Duration elapsed) {
    final start = firstDotDelay + dotInterval * k;
    final progress = (elapsed - start).inMicroseconds / dotFade.inMicroseconds;
    return progress.clamp(0.0, 1.0);
  }
}
