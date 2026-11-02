import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../cases/domain/true_crime_case.dart';
import 'portada_poster_card.dart';
import 'portada_unsolved_keys.dart';
import 'portada_unsolved_layout.dart';

/// Fila «Sin resolver»: casos abiertos en pósters con desplazamiento horizontal.
class PortadaUnsolvedRow extends StatefulWidget {
  const PortadaUnsolvedRow({
    super.key,
    required this.cases,
    required this.onOpenCase,
  });

  /// Casos a mostrar, ya seleccionados y ordenados.
  final List<TrueCrimeCase> cases;
  final ValueChanged<TrueCrimeCase> onOpenCase;

  @override
  State<PortadaUnsolvedRow> createState() => _PortadaUnsolvedRowState();
}

class _PortadaUnsolvedRowState extends State<PortadaUnsolvedRow> {
  String? _hoveredId;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scroll(int direction, PortadaPosterMetrics metrics) {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final target = (position.pixels + direction * (metrics.width + metrics.gap) * 2)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    if (MediaQuery.disableAnimationsOf(context)) {
      _scrollController.jumpTo(target);
    } else {
      _scrollController.animateTo(target, duration: DsMotion.hover, curve: DsMotion.easeUi);
    }
  }

  void _setHovered(String id, bool hovered) {
    if (hovered) {
      setState(() => _hoveredId = id);
    } else if (_hoveredId == id) {
      setState(() => _hoveredId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cases.isEmpty) return const SizedBox.shrink();
    final metrics = PortadaPosterMetrics.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: metrics.sectionBottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: metrics.margin),
            child: _Header(
              metrics: metrics,
              onPrevious: () => _scroll(-1, metrics),
              onNext: () => _scroll(1, metrics),
            ),
          ),
          SizedBox(height: metrics.headerBottom),
          // Sin recorte: el póster elevado sobresale de la fila al pasar el ratón.
          SingleChildScrollView(
            key: PortadaUnsolvedKeys.row,
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: EdgeInsets.symmetric(horizontal: metrics.margin),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: metrics.gap,
              children: [
                for (final crimeCase in widget.cases)
                  PortadaPosterCard(
                    key: ValueKey(crimeCase.id),
                    crimeCase: crimeCase,
                    dimmed: _hoveredId != null && _hoveredId != crimeCase.id,
                    onOpen: () => widget.onOpenCase(crimeCase),
                    onHoverChanged: (hovered) =>
                        _setHovered(crimeCase.id, hovered),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.metrics, required this.onPrevious, required this.onNext});

  final PortadaPosterMetrics metrics;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final title = Semantics(
      header: true,
      child: Text(
        'Sin resolver',
        style: DsTextStylesResolver.of(context).displaySection,
      ),
    );
    const subtitle = DsMonoLabel(
      'Casos abiertos que siguen esperando respuesta',
      letterSpacingEm: 0.14,
    );

    final heading = metrics.stackedHeader
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: PortadaPosterMetrics.headerStackedGap,
            children: [title, subtitle],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            spacing: PortadaPosterMetrics.headerTitleGap,
            children: [title, const Flexible(child: subtitle)],
          );
    return Row(
      children: [
        Expanded(child: heading),
        _ScrollButton(label: 'Casos anteriores', icon: Icons.arrow_back, onPressed: onPrevious),
        const SizedBox(width: DsSpacing.s8),
        _ScrollButton(label: 'Más casos', icon: Icons.arrow_forward, onPressed: onNext),
      ],
    );
  }
}

class _ScrollButton extends StatelessWidget {
  const _ScrollButton({required this.label, required this.icon, required this.onPressed});

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => DsPressable(
    semanticLabel: label,
    onTap: onPressed,
    minTapTarget: const Size.square(52),
    focusRadius: 26,
    builder: (context, state) => Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: state.hovered ? DsColors.lineHairline : DsColors.surfaceCard,
        border: Border.all(color: DsColors.lineHairline),
      ),
      child: Icon(icon, size: 18, color: DsColors.textPrimary),
    ),
  );
}
