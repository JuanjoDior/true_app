import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/config/map_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../home/presentation/widgets/situation/situation_styles.dart';

/// Mapa para señalar dónde ocurrió el caso.
///
/// Marcar el punto en el mapa sustituye a escribir latitud y longitud a mano,
/// que es la parte del formulario que nadie sabe rellenar de memoria.
class LocationPickerMap extends ConsumerStatefulWidget {
  const LocationPickerMap({
    super.key,
    required this.point,
    required this.onPointSelected,
    this.height = 240,
  });

  /// Punto ya marcado, si el borrador tiene coordenadas.
  final LatLng? point;
  final ValueChanged<LatLng> onPointSelected;
  final double height;

  @override
  ConsumerState<LocationPickerMap> createState() => _LocationPickerMapState();
}

class _LocationPickerMapState extends ConsumerState<LocationPickerMap> {
  final MapController _map = MapController();

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(mapConfigProvider);
    final point = widget.point;

    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            FlutterMap(
              key: const Key('intake-location-map'),
              mapController: _map,
              options: MapOptions(
                initialCenter: point ?? config.initialCenter,
                initialZoom: point == null
                    ? config.initialZoom
                    : config.focusZoom,
                minZoom: config.minZoom,
                maxZoom: config.maxZoom,
                onTap: (_, latLng) => widget.onPointSelected(latLng),
              ),
              children: [
                if (config.tilesEnabled)
                  TileLayer(
                    urlTemplate: config.tileUrlTemplate,
                    subdomains: config.subdomains,
                    userAgentPackageName: config.userAgentPackageName,
                  ),
                if (point != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: point,
                        width: 26,
                        height: 26,
                        child: const _SelectedPointMarker(),
                      ),
                    ],
                  ),
              ],
            ),
            if (point == null)
              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bar.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.panelMuted),
                  ),
                  child: Text(
                    'Toca el mapa para situar el caso',
                    style: SituationStyles.sans(
                      size: 11,
                      color: AppColors.textSub,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SelectedPointMarker extends StatelessWidget {
  const _SelectedPointMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.25),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.gold, width: 2),
      ),
      child: const Center(
        child: Icon(Icons.place, size: 13, color: AppColors.gold),
      ),
    );
  }
}
