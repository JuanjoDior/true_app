import 'ds_map_arc.dart';

/// Aparición de los arcos: espera [DsMapArc.revealDelay] y luego funde en [fade].
abstract final class DsMapArcReveal {
  static const Duration fade = Duration(milliseconds: 400);

  static Duration get total => Duration(
    microseconds: DsMapArc.revealDelay.inMicroseconds + fade.inMicroseconds,
  );

  /// [progress] 0..1 sobre [total].
  static double opacity(double progress) {
    final elapsedMicros = progress * total.inMicroseconds;
    final fadeMicros =
        (elapsedMicros - DsMapArc.revealDelay.inMicroseconds) /
        fade.inMicroseconds;
    return fadeMicros.clamp(0.0, 1.0);
  }
}
