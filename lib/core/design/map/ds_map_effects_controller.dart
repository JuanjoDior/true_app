import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart' show Listenable;

import 'ds_map_arc_reveal.dart';
import 'ds_map_motion_clock.dart';

/// Relojes de los efectos: un bucle único para pulsos y trazos, y otro de un solo disparo para los arcos nuevos.
class DsMapEffectsController {
  DsMapEffectsController({required TickerProvider vsync})
    : _motion = AnimationController(
        vsync: vsync,
        duration: DsMapMotionClock.period,
      ),
      _reveal = AnimationController(
        vsync: vsync,
        duration: DsMapArcReveal.total,
      ) {
    repaint = Listenable.merge([_motion, _reveal]);
    revealRepaint = _reveal;
  }

  final AnimationController _motion;
  final AnimationController _reveal;
  late final Listenable repaint;
  late final Listenable revealRepaint;

  bool _reduceMotion = false;
  Set<String> _known = {};
  Set<String> _revealing = {};

  bool get animating => !_reduceMotion;

  Duration get elapsed => Duration(
    microseconds: (_motion.value * DsMapMotionClock.period.inMicroseconds)
        .round(),
  );

  double get dashProgress =>
      _reduceMotion ? 0 : DsMapMotionClock.dashProgress(elapsed);

  double arcOpacity(String key) =>
      _revealing.contains(key) ? DsMapArcReveal.opacity(_reveal.value) : 1;

  /// Idempotente: solo arranca o detiene relojes cuando cambia lo que se necesita.
  void sync({
    required Set<String> arcKeys,
    required bool anyPulsing,
    required bool reduceMotion,
  }) {
    _reduceMotion = reduceMotion;
    final needsMotion = !reduceMotion && (anyPulsing || arcKeys.isNotEmpty);
    if (needsMotion && !_motion.isAnimating) {
      _motion.repeat();
    } else if (!needsMotion && _motion.isAnimating) {
      _motion.stop();
    }

    if (reduceMotion) {
      _reveal.stop();
      _revealing = {};
      _known = arcKeys;
      return;
    }
    final added = arcKeys.difference(_known);
    final carried = _reveal.isAnimating
        ? _revealing.intersection(arcKeys)
        : <String>{};
    _revealing = added.isEmpty ? carried : {...added, ...carried};
    _known = arcKeys;
    if (added.isNotEmpty) _reveal.forward(from: 0);
  }

  void dispose() {
    _motion.dispose();
    _reveal.dispose();
  }
}
