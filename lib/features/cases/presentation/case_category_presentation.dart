import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/case_category.dart';

class CaseCategoryPresentation {
  const CaseCategoryPresentation({
    required this.label,
    required this.shortLabel,
    required this.color,
  });

  final String label;
  final String shortLabel;
  final Color color;
}

extension CaseCategoryPresentationMapper on CaseCategory {
  CaseCategoryPresentation get presentation {
    return switch (this) {
      CaseCategory.isolatedMurder => const CaseCategoryPresentation(
        label: 'Asesinato aislado',
        shortLabel: 'Aislado',
        color: AppColors.catIsolated,
      ),
      CaseCategory.serialKiller => const CaseCategoryPresentation(
        label: 'Asesinos en serie',
        shortLabel: 'Serie',
        color: AppColors.catSerie,
      ),
      CaseCategory.kidnapping => const CaseCategoryPresentation(
        label: 'Secuestro',
        shortLabel: 'Secuestro',
        color: AppColors.catKidnapping,
      ),
      CaseCategory.unsolved => const CaseCategoryPresentation(
        label: 'Caso sin resolver',
        shortLabel: 'Sin resolver',
        color: AppColors.catUnsolved,
      ),
    };
  }
}
