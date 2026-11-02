import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../domain/case_draft.dart';
import '../design/case_design_mapping.dart';

/// Cabecera compacta de la previsualización: categoría, estado, título, lugar
/// y las dos cifras del borrador (año y coordenadas). Los campos vacíos se
/// muestran como pendientes, nunca inventados.
class IntakePreviewSummary extends StatelessWidget {
  const IntakePreviewSummary({super.key, required this.draft});

  final CaseDraft draft;

  @override
  Widget build(BuildContext context) {
    final styles = DsTextStylesResolver.of(context);
    final category = draft.category;
    final status = draft.status;
    final categoryColor = category?.designColor;
    final title = draft.title?.trim() ?? '';
    final place = [
      draft.regionOrCity?.trim() ?? '',
      draft.country?.trim() ?? '',
      if (draft.year != null) '${draft.year}',
    ].where((part) => part.isNotEmpty).join(' · ');
    final lat = draft.latitude;
    final lon = draft.longitude;
    final glow = (categoryColor?.dot ?? DsColors.textFaint).withValues(
      alpha: 0.28,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(DsSpacing.s20),
          decoration: BoxDecoration(
            borderRadius: DsRadii.sheetBorder,
            border: Border.all(color: DsColors.lineHairline),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                glow,
                categoryColor?.posterBase ?? DsColors.bgGlow,
                DsColors.bgBase,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: DsSpacing.s12,
                runSpacing: DsSpacing.s8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  DsBadge(
                    label: category?.label ?? 'Categoría pendiente',
                    color: categoryColor?.dot ?? DsColors.textFaint,
                  ),
                  DsStatusLabel(
                    label: status?.label ?? 'Estado pendiente',
                    color: status?.designColor ?? DsColors.textFaint,
                  ),
                ],
              ),
              const SizedBox(height: DsSpacing.s16),
              Text(
                title.isEmpty ? 'Sin título' : title,
                key: const Key('intake-preview-title'),
                style: styles.displayCard.copyWith(
                  color: title.isEmpty
                      ? DsColors.textPlaceholder
                      : DsColors.textStrong,
                ),
              ),
              if (place.isNotEmpty) ...[
                const SizedBox(height: DsSpacing.s10),
                DsMonoLabel(place, color: DsColors.textBody),
              ],
            ],
          ),
        ),
        const SizedBox(height: DsSpacing.s12),
        Wrap(
          spacing: DsSpacing.s10,
          runSpacing: DsSpacing.s10,
          children: [
            _Fact(
              label: 'Año',
              value: draft.year == null ? 'Sin año' : '${draft.year}',
              pending: draft.year == null,
            ),
            _Fact(
              label: 'Coordenadas',
              value: lat == null || lon == null
                  ? 'Sin punto'
                  : '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}',
              pending: lat == null || lon == null,
            ),
          ],
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({
    required this.label,
    required this.value,
    required this.pending,
  });

  final String label;
  final String value;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final styles = DsTextStylesResolver.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.all(DsSpacing.s14),
      decoration: BoxDecoration(
        color: DsColors.surfaceCard,
        borderRadius: DsRadii.controlBorder,
        border: Border.all(color: DsColors.lineHairline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DsMonoLabel(label, letterSpacingEm: 0.14),
          const SizedBox(height: DsSpacing.s8),
          Text(
            value,
            style: styles.uiButton.copyWith(
              fontSize: 16,
              color: pending ? DsColors.textFaint : DsColors.accentGold,
            ),
          ),
        ],
      ),
    );
  }
}
