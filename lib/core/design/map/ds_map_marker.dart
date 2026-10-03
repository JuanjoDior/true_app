import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' show immutable;

@immutable
class DsMapMarker {
  const DsMapMarker({
    required this.id,
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.color,
    required this.year,
  });

  final String id;
  final String label;
  final double latitude;
  final double longitude;
  final Color color;
  final int year;

  @override
  bool operator ==(Object other) =>
      other is DsMapMarker &&
      other.id == id &&
      other.label == label &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.color == color &&
      other.year == year;

  @override
  int get hashCode => Object.hash(id, label, latitude, longitude, color, year);
}
