import 'package:flutter/gestures.dart' show PointerHoverEvent, TapUpDetails;
import 'package:flutter/widgets.dart';

import '../map/ds_map_connection.dart';
import '../map/ds_map_marker.dart';
import '../map/ds_map_marker_layer_painter.dart';
import '../map/ds_map_marker_layout.dart';
import '../tokens/ds_motion.dart';
import 'ds_globe_arc_painter.dart';
import 'ds_globe_body_painter.dart';
import 'ds_globe_camera.dart';
import 'ds_globe_camera_animation.dart';
import 'ds_globe_effects_controller.dart';
import 'ds_globe_label_painter.dart';
import 'ds_globe_land_painter.dart';
import 'ds_globe_marker_projection.dart';

/// Globo 3D: halo, esfera, tierra, arcos, marcadores y etiquetas con cámara animada y deriva (doc 3.1–3.4).
class DsGlobeScene extends StatefulWidget {
  const DsGlobeScene({
    super.key,
    required this.markers,
    required this.camera,
    this.selectedId,
    this.relatedIds = const {},
    this.matchingIds,
    this.timelineYear,
    this.haloColor,
    this.showLabels = true,
    this.connections = const [],
    this.onMarkerTap,
  });

  final List<DsMapMarker> markers;
  final DsGlobeCamera camera;
  final String? selectedId;
  final Set<String> relatedIds;

  /// `null`: todos los marcadores cumplen el filtro.
  final Set<String>? matchingIds;

  /// `null`: sin filtro por año.
  final int? timelineYear;

  /// `null`: sin halo.
  final Color? haloColor;
  final bool showLabels;

  /// Pares ya filtrados por la pantalla; los ids desconocidos u ocultos se omiten.
  final List<DsMapConnection> connections;
  final ValueChanged<String>? onMarkerTap;

  @override
  State<DsGlobeScene> createState() => _DsGlobeSceneState();
}

class _DsGlobeSceneState extends State<DsGlobeScene>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curve;
  late DsGlobeCameraTween _tween;
  late final DsGlobeEffectsController _effects;
  late final Listenable _frames;
  bool _overMarker = false;

  @override
  void initState() {
    super.initState();
    _tween = DsGlobeCameraTween(begin: widget.camera, end: widget.camera);
    // value 1: la primera cámara se muestra sin animar.
    _controller = AnimationController(vsync: this, value: 1);
    _curve = CurvedAnimation(parent: _controller, curve: DsMotion.easeGlobe);
    _effects = DsGlobeEffectsController(vsync: this);
    _frames = Listenable.merge([_controller, _effects]);
    _controller.addStatusListener(_handleFlightStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncEffects();
  }

  @override
  void didUpdateWidget(DsGlobeScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.camera != oldWidget.camera) _startFlight();
    _syncEffects();
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_handleFlightStatus);
    _effects.dispose();
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _startFlight() {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    // Parte de la cámara mostrada ahora (con deriva), no del destino anterior.
    _tween = DsGlobeCameraTween(begin: _displayedCamera, end: widget.camera);
    _effects.startFlight(reduceMotion: reduceMotion);
    _controller.duration = DsGlobeCameraAnimation.duration(
      reduceMotion: reduceMotion,
    );
    _controller.forward(from: 0);
  }

  void _handleFlightStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _syncEffects();
  }

  void _syncEffects() {
    _effects.sync(
      arcKeys: DsGlobeArcLayout.keys(
        connections: widget.connections,
        markers: widget.markers,
      ),
      reduceMotion: MediaQuery.disableAnimationsOf(context),
      hasSelection: widget.selectedId != null,
      flying: _controller.isAnimating,
    );
  }

  DsGlobeCamera get _displayedCamera =>
      _tween.evaluate(_curve).drifted(degrees: _effects.driftDegrees);

  List<DsGlobePlacedMarker> _placedFor(DsGlobeCamera camera) =>
      DsGlobeMarkerProjection.place(
        markers: widget.markers,
        camera: camera,
        selectedId: widget.selectedId,
        relatedIds: widget.relatedIds,
        matchingIds: widget.matchingIds,
        timelineYear: widget.timelineYear,
      );

  DsMapMarkerPlacement? _hitAt(Offset position) => DsMapMarkerLayout.hitTest(
    DsGlobeMarkerProjection.placementsOf(_placedFor(_displayedCamera)),
    position,
  );

  void _handleTapUp(TapUpDetails details) {
    final onTap = widget.onMarkerTap;
    if (onTap == null) return;
    final hit = _hitAt(details.localPosition);
    if (hit != null) onTap(hit.marker.id);
  }

  void _handleHover(PointerHoverEvent event) {
    _setOverMarker(
      widget.onMarkerTap != null && _hitAt(event.localPosition) != null,
    );
  }

  void _setOverMarker(bool value) {
    if (value != _overMarker) setState(() => _overMarker = value);
  }

  @override
  Widget build(BuildContext context) {
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
            animation: _frames,
            builder: (context, _) {
              final camera = _displayedCamera;
              final placed = _placedFor(camera);
              // Capas de abajo arriba: halo, esfera, tierra, arcos, sombreado, marcadores, etiquetas.
              return Stack(
                fit: StackFit.expand,
                children: [
                  ExcludeSemantics(
                    child: IgnorePointer(
                      child: RepaintBoundary(
                        child: DsGlobeHalo(
                          camera: camera,
                          color: widget.haloColor,
                        ),
                      ),
                    ),
                  ),
                  ExcludeSemantics(
                    child: IgnorePointer(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: DsGlobeBodyPainter(camera: camera),
                        ),
                      ),
                    ),
                  ),
                  ExcludeSemantics(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: DsGlobeLandPainter(camera: camera),
                      ),
                    ),
                  ),
                  ExcludeSemantics(
                    child: IgnorePointer(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: DsGlobeArcPainter(
                            camera: camera,
                            arcs: DsGlobeArcLayout.visible(
                              connections: widget.connections,
                              placed: placed,
                            ),
                            elapsedOf: _effects.arcElapsed,
                            repaint: _effects.revealRepaint,
                          ),
                        ),
                      ),
                    ),
                  ),
                  ExcludeSemantics(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: DsGlobeShadingPainter(camera: camera),
                      ),
                    ),
                  ),
                  CustomPaint(
                    painter: DsMapMarkerLayerPainter(
                      placements: DsGlobeMarkerProjection.placementsOf(placed),
                      onMarkerTap: widget.onMarkerTap,
                      textDirection: Directionality.of(context),
                    ),
                  ),
                  ExcludeSemantics(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: DsGlobeLabelPainter(
                          markers: placed,
                          showLabels:
                              widget.showLabels && _effects.labelsVisible,
                          textDirection: Directionality.of(context),
                        ),
                      ),
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
