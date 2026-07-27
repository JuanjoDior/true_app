import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home/presentation/widgets/situation/situation_styles.dart';
import '../../application/case_draft_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../home/presentation/widgets/situation/case_dossier_panel.dart';

/// Previsualización del borrador con el mismo `CaseDossierPanel` que usan los
/// casos publicados [Spec: Expediente Preview Parity].
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
    return CaseDossierPanel(crimeCase: previewCase);
  }
}
