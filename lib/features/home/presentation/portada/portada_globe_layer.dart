import 'package:flutter/widgets.dart';

import '../../../../core/design/design.dart';
import 'portada_hero_layout.dart';

/// Globo en modo portada sobre el lienzo de 1440 px, escalado al ancho disponible.
class PortadaGlobeLayer extends StatelessWidget {
  const PortadaGlobeLayer({
    super.key,
    required this.markers,
    required this.camera,
    required this.selectedId,
    required this.haloColor,
  });

  final List<DsMapMarker> markers;
  final DsGlobeCamera camera;
  final String selectedId;
  final Color haloColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = constraints.maxWidth / PortadaLayout.canvasWidth;
        if (scale <= 0 || !constraints.hasBoundedHeight) {
          return const SizedBox.shrink();
        }
        return ClipRect(
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.topLeft,
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: PortadaLayout.canvasWidth,
              maxWidth: PortadaLayout.canvasWidth,
              minHeight: constraints.maxHeight / scale,
              maxHeight: constraints.maxHeight / scale,
              child: DsGlobeScene(
                markers: markers,
                camera: camera,
                selectedId: selectedId,
                haloColor: haloColor,
                showLabels: false,
              ),
            ),
          ),
        );
      },
    );
  }
}
