import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/design/design.dart';
import '../../../cases/domain/true_crime_case.dart';
import 'portada_hero_keys.dart';
import 'portada_hero_layout.dart';

/// Pestañas del carrusel: nombre del caso y barra que se rellena con el reloj.
///
/// En modo compacto (móvil) solo quedan las barras, como las historias del prototipo.
class PortadaTabs extends StatelessWidget {
  const PortadaTabs({
    super.key,
    required this.featured,
    required this.activeIndex,
    required this.progress,
    required this.reduceMotion,
    required this.onSelect,
    this.compact = false,
  });

  final List<TrueCrimeCase> featured;
  final int activeIndex;
  final ValueListenable<double> progress;

  /// Sin reloj: la pestaña activa se marca con la barra llena.
  final bool reduceMotion;
  final ValueChanged<int> onSelect;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: compact ? PortadaLayout.compactTabGap : PortadaLayout.tabGap,
      children: [
        for (var i = 0; i < featured.length; i++)
          Expanded(
            child: _PortadaTab(
              index: i,
              title: featured[i].title,
              active: i == activeIndex,
              progress: progress,
              reduceMotion: reduceMotion,
              compact: compact,
              onSelect: () => onSelect(i),
            ),
          ),
      ],
    );
  }
}

class _PortadaTab extends StatelessWidget {
  const _PortadaTab({
    required this.index,
    required this.title,
    required this.active,
    required this.progress,
    required this.reduceMotion,
    required this.compact,
    required this.onSelect,
  });

  final int index;
  final String title;
  final bool active;
  final ValueListenable<double> progress;
  final bool reduceMotion;
  final bool compact;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    // Enter y espacio activan la pestaña también cuando el foco está en este nodo envolvente.
    return Focus(
      skipTraversal: true,
      onKeyEvent: (node, event) {
        final activates =
            event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.numpadEnter ||
                event.logicalKey == LogicalKeyboardKey.space);
        if (!activates) return KeyEventResult.ignored;
        onSelect();
        return KeyEventResult.handled;
      },
      child: DsPressable(
        key: PortadaHeroKeys.tab(index),
        onTap: onSelect,
        semanticLabel: title,
        selected: active,
        inMutuallyExclusiveGroup: true,
        builder: (context, state) => compact
            ? SizedBox(
                height: PortadaLayout.compactTabHeight,
                child: Center(
                  child: _TabBar(
                    index: index,
                    active: active,
                    progress: progress,
                    reduceMotion: reduceMotion,
                  ),
                ),
              )
            : SizedBox(
                height: PortadaLayout.tabHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _TabName(index: index, title: title, active: active),
                    _TabBar(
                      index: index,
                      active: active,
                      progress: progress,
                      reduceMotion: reduceMotion,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _TabName extends StatelessWidget {
  const _TabName({
    required this.index,
    required this.title,
    required this.active,
  });

  final int index;
  final String title;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final base = DsTextStylesResolver.of(context).uiButton.copyWith(
      fontSize: PortadaLayout.tabNameFontSize,
      fontWeight: FontWeight.w600,
    );
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: active ? DsColors.textStrong : DsColors.textFaint),
      duration: DsMotion.resolve(DsMotion.hover, reduceMotion: reduceMotion),
      curve: DsMotion.easeUi,
      builder: (context, color, _) => Text(
        title,
        key: PortadaHeroKeys.tabName(index),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: base.copyWith(color: color),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.index,
    required this.active,
    required this.progress,
    required this.reduceMotion,
  });

  final int index;
  final bool active;
  final ValueListenable<double> progress;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      key: PortadaHeroKeys.tabTrack(index),
      borderRadius: BorderRadius.circular(PortadaLayout.tabBarHeight / 2),
      child: SizedBox(
        height: PortadaLayout.tabBarHeight,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: DsColors.ctaGlassBorder),
            if (!active)
              _fill(0)
            else if (reduceMotion)
              _fill(1)
            else
              ValueListenableBuilder<double>(
                valueListenable: progress,
                builder: (context, value, _) => _fill(value),
              ),
          ],
        ),
      ),
    );
  }

  // El Align suelta la restricción apretada del Stack: sin él la barra mediría siempre el ancho completo.
  // heightFactor 1 es necesario: un ColoredBox sin hijo mide 0 de alto con restricciones sueltas.
  Widget _fill(double fraction) => Align(
    alignment: Alignment.centerLeft,
    child: FractionallySizedBox(
      key: PortadaHeroKeys.tabFill(index),
      widthFactor: fraction.clamp(0, 1),
      heightFactor: 1,
      child: const ColoredBox(color: DsColors.textStrong),
    ),
  );
}
