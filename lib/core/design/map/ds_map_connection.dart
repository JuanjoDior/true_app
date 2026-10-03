import 'package:flutter/foundation.dart' show immutable;

/// Relación entre dos marcadores, dibujada como arco (doc 2.4).
@immutable
class DsMapConnection {
  const DsMapConnection({
    required this.fromId,
    required this.toId,
    required this.label,
  });

  final String fromId;
  final String toId;
  final String label;

  @override
  bool operator ==(Object other) =>
      other is DsMapConnection &&
      other.fromId == fromId &&
      other.toId == toId &&
      other.label == label;

  @override
  int get hashCode => Object.hash(fromId, toId, label);
}
