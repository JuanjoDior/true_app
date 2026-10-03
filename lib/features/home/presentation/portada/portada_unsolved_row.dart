import 'package:flutter/widgets.dart';

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
            child: _Header(metrics: metrics),
          ),
          SizedBox(height: metrics.headerBottom),
          // Sin recorte: el póster elevado sobresale de la fila al pasar el ratón.
          SingleChildScrollView(
            key: PortadaUnsolvedKeys.row,
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
  const _Header({required this.metrics});

  final PortadaPosterMetrics metrics;

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

    if (metrics.stackedHeader) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: PortadaPosterMetrics.headerStackedGap,
        children: [title, subtitle],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      spacing: PortadaPosterMetrics.headerTitleGap,
      children: [
        title,
        const Flexible(child: subtitle),
      ],
    );
  }
}
