import 'package:flutter/widgets.dart';

import '../theme/ds_text_styles_resolver.dart';
import '../tokens/tokens.dart';

class DsBadge extends StatelessWidget {
  const DsBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  static const double height = 28;

  @override
  Widget build(BuildContext context) {
    final style = DsTextStylesResolver.of(
      context,
    ).uiButton.copyWith(fontSize: 12, color: color);

    // minHeight en vez de height fijo: con texto ampliado la insignia crece
    return Container(
      constraints: const BoxConstraints(minHeight: height),
      padding: const EdgeInsets.symmetric(horizontal: DsSpacing.s10),
      decoration: BoxDecoration(
        borderRadius: DsRadii.badgeBorder,
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              label,
              style: style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
