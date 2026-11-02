import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../cases/domain/case_category.dart';
import '../../../cases/domain/true_crime_case.dart';
import '../../../cases/presentation/design/case_design_mapping.dart';

/// Accesos al archivo por categoría, calculados a partir del catálogo recibido.
class PortadaCategories extends StatelessWidget {
  const PortadaCategories({super.key, required this.cases, required this.onSelectCategory});

  final List<TrueCrimeCase> cases;
  final ValueChanged<CaseCategory> onSelectCategory;

  @override
  Widget build(BuildContext context) {
    if (cases.isEmpty) return const SizedBox.shrink();
    const categories = [CaseCategory.serialKiller, CaseCategory.unsolved, CaseCategory.isolatedMurder, CaseCategory.kidnapping];
    final counts = {for (final category in categories) category: 0};
    for (final item in cases) {
      counts[item.category] = counts[item.category]! + 1;
    }
    final styles = DsTextStylesResolver.of(context);
    return LayoutBuilder(builder: (context, constraints) {
      final mobile = constraints.maxWidth < 700;
      final margin = mobile ? DsSpacing.pageMarginMobile : DsSpacing.pageMarginDesktop;
      final available = constraints.maxWidth - margin * 2;
      final columns = available < 600 ? 2 : 4;
      final width = (available - (columns - 1) * DsSpacing.s16) / columns;
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: margin),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Semantics(header: true, child: Text('Por categoría', style: styles.displaySection)),
          const DsMonoLabel('El archivo, por tipo de caso'),
          const SizedBox(height: DsSpacing.s20),
          Wrap(spacing: DsSpacing.s16, runSpacing: DsSpacing.s16, children: [
            for (final category in categories)
              SizedBox(width: width, child: _CategoryCard(category: category, count: counts[category]!, compact: columns == 2, onTap: () => onSelectCategory(category))),
          ]),
        ]),
      );
    });
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.count, required this.compact, required this.onTap});
  final CaseCategory category;
  final int count;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = category.designColor;
    final styles = DsTextStylesResolver.of(context);
    return Semantics(
      button: true,
      label: '${category.label}: $count ${count == 1 ? 'expediente' : 'expedientes'}. Abre El archivo filtrado',
      excludeSemantics: true,
      child: Material(
        color: DsColors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: DsRadii.cardBorder,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color.posterBase, DsColors.surfaceCard]),
              border: Border.all(color: DsColors.lineHairline),
              borderRadius: DsRadii.cardBorder,
            ),
            child: Container(
              constraints: const BoxConstraints(minHeight: 168),
              padding: EdgeInsets.all(compact ? DsSpacing.s12 : DsSpacing.s16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(height: 3, color: color.dot),
                const SizedBox(height: DsSpacing.s12),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(margin: const EdgeInsets.only(top: DsSpacing.s8, right: DsSpacing.s8), width: 10, height: 10, decoration: BoxDecoration(color: color.dot, shape: BoxShape.circle)),
                  Expanded(child: Text(category.label, style: compact ? styles.displayPoster.copyWith(fontSize: 16) : styles.displayPoster)),
                ]),
                const SizedBox(height: DsSpacing.s16),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('$count', style: styles.displayPage),
                    Text(count == 1 ? 'expediente' : 'expedientes', style: styles.body),
                  ])),
                  const Icon(Icons.arrow_forward, color: DsColors.textBody),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
