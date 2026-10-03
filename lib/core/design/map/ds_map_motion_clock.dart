import '../tokens/ds_motion.dart';
import 'ds_map_marker_state.dart';

/// Fases de pulsos y trazos a partir de un único reloj en bucle.
abstract final class DsMapMotionClock {
  // mcm de 1,8 s (pulso seleccionado), 3 s (pulso en reposo) y 1,2 s (trazo): el bucle no da saltos.
  static const Duration period = Duration(seconds: 18);

  /// Progreso 0..1 (exclusivo) del anillo de un marcador; el retraso desfasa su ciclo.
  static double pulseProgress({
    required Duration elapsed,
    required int index,
    required bool selected,
  }) {
    final cycle =
        (selected ? DsMotion.pulseSelected : DsMotion.pulseIdle).inMicroseconds;
    final delay = DsMapMarkerStates.pulseDelay(index).inMicroseconds;
    return ((elapsed.inMicroseconds - delay) % cycle) / cycle;
  }

  static double dashProgress(Duration elapsed) {
    final cycle = DsMotion.dash.inMicroseconds;
    return (elapsed.inMicroseconds % cycle) / cycle;
  }
}
