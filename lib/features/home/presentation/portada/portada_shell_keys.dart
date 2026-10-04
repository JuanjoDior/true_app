import 'package:flutter/widgets.dart';

/// Claves estables de las barras superior e inferior de la portada, para pruebas.
abstract final class PortadaShellKeys {
  static const Key topBar = ValueKey('portada-top-bar');
  static const Key searchField = ValueKey('portada-search-field');
  static const Key searchToggle = ValueKey('portada-search-toggle');
  static const Key topBarHome = ValueKey('portada-top-bar-home');
  static const Key topBarMap = ValueKey('portada-top-bar-map');
  static const Key topBarArchive = ValueKey('portada-top-bar-archive');
  static const Key topBarForm = ValueKey('portada-top-bar-form');

  static const Key bottomBar = ValueKey('portada-bottom-bar');
  static const Key bottomBarHome = ValueKey('portada-bottom-bar-home');
  static const Key bottomBarMap = ValueKey('portada-bottom-bar-map');
  static const Key bottomBarArchive = ValueKey('portada-bottom-bar-archive');
  static const Key bottomBarForm = ValueKey('portada-bottom-bar-form');
}
