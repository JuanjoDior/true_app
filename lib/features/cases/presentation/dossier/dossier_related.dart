import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../application/cases_providers.dart';
import '../../domain/true_crime_case.dart';
import '../design/case_design_mapping.dart';

abstract final class DossierRelatedKeys {
  static Key poster(String id) => ValueKey('dossier-related-$id');
}

abstract final class DossierRelatedMetrics {
  static const double posterHeight = 136;
}

class DossierRelated extends StatelessWidget {
  const DossierRelated({
    super.key,
    required this.relatedCases,
    required this.onOpen,
  });

  final List<RelatedCase> relatedCases;
  final ValueChanged<TrueCrimeCase> onOpen;

  @override
  Widget build(BuildContext context) {
    if (relatedCases.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(header: true, child: const DsMonoLabel('Casos relacionados')),
        const SizedBox(height: DsSpacing.s12),
        for (var i = 0; i < relatedCases.length; i++) ...[
          if (i > 0) const SizedBox(height: DsSpacing.s8),
          _RelatedPoster(
            related: relatedCases[i],
            onTap: () => onOpen(relatedCases[i].crimeCase),
          ),
        ],
      ],
    );
  }
}

class _RelatedPoster extends StatelessWidget {
  const _RelatedPoster({required this.related, required this.onTap});

  final RelatedCase related;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final crimeCase = related.crimeCase;
    final category = crimeCase.category.designColor;
    final labelColor = category.dot == DsColors.accentRed
        ? DsColors.accentRedText
        : category.dot;

    return Material(
      key: DossierRelatedKeys.poster(crimeCase.id),
      color: DsColors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: DsRadii.cardBorder),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        height: DossierRelatedMetrics.posterHeight,
        decoration: BoxDecoration(
          borderRadius: DsRadii.cardBorder,
          border: Border.all(color: DsColors.lineHairline),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [category.posterBase, DsColors.bgBase],
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                top: -DsSpacing.s8,
                right: DsSpacing.s10,
                child: ExcludeSemantics(
                  child: Text(
                    '${crimeCase.year}',
                    style: DsTextStyles.desktop.displayGhostYear.copyWith(
                      fontSize: 86,
                      height: 1,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DsSpacing.s18,
                  vertical: DsSpacing.s16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DsMonoLabel(
                      crimeCase.category.label,
                      color: labelColor,
                      letterSpacingEm: 0.14,
                    ),
                    const Spacer(),
                    Text(
                      crimeCase.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DsTextStyles.desktop.displayPoster.copyWith(
                        color: DsColors.textStrong,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: DsSpacing.s4),
                    Text(
                      related.relation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DsTextStyles.desktop.body.copyWith(
                        fontSize: 13,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
