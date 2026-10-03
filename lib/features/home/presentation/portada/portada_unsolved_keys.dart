import 'package:flutter/widgets.dart';

/// Claves estables de la fila «Sin resolver» y sus pósters, para pruebas.
abstract final class PortadaUnsolvedKeys {
  static const Key row = ValueKey('portada-unsolved-row');

  static Key poster(String caseId) => ValueKey('portada-poster-$caseId');
  static Key posterBackdrop(String caseId) =>
      ValueKey('portada-poster-backdrop-$caseId');
  static Key posterPhoto(String caseId) =>
      ValueKey('portada-poster-photo-$caseId');
  static Key posterGhostYear(String caseId) =>
      ValueKey('portada-poster-ghost-$caseId');
  static Key posterBase(String caseId) =>
      ValueKey('portada-poster-base-$caseId');
  static Key posterMore(String caseId) =>
      ValueKey('portada-poster-more-$caseId');
}
