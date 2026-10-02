import 'package:flutter/animation.dart';

abstract final class DsMotion {
  static const Cubic easeUi = Cubic(0.2, 0.8, 0.2, 1);
  static const Cubic easeFly = Cubic(0.22, 0.8, 0.2, 1);
  static const Cubic easeGlobe = Cubic(0.45, 0.05, 0.2, 1);

  // Mínimo del rango 250–450 ms: el hover frecuente debe sentirse inmediato
  static const Duration hover = Duration(milliseconds: 250);
  static const Duration press = Duration(milliseconds: 160);
  static const Duration crossfade = Duration(milliseconds: 900);
  static const Duration kenBurns = Duration(seconds: 8);
  static const Duration fly = Duration(milliseconds: 1800);
  static const Duration carouselDesktop = Duration(seconds: 7);
  static const Duration carouselMobile = Duration(milliseconds: 6500);
  static const Duration pulseSelected = Duration(milliseconds: 1800);
  static const Duration pulseIdle = Duration(seconds: 3);
  static const Duration dash = Duration(milliseconds: 1200);

  static Duration resolve(Duration duration, {required bool reduceMotion}) =>
      reduceMotion ? Duration.zero : duration;
}
