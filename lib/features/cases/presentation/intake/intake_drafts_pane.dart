import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/design.dart';
import '../../application/case_draft_providers.dart';
import '../../application/draft_validator.dart';
import '../../domain/case_draft.dart';
import 'intake_drafts_pane_account.dart';

/// Panel izquierdo del workspace: lista de borradores locales y pie de cuenta.
class IntakeDraftsPane extends ConsumerWidget {
  const IntakeDraftsPane({
    super.key,
    required this.drafts,
    required this.selectedId,
    this.onAfterSelect,
  });

  final List<CaseDraft> drafts;
  final String? selectedId;

  /// Sólo lo usa la hoja de lista en el workspace estrecho: elegir un
  /// borrador ahí es una elección modal terminal, así que la hoja se cierra
  /// sola [Diseño D3]. El escritorio no lo pasa y no cambia de
  /// comportamiento.
  final VoidCallback? onAfterSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: DsColors.lineHairline)),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: DsSpacing.s16,
                vertical: DsSpacing.s20,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: DsSpacing.s4,
                    bottom: DsSpacing.s12,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: DsMonoLabel('Borradores · ${drafts.length}'),
                  ),
                ),
                for (final draft in drafts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: DsSpacing.s8),
                    child: _DraftCard(
                      draft: draft,
                      selected: draft.draftId == selectedId,
                      onSelect: () {
                        ref.read(editingDraftIdProvider.notifier).state =
                            draft.draftId;
                        onAfterSelect?.call();
                      },
                      onDelete: () => _confirmAndDelete(context, ref, draft),
                    ),
                  ),
              ],
            ),
          ),
          const IntakeAccountFooter(),
        ],
      ),
    );
  }

  /// Un clic en la papelera no basta para perder un borrador: sólo se borra
  /// tras confirmar. Cancelar, Escape o tocar fuera no tocan nada [S4].
  Future<void> _confirmAndDelete(
    BuildContext context,
    WidgetRef ref,
    CaseDraft draft,
  ) async {
    // Se leen antes de esperar: la hoja estrecha puede cerrarse mientras
    // el diálogo está abierto y `ref` dejaría de ser utilizable.
    final drafts = ref.read(caseDraftsProvider.notifier);
    final editingDraftId = ref.read(editingDraftIdProvider.notifier);
    final confirmed = await showDsDialog<bool>(
      context: context,
      builder: (dialogContext) => DsDialog(
        key: const Key('intake-draft-delete-dialog'),
        title: '¿Borrar este borrador?',
        content: Text(
          '«${_draftLabel(draft)}». '
          'Se borra de este equipo y no se puede deshacer.',
        ),
        actions: [
          DsButton(
            key: const Key('intake-draft-delete-cancel'),
            label: 'Cancelar',
            variant: DsButtonVariant.outline,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          DsButton(
            key: const Key('intake-draft-delete-confirm'),
            label: 'Borrar',
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await drafts.deleteDraft(draft.draftId);
    if (selectedId == draft.draftId) {
      editingDraftId.state = null;
    }
  }
}

/// Etiqueta con la que se nombra un borrador en la lista y al borrarlo.
String _draftLabel(CaseDraft draft) =>
    draft.title?.isNotEmpty == true ? draft.title! : 'Sin título';

/// Tarjeta de un borrador: zona seleccionable y papelera, con el activo
/// resaltado en rojo de marca.
class _DraftCard extends StatelessWidget {
  const _DraftCard({
    required this.draft,
    required this.selected,
    required this.onSelect,
    required this.onDelete,
  });

  final CaseDraft draft;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final styles = DsTextStylesResolver.of(context);
    final isValid = validateDraft(draft).isValid;
    final untitled = draft.title?.isNotEmpty != true;
    final label = _draftLabel(draft);
    final status = isValid ? 'Listo · sin publicar' : 'Incompleto';

    return AnimatedContainer(
      duration: DsMotion.hover,
      curve: DsMotion.easeUi,
      decoration: BoxDecoration(
        color: selected
            ? DsColors.accentRed.withValues(alpha: 0.12)
            : DsColors.surfaceCard,
        borderRadius: DsRadii.controlBorder,
        border: Border.all(
          color: selected
              ? DsColors.accentRed.withValues(alpha: 0.6)
              : DsColors.lineHairline,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: DsPressable(
              key: Key('intake-draft-item-${draft.draftId}'),
              onTap: onSelect,
              selected: selected,
              semanticLabel: '$label. $status',
              builder: (context, state) => Padding(
                padding: const EdgeInsets.fromLTRB(
                  DsSpacing.s16,
                  DsSpacing.s12,
                  DsSpacing.s4,
                  DsSpacing.s12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: styles.displayPoster.copyWith(
                        fontSize: 17,
                        height: 1.2,
                        color: untitled
                            ? DsColors.textMuted
                            : DsColors.textStrong,
                        fontStyle: untitled ? FontStyle.italic : null,
                      ),
                    ),
                    const SizedBox(height: DsSpacing.s8),
                    DsStatusLabel(
                      label: status,
                      color: isValid
                          ? DsStatusColors.solved
                          : DsStatusColors.inProgress,
                    ),
                  ],
                ),
              ),
            ),
          ),
          DsIconButton(
            key: Key('intake-draft-delete-${draft.draftId}'),
            icon: Icons.delete_outline,
            semanticLabel: 'Borrar borrador',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
