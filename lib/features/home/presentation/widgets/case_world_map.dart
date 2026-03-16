import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../../core/config/map_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../cases/domain/case_category.dart';
import '../../../cases/domain/true_crime_case.dart';
import '../../../cases/presentation/case_category_presentation.dart';

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
                cases.isEmpty
                    ? 'Sin marcadores publicados'
                    : '${cases.length} marcadores visibles',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
          const Positioned(left: 18, bottom: 54, child: _MapLegend()),
          if (cases.isEmpty) const Positioned.fill(child: _MapEmptyState()),
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

class _MapEmptyState extends StatelessWidget {
  const _MapEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IgnorePointer(
      child: Center(
        child: Container(
          key: const Key('case-world-map-empty-state'),
          constraints: const BoxConstraints(maxWidth: 420),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xE612151B),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 28,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aún no hay casos publicados en el mapa.',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'La estructura ya está lista para cargar expedientes por tipo y visualizarlos por ubicación.',
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xCC111317),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tipos de caso',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppColors.gold),
          ),
          const SizedBox(height: 10),
          ...CaseCategory.values.map((category) {
            final presentation = category.presentation;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: presentation.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    presentation.shortLabel,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            );
          }),
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
    final color = crimeCase.category.presentation.color;
    final scale = isSelected
        ? 1.14
        : isHovered
        ? 1.06
        : 1.0;

    return Tooltip(
      message: '${crimeCase.title} · ${crimeCase.category.presentation.label}',
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
                    color: color.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -4),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.gold : color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.72),
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
                    color: isSelected ? AppColors.gold : color,
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
