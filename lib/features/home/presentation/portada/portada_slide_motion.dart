import 'package:flutter/widgets.dart';

import '../../../../core/design/design.dart';

/// Entrada y salida de un slide: un solo controlador y cuatro animaciones.
///
/// Cada cambio de destino parte del valor que se está viendo, de modo que
/// volver a un slide que se estaba yendo no produce saltos.
class PortadaSlideMotion {
  PortadaSlideMotion({required TickerProvider vsync, required bool visible})
    : controller = AnimationController(vsync: vsync) {
    _snap(visible ? _shown : _hidden);
  }

  static const Duration exitDuration = Duration(milliseconds: 350);
  static const Duration enterDelay = Duration(milliseconds: 450);
  static const Duration enterDuration = Duration(milliseconds: 900);

  // El contenido sube al entrar y un poco más al salir; el año llega desde la izquierda.
  static const double enterShift = 28;
  static const double exitShift = -12;
  static const double ghostEnterShift = -60;

  static const _Pose _shown = _Pose(
    opacity: 1,
    shift: 0,
    ghostOpacity: 1,
    ghostShift: 0,
  );
  static const _Pose _hidden = _Pose(
    opacity: 0,
    shift: enterShift,
    ghostOpacity: 0,
    ghostShift: ghostEnterShift,
  );

  final AnimationController controller;

  Animation<double> contentOpacity = const AlwaysStoppedAnimation(1);
  Animation<double> contentShift = const AlwaysStoppedAnimation(0);
  Animation<double> ghostOpacity = const AlwaysStoppedAnimation(1);
  Animation<double> ghostShift = const AlwaysStoppedAnimation(0);

  bool _leaving = false;
  bool _removed = false;

  bool get isLeaving => _leaving;

  /// Ya no se ve nada: terminó de salir o se retiró sin animar.
  // Se mira el valor y no el estado: `completed` llega un fotograma después de alcanzar 1.
  bool get isGone => _removed || (_leaving && controller.value >= 1);

  _Pose get _current => _Pose(
    opacity: contentOpacity.value,
    shift: contentShift.value,
    ghostOpacity: ghostOpacity.value,
    ghostShift: ghostShift.value,
  );

  void enter({required bool reduceMotion}) {
    final from = isGone ? _hidden : _current;
    _leaving = false;
    _removed = false;
    if (reduceMotion) {
      _snap(_shown);
      return;
    }
    // Solo espera si el contenido está oculto; uno a medio salir vuelve sin pausa.
    final delay = enterDelay * (1 - from.opacity);
    final total = delay + enterDuration;
    _play(
      from: from,
      to: _shown,
      duration: total,
      content: Interval(
        _fraction(delay, total),
        1,
        curve: DsMotion.easeUi,
      ),
      ghost: Interval(
        0,
        _fraction(enterDuration, total),
        curve: DsMotion.easeUi,
      ),
    );
  }

  void exit({required bool reduceMotion}) {
    if (isGone || _leaving) return;
    _leaving = true;
    if (reduceMotion) {
      _removed = true;
      controller.stop();
      return;
    }
    final from = _current;
    _play(
      from: from,
      to: _Pose(
        opacity: 0,
        shift: exitShift,
        ghostOpacity: 0,
        ghostShift: from.ghostShift,
      ),
      duration: exitDuration,
      content: const Interval(0, 1, curve: DsMotion.easeUi),
      ghost: const Interval(0, 1, curve: DsMotion.easeUi),
    );
  }

  void dispose() => controller.dispose();

  void _snap(_Pose pose) {
    controller.stop();
    controller.value = 0;
    contentOpacity = AlwaysStoppedAnimation(pose.opacity);
    contentShift = AlwaysStoppedAnimation(pose.shift);
    ghostOpacity = AlwaysStoppedAnimation(pose.ghostOpacity);
    ghostShift = AlwaysStoppedAnimation(pose.ghostShift);
  }

  void _play({
    required _Pose from,
    required _Pose to,
    required Duration duration,
    required Interval content,
    required Interval ghost,
  }) {
    controller.stop();
    controller.duration = duration;
    controller.value = 0;
    contentOpacity = _tween(from.opacity, to.opacity, content);
    contentShift = _tween(from.shift, to.shift, content);
    ghostOpacity = _tween(from.ghostOpacity, to.ghostOpacity, ghost);
    ghostShift = _tween(from.ghostShift, to.ghostShift, ghost);
    controller.forward();
  }

  Animation<double> _tween(double begin, double end, Interval interval) =>
      controller
          .drive(CurveTween(curve: interval))
          .drive(Tween<double>(begin: begin, end: end));

  // Misma operación que hace el controlador, para que el borde del intervalo coincida al microsegundo.
  static double _fraction(Duration part, Duration total) =>
      (part.inMicroseconds / Duration.microsecondsPerSecond) /
      (total.inMicroseconds / Duration.microsecondsPerSecond);
}

class _Pose {
  const _Pose({
    required this.opacity,
    required this.shift,
    required this.ghostOpacity,
    required this.ghostShift,
  });

  final double opacity;
  final double shift;
  final double ghostOpacity;
  final double ghostShift;
}
