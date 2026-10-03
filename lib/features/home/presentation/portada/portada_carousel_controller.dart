import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';

import '../../../../core/design/design.dart';

/// Estado del carrusel «En el foco»: slide activo y reloj de autoavance.
///
/// El reloj es un `AnimationController` lineal de un slide: su valor es el
/// progreso de la barra de la pestaña activa y, al completarse, pasa al
/// siguiente slide. Así barra y avance comparten una sola fuente de tiempo.
class PortadaCarouselController extends ChangeNotifier {
  PortadaCarouselController({
    required int length,
    required TickerProvider vsync,
    int initialIndex = 0,
    this.interval = DsMotion.carouselDesktop,
  }) : _length = length < 0 ? 0 : length,
       _index = _clamp(initialIndex, length),
       _clock = AnimationController(vsync: vsync, duration: interval) {
    _clock.addListener(_handleClockTick);
    _runClock();
  }

  final Duration interval;
  final AnimationController _clock;
  int _length;
  int _index;
  bool _paused = false;

  int get length => _length;
  int get index => _index;
  bool get isPaused => _paused;

  /// 0..1 dentro del slide activo; vuelve a 0 en cada cambio o reinicio.
  ValueListenable<double> get progress => _clock;

  set length(int value) {
    final next = value < 0 ? 0 : value;
    if (next == _length) return;
    _length = next;
    final clamped = _clamp(_index, _length);
    final moved = clamped != _index;
    _index = clamped;
    _restartClock();
    if (moved) notifyListeners();
  }

  /// Cualquier interacción reinicia los 7 s, incluso sobre el slide activo.
  void select(int index) {
    if (index < 0 || index >= _length) return;
    final moved = index != _index;
    _index = index;
    _restartClock();
    if (moved) notifyListeners();
  }

  void next() {
    if (_length < 2) return;
    select((_index + 1) % _length);
  }

  void pause() {
    if (_paused) return;
    _paused = true;
    _clock.stop();
  }

  void resume() {
    if (!_paused) return;
    _paused = false;
    _runClock();
  }

  @override
  void dispose() {
    _clock.removeListener(_handleClockTick);
    _clock.dispose();
    super.dispose();
  }

  // Se escucha el valor y no el estado: el estado `completed` llega un
  // fotograma después de alcanzar 1.0 y el slide durante 7 s exactos
  void _handleClockTick() {
    if (_clock.value >= 1) next();
  }

  void _restartClock() {
    _clock.stop();
    _clock.value = 0;
    _runClock();
  }

  void _runClock() {
    if (_paused || _length < 2) return;
    if (!_clock.isAnimating) _clock.forward();
  }

  static int _clamp(int index, int length) =>
      length <= 0 ? 0 : index.clamp(0, length - 1);
}
