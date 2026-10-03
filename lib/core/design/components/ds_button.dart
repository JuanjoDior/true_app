import 'package:flutter/widgets.dart';

import '../theme/ds_text_styles_resolver.dart';
import '../tokens/tokens.dart';
import 'ds_pressable.dart';

enum DsButtonVariant { primary, glass, outline }

class DsButton extends StatelessWidget {
  const DsButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = DsButtonVariant.primary,
    this.trailingIcon,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final DsButtonVariant variant;
  final IconData? trailingIcon;
  final bool expand;

  static const double heightDesktop = 52;
  static const double heightMobile = 56;
  static const double hoverScale = 1.04;
  static const Color _transparent = Color(0x00000000);

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final isDesktop = MediaQuery.sizeOf(context).width >= DsBreakpoints.desktop;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final (:background, :foreground, :border) = _paletteFor(enabled);
    // Alto total = contenido mínimo + relleno vertical + borde de 1 px
    final innerMinHeight =
        (isDesktop ? heightDesktop : heightMobile) - 2 * DsSpacing.s12 - 2;
    final textStyle = DsTextStylesResolver.of(
      context,
    ).uiButton.copyWith(color: foreground);

    return DsPressable(
      onTap: onPressed,
      semanticLabel: label,
      hoverScale: hoverScale,
      focusRadius: DsRadii.control,
      builder: (context, state) => AnimatedContainer(
        duration: DsMotion.resolve(DsMotion.hover, reduceMotion: reduceMotion),
        curve: DsMotion.easeUi,
        width: expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(
          horizontal: DsSpacing.s24,
          vertical: DsSpacing.s12,
        ),
        // Borde de 1 px en todas las variantes para que midan lo mismo
        decoration: BoxDecoration(
          color: background,
          borderRadius: DsRadii.controlBorder,
          border: Border.all(color: border),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: innerMinHeight),
          child: Align(
            widthFactor: 1,
            heightFactor: 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: textStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: DsSpacing.s8),
                  Icon(trailingIcon, size: 18, color: foreground),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  ({Color background, Color foreground, Color border}) _paletteFor(
    bool enabled,
  ) {
    if (!enabled) {
      return (
        background: DsColors.surfaceCard,
        foreground: DsColors.textPlaceholder,
        border: variant == DsButtonVariant.primary
            ? _transparent
            : DsColors.lineHairline,
      );
    }
    return switch (variant) {
      DsButtonVariant.primary => (
        background: DsColors.ctaBg,
        foreground: DsColors.ctaFg,
        border: _transparent,
      ),
      DsButtonVariant.glass => (
        background: DsColors.ctaGlass,
        foreground: DsColors.textPrimary,
        border: DsColors.ctaGlassBorder,
      ),
      DsButtonVariant.outline => (
        background: _transparent,
        foreground: DsColors.textPrimary,
        border: DsColors.ctaOutlineBorder,
      ),
    };
  }
}
