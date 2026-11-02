import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/design/design.dart';
import '../../../cases/domain/true_crime_case.dart';
import '../../../cases/presentation/design/case_design_mapping.dart';
import 'portada_poster_backdrop.dart';
import 'portada_unsolved_keys.dart';
import 'portada_unsolved_layout.dart';

/// Póster apaisado de un caso: título y lugar en reposo, resumen al pasar el ratón.
class PortadaPosterCard extends StatelessWidget {
  const PortadaPosterCard({
    super.key,
    required this.crimeCase,
    required this.onOpen,
    required this.onHoverChanged,
    this.dimmed = false,
  });

  final TrueCrimeCase crimeCase;
  final VoidCallback onOpen;

  /// Solo se notifica el hover de ratón; el táctil no lo produce.
  final ValueChanged<bool> onHoverChanged;

  /// Otro póster de la fila está bajo el ratón.
  final bool dimmed;

  String get _semanticLabel =>
      '${crimeCase.title}. ${crimeCase.regionOrCity}, ${crimeCase.year}. '
      '${crimeCase.statusLabel ?? crimeCase.status.label}';

  @override
  Widget build(BuildContext context) {
    final metrics = PortadaPosterMetrics.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return AnimatedOpacity(
      opacity: dimmed ? PortadaPosterMetrics.dimmedOpacity : 1,
      duration: DsMotion.resolve(DsMotion.hover, reduceMotion: reduceMotion),
      curve: DsMotion.easeUi,
      child: MouseRegion(
        onEnter: (event) {
          if (event.kind == PointerDeviceKind.mouse) onHoverChanged(true);
        },
        onExit: (_) => onHoverChanged(false),
        child: DsPressable(
          onTap: onOpen,
          semanticLabel: _semanticLabel,
          hoverScale: PortadaPosterMetrics.hoverScale,
          minTapTarget: PortadaPosterMetrics.minTapTarget,
          focusRadius: DsRadii.card,
          builder: (context, state) => _PosterFace(
            crimeCase: crimeCase,
            metrics: metrics,
            hovered: state.hovered,
            reduceMotion: reduceMotion,
          ),
        ),
      ),
    );
  }
}

class _PosterFace extends StatelessWidget {
  const _PosterFace({
    required this.crimeCase,
    required this.metrics,
    required this.hovered,
    required this.reduceMotion,
  });

  final TrueCrimeCase crimeCase;
  final PortadaPosterMetrics metrics;
  final bool hovered;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final id = crimeCase.id;
    // La escala del hover también agranda el desplazamiento: se compensa para
    // que el póster suba 12 px reales, como `translateY(-12px) scale(1.06)`.
    final lift = hovered && !reduceMotion
        ? PortadaPosterMetrics.hoverLift / PortadaPosterMetrics.hoverScale
        : 0.0;

    // El borde va en primer plano: un borde en `decoration` encogería el póster.
    return AnimatedContainer(
      duration: DsMotion.resolve(DsMotion.hover, reduceMotion: reduceMotion),
      curve: DsMotion.easeUi,
      transform: Matrix4.translationValues(0, -lift, 0),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: DsRadii.cardBorder,
        boxShadow: hovered ? DsShadows.posterHover : const <BoxShadow>[],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: DsRadii.cardBorder,
        border: Border.all(color: DsColors.lineHairline),
      ),
      child: SizedBox(
        key: PortadaUnsolvedKeys.poster(id),
        width: metrics.width,
        height: metrics.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PortadaPosterBackdrop(crimeCase: crimeCase, metrics: metrics),
            Positioned(
              top: DsSpacing.s16,
              left: DsSpacing.s20,
              right: DsSpacing.s20,
              child: DsMonoLabel(
                crimeCase.category.label,
                color: crimeCase.category.designColor.dot,
                letterSpacingEm: 0.14,
              ),
            ),
            _BaseLayer(
              crimeCase: crimeCase,
              metrics: metrics,
              visible: !hovered,
              reduceMotion: reduceMotion,
            ),
            _MoreLayer(
              crimeCase: crimeCase,
              metrics: metrics,
              visible: hovered,
              reduceMotion: reduceMotion,
            ),
          ],
        ),
      ),
    );
  }
}

class _BaseLayer extends StatelessWidget {
  const _BaseLayer({
    required this.crimeCase,
    required this.metrics,
    required this.visible,
    required this.reduceMotion,
  });

  final TrueCrimeCase crimeCase;
  final PortadaPosterMetrics metrics;
  final bool visible;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final styles = DsTextStylesResolver.of(context);
    final title = styles.displayPoster.copyWith(
      fontSize: metrics.titleFontSize,
      height: PortadaPosterMetrics.titleLineHeight,
      color: DsColors.textStrong,
    );
    final location = styles.body.copyWith(fontSize: metrics.locationFontSize);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: AnimatedOpacity(
        key: PortadaUnsolvedKeys.posterBase(crimeCase.id),
        opacity: visible ? 1 : 0,
        duration: DsMotion.resolve(DsMotion.hover, reduceMotion: reduceMotion),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                DsColors.bgBase.withValues(alpha: 0),
                DsColors.bgBase.withValues(
                  alpha: PortadaPosterMetrics.baseScrimAlpha,
                ),
              ],
            ),
          ),
          child: Padding(
            padding: metrics.basePadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: metrics.baseGap,
              children: [
                Text(
                  crimeCase.title,
                  style: title,
                  maxLines: PortadaPosterMetrics.titleMaxLines,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${crimeCase.regionOrCity} · ${crimeCase.year}',
                  style: location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                DsStatusLabel(
                  label: crimeCase.statusLabel ?? crimeCase.status.label,
                  color: crimeCase.status.designColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MoreLayer extends StatelessWidget {
  const _MoreLayer({
    required this.crimeCase,
    required this.metrics,
    required this.visible,
    required this.reduceMotion,
  });

  final TrueCrimeCase crimeCase;
  final PortadaPosterMetrics metrics;
  final bool visible;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final styles = DsTextStylesResolver.of(context);
    final summary = styles.body.copyWith(
      fontSize: PortadaPosterMetrics.summaryFontSize,
      height: PortadaPosterMetrics.summaryLineHeight,
    );
    final duration = DsMotion.resolve(
      DsMotion.hover,
      reduceMotion: reduceMotion,
    );

    return Positioned.fill(
      child: AnimatedOpacity(
        key: PortadaUnsolvedKeys.posterMore(crimeCase.id),
        opacity: visible ? 1 : 0,
        duration: duration,
        child: AnimatedSlide(
          offset: visible || reduceMotion
              ? Offset.zero
              : Offset(0, PortadaPosterMetrics.moreSlide / metrics.height),
          duration: duration,
          curve: DsMotion.easeUi,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  DsColors.bgBase.withValues(
                    alpha: PortadaPosterMetrics.moreScrimTopAlpha,
                  ),
                  DsColors.bgBase.withValues(
                    alpha: PortadaPosterMetrics.moreScrimBottomAlpha,
                  ),
                ],
                stops: const [0, PortadaPosterMetrics.moreScrimStop],
              ),
            ),
            child: Padding(
              padding: PortadaPosterMetrics.morePadding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: PortadaPosterMetrics.moreGap,
                children: [
                  Text(
                    crimeCase.title,
                    style: styles.displayPoster.copyWith(
                      color: DsColors.textStrong,
                    ),
                    maxLines: PortadaPosterMetrics.titleMaxLines,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Flexible(
                    child: Text(
                      crimeCase.summary,
                      style: summary,
                      maxLines: PortadaPosterMetrics.summaryMaxLines,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
