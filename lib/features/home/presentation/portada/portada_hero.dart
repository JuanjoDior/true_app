import 'package:flutter/widgets.dart';

import '../../../../core/design/design.dart';
import '../../../cases/domain/true_crime_case.dart';
import '../../../cases/presentation/design/case_design_mapping.dart';
import 'portada_carousel_controller.dart';
import 'portada_globe_layer.dart';
import 'portada_hero_background.dart';
import 'portada_hero_keys.dart';
import 'portada_hero_layout.dart';
import 'portada_slide_motion.dart';
import 'portada_slide_view.dart';
import 'portada_tabs.dart';

/// Héroe «En el foco»: globo que gira al caso activo, carrusel de 7 s y pestañas.
class PortadaHero extends StatefulWidget {
  const PortadaHero({
    super.key,
    required this.featured,
    required this.allCases,
    required this.onOpenCase,
    required this.onExploreCase,
    this.initialIndex = 0,
  });

  /// Casos del carrusel, en orden.
  final List<TrueCrimeCase> featured;

  /// Todos los casos: son los marcadores del globo.
  final List<TrueCrimeCase> allCases;
  final int initialIndex;
  final ValueChanged<TrueCrimeCase> onOpenCase;
  final ValueChanged<TrueCrimeCase> onExploreCase;

  @override
  State<PortadaHero> createState() => _PortadaHeroState();
}

class _PortadaHeroState extends State<PortadaHero>
    with TickerProviderStateMixin {
  late final PortadaCarouselController _carousel;
  final Map<String, PortadaSlideMotion> _layers = {};
  late List<DsMapMarker> _markers;
  DsGlobeCamera? _camera;
  String? _activeId;
  bool _hovered = false;
  bool _focused = false;
  bool _reduceMotion = false;

  TrueCrimeCase? get _activeCase {
    final featured = widget.featured;
    if (featured.isEmpty) return null;
    return featured[_carousel.index];
  }

  @override
  void initState() {
    super.initState();
    _markers = _markersOf(widget.allCases);
    _carousel = PortadaCarouselController(
      length: widget.featured.length,
      vsync: this,
      initialIndex: widget.initialIndex,
    )..addListener(_handleSlideChanged);
    _syncSlide(initial: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _syncPause();
  }

  @override
  void didUpdateWidget(PortadaHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.allCases, widget.allCases)) {
      _markers = _markersOf(widget.allCases);
    }
    if (!identical(oldWidget.featured, widget.featured)) {
      final ids = {for (final crimeCase in widget.featured) crimeCase.id};
      _layers.removeWhere((id, motion) {
        final dropped = !ids.contains(id);
        if (dropped) motion.dispose();
        return dropped;
      });
      // El ajuste de longitud notifica si el índice cambia; aquí se resuelve a mano.
      _carousel.removeListener(_handleSlideChanged);
      _carousel.length = widget.featured.length;
      _carousel.addListener(_handleSlideChanged);
      _syncSlide();
    }
  }

  @override
  void dispose() {
    _carousel.removeListener(_handleSlideChanged);
    _carousel.dispose();
    for (final motion in _layers.values) {
      motion.dispose();
    }
    super.dispose();
  }

  static List<DsMapMarker> _markersOf(List<TrueCrimeCase> cases) => [
    for (final crimeCase in cases) crimeCase.toMapMarker(),
  ];

  void _handleSlideChanged() => setState(_syncSlide);

  void _syncSlide({bool initial = false}) {
    final active = _activeCase;
    if (active?.id == _activeId) return;
    final previousId = _activeId;
    _activeId = active?.id;

    if (previousId != null) {
      _layers[previousId]?.exit(reduceMotion: _reduceMotion);
    }
    if (active != null) {
      // Conserva gy para que el globo gire por el camino corto.
      _camera = DsGlobeCameraTargets.cover(
        latitude: active.latitude,
        longitude: active.longitude,
        currentGy: _camera?.gy ?? 0,
      );
      final existing = _layers[active.id];
      if (existing != null) {
        existing.enter(reduceMotion: _reduceMotion);
      } else {
        final motion = PortadaSlideMotion(vsync: this, visible: initial);
        _layers[active.id] = motion;
        if (!initial) motion.enter(reduceMotion: _reduceMotion);
      }
    }
    _disposeGoneLayers();
  }

  void _disposeGoneLayers() {
    _layers.removeWhere((id, motion) {
      final gone = motion.isGone && id != _activeId;
      if (gone) motion.dispose();
      return gone;
    });
  }

  void _setHovered(bool value) {
    _hovered = value;
    _syncPause();
  }

  void _setFocused(bool value) {
    _focused = value;
    _syncPause();
  }

  // Con movimiento reducido el carrusel no corre: solo cambia por la acción de la persona.
  void _syncPause() {
    if (_reduceMotion || _hovered || _focused) {
      _carousel.pause();
    } else {
      _carousel.resume();
    }
  }

  @override
  Widget build(BuildContext context) {
    final featured = widget.featured;
    final active = _activeCase;
    final camera = _camera;

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: _setFocused,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(
              child: PortadaBackground(key: PortadaHeroKeys.background),
            ),
            if (active != null && camera != null) ...[
              Positioned.fill(
                child: PortadaGlobeLayer(
                  key: PortadaHeroKeys.globe,
                  markers: _markers,
                  camera: camera,
                  selectedId: active.id,
                  haloColor: active.category.designColor.dot,
                ),
              ),
              const PortadaVeil(),
            ],
            for (var i = 0; i < featured.length; i++)
              if (_layers[featured[i].id] case final motion?)
                Positioned.fill(
                  key: ValueKey(featured[i].id),
                  child: PortadaSlideView(
                    crimeCase: featured[i],
                    motion: motion,
                    position: i + 1,
                    count: featured.length,
                    onOpen: () => widget.onOpenCase(featured[i]),
                    onExplore: () => widget.onExploreCase(featured[i]),
                  ),
                ),
            if (active != null)
              Positioned(
                left: PortadaLayout.margin,
                bottom: PortadaLayout.tabsBottom,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: PortadaLayout.tabsWidth,
                  ),
                  child: PortadaTabs(
                    featured: featured,
                    activeIndex: _carousel.index,
                    progress: _carousel.progress,
                    reduceMotion: _reduceMotion,
                    onSelect: _carousel.select,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
