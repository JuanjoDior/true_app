import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../cases/domain/true_crime_case.dart';
import 'situation_styles.dart';

/// Marcador de un caso en el mapa. Cambia de tamaño y halo según su estado de
/// selección/relación, replicando el comportamiento del diseño.
class CaseMarker extends StatelessWidget {
  const CaseMarker({
    super.key,
    required this.color,
    required this.selected,
    required this.related,
    required this.dimmed,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final bool related;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = selected ? 18.0 : 12.0;
    final glow = related
        ? [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.55),
              blurRadius: 0,
              spreadRadius: 3,
            ),
            BoxShadow(color: color, blurRadius: 14, spreadRadius: 3),
          ]
        : [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 12, spreadRadius: 2)];

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedOpacity(
          opacity: dimmed ? 0.32 : 1,
          duration: const Duration(milliseconds: 350),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (selected) _RadarRing(color: color, size: size + 14),
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: selected ? 0.92 : 0.5,
                    ),
                    width: 1.5,
                  ),
                  boxShadow: glow,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Anillo que pulsa alrededor del caso seleccionado.
class _RadarRing extends StatefulWidget {
  const _RadarRing({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  State<_RadarRing> createState() => _RadarRingState();
}

class _RadarRingState extends State<_RadarRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final scale = 0.4 + t * 1.4;
        final opacity = (0.55 * (1 - t)).clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: widget.color, width: 1.5),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Etiqueta de la relación entre dos casos, en el punto medio de la conexión.
class ConnectionLabel extends StatelessWidget {
  const ConnectionLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bar.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: SituationStyles.mono(
          size: 10,
          weight: FontWeight.w500,
          color: AppColors.gold,
        ),
      ),
    );
  }
}

/// Tooltip permanente del caso seleccionado, junto a su marcador.
class SelectedMarkerTooltip extends StatelessWidget {
  const SelectedMarkerTooltip({super.key, required this.crimeCase});

  final TrueCrimeCase crimeCase;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgDeep.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2A3340)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 2, color: AppColors.accent),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      crimeCase.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SituationStyles.serif(size: 13, height: 1.1),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${crimeCase.regionOrCity} · ${crimeCase.year}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SituationStyles.mono(size: 10, color: AppColors.textSub),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
