import 'package:flutter/widgets.dart';

import '../../../../core/design/tokens/ds_colors.dart';
import '../../domain/true_crime_case.dart';
import '../design/case_design_mapping.dart';
import 'dossier_facts_pending.dart';
import 'dossier_hero_keys.dart';

class DossierHero extends StatelessWidget {
  const DossierHero({
    super.key,
    required this.crimeCase,
    this.pending = DossierPending.none,
  });

  final TrueCrimeCase crimeCase;

  /// Datos que faltan en un borrador: se pintan como «pendiente».
  final DossierPending pending;

  static const double factsOverlap = 72;
  static const double summaryMaxWidth = 760;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1200;
    final category = crimeCase.category.designColor;
    final status = crimeCase.status.designColor;
    final categoryColor = pending.category ? DsColors.textMuted : category.dot;
    final statusColor = pending.status ? DsColors.textMuted : status;
    const missing = DossierPending.placeholder;
    final region = pending.region ? missing : crimeCase.regionOrCity;
    final country = pending.country ? missing : crimeCase.country;
    final year = pending.year ? missing : '${crimeCase.year}';
    return Container(
      key: DossierHeroKeys.background,
      constraints: const BoxConstraints(minHeight: 560),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [category.posterBase, DsColors.bgBase],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Sin año no hay año fantasma: pintar «0» sería inventarlo.
          if (!pending.year)
            Positioned(
              right: 24,
              top: 40,
              child: ExcludeSemantics(
                key: DossierHeroKeys.ghostYear,
                child: Text(
                  '${crimeCase.year}',
                  style: TextStyle(
                    fontFamily: 'NotoSerifDisplay',
                    fontSize: wide ? 400 : 180,
                    fontWeight: FontWeight.bold,
                    color: DsColors.textStrong.withValues(alpha: 0.05),
                  ),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              wide ? 80 : 20,
              120,
              wide ? 80 : 20,
              factsOverlap + 48,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 14,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      key: DossierHeroKeys.category,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: categoryColor),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        pending.category ? missing : crimeCase.category.label,
                        style: TextStyle(color: categoryColor, fontSize: 13),
                      ),
                    ),
                    KeyedSubtree(
                      key: DossierHeroKeys.status,
                      child: Text(
                        pending.status
                            ? missing
                            : crimeCase.statusLabel?.trim().isNotEmpty == true
                            ? crimeCase.statusLabel!
                            : crimeCase.status.label,
                        style: TextStyle(color: statusColor, fontSize: 15),
                      ),
                    ),
                    Text(
                      '· ${region.toUpperCase()} · ${country.toUpperCase()} · ${year.toUpperCase()}',
                      key: DossierHeroKeys.place,
                      style: const TextStyle(
                        color: DsColors.textBody,
                        fontSize: 13,
                        fontFamily: 'IBMPlexMono',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  crimeCase.title,
                  key: DossierHeroKeys.title,
                  style: TextStyle(
                    fontFamily: 'NotoSerifDisplay',
                    fontSize: wide ? 128 : 48,
                    height: 0.98,
                    fontWeight: FontWeight.bold,
                    color: DsColors.textStrong,
                  ),
                ),
                const SizedBox(height: 24),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: summaryMaxWidth),
                  child: Text(
                    pending.summary ? 'Resumen $missing.' : crimeCase.summary,
                    key: DossierHeroKeys.summary,
                    style: TextStyle(
                      fontFamily: 'NotoSerifDisplay',
                      fontSize: wide ? 24 : 19,
                      height: 1.45,
                      fontWeight: FontWeight.bold,
                      color: pending.summary
                          ? DsColors.textMuted
                          : DsColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
