import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/design.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../home/presentation/widgets/situation/situation_styles.dart';
import '../../application/case_draft_providers.dart';
import 'intake_preview_checklist.dart';
import 'intake_preview_dossier.dart';
import 'intake_preview_summary.dart';

/// Previsualización del borrador con el MISMO expediente que ven los casos
/// publicados [Spec: Expediente Preview Parity].
///
/// Bajo el resumen, la lista de pendientes y el aviso va el expediente nuevo
/// de la página pública, completo y adaptado al ancho del panel. Los enlaces
/// del borrador son sus fuentes citadas; no hay una lista de enlaces aparte,
/// así que ninguna fuente se ve dos veces [diseño §9.3].
class IntakePreviewPanel extends ConsumerWidget {
  const IntakePreviewPanel({super.key, this.onSelectSection});

  /// Se invoca con el índice (en `kCaseFormSections`) de la sección del campo
  /// pendiente que se pulsa en la lista; el anfitrión decide cómo llevar el
  /// editor hasta ahí. Sin callback las filas son sólo informativas.
  final ValueChanged<int>? onSelectSection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewCase = ref.watch(draftPreviewCaseProvider);
    final draft = ref.watch(editingDraftProvider);
    if (previewCase == null || draft == null) {
      return Center(
        child: Text(
          'Crea o selecciona un borrador para previsualizarlo.',
          style: SituationStyles.sans(size: 13, color: AppColors.textSub),
        ),
      );
    }

    // Un único scroll: resumen, lista, aviso y expediente completo corren
    // juntos, sin scrolls anidados que se disputen el gesto. El expediente va
    // a todo el ancho del panel; sólo la cabecera lleva margen.
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(DsSpacing.s24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const DsMonoLabel('Previsualización'),
                    const SizedBox(width: DsSpacing.s12),
                    Expanded(
                      child: Text(
                        'Así se verá el expediente',
                        textAlign: TextAlign.end,
                        style: SituationStyles.sans(
                          size: 12,
                          color: DsColors.textFaint,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DsSpacing.s16),
                IntakePreviewSummary(draft: draft),
                const SizedBox(height: DsSpacing.s20),
                IntakePreviewChecklist(
                  draft: draft,
                  onSelectSection: onSelectSection,
                ),
                const SizedBox(height: DsSpacing.s20),
                const _ReservedNotice(),
              ],
            ),
          ),
          IntakePreviewDossier(previewCase: previewCase, draft: draft),
        ],
      ),
    );
  }
}

/// Aviso del envío a revisión: reservado, sin acción todavía.
class _ReservedNotice extends StatelessWidget {
  const _ReservedNotice();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.all(DsSpacing.s16),
        decoration: BoxDecoration(
          borderRadius: DsRadii.controlBorder,
          border: Border.all(color: DsColors.ctaOutlineBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DsMonoLabel('Enviar a revisión · Reservado'),
            const SizedBox(height: DsSpacing.s8),
            Text(
              'Aquí irá el envío a revisión. Todavía no está disponible: de '
              'momento, exporta con «Copiar JSON».',
              style: SituationStyles.sans(size: 13, color: DsColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
