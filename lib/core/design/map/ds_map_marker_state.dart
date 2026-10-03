import '../tokens/ds_motion.dart';

const double _diameterNormal = 12;
const double _diameterNormalMobile = 14;
const double _diameterSelected = 18;
const double _diameterSelectedMobile = 20;
const double _glowNormal = 12;
const double _glowSelected = 26;
const double _opacityVisible = 1;
const double _opacityDimmed = 0.4;
const double _opacityFilteredOut = 0.12;
const double _opacityHidden = 0;

const int _pulseDelayStepMicros = 410000;
const int _pulseDelayCycleMicros = 3000000;

class DsMapMarkerVisual {
  const DsMapMarkerVisual({
    required this.diameter,
    required this.glowRadius,
    required this.opacity,
    required this.showLabel,
    required this.goldBorder,
    required this.pulsing,
    required this.pulseDuration,
    required this.interactive,
  });

  final double diameter;
  final double glowRadius;
  final double opacity;
  final bool showLabel;
  final bool goldBorder;
  final bool pulsing;
  final Duration pulseDuration;
  final bool interactive;

  @override
  bool operator ==(Object other) =>
      other is DsMapMarkerVisual &&
      other.diameter == diameter &&
      other.glowRadius == glowRadius &&
      other.opacity == opacity &&
      other.showLabel == showLabel &&
      other.goldBorder == goldBorder &&
      other.pulsing == pulsing &&
      other.pulseDuration == pulseDuration &&
      other.interactive == interactive;

  @override
  int get hashCode => Object.hash(
    diameter,
    glowRadius,
    opacity,
    showLabel,
    goldBorder,
    pulsing,
    pulseDuration,
    interactive,
  );
}

/// Reglas visuales de los marcadores del mapa (doc 2.3).
abstract final class DsMapMarkerStates {
  static const double minTapTarget = 44;
  static const double pulseScaleFrom = 0.5;
  static const double pulseScaleTo = 2.8;

  static DsMapMarkerVisual resolve({
    required bool selected,
    required bool related,
    required bool matchesFilter,
    required bool shownByYear,
    required bool hasSelection,
    required bool mobile,
  }) {
    final diameter = selected
        ? (mobile ? _diameterSelectedMobile : _diameterSelected)
        : (mobile ? _diameterNormalMobile : _diameterNormal);
    final opacity = !shownByYear
        ? _opacityHidden
        : matchesFilter
        ? (hasSelection && !selected && !related
              ? _opacityDimmed
              : _opacityVisible)
        : _opacityFilteredOut;
    return DsMapMarkerVisual(
      diameter: diameter,
      glowRadius: selected ? _glowSelected : _glowNormal,
      opacity: opacity,
      showLabel: related,
      goldBorder: related,
      pulsing: opacity > 0,
      pulseDuration: selected ? DsMotion.pulseSelected : DsMotion.pulseIdle,
      interactive: shownByYear,
    );
  }

  static bool shownByYear({required int caseYear, required int timelineYear}) =>
      caseYear <= timelineYear;

  /// Aritmética entera para que `(i * 0,41) mod 3` no acumule error de coma flotante.
  static Duration pulseDelay(int index) {
    assert(index >= 0, 'index must be non-negative');
    return Duration(
      microseconds: (index * _pulseDelayStepMicros) % _pulseDelayCycleMicros,
    );
  }

  static double counterScale(double cameraScale) {
    assert(cameraScale > 0, 'cameraScale must be positive');
    return 1 / cameraScale;
  }
}
