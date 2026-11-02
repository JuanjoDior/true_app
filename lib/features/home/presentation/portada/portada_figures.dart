import 'package:flutter/widgets.dart';

import '../../../../core/design/design.dart';
import '../../../cases/domain/case_status.dart';
import '../../../cases/domain/true_crime_case.dart';

/// Cifras derivadas exclusivamente de los casos publicados recibidos.
class PortadaFigures extends StatelessWidget {
  const PortadaFigures({super.key, required this.cases});

  final List<TrueCrimeCase> cases;

  @override
  Widget build(BuildContext context) {
    final countries = cases.map((c) => c.country.trim().toLowerCase()).where((c) => c.isNotEmpty).toSet();
    final years = cases.map((c) => c.year).toList()..sort();
    final figures = <(String, String)>[
      ('Expedientes', '${cases.length}'),
      ('Sin resolver', '${cases.where((c) => c.status == CaseStatus.open).length}'),
      ('Países', '${countries.length}'),
      ('Periodo documentado', years.isEmpty ? '—' : '${years.first}–${years.last}'),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 700 ? 4 : 2;
      return DsGlassPanel(
        child: Column(children: [
          for (var start = 0; start < figures.length; start += columns)
            IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (var i = start; i < start + columns; i++)
                Expanded(child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: DsSpacing.s20, vertical: DsSpacing.s24),
                  decoration: BoxDecoration(border: Border(left: i % columns == 0 ? BorderSide.none : const BorderSide(color: DsColors.lineHairline))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(figures[i].$2, style: DsTextStylesResolver.of(context).displaySection.copyWith(color: DsColors.accentGold)),
                    const SizedBox(height: DsSpacing.s8),
                    DsMonoLabel(figures[i].$1),
                  ]),
                )),
            ])),
        ]),
      );
    });
  }
}
