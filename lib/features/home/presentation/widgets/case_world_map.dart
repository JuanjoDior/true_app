import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../../core/config/map_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../cases/domain/true_crime_case.dart';

class CaseWorldMap extends StatelessWidget {
  const CaseWorldMap({
    super.key,
    required this.mapController,
    required this.mapConfig,
    required this.cases,
    required this.selectedCaseId,
    required this.hoveredCaseId,
    required this.onCaseTap,
    required this.onHoverChanged,
    required this.onBackgroundTap,
  });

  final MapController mapController;
  final MapConfig mapConfig;
  final List<TrueCrimeCase> cases;
  final String? selectedCaseId;
  final String? hoveredCaseId;
  final ValueChanged<TrueCrimeCase> onCaseTap;
  final ValueChanged<String?> onHoverChanged;
  final VoidCallback onBackgroundTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF151822),
                    Color(0xFF0F1016),
                    Color(0xFF090B10),
                  ],
                ),
              ),
              child: FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: mapConfig.initialCenter,
                  initialZoom: mapConfig.initialZoom,
                  minZoom: mapConfig.minZoom,
                  maxZoom: mapConfig.maxZoom,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                  onTap: (tapPosition, point) => onBackgroundTap(),
                ),
                children: [
                  if (mapConfig.tilesEnabled)
                    TileLayer(
                      urlTemplate: mapConfig.tileUrlTemplate,
                      userAgentPackageName: mapConfig.userAgentPackageName,
                    ),
                  MarkerLayer(
                    markers: cases
                        .map((crimeCase) {
                          final isSelected = selectedCaseId == crimeCase.id;
                          final isHovered = hoveredCaseId == crimeCase.id;

                          return Marker(
                            point: crimeCase.location,
                            width: 62,
                            height: 62,
                            child: _MapMarker(
                              key: Key('marker-${crimeCase.id}'),
                              crimeCase: crimeCase,
                              isHovered: isHovered,
                              isSelected: isSelected,
                              onTap: () => onCaseTap(crimeCase),
                              onHoverChanged: onHoverChanged,
                            ),
                          );
                        })
                        .toList(growable: false),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 18,
            left: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xCC111317),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                '${cases.length} puntos curados',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xCC0E1014),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                mapConfig.attribution,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({
    super.key,
    required this.crimeCase,
    required this.isHovered,
    required this.isSelected,
    required this.onTap,
    required this.onHoverChanged,
  });

  final TrueCrimeCase crimeCase;
  final bool isHovered;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<String?> onHoverChanged;

  @override
  Widget build(BuildContext context) {
    final scale = isSelected
        ? 1.14
        : isHovered
        ? 1.06
        : 1.0;

    return Tooltip(
      message: crimeCase.title,
      child: MouseRegion(
        onEnter: (_) => onHoverChanged(crimeCase.id),
        onExit: (_) => onHoverChanged(null),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 180),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -4),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.gold : AppColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.7),
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  child: Icon(
                    Icons.location_on_rounded,
                    size: 32,
                    color: isSelected ? AppColors.gold : AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
