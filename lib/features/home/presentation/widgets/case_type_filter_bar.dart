import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../cases/domain/case_category.dart';
import '../../../cases/presentation/case_category_presentation.dart';

class CaseTypeFilterBar extends StatelessWidget {
  const CaseTypeFilterBar({
    super.key,
    required this.counts,
    required this.activeCategory,
    required this.onCategorySelected,
  });

  final Map<CaseCategory, int> counts;
  final CaseCategory? activeCategory;
  final ValueChanged<CaseCategory?> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Filtra por tipo', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'La taxonomía ya está preparada para clasificar el catálogo cuando empiece a crecer.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChipCard(
                key: const Key('category-chip-all'),
                label: 'Todos',
                count: counts.values.fold<int>(
                  0,
                  (total, value) => total + value,
                ),
                isSelected: activeCategory == null,
                color: AppColors.gold,
                onTap: () => onCategorySelected(null),
              ),
              const SizedBox(width: 12),
              ...CaseCategory.values.expand((category) {
                final presentation = category.presentation;

                return [
                  _FilterChipCard(
                    key: Key('category-chip-${category.name}'),
                    label: presentation.label,
                    count: counts[category] ?? 0,
                    isSelected: activeCategory == category,
                    color: presentation.color,
                    onTap: () => onCategorySelected(category),
                  ),
                  const SizedBox(width: 12),
                ];
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChipCard extends StatelessWidget {
  const _FilterChipCard({
    super.key,
    required this.label,
    required this.count,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.2)
                : AppColors.panelMuted,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: isSelected ? color : AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
