import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

class MapConfig {
  const MapConfig({
    required this.initialCenter,
    required this.initialZoom,
    required this.focusZoom,
    required this.tileUrlTemplate,
    required this.attribution,
    required this.userAgentPackageName,
    this.tilesEnabled = true,
    this.minZoom = 2,
    this.maxZoom = 7,
  });

  final LatLng initialCenter;
  final double initialZoom;
  final double focusZoom;
  final String tileUrlTemplate;
  final String attribution;
  final String userAgentPackageName;
  final bool tilesEnabled;
  final double minZoom;
  final double maxZoom;

  factory MapConfig.production() {
    return const MapConfig(
      initialCenter: LatLng(18, 5),
      initialZoom: 2.2,
      focusZoom: 4.8,
      tileUrlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      attribution: 'Mapa base © OpenStreetMap contributors',
      userAgentPackageName: 'com.example.true_app',
    );
  }

  factory MapConfig.testing() {
    return const MapConfig(
      initialCenter: LatLng(18, 5),
      initialZoom: 2.2,
      focusZoom: 4.8,
      tileUrlTemplate: '',
      attribution: 'Mapa de prueba',
      userAgentPackageName: 'com.example.true_app.test',
      tilesEnabled: false,
    );
  }
}

final mapConfigProvider = Provider<MapConfig>((ref) {
  return MapConfig.production();
});

final mapSectionGradientProvider = Provider<LinearGradient>((ref) {
  return const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B1B21), Color(0xFF111217), Color(0xFF0A0B0F)],
  );
});
