import 'package:flutter/widgets.dart';

import '../../../../core/design/design.dart';
import 'portada_hero_layout.dart';

/// Globo en modo portada: la cámara de portada sobre su lienzo de diseño,
/// trasladada y escalada para que la esfera caiga en el sitio que fija el héroe.
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
        if (!constraints.hasBoundedWidth || !constraints.hasBoundedHeight) {
          return const SizedBox.shrink();
        }
        final placement = PortadaLayout.globePlacement(constraints.biggest);
        final scale = placement.radius / (DsGlobeMath.radius * camera.scale);
        if (scale <= 0) return const SizedBox.shrink();
        final offset = placement.center - camera.center * scale;
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: PortadaLayout.globeCanvasWidth,
            maxWidth: PortadaLayout.globeCanvasWidth,
            minHeight: PortadaLayout.globeCanvasHeight,
            maxHeight: PortadaLayout.globeCanvasHeight,
            child: Transform(
              transform: Matrix4.translationValues(offset.dx, offset.dy, 0)
                ..scaleByDouble(scale, scale, 1, 1),
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
