import 'package:flutter/widgets.dart';

/// Claves estables de la ficha técnica del expediente.
abstract final class DossierFactsKeys {
  static const Key strip = ValueKey('dossier-facts');
  static const Key year = ValueKey('dossier-facts-year');
  static const Key place = ValueKey('dossier-facts-place');
  static const Key victims = ValueKey('dossier-facts-victims');
  static const Key status = ValueKey('dossier-facts-status');
  static const Key connections = ValueKey('dossier-facts-connections');
}
