import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/breakpoints.dart';
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
    final isNarrow =
        MediaQuery.sizeOf(context).width < Breakpoints.intakeThreePane;

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Column(
        children: [
          _WorkspaceTopBar(compact: isNarrow),
          Expanded(
            child: draftsAsync.when(
              data: (drafts) => isNarrow
                  ? _NarrowIntakeBody(
                      drafts: drafts,
                      editingDraftId: editingDraftId,
                    )
                  // Tres columnas simultáneas: lista, formulario y
                  // previsualización [Requirement: Desktop Three-Pane Layout
                  // Unchanged]. Sin cambios respecto al comportamiento previo.
                  : Row(
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
                              // La clave por borrador es lo que mantiene
                              // honesto al formulario: los campos de texto
                              // guardan su propio texto y sólo leen
                              // `initialValue` al construirse, así que sin
                              // esto al cambiar de borrador seguirían
                              // enseñando los valores del anterior.
                              : _FormAndPreview(key: ValueKey(editingDraftId)),
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
  const _WorkspaceTopBar({required this.compact});

  /// Por debajo de `Breakpoints.intakeThreePane` la barra a tamaño completo
  /// desborda (≈476px de contenido en 360px), así que se reduce a iconos
  /// [Diseño D7].
  final bool compact;

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
            onPressed: () => ref.read(workspaceProvider.notifier).state =
                Workspace.situationRoom,
          ),
          if (compact)
            Flexible(
              child: Text(
                'Formulario de casos',
                style: SituationStyles.serif(size: 16),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            )
          else ...[
            Text('Formulario de casos', style: SituationStyles.serif(size: 16)),
            const Spacer(),
          ],
          if (compact) ...[
            IconButton(
              key: const Key('intake-drafts-toggle-button'),
              tooltip: 'Borradores',
              icon: const Icon(Icons.list_alt, size: 20),
              onPressed: () =>
                  ref.read(intakeDraftListOpenProvider.notifier).state = !ref
                      .read(intakeDraftListOpenProvider),
            ),
            IconButton(
              key: const Key('intake-preview-toggle-button'),
              tooltip: 'Previsualización',
              icon: const Icon(Icons.visibility_outlined, size: 20),
              onPressed: () =>
                  ref.read(intakePreviewOpenProvider.notifier).state = !ref
                      .read(intakePreviewOpenProvider),
            ),
            const ExportCaseButton(compact: true),
            IconButton(
              key: const Key('intake-new-draft-button'),
              tooltip: 'Nuevo borrador',
              icon: const Icon(Icons.add, size: 20),
              onPressed: () async {
                final draftId = await ref
                    .read(caseDraftsProvider.notifier)
                    .createDraft();
                ref.read(editingDraftIdProvider.notifier).state = draftId;
              },
            ),
          ] else ...[
            const ExportCaseButton(),
            const SizedBox(width: 8),
            TextButton.icon(
              key: const Key('intake-new-draft-button'),
              onPressed: () async {
                final draftId = await ref
                    .read(caseDraftsProvider.notifier)
                    .createDraft();
                ref.read(editingDraftIdProvider.notifier).state = draftId;
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Nuevo borrador'),
            ),
          ],
        ],
      ),
    );
  }
}

class _DraftList extends ConsumerWidget {
  const _DraftList({
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
            onTap: () {
              ref.read(editingDraftIdProvider.notifier).state = draft.draftId;
              onAfterSelect?.call();
            },
          );
        },
      ),
    );
  }
}

class _FormAndPreview extends StatelessWidget {
  const _FormAndPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: _IntakeFormColumn()),
        const SizedBox(width: 380, child: IntakePreviewPanel()),
      ],
    );
  }
}

/// La columna de secciones del formulario, sin la previsualización lateral.
/// La usan tanto el escritorio (dentro de [_FormAndPreview]) como el
/// workspace estrecho (a pantalla completa, con la previsualización como
/// hoja aparte) [Diseño: Data Flow].
class _IntakeFormColumn extends StatelessWidget {
  const _IntakeFormColumn({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const Key('intake-form-column'),
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
    );
  }
}

/// Workspace por debajo de `Breakpoints.intakeThreePane`: el formulario
/// ocupa toda la pantalla y la lista de borradores y la previsualización se
/// alcanzan mediante hojas superpuestas, en vez de columnas permanentes
/// [Requirement: Narrow Workspace Composition].
class _NarrowIntakeBody extends ConsumerStatefulWidget {
  const _NarrowIntakeBody({required this.drafts, required this.editingDraftId});

  final List<CaseDraft> drafts;
  final String? editingDraftId;

  @override
  ConsumerState<_NarrowIntakeBody> createState() => _NarrowIntakeBodyState();
}

class _NarrowIntakeBodyState extends ConsumerState<_NarrowIntakeBody> {
  // Sólo debe dispararse una vez por apertura del workspace, no en cada
  // reconstrucción mientras el borrador todavía se está creando
  // [Diseño D6].
  bool _landingScheduled = false;

  @override
  void initState() {
    super.initState();
    _scheduleLandingIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _NarrowIntakeBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleLandingIfNeeded();
  }

  void _scheduleLandingIfNeeded() {
    if (_landingScheduled || widget.editingDraftId != null) {
      return;
    }
    _landingScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      if (widget.drafts.isEmpty) {
        final draftId = await ref
            .read(caseDraftsProvider.notifier)
            .createDraft();
        if (!mounted) {
          return;
        }
        ref.read(editingDraftIdProvider.notifier).state = draftId;
      } else {
        ref.read(editingDraftIdProvider.notifier).state =
            widget.drafts.last.draftId;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final draftListOpen = ref.watch(intakeDraftListOpenProvider);
    final previewOpen = ref.watch(intakePreviewOpenProvider);
    final height = MediaQuery.sizeOf(context).height;
    final editingDraftId = widget.editingDraftId;

    return Stack(
      children: [
        Positioned.fill(
          child: editingDraftId == null
              ? const SizedBox.shrink()
              : _IntakeFormColumn(key: ValueKey(editingDraftId)),
        ),
        if (previewOpen)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            // Sin scrim: el formulario sigue tocable detrás mientras la
            // hoja de previsualización está abierta [Requirement: Live
            // Preview Behind an Open Sheet].
            child: Container(
              key: const Key('intake-preview-sheet'),
              height: height * 0.5,
              decoration: BoxDecoration(
                color: AppColors.bar,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                border: const Border(
                  top: BorderSide(color: AppColors.panelMuted),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 40,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: const IntakePreviewPanel(),
            ),
          ),
        if (draftListOpen) ...[
          Positioned.fill(
            child: GestureDetector(
              key: const Key('intake-draft-list-scrim'),
              onTap: () =>
                  ref.read(intakeDraftListOpenProvider.notifier).state = false,
              child: Container(color: Colors.black.withValues(alpha: 0.5)),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            top: 60,
            bottom: 60,
            child: Container(
              key: const Key('intake-draft-list-sheet'),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.panelMuted),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 40,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              // `ListTile` pinta su fondo y el ripple sobre el `Material`
              // ancestro más cercano: si el color va en el `Container` de
              // fuera, Flutter avisa de que quedaría invisible.
              child: Material(
                color: AppColors.bar,
                child: _DraftList(
                  drafts: widget.drafts,
                  selectedId: editingDraftId,
                  onAfterSelect: () =>
                      ref.read(intakeDraftListOpenProvider.notifier).state =
                          false,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
