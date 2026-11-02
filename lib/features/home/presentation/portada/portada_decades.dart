import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../cases/domain/true_crime_case.dart';

/// Histograma estático de décadas presentes en el catálogo recibido.
class PortadaDecades extends StatelessWidget {
  const PortadaDecades({super.key, required this.cases, required this.onSelectDecade});

  final List<TrueCrimeCase> cases;
  /// Recibe el primer año de la década seleccionada.
  final ValueChanged<int> onSelectDecade;

  @override
  Widget build(BuildContext context) {
    if (cases.isEmpty) return const SizedBox.shrink();
    final counts = <int, int>{};
    for (final item in cases) {
      final decade = (item.year / 10).floor() * 10;
      counts.update(decade, (value) => value + 1, ifAbsent: () => 1);
    }
    final decades = counts.keys.toList()..sort();
    final maximum = counts.values.reduce((a, b) => a > b ? a : b);
    final styles = DsTextStylesResolver.of(context);
    return LayoutBuilder(builder: (context, constraints) {
      final margin = constraints.maxWidth < 700 ? DsSpacing.pageMarginMobile : DsSpacing.pageMarginDesktop;
      final available = constraints.maxWidth - margin * 2;
      final width = (available / decades.length).clamp(64.0, 120.0);
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: margin),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Semantics(header: true, child: Text('Recorre el tiempo', style: styles.displaySection)),
          const DsMonoLabel('Expedientes por década'),
          const SizedBox(height: DsSpacing.s20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (final decade in decades)
                Semantics(
                  button: true,
                  label: 'Década de $decade: ${counts[decade]} ${counts[decade] == 1 ? 'expediente' : 'expedientes'}',
                  excludeSemantics: true,
                  child: SizedBox(
                    width: width,
                    child: Material(
                      color: DsColors.transparent,
                      child: InkWell(
                        onTap: () => onSelectDecade(decade),
                        borderRadius: DsRadii.controlBorder,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: DsSpacing.s4, vertical: DsSpacing.s12),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Text('${counts[decade]}', style: styles.monoData),
                            const SizedBox(height: DsSpacing.s8),
                            Container(
                              width: 44,
                              height: 176 * counts[decade]! / maximum,
                              decoration: BoxDecoration(
                                borderRadius: DsRadii.badgeBorder,
                                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [DsColors.accentGold, DsColors.accentGold.withValues(alpha: 0.18)]),
                              ),
                            ),
                            const SizedBox(height: DsSpacing.s12),
                            Text('${decade}s', style: styles.monoLabel),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ]),
      );
    });
  }
}
