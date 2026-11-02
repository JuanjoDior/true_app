import 'package:flutter/widgets.dart';

import '../../../../core/design/design.dart';
import '../../../cases/domain/true_crime_case.dart';
import '../../../cases/presentation/case_category_presentation.dart';
import '../../../cases/presentation/design/case_design_mapping.dart';
import 'portada_hero_keys.dart';
import 'portada_hero_layout.dart';
import 'portada_slide_motion.dart';

/// Capa de un slide: año fantasma, texto con botones y coordenadas.
class PortadaSlideView extends StatelessWidget {
  const PortadaSlideView({
    super.key,
    required this.crimeCase,
    required this.motion,
    required this.position,
    required this.count,
    required this.onOpen,
    this.onExplore,
    this.connectionCount = 0,
  });

  final TrueCrimeCase crimeCase;
  final PortadaSlideMotion motion;
  final int connectionCount;

  /// Posición del slide empezando en 1.
  final int position;
  final int count;
  final VoidCallback onOpen;

  /// Nulo oculta «Explorar el globo».
  final VoidCallback? onExplore;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < DsBreakpoints.desktop;
    final ghost = _GhostYear(crimeCase: crimeCase);
    final body = _SlideBody(
      crimeCase: crimeCase,
      compact: compact,
      position: position,
      count: count,
      connectionCount: connectionCount,
      onOpen: onOpen,
      onExplore: onExplore,
    );
    final coords = DsMonoLabel(
      crimeCase.coordsLabel,
      key: PortadaHeroKeys.coords(crimeCase.id),
      color: DsColors.textMuted,
      letterSpacingEm: 0.14,
    );

    return AnimatedBuilder(
      animation: motion.controller,
      builder: (context, _) {
        if (motion.isGone) return const SizedBox.shrink();
        final leaving = motion.isLeaving;
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: PortadaLayout.ghostLeft,
              top: PortadaLayout.ghostTop,
              child: Transform.translate(
                offset: Offset(motion.ghostShift.value, 0),
                child: FadeTransition(
                  key: PortadaHeroKeys.ghostYear(crimeCase.id),
                  opacity: motion.ghostOpacity,
                  child: ExcludeSemantics(child: ghost),
                ),
              ),
            ),
            Positioned(
              left: compact ? 20 : PortadaLayout.margin,
              top: compact ? 126 : PortadaLayout.contentTop,
              right: compact ? 20 : 0,
              bottom: compact ? 36 : PortadaLayout.contentBottom,
              child: Transform.translate(
                offset: Offset(0, motion.contentShift.value),
                child: IgnorePointer(
                  ignoring: leaving,
                  child: ExcludeSemantics(
                    excluding: leaving,
                    child: compact
                        ? SingleChildScrollView(
                            child: FadeTransition(
                              key: PortadaHeroKeys.content(crimeCase.id),
                              opacity: motion.contentOpacity,
                              child: body,
                            ),
                          )
                        : Align(
                            alignment: Alignment.bottomLeft,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.bottomLeft,
                              child: FadeTransition(
                                key: PortadaHeroKeys.content(crimeCase.id),
                                opacity: motion.contentOpacity,
                                child: body,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: compact ? 20 : PortadaLayout.margin,
              bottom: compact ? 10 : PortadaLayout.coordsBottom,
              child: ExcludeSemantics(
                excluding: leaving,
                child: FadeTransition(
                  opacity: motion.contentOpacity,
                  child: coords,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GhostYear extends StatelessWidget {
  const _GhostYear({required this.crimeCase});

  final TrueCrimeCase crimeCase;

  @override
  Widget build(BuildContext context) {
    final style = DsTextStylesResolver.of(context).displayGhostYear.copyWith(
      fontSize: PortadaLayout.ghostFontSize,
      height: 1,
    );
    // Decoración pura: no debe crecer con el tamaño de texto del sistema.
    return Text(
      '${crimeCase.year}',
      style: style,
      textScaler: TextScaler.noScaling,
      softWrap: false,
      maxLines: 1,
    );
  }
}

class _SlideBody extends StatelessWidget {
  const _SlideBody({
    required this.crimeCase,
    required this.compact,
    required this.position,
    required this.count,
    required this.connectionCount,
    required this.onOpen,
    required this.onExplore,
  });

  final TrueCrimeCase crimeCase;
  final bool compact;
  final int position;
  final int count;
  final int connectionCount;
  final VoidCallback onOpen;
  final VoidCallback? onExplore;

  @override
  Widget build(BuildContext context) {
    final styles = DsTextStylesResolver.of(context);
    final categoryColor = crimeCase.category.designColor.dot;
    final id = crimeCase.id;

    return SizedBox(
      width: compact ? double.infinity : PortadaLayout.contentWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: compact ? DsSpacing.s8 : DsSpacing.s20,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: DsSpacing.s14,
            children: [
              DsMonoLabel(
                'En el foco',
                color: categoryColor,
                letterSpacingEm: 0.22,
              ),
              const SizedBox(
                width: DsSpacing.s32,
                height: 1,
                child: ColoredBox(color: DsColors.ctaOutlineBorder),
              ),
              DsMonoLabel(
                '$position / $count',
                color: DsColors.textMuted,
                letterSpacingEm: 0.14,
              ),
            ],
          ),
          Text(
            crimeCase.title,
            key: PortadaHeroKeys.title(id),
            maxLines: PortadaLayout.titleMaxLines,
            overflow: TextOverflow.ellipsis,
            style: styles.displayHero.copyWith(
              fontSize: compact ? 36 : PortadaLayout.titleFontSize,
              height: PortadaLayout.titleLineHeight,
              letterSpacing: -(compact ? 36 : PortadaLayout.titleFontSize) * 0.01,
            ),
          ),
          Wrap(
            spacing: DsSpacing.s14,
            runSpacing: DsSpacing.s8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DsBadge(
                label: crimeCase.category.presentation.label,
                color: categoryColor,
              ),
              Text(
                '${crimeCase.locationLabel} · ${crimeCase.year}',
                style: styles.body.copyWith(
                  fontSize: PortadaLayout.metaFontSize,
                  color: DsColors.textPrimary,
                ),
              ),
              DsStatusLabel(
                label: crimeCase.statusLabel ?? crimeCase.status.label,
                color: crimeCase.status.designColor,
              ),
              Text(
                '$connectionCount ${connectionCount == 1 ? 'caso conectado' : 'casos conectados'}',
                style: styles.monoData.copyWith(color: DsColors.accentGold),
              ),
            ],
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: PortadaLayout.summaryMaxWidth,
            ),
            child: Text(
              crimeCase.summary,
              key: PortadaHeroKeys.summary(id),
              maxLines: PortadaLayout.summaryMaxLines,
              overflow: TextOverflow.ellipsis,
              style: styles.bodyLarge.copyWith(
                fontSize: compact ? 16 : PortadaLayout.summaryFontSize,
                height: compact ? 1.4 : PortadaLayout.summaryLineHeight,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: DsSpacing.s4),
            child: Wrap(
              spacing: DsSpacing.s14,
              runSpacing: DsSpacing.s14,
              children: [
                DsButton(label: 'Abrir expediente', onPressed: onOpen),
                if (onExplore != null)
                  DsButton(
                    label: 'Explorar el globo',
                    variant: DsButtonVariant.glass,
                    onPressed: onExplore,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
