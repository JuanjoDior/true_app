import 'package:flutter/widgets.dart';

abstract final class DossierBodyKeys {
  static const victims = Key('dossier-victims');
  static const detailPanel = Key('dossier-detail-panel');
  static const aside = Key('dossier-aside');
  static const footer = Key('dossier-footer');
}

abstract final class DossierBodyMetrics {
  static const double asideWidth = 400;
}
