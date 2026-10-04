import 'package:flutter/widgets.dart';

/// Claves estables de las piezas del héroe, para pruebas y semántica.
abstract final class PortadaHeroKeys {
  static const Key background = ValueKey('portada-background');
  static const Key globe = ValueKey('portada-globe');
  static const Key veil = ValueKey('portada-veil');
  static const Key stars = ValueKey('portada-stars');

  static Key content(String caseId) => ValueKey('portada-content-$caseId');
  static Key ghostYear(String caseId) => ValueKey('portada-ghost-$caseId');
  static Key title(String caseId) => ValueKey('portada-title-$caseId');
  static Key summary(String caseId) => ValueKey('portada-summary-$caseId');
  static Key coords(String caseId) => ValueKey('portada-coords-$caseId');
  static Key tab(int index) => ValueKey('portada-tab-$index');
  static Key tabName(int index) => ValueKey('portada-tab-name-$index');
  static Key tabTrack(int index) => ValueKey('portada-tab-track-$index');
  static Key tabFill(int index) => ValueKey('portada-tab-fill-$index');
}
