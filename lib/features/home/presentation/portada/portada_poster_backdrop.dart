import 'package:flutter/widgets.dart';

import '../../../../core/design/design.dart';
import '../../../cases/domain/true_crime_case.dart';
import '../../../cases/presentation/design/case_design_mapping.dart';
import 'portada_unsolved_keys.dart';
import 'portada_unsolved_layout.dart';

/// Fondo del póster: degradado de la categoría y, encima, `photos.first` si existe.
///
/// Sin foto, o si la imagen falla, queda el color de la categoría con el año
/// fantasma.
class PortadaPosterBackdrop extends StatelessWidget {
  const PortadaPosterBackdrop({
    super.key,
    required this.crimeCase,
    required this.metrics,
  });

  final TrueCrimeCase crimeCase;
  final PortadaPosterMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final color = crimeCase.category.designColor;
    final id = crimeCase.id;
    final ghost = _PosterGhostYear(
      key: PortadaUnsolvedKeys.posterGhostYear(id),
      year: crimeCase.year,
      metrics: metrics,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          key: PortadaUnsolvedKeys.posterBackdrop(id),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: PortadaPosterMetrics.gradientBegin,
              end: PortadaPosterMetrics.gradientEnd,
              colors: [color.posterBase, DsColors.bgBase],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: PortadaPosterMetrics.glowCenter,
              radius: PortadaPosterMetrics.glowRadius,
              colors: [
                color.dot.withValues(alpha: PortadaPosterMetrics.glowAlpha),
                DsColors.transparent,
              ],
              stops: const [0, PortadaPosterMetrics.glowStop],
            ),
          ),
        ),
        if (crimeCase.photos.isEmpty)
          ghost
        else
          Image.network(
            crimeCase.photos.first.url,
            key: PortadaUnsolvedKeys.posterPhoto(id),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => ghost,
          ),
      ],
    );
  }
}

class _PosterGhostYear extends StatelessWidget {
  const _PosterGhostYear({
    super.key,
    required this.year,
    required this.metrics,
  });

  final int year;
  final PortadaPosterMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final style = DsTextStylesResolver.of(context).displayGhostYear.copyWith(
      fontSize: metrics.ghostFontSize,
      height: 1,
      color: DsColors.textStrong.withValues(
        alpha: PortadaPosterMetrics.ghostAlpha,
      ),
    );

    // Decoración pura: no crece con el tamaño de texto del sistema ni se anuncia.
    return ExcludeSemantics(
      child: Stack(
        children: [
          Positioned(
            right: metrics.ghostRight,
            top: metrics.ghostTop,
            child: Text(
              '$year',
              style: style,
              textScaler: TextScaler.noScaling,
              softWrap: false,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
