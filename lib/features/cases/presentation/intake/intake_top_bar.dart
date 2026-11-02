import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/design.dart';
import '../../application/case_draft_providers.dart';
import '../../application/cases_providers.dart';
import 'drafts_backup_button.dart';
import 'export_case_button.dart';

/// Barra superior del workspace: volver a la portada, título y las acciones
/// globales (copia de seguridad, exportar, nuevo borrador).
class IntakeTopBar extends ConsumerWidget {
  const IntakeTopBar({super.key, required this.compact});

  /// Por debajo de `Breakpoints.intakeThreePane` la barra a tamaño completo
  /// desborda (≈476px de contenido en 360px), así que se reduce a iconos
  /// [Diseño D7].
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final styles = DsTextStylesResolver.of(context);

    Future<void> createDraft() async {
      final draftId = await ref.read(caseDraftsProvider.notifier).createDraft();
      ref.read(editingDraftIdProvider.notifier).state = draftId;
    }

    return Container(
      height: compact ? 56 : 68,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? DsSpacing.s8 : DsSpacing.s20,
      ),
      decoration: const BoxDecoration(
        color: DsColors.surfaceChrome,
        border: Border(bottom: BorderSide(color: DsColors.lineHairline)),
      ),
      child: Row(
        children: [
          DsIconButton(
            key: const Key('intake-back-button'),
            icon: Icons.arrow_back,
            semanticLabel: 'Volver a la portada',
            onPressed: () => ref.read(workspaceProvider.notifier).state =
                Workspace.situationRoom,
          ),
          SizedBox(width: compact ? DsSpacing.s4 : DsSpacing.s16),
          if (compact)
            Flexible(
              child: Text(
                'Formulario de casos',
                style: styles.uiButton.copyWith(
                  fontSize: 14,
                  color: DsColors.textBody,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            )
          else ...[
            // Expanded en vez de Spacer: con el ancho justo del escritorio
            // el título cede y se recorta antes que desbordar la barra.
            Expanded(
              child: Text(
                'Formulario de casos',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: styles.uiButton.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: DsColors.textBody,
                ),
              ),
            ),
          ],
          if (compact) ...[
            DsIconButton(
              key: const Key('intake-drafts-toggle-button'),
              icon: Icons.list_alt,
              semanticLabel: 'Borradores',
              onPressed: () =>
                  ref.read(intakeDraftListOpenProvider.notifier).state = !ref
                      .read(intakeDraftListOpenProvider),
            ),
            DsIconButton(
              key: const Key('intake-preview-toggle-button'),
              icon: Icons.visibility_outlined,
              semanticLabel: 'Previsualización',
              onPressed: () =>
                  ref.read(intakePreviewOpenProvider.notifier).state = !ref
                      .read(intakePreviewOpenProvider),
            ),
            const DraftsBackupButton(compact: true),
            const ExportCaseButton(compact: true),
            DsIconButton(
              key: const Key('intake-new-draft-button'),
              icon: Icons.add,
              semanticLabel: 'Nuevo borrador',
              onPressed: createDraft,
            ),
          ] else ...[
            const DraftsBackupButton(),
            const SizedBox(width: DsSpacing.s10),
            const ExportCaseButton(),
            const SizedBox(width: DsSpacing.s10),
            DsButton(
              key: const Key('intake-new-draft-button'),
              label: 'Nuevo borrador',
              trailingIcon: Icons.add,
              onPressed: createDraft,
            ),
          ],
        ],
      ),
    );
  }
}
