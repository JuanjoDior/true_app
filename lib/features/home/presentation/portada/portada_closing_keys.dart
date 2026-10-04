import 'package:flutter/widgets.dart';

/// Claves estables de la invitación al mapa, el pie y los estados de la portada.
abstract final class PortadaClosingKeys {
  static const Key mapInvite = ValueKey('portada-map-invite');
  static const Key mapInviteCard = ValueKey('portada-map-invite-card');
  static const Key mapLayer = ValueKey('portada-map-layer');
  static const Key footer = ValueKey('portada-footer');

  static const Key statusLoading = ValueKey('portada-status-loading');
  static const Key statusError = ValueKey('portada-status-error');
  static const Key statusEmpty = ValueKey('portada-status-empty');
}
