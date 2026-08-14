import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../home/presentation/widgets/situation/case_dossier_content.dart';
import '../../../home/presentation/widgets/situation/case_dossier_panel.dart';
import '../../../home/presentation/widgets/situation/situation_styles.dart';
import '../../application/case_draft_providers.dart';
import 'preview_source_groups.dart';

/// Previsualización del borrador con el MISMO expediente que ven los casos
/// publicados [Spec: Expediente Preview Parity].
///
/// Ya no añade una lista de enlaces propia debajo: los enlaces del borrador
/// entran como grupos de fuentes y los pinta el renderizador compartido, con
/// las mismas tarjetas que un caso publicado. Ese override es también lo que
/// impide que las fuentes se vean dos veces [diseño §9.3].
class IntakePreviewPanel extends ConsumerWidget {
  const IntakePreviewPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewCase = ref.watch(draftPreviewCaseProvider);
    if (previewCase == null) {
      return Center(
        child: Text(
          'Crea o selecciona un borrador para previsualizarlo.',
          style: SituationStyles.sans(size: 13, color: AppColors.textSub),
        ),
      );
    }

    final draft = ref.watch(editingDraftProvider);

    return CaseDossierPanel(
      crimeCase: previewCase,
      // Sin mapa detrás no hay adónde volver ni qué recentrar.
      mode: CaseDossierMode.preview,
      // Un borrador no tiene casos relacionados: pasar la lista vacía evita
      // que el panel se ponga a derivarlos del catálogo publicado.
      relatedCases: const [],
      sourceGroups: previewSourceGroups(draft?.links ?? const []),
    );
  }
}
