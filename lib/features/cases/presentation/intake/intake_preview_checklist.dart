import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../application/draft_validator.dart';
import '../../domain/case_draft.dart';
import 'case_form_section.dart';

/// Un bloque de la lista «Campos obligatorios»: agrupa los errores de
/// [validateDraft] que se corrigen en el mismo punto del formulario.
class IntakeChecklistItem {
  const IntakeChecklistItem({
    required this.id,
    required this.label,
    required this.sectionTitle,
    required this.errors,
  });

  final String id;
  final String label;

  /// Título de la sección de [kCaseFormSections] donde se corrige.
  final String sectionTitle;

  /// Mensajes de error del validador para este bloque (vacío si está listo).
  final List<String> errors;

  bool get isDone => errors.isEmpty;

  /// Índice en [kCaseFormSections] de la sección que contiene el campo.
  int get sectionIndex {
    final index = kCaseFormSections.indexWhere(
      (section) => section.title == sectionTitle,
    );
    assert(index >= 0, 'Sección desconocida: $sectionTitle');
    return index < 0 ? 0 : index;
  }
}

/// Deriva la lista SOLO de [validateDraft]: no hay reglas propias aquí.
List<IntakeChecklistItem> buildIntakeChecklist(CaseDraft draft) {
  final result = validateDraft(draft);
  List<String> errs(List<String?> all) => all.whereType<String>().toList();

  return [
    IntakeChecklistItem(
      id: 'title',
      label: 'Título',
      sectionTitle: 'Datos básicos',
      errors: errs([result.titleError]),
    ),
    IntakeChecklistItem(
      id: 'classification',
      label: 'Categoría, año y estado',
      sectionTitle: 'Datos básicos',
      errors: errs([
        result.categoryError,
        result.yearError,
        result.statusError,
      ]),
    ),
    IntakeChecklistItem(
      id: 'place',
      label: 'País, región y código ISO',
      sectionTitle: 'Ubicación',
      errors: errs([
        result.countryError,
        result.countryCodeError,
        result.regionOrCityError,
      ]),
    ),
    IntakeChecklistItem(
      id: 'coordinates',
      label: 'Punto en el mapa',
      sectionTitle: 'Ubicación',
      errors: errs([result.latitudeError, result.longitudeError]),
    ),
  ];
}

/// Lista «Campos obligatorios» del panel de previsualización. Cada fila
/// avisa con [onSelectSection] para que el anfitrión lleve el editor a la
/// sección del campo.
class IntakePreviewChecklist extends StatelessWidget {
  const IntakePreviewChecklist({
    super.key,
    required this.draft,
    this.onSelectSection,
  });

  final CaseDraft draft;
  final ValueChanged<int>? onSelectSection;

  @override
  Widget build(BuildContext context) {
    final items = buildIntakeChecklist(draft);
    return Container(
      padding: const EdgeInsets.all(DsSpacing.s16),
      decoration: BoxDecoration(
        color: DsColors.surfaceCard,
        borderRadius: DsRadii.cardBorder,
        border: Border.all(color: DsColors.lineHairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DsMonoLabel('Campos obligatorios'),
          const SizedBox(height: DsSpacing.s8),
          for (final item in items)
            _ChecklistRow(
              item: item,
              onTap: onSelectSection == null
                  ? null
                  : () => onSelectSection!(item.sectionIndex),
            ),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.item, required this.onTap});

  final IntakeChecklistItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final styles = DsTextStylesResolver.of(context);
    final done = item.isDone;
    final color = done ? DsStatusColors.solved : DsStatusColors.inProgress;
    final hint = done ? 'Listo' : item.errors.first;

    return Semantics(
      button: onTap != null,
      label: '${item.label}: $hint',
      excludeSemantics: true,
      child: InkWell(
        key: Key('intake-checklist-${item.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DsSpacing.s8,
              vertical: DsSpacing.s8,
            ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? color.withValues(alpha: 0.16) : null,
                    border: done ? null : Border.all(color: color, width: 1.5),
                  ),
                  child: Icon(
                    done ? Icons.check : Icons.priority_high,
                    size: 13,
                    color: color,
                  ),
                ),
                const SizedBox(width: DsSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: styles.uiButton.copyWith(
                          fontSize: 14,
                          color: DsColors.textPrimary,
                        ),
                      ),
                      if (!done)
                        Text(
                          hint,
                          style: styles.uiButton.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: color,
                          ),
                        ),
                    ],
                  ),
                ),
                if (done) ...[
                  const SizedBox(width: DsSpacing.s8),
                  Text(
                    hint,
                    style: styles.uiButton.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: DsColors.textFaint,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
