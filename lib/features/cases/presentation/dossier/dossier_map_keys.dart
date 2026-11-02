import 'package:flutter/widgets.dart';

abstract final class DossierMapKeys {
  static const band = ValueKey('dossier-map-band');
  static const locationCard = ValueKey('dossier-map-location-card');
  static const viewSwitcher = ValueKey('dossier-map-view-switcher');
  static const legend = ValueKey('dossier-map-legend');
  static const openCase = ValueKey('dossier-map-open-case');
  static Key connectedCase(String id) => ValueKey('dossier-connected-$id');
}
