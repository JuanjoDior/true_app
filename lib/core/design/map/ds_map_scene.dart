import 'package:flutter/gestures.dart' show PointerHoverEvent, TapUpDetails;
import 'package:flutter/widgets.dart';

import '../tokens/ds_motion.dart';
import 'ds_map_camera.dart';
import 'ds_map_camera_animation.dart';
import 'ds_map_land_layer_painter.dart';
import 'ds_map_marker.dart';
import 'ds_map_marker_layer_painter.dart';
import 'ds_map_marker_layout.dart';

/// Mapa plano: capa de tierra, marcadores y cámara animada (doc 2.1–2.3).
class DsMapScene extends StatefulWidget {
  const DsMapScene({
    super.key,
    required this.markers,
    required this.camera,
    this.selectedId,
    this.relatedIds = const {},
    this.matchingIds,
    this.timelineYear,
    this.mobile = false,
    this.verticalOffset = 0,
    this.onMarkerTap,
    this.landDotDiameter,
  });

  static const double landDotDiameterDesktop = 5;
  static const double landDotDiameterMobile = 6;

  final List<DsMapMarker> markers;
  final DsMapCamera camera;
  final String? selectedId;
  final Set<String> relatedIds;

  /// `null`: todos los marcadores cumplen el filtro.
  final Set<String>? matchingIds;

  /// `null`: sin filtro por año.
  final int? timelineYear;
  final bool mobile;
  final double verticalOffset;
  final ValueChanged<String>? onMarkerTap;
  final double? landDotDiameter;

  @override
  State<DsMapScene> createState() => _DsMapSceneState();
}

class _DsMapSceneState extends State<DsMapScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curve;
  late DsMapCameraTween _tween;
  bool _overMarker = false;

  @override
  void initState() {
    super.initState();
    _tween = DsMapCameraTween(begin: widget.camera, end: widget.camera);
    // value 1: la primera cámara se muestra sin animar.
    _controller = AnimationController(vsync: this, value: 1);
    _curve = CurvedAnimation(parent: _controller, curve: DsMotion.easeFly);
  }

  @override
  void didUpdateWidget(DsMapScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.camera == oldWidget.camera) return;
    // Parte de la cámara mostrada ahora, no del destino anterior.
    _tween = DsMapCameraTween(begin: _displayedCamera, end: widget.camera);
    _controller.duration = DsMapCameraAnimation.duration(
      reduceMotion: MediaQuery.disableAnimationsOf(context),
    );
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  DsMapCamera get _displayedCamera => _tween.evaluate(_curve);

  List<DsMapMarkerPlacement> _placementsFor(DsMapCamera camera) =>
      DsMapMarkerLayout.place(
        markers: widget.markers,
        camera: camera,
        verticalOffset: widget.verticalOffset,
        selectedId: widget.selectedId,
        relatedIds: widget.relatedIds,
        matchingIds: widget.matchingIds,
        timelineYear: widget.timelineYear,
        mobile: widget.mobile,
      );

  void _handleTapUp(TapUpDetails details) {
    final onTap = widget.onMarkerTap;
    if (onTap == null) return;
    final hit = DsMapMarkerLayout.hitTest(
      _placementsFor(_displayedCamera),
      details.localPosition,
    );
    if (hit != null) onTap(hit.marker.id);
  }

  void _handleHover(PointerHoverEvent event) {
    final over =
        widget.onMarkerTap != null &&
        DsMapMarkerLayout.hitTest(
              _placementsFor(_displayedCamera),
              event.localPosition,
            ) !=
            null;
    _setOverMarker(over);
  }

  void _setOverMarker(bool value) {
    if (value != _overMarker) setState(() => _overMarker = value);
  }

  @override
  Widget build(BuildContext context) {
    final landDotDiameter =
        widget.landDotDiameter ??
        (widget.mobile
            ? DsMapScene.landDotDiameterMobile
            : DsMapScene.landDotDiameterDesktop);
    return MouseRegion(
      cursor: _overMarker ? SystemMouseCursors.click : MouseCursor.defer,
      onHover: _handleHover,
      onExit: (_) => _setOverMarker(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTapUp: _handleTapUp,
        child: SizedBox.expand(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final camera = _displayedCamera;
              // Capas de abajo arriba: tierra, efectos (arcos, pulsos), marcadores.
              return Stack(
                fit: StackFit.expand,
                children: [
                  ExcludeSemantics(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: DsMapLandLayerPainter(
                          camera: camera,
                          verticalOffset: widget.verticalOffset,
                          dotDiameter: landDotDiameter,
                        ),
                      ),
                    ),
                  ),
                  CustomPaint(
                    painter: DsMapMarkerLayerPainter(
                      placements: _placementsFor(camera),
                      onMarkerTap: widget.onMarkerTap,
                      textDirection: Directionality.of(context),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
