import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:latlong2/latlong.dart';

class MapConfig {
  const MapConfig({
    required this.initialCenter,
    required this.initialZoom,
    required this.focusZoom,
    required this.tileUrlTemplate,
    required this.attribution,
    required this.userAgentPackageName,
    this.subdomains = const ['a', 'b', 'c', 'd'],
    this.tilesEnabled = true,
    this.minZoom = 2,
    this.maxZoom = 11,
  });

  final LatLng initialCenter;
  final double initialZoom;
  final double focusZoom;
  final String tileUrlTemplate;
  final String attribution;
  final String userAgentPackageName;
  final List<String> subdomains;
  final bool tilesEnabled;
  final double minZoom;
  final double maxZoom;

  factory MapConfig.production() {
    // CARTO dejó de servir sus teselas oscuras sin clave (devuelve una marca de agua).
    return const MapConfig(
      initialCenter: LatLng(40, 0),
      initialZoom: 2.4,
      focusZoom: 6,
      tileUrlTemplate:
          'https://services.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}',
      attribution: 'Mapa © Esri · OpenStreetMap',
      userAgentPackageName: 'com.example.true_app',
    );
  }

  factory MapConfig.testing() {
    return const MapConfig(
      initialCenter: LatLng(40, 0),
      initialZoom: 2.4,
      focusZoom: 6,
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

/// Contador que, al incrementarse, pide al mapa recentrar el caso seleccionado.
/// Permite que controles fuera del mapa (p. ej. el botón "Centrar" del dossier)
/// disparen un recentrado sin acoplarse al `MapController`.
final mapRecenterTickProvider = StateProvider<int>((ref) => 0);

final mapSectionGradientProvider = Provider<LinearGradient>((ref) {
  return const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B1B21), Color(0xFF111217), Color(0xFF0A0B0F)],
  );
});
