import 'package:flutter/widgets.dart';

import '../theme/ds_text_styles_resolver.dart';
import '../tokens/tokens.dart';
import 'ds_pressable.dart';

class DsFilterChip extends StatelessWidget {
  const DsFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  static const double height = 40;
  static const double tapTarget = 44;
  static const double hoverShift = 4;

  @override
  Widget build(BuildContext context) {
    final handler = onSelected;
    final enabled = handler != null;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final active = enabled && selected;

    final foreground = !enabled
        ? DsColors.textPlaceholder
        : active
        ? DsColors.ctaFg
        : DsColors.textBody;
    // Mismo peso en ambos estados: cambiarlo movería a las fichas vecinas
    final textStyle = DsTextStylesResolver.of(
      context,
    ).uiButton.copyWith(fontSize: 14, color: foreground);

    return DsPressable(
      onTap: enabled ? () => handler(!selected) : null,
      semanticLabel: label,
      selected: selected,
      hoverShiftX: hoverShift,
      minTapTarget: const Size.square(tapTarget),
      focusRadius: DsRadii.pill,
      builder: (context, state) => AnimatedContainer(
        duration: DsMotion.resolve(DsMotion.hover, reduceMotion: reduceMotion),
        curve: DsMotion.easeUi,
        padding: const EdgeInsets.symmetric(
          horizontal: DsSpacing.s16,
          vertical: DsSpacing.s8,
        ),
        decoration: BoxDecoration(
          color: active ? DsColors.ctaBg : DsColors.surfaceCard,
          borderRadius: DsRadii.pillBorder,
          border: Border.all(
            color: active ? DsColors.ctaBg : DsColors.lineHairline,
          ),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: height - 2 * DsSpacing.s8 - 2,
          ),
          child: Align(
            widthFactor: 1,
            heightFactor: 1,
            child: Text(
              label,
              style: textStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
