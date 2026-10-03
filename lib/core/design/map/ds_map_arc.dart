import 'dart:math' as math;
import 'dart:ui';

const double _controlLiftFactor = 0.28;
const double _controlLiftBase = 20;
const double _labelEndWeight = 0.25;
const double _labelControlWeight = 0.5;

/// Geometría de un arco de conexión entre dos casos (doc 2.4).
class DsMapArc {
  const DsMapArc._({
    required this.start,
    required this.end,
    required this.control,
    required this.labelPoint,
  });

  factory DsMapArc.between(Offset a, Offset b) {
    final dist = (a - b).distance;
    final control = Offset(
      (a.dx + b.dx) / 2,
      math.min(a.dy, b.dy) - dist * _controlLiftFactor - _controlLiftBase,
    );
    final labelPoint =
        a * _labelEndWeight +
        control * _labelControlWeight +
        b * _labelEndWeight;
    return DsMapArc._(
      start: a,
      end: b,
      control: control,
      labelPoint: labelPoint,
    );
  }

  /// Ancho constante en pantalla: el painter debe dividirlo entre la escala de la cámara.
  static const double strokeWidth = 1.8;
  static const double dashOn = 7;
  static const double dashOff = 7;
  static const double dashPeriod = dashOn + dashOff;
  static const Duration revealDelay = Duration(milliseconds: 600);

  final Offset start;
  final Offset end;
  final Offset control;
  final Offset labelPoint;

  Path get path => Path()
    ..moveTo(start.dx, start.dy)
    ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);

  /// [animationValue] en 0..1 (bucle) a desplazamiento en unidades de la escena.
  static double dashPhase(double animationValue) => animationValue * dashPeriod;

  Path dashedPath({required double phase}) {
    final dashed = Path();
    final shift = phase % dashPeriod;
    for (final metric in path.computeMetrics()) {
      // El patrón arranca antes del origen para que el desfase avance los trazos.
      for (var from = -shift; from < metric.length; from += dashPeriod) {
        final begin = math.max(from, 0.0);
        final finish = math.min(from + dashOn, metric.length);
        if (finish > begin) {
          dashed.addPath(metric.extractPath(begin, finish), Offset.zero);
        }
      }
    }
    return dashed;
  }
}
