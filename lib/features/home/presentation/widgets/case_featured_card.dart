import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../cases/domain/true_crime_case.dart';

class CaseFeaturedCard extends StatelessWidget {
  const CaseFeaturedCard({
    super.key,
    required this.crimeCase,
    required this.onTap,
    this.isSelected = false,
  });

  final TrueCrimeCase crimeCase;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: 'Abrir caso ${crimeCase.title}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: AnimatedContainer(
          key: Key('featured-case-card-${crimeCase.id}'),
          duration: const Duration(milliseconds: 220),
          width: 264,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isSelected
                  ? const [Color(0xFF3B1116), Color(0xFF18171D)]
                  : const [Color(0xFF1A1D24), Color(0xFF101217)],
            ),
            border: Border.all(
              color: isSelected ? AppColors.accent : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 28,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '#${crimeCase.featuredRank}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_outward_rounded,
                    color: isSelected ? AppColors.gold : AppColors.textMuted,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                crimeCase.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(height: 1.1),
              ),
              const SizedBox(height: 10),
              Text(
                '${crimeCase.regionOrCity}, ${crimeCase.country} · ${crimeCase.year}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: crimeCase.tags
                    .take(3)
                    .map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF212630),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          tag,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
