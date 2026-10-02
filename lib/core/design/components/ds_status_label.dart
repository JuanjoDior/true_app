import 'package:flutter/widgets.dart';

import '../theme/ds_text_styles_resolver.dart';
import '../tokens/tokens.dart';

class DsStatusLabel extends StatelessWidget {
  const DsStatusLabel({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  static const double dotSize = 8;

  @override
  Widget build(BuildContext context) {
    final style = DsTextStylesResolver.of(context).uiButton.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: color,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: const SizedBox(width: dotSize, height: dotSize),
          ),
        ),
        const SizedBox(width: DsSpacing.s8),
        Flexible(
          child: Text(
            label,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
