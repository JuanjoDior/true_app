import 'package:flutter/widgets.dart';

import '../../../../core/design/design.dart';
import 'portada_closing_keys.dart';
import 'portada_closing_layout.dart';

/// Pie de la portada: marca y nota de respeto a las víctimas.
class PortadaFooter extends StatelessWidget {
  const PortadaFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final metrics = PortadaFooterMetrics.of(context);
    final styles = DsTextStylesResolver.of(context);

    final brand = Text(
      'TRUE',
      style: styles.displaySection.copyWith(
        fontSize: metrics.brandFontSize,
        letterSpacing:
            metrics.brandFontSize * PortadaFooterMetrics.brandLetterSpacingEm,
        color: DsColors.textBody,
      ),
    );
    final note = Text(
      'Crímenes reales · documentados con respeto. '
      'Las víctimas se nombran con respeto.',
      textAlign: metrics.stacked ? TextAlign.start : TextAlign.end,
      style: styles.body.copyWith(
        fontSize: PortadaFooterMetrics.noteFontSize,
        height: metrics.stacked ? PortadaFooterMetrics.noteLineHeight : null,
        color: DsColors.textMuted,
      ),
    );

    final Widget content = metrics.stacked
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: PortadaFooterMetrics.stackedGap,
            children: [brand, note],
          )
        : ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: PortadaFooterMetrics.desktopHeight,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: DsSpacing.s24,
              children: [
                brand,
                Flexible(child: note),
              ],
            ),
          );

    return DecoratedBox(
      key: PortadaClosingKeys.footer,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: DsColors.lineHairline,
            width: PortadaFooterMetrics.ruleWidth,
          ),
        ),
      ),
      child: Padding(padding: metrics.padding, child: content),
    );
  }
}
