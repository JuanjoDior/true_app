import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../theme/ds_text_styles_resolver.dart';
import '../tokens/tokens.dart';
import 'ds_pressable.dart';

class DsSegment<T> {
  const DsSegment({required this.value, required this.label});

  final T value;
  final String label;
}

/// Necesita un ancho acotado: los segmentos se reparten el espacio disponible.
class DsSegmented<T> extends StatefulWidget {
  const DsSegmented({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
  });

  final List<DsSegment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;

  static const double segmentHeight = 44;
  static const double _inset = 4;

  @override
  State<DsSegmented<T>> createState() => _DsSegmentedState<T>();
}

class _DsSegmentedState<T> extends State<DsSegmented<T>> {
  final List<FocusNode> _nodes = [];

  void _syncNodes() {
    while (_nodes.length < widget.segments.length) {
      _nodes.add(FocusNode(debugLabel: 'DsSegmented#${_nodes.length}'));
    }
    while (_nodes.length > widget.segments.length) {
      _nodes.removeLast().dispose();
    }
  }

  @override
  void initState() {
    super.initState();
    _syncNodes();
  }

  @override
  void didUpdateWidget(DsSegmented<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncNodes();
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  // Las flechas solo mueven el foco; elegir es cosa de Enter / Espacio
  void _moveFocus(int delta) {
    final current = _nodes.indexWhere((node) => node.hasFocus);
    if (current == -1) return;
    final target = current + delta;
    if (target < 0 || target >= _nodes.length) return;
    _nodes[target].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final textStyle = DsTextStylesResolver.of(
      context,
    ).uiButton.copyWith(fontSize: 14);
    const innerRadius = BorderRadius.all(
      Radius.circular(DsRadii.control - DsSegmented._inset),
    );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            _moveFocus(rtl ? 1 : -1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            _moveFocus(rtl ? -1 : 1),
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: DsColors.surfaceCard,
          borderRadius: DsRadii.controlBorder,
          border: Border.all(color: DsColors.lineHairline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(DsSegmented._inset - 1),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < widget.segments.length; i++)
                Flexible(
                  child: _buildSegment(
                    widget.segments[i],
                    _nodes[i],
                    textStyle,
                    innerRadius,
                    reduceMotion,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegment(
    DsSegment<T> segment,
    FocusNode node,
    TextStyle textStyle,
    BorderRadius radius,
    bool reduceMotion,
  ) {
    final selected = segment.value == widget.value;

    return DsPressable(
      onTap: selected ? () {} : () => widget.onChanged(segment.value),
      semanticLabel: segment.label,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      focusNode: node,
      focusRadius: DsRadii.control - DsSegmented._inset,
      builder: (context, state) => AnimatedContainer(
        duration: DsMotion.resolve(DsMotion.hover, reduceMotion: reduceMotion),
        curve: DsMotion.easeUi,
        padding: const EdgeInsets.symmetric(
          horizontal: DsSpacing.s16,
          vertical: DsSpacing.s8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? DsColors.ctaBg
              : state.hovered
              ? DsColors.lineHairline
              : const Color(0x00000000),
          borderRadius: radius,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: DsSegmented.segmentHeight - 2 * DsSpacing.s8,
          ),
          child: Align(
            widthFactor: 1,
            heightFactor: 1,
            child: Text(
              segment.label,
              style: textStyle.copyWith(
                color: selected ? DsColors.ctaFg : DsColors.textBody,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
