import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../core/config/map_config.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../cases/application/cases_providers.dart';
import '../../../../cases/domain/true_crime_case.dart';
import '../../../../cases/presentation/case_category_presentation.dart';
import 'archive_control_bar.dart';
import 'case_status_chips.dart';
import 'situation_map_marker.dart';
import 'situation_styles.dart';

/// Lienzo central de la Sala de Situación: mapa oscuro con casos, conexiones,
/// densidad y todos los controles superpuestos.
class SituationMapStage extends ConsumerStatefulWidget {
  const SituationMapStage({super.key, this.showControls = true});

  /// En móvil ocultamos chips/leyenda densos para no saturar el lienzo.
  final bool showControls;

  @override
  ConsumerState<SituationMapStage> createState() => _SituationMapStageState();
}

class _SituationMapStageState extends ConsumerState<SituationMapStage> {
  final MapController _map = MapController();
  bool _ready = false;

  /// Si la cámara se puede mover ahora mismo.
  ///
  /// `onMapReady` se dispara aunque el mapa esté FUERA DE PANTALLA — por
  /// ejemplo con la Sala de Situación tapada por la ruta de un expediente —,
  /// pero su visor interactivo sólo se inicializa cuando de verdad se pinta.
  /// Mover la cámara en ese hueco revienta con un `LateInitializationError`
  /// dentro de flutter_map. Un mapa sin tamaño no está en pantalla, y a un mapa
  /// que no está en pantalla no hay nada que moverle.
  bool get _canMoveCamera {
    if (!_ready || !mounted) {
      return false;
    }
    final box = context.findRenderObject();
    return box is RenderBox && box.hasSize && !box.size.isEmpty;
  }

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  void _fitToCases(List<TrueCrimeCase> cases) {
    if (!_canMoveCamera || cases.isEmpty) return;
    final bounds = LatLngBounds.fromPoints(
      cases.map((c) => c.location).toList(growable: false),
    );
    _map.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(64)),
    );
  }

  void _showWorld() {
    ref.read(selectedCaseIdProvider.notifier).state = null;
    final visible = ref.read(filteredCasesProvider).value ?? const [];
    _fitToCases(visible);
  }

  void _showDetail() {
    final selected = ref.read(selectedCaseProvider).value;
    final config = ref.read(mapConfigProvider);
    if (selected != null) {
      _map.move(selected.location, config.focusZoom);
    } else {
      _map.move(_map.camera.center, (_map.camera.zoom + 1.5).clamp(2, 11));
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(mapConfigProvider);
    final visibleCases = ref.watch(filteredCasesProvider).value ?? const [];
    final selected = ref.watch(selectedCaseProvider).value;
    final related = selected == null
        ? const <RelatedCase>[]
        : ref.watch(relatedCasesProvider(selected.id));

    // Mueve la cámara al seleccionar un caso.
    ref.listen(selectedCaseProvider, (_, next) {
      final crimeCase = next.value;
      if (crimeCase != null && _canMoveCamera) {
        _map.move(crimeCase.location, config.focusZoom);
      }
    });

    // Recentra el caso seleccionado cuando lo pide un control externo.
    ref.listen(mapRecenterTickProvider, (_, _) {
      final crimeCase = ref.read(selectedCaseProvider).value;
      if (crimeCase != null && _canMoveCamera) {
        _map.move(crimeCase.location, config.focusZoom);
      }
    });

    final visibleIds = {for (final c in visibleCases) c.id};
    final relatedVisible = related
        .where((r) => visibleIds.contains(r.crimeCase.id))
        .toList(growable: false);
    final relatedIds = {for (final r in relatedVisible) r.crimeCase.id};

    return ClipRect(
      child: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: config.initialCenter,
                initialZoom: config.initialZoom,
                minZoom: config.minZoom,
                maxZoom: config.maxZoom,
                backgroundColor: AppColors.bgDeep,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onTap: (_, _) =>
                    ref.read(selectedCaseIdProvider.notifier).state = null,
                onMapReady: () {
                  _ready = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _fitToCases(visibleCases);
                  });
                },
              ),
              children: [
                if (config.tilesEnabled)
                  TileLayer(
                    urlTemplate: config.tileUrlTemplate,
                    subdomains: config.subdomains,
                    userAgentPackageName: config.userAgentPackageName,
                  ),
                const _DensityLayer(),
                if (selected != null && relatedVisible.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      for (final r in relatedVisible)
                        Polyline(
                          points: [selected.location, r.crimeCase.location],
                          strokeWidth: 1.4,
                          color: AppColors.gold.withValues(alpha: 0.78),
                          pattern: StrokePattern.dashed(segments: const [6, 8]),
                        ),
                    ],
                  ),
                if (selected != null && relatedVisible.isNotEmpty)
                  MarkerLayer(
                    markers: [
                      for (final r in relatedVisible)
                        Marker(
                          point: LatLng(
                            (selected.latitude + r.crimeCase.latitude) / 2,
                            (selected.longitude + r.crimeCase.longitude) / 2,
                          ),
                          width: 260,
                          height: 30,
                          child: Center(
                            child: ConnectionLabel(text: r.relation),
                          ),
                        ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    for (final crimeCase in visibleCases)
                      Marker(
                        point: crimeCase.location,
                        width: 44,
                        height: 44,
                        child: CaseMarker(
                          key: Key('marker-${crimeCase.id}'),
                          color: crimeCase.category.presentation.color,
                          selected: selected?.id == crimeCase.id,
                          related: relatedIds.contains(crimeCase.id),
                          dimmed:
                              selected != null &&
                              selected.id != crimeCase.id &&
                              !relatedIds.contains(crimeCase.id),
                          onTap: () =>
                              ref.read(selectedCaseIdProvider.notifier).state =
                                  crimeCase.id,
                        ),
                      ),
                    if (selected != null)
                      Marker(
                        point: selected.location,
                        width: 250,
                        height: 54,
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 18),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SelectedMarkerTooltip(crimeCase: selected),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (widget.showControls)
            Positioned(top: 14, left: 16, child: const CaseStatusChips()),
          if (widget.showControls)
            const Positioned(top: 14, right: 16, child: _RespectBadge()),
          if (widget.showControls)
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: ArchiveControlBar(
                onWorld: _showWorld,
                onDetail: _showDetail,
              ),
            ),
        ],
      ),
    );
  }
}

class _DensityLayer extends ConsumerWidget {
  const _DensityLayer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CircleLayer(
      circles: [
        for (final point in const [LatLng(39, -98), LatLng(50, 10)])
          CircleMarker(
            point: point,
            radius: 56,
            useRadiusInMeter: false,
            color: AppColors.statusOpen.withValues(alpha: 0.12),
            borderStrokeWidth: 0,
          ),
      ],
    );
  }
}

class _RespectBadge extends StatelessWidget {
  const _RespectBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bar.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.panelMuted),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.shield_outlined,
            size: 12,
            color: AppColors.textFaint,
          ),
          const SizedBox(width: 7),
          Text(
            'Crímenes reales · documentados con respeto',
            style: SituationStyles.mono(size: 10, color: AppColors.textSub),
          ),
        ],
      ),
    );
  }
}
