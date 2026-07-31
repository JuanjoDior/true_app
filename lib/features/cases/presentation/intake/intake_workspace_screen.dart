import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../home/presentation/widgets/situation/situation_styles.dart';
import '../../application/case_draft_providers.dart';
import '../../application/cases_providers.dart';
import '../../application/draft_validator.dart';
import '../../domain/case_draft.dart';
import 'case_form_section.dart';
import 'export_case_button.dart';
import 'intake_gate_screen.dart';
import 'intake_preview_panel.dart';

/// Workspace de alta de casos de Iván: gate por clave compartida, lista de
/// borradores, formulario por secciones y previsualización del expediente.
class IntakeWorkspaceScreen extends ConsumerWidget {
  const IntakeWorkspaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = ref.watch(intakeUnlockedProvider);
    if (!unlocked) {
      return const IntakeGateScreen();
    }
    return const _IntakeFormBody();
  }
}

class _IntakeFormBody extends ConsumerWidget {
  const _IntakeFormBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draftsAsync = ref.watch(caseDraftsProvider);
    final editingDraftId = ref.watch(editingDraftIdProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Column(
        children: [
          const _WorkspaceTopBar(),
          Expanded(
            child: draftsAsync.when(
              data: (drafts) => Row(
                children: [
                  SizedBox(
                    width: 260,
                    child: _DraftList(
                      drafts: drafts,
                      selectedId: editingDraftId,
                    ),
                  ),
                  Expanded(
                    child: editingDraftId == null
                        ? Center(
                            child: Text(
                              'Crea o selecciona un borrador para editarlo.',
                              style: SituationStyles.sans(
                                size: 13,
                                color: AppColors.textSub,
                              ),
                            ),
                          )
                        : const _FormAndPreview(),
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text('Error al cargar borradores: $error')),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceTopBar extends ConsumerWidget {
  const _WorkspaceTopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.bar,
        border: Border(bottom: BorderSide(color: AppColors.panelMuted)),
      ),
      child: Row(
        children: [
          IconButton(
            key: const Key('intake-back-button'),
            icon: const Icon(Icons.arrow_back, color: AppColors.textSoft),
            onPressed: () =>
                ref.read(workspaceProvider.notifier).state =
                    Workspace.situationRoom,
          ),
          Text('Formulario de casos', style: SituationStyles.serif(size: 16)),
          const Spacer(),
          const ExportCaseButton(),
          const SizedBox(width: 8),
          TextButton.icon(
            key: const Key('intake-new-draft-button'),
            onPressed: () async {
              final draftId =
                  await ref.read(caseDraftsProvider.notifier).createDraft();
              ref.read(editingDraftIdProvider.notifier).state = draftId;
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Nuevo borrador'),
          ),
        ],
      ),
    );
  }
}

class _DraftList extends ConsumerWidget {
  const _DraftList({required this.drafts, required this.selectedId});

  final List<CaseDraft> drafts;
  final String? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppColors.panelMuted)),
      ),
      child: ListView.builder(
        itemCount: drafts.length,
        itemBuilder: (context, index) {
          final draft = drafts[index];
          final isSelected = draft.draftId == selectedId;
          final isValid = validateDraft(draft).isValid;
          return ListTile(
            key: Key('intake-draft-item-${draft.draftId}'),
            selected: isSelected,
            title: Text(
              draft.title?.isNotEmpty == true ? draft.title! : 'Sin título',
            ),
            subtitle: Text(isValid ? 'Listo · sin publicar' : 'Incompleto'),
            trailing: IconButton(
              key: Key('intake-draft-delete-${draft.draftId}'),
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: () async {
                await ref
                    .read(caseDraftsProvider.notifier)
                    .deleteDraft(draft.draftId);
                if (selectedId == draft.draftId) {
                  ref.read(editingDraftIdProvider.notifier).state = null;
                }
              },
            ),
            onTap: () =>
                ref.read(editingDraftIdProvider.notifier).state = draft.draftId,
          );
        },
      ),
    );
  }
}

class _FormAndPreview extends StatelessWidget {
  const _FormAndPreview();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final section in kCaseFormSections) ...[
                  SituationSectionLabel(section.title),
                  const SizedBox(height: 10),
                  Builder(builder: section.builder),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(
          width: 380,
          child: IntakePreviewPanel(),
        ),
      ],
    );
  }
}
