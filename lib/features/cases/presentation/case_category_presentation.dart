import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/case_category.dart';

class CaseCategoryPresentation {
  const CaseCategoryPresentation({
    required this.label,
    required this.shortLabel,
    required this.description,
    required this.color,
  });

  final String label;
  final String shortLabel;
  final String description;
  final Color color;
}

extension CaseCategoryPresentationMapper on CaseCategory {
  CaseCategoryPresentation get presentation {
    return switch (this) {
      CaseCategory.isolatedMurder => const CaseCategoryPresentation(
        label: 'Asesinatos aislados',
        shortLabel: 'Aislados',
        description: 'Homicidios puntuales con gran impacto editorial.',
        color: Color(0xFF7A1F26),
      ),
      CaseCategory.serialKiller => const CaseCategoryPresentation(
        label: 'Asesinos en serie',
        shortLabel: 'Serie',
        description: 'Patrones repetidos y cobertura criminal prolongada.',
        color: AppColors.accent,
      ),
      CaseCategory.kidnapping => const CaseCategoryPresentation(
        label: 'Secuestros',
        shortLabel: 'Secuestros',
        description: 'Desapariciones y retenciones con investigación activa.',
        color: Color(0xFF8D6B2E),
      ),
      CaseCategory.unsolved => const CaseCategoryPresentation(
        label: 'Casos sin resolver',
        shortLabel: 'Sin resolver',
        description: 'Casos emblemáticos sin cierre judicial definitivo.',
        color: Color(0xFF50657C),
      ),
    };
  }
}
