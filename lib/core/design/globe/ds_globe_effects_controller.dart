import 'dart:async';

import 'package:flutter/animation.dart' show AnimationController;
import 'package:flutter/foundation.dart' show ChangeNotifier, Listenable;
import 'package:flutter/scheduler.dart' show Ticker, TickerProvider;

import '../tokens/ds_motion.dart';
import 'ds_globe_arc_reveal.dart';
import 'ds_globe_camera.dart';
import 'ds_globe_camera_animation.dart';

/// Relojes de los efectos del globo: arcos, deriva y retardo de etiquetas.
class DsGlobeEffectsController extends ChangeNotifier {
  DsGlobeEffectsController({required TickerProvider vsync})
    : _reveal = AnimationController(
        vsync: vsync,
        duration: DsGlobeArcReveal.total,
      ) {
    _drift = vsync.createTicker(_onDriftTick);
  }

  static const Duration labelDelay = Duration(milliseconds: 1700);

  final AnimationController _reveal;
  late final Ticker _drift;
  Timer? _labelTimer;

  Listenable get revealRepaint => _reveal;

  bool _reduceMotion = false;
  bool _labelsPending = false;
  double _driftBase = 0;
  double _driftDegrees = 0;
  Set<String> _known = {};
  Map<String, Duration> _offsets = {};

  /// Grados acumulados que se restan a `gy`.
  double get driftDegrees => _driftDegrees;

  bool get drifting => _drift.isActive;

  bool get labelsVisible => !_labelsPending;

  /// Una aparición ya terminada (o sin reloj) cuenta como completa.
  Duration arcElapsed(String key) {
    final offset = _offsets[key];
    if (offset == null) return DsGlobeArcReveal.total;
    final elapsed =
        offset +
        Duration(
          microseconds: (_reveal.value * DsGlobeArcReveal.total.inMicroseconds)
              .round(),
        );
    return elapsed > DsGlobeArcReveal.total ? DsGlobeArcReveal.total : elapsed;
  }

  /// Idempotente: solo arranca o detiene relojes cuando cambia lo que se necesita.
  void sync({
    required Set<String> arcKeys,
    required bool reduceMotion,
    required bool hasSelection,
    required bool flying,
  }) {
    _reduceMotion = reduceMotion;
    _syncArcs(arcKeys);
    _syncDrift(
      DsGlobeCameraAnimation.driftEnabled(
        reduceMotion: reduceMotion,
        hasSelection: hasSelection,
        flightFinished: !flying,
      ),
    );
    if (reduceMotion && _labelsPending) _showLabels();
  }

  /// La cámara mostrada ya incluye la deriva: parte de ella y reinicia el acumulado.
  void startFlight({required bool reduceMotion}) {
    if (_drift.isActive) _drift.stop();
    _driftBase = 0;
    _driftDegrees = 0;
    _labelTimer?.cancel();
    if (reduceMotion) {
      _labelsPending = false;
      return;
    }
    _labelsPending = true;
    _labelTimer = Timer(labelDelay, _showLabels);
  }

  void _showLabels() {
    _labelTimer?.cancel();
    _labelsPending = false;
    notifyListeners();
  }

  void _syncArcs(Set<String> keys) {
    if (_reduceMotion) {
      _reveal.stop();
      _offsets = {};
      _known = keys;
      return;
    }
    final added = keys.difference(_known);
    _known = keys;
    final kept = {
      for (final key in _offsets.keys)
        if (keys.contains(key)) key,
    };
    if (added.isEmpty) {
      _offsets = {for (final key in kept) key: _offsets[key]!};
      return;
    }
    // Los arcos en curso conservan su progreso al reiniciar el reloj compartido.
    _offsets = {
      for (final key in kept) key: arcElapsed(key),
      for (final key in added) key: Duration.zero,
    };
    _reveal.forward(from: 0);
  }

  void _syncDrift(bool enabled) {
    if (enabled && !_drift.isActive) {
      _drift.start();
    } else if (!enabled && _drift.isActive) {
      _drift.stop();
      _driftBase = _driftDegrees;
    }
  }

  // 0,22° cada 70 ms equivale a 3,142857°/s; la transición lineal de 80 ms de la web lo vuelve continuo.
  void _onDriftTick(Duration elapsed) {
    _driftDegrees =
        _driftBase +
        DsGlobeCamera.driftDegreesPerStep *
            elapsed.inMicroseconds /
            DsMotion.globeDriftStep.inMicroseconds;
    notifyListeners();
  }

  @override
  void dispose() {
    _labelTimer?.cancel();
    _drift.dispose();
    _reveal.dispose();
    super.dispose();
  }
}
