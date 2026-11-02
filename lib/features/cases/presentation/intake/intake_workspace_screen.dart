import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/design.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../home/presentation/widgets/situation/situation_styles.dart';
import '../../application/case_draft_providers.dart';
import '../../application/draft_validator.dart';
import '../../domain/case_draft.dart';
import 'intake_drafts_pane.dart';
import 'intake_editor.dart';
import 'intake_preview_panel.dart';
import 'intake_top_bar.dart';

/// Workspace local de alta de casos: la sesión se reserva para el envío
/// explícito a revisión y nunca bloquea los borradores de este dispositivo.
class IntakeWorkspaceScreen extends StatelessWidget {
  const IntakeWorkspaceScreen({super.key});

  @override
  Widget build(BuildContext context) => const _IntakeFormBody();
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
          IntakeTopBar(compact: isNarrow),
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
                          child: IntakeDraftsPane(
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

class _FormAndPreview extends StatefulWidget {
  const _FormAndPreview({super.key});

  @override
  State<_FormAndPreview> createState() => _FormAndPreviewState();
}

class _FormAndPreviewState extends State<_FormAndPreview> {
  final _editorController = IntakeEditorController();

  @override
  void dispose() {
    _editorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _IntakeFormColumn(controller: _editorController)),
        SizedBox(
          width: 380,
          child: IntakePreviewPanel(
            onSelectSection: _editorController.scrollToSection,
          ),
        ),
      ],
    );
  }
}

/// La columna del editor, sin la previsualización lateral. La usan tanto el
/// escritorio (dentro de [_FormAndPreview]) como el workspace estrecho (a
/// pantalla completa, con la previsualización como hoja aparte)
/// [Diseño: Data Flow].
class _IntakeFormColumn extends StatelessWidget {
  const _IntakeFormColumn({super.key, required this.controller});

  final IntakeEditorController controller;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const Key('intake-form-column'),
      child: IntakeEditor(
        controller: controller,
        header: const _EditorHeader(),
      ),
    );
  }
}

/// Cabecera del editor: título del borrador y estado derivado de
/// [validateDraft]. No guarda nada: sólo lee el borrador en edición.
class _EditorHeader extends ConsumerWidget {
  const _EditorHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(editingDraftProvider);
    if (draft == null) {
      return const SizedBox.shrink();
    }
    final styles = DsTextStylesResolver.of(context);
    final compact = MediaQuery.sizeOf(context).width < DsBreakpoints.desktop;
    final margin = compact ? DsSpacing.s16 : DsSpacing.s32;
    final title = draft.title?.trim() ?? '';
    final ready = validateDraft(draft).isValid;
    final statusColor = ready ? DsStatusColors.open : DsStatusColors.inProgress;

    return Padding(
      key: const Key('intake-editor-header'),
      padding: EdgeInsets.fromLTRB(
        margin,
        DsSpacing.s20,
        margin,
        DsSpacing.s16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DsMonoLabel(
            'Borrador local',
            color: DsColors.accentRedText,
            letterSpacingEm: 0.22,
          ),
          const SizedBox(height: DsSpacing.s8),
          Semantics(
            header: true,
            child: Text(
              title.isEmpty ? 'Sin título' : title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: styles.displaySection.copyWith(
                fontSize: compact ? 22 : 28,
              ),
            ),
          ),
          const SizedBox(height: DsSpacing.s10),
          Row(
            children: [
              Icon(
                ready ? Icons.check_circle_outline : Icons.circle_outlined,
                size: 14,
                color: statusColor,
              ),
              const SizedBox(width: DsSpacing.s8),
              Text(
                ready ? 'Listo · sin publicar' : 'Incompleto',
                key: const Key('intake-editor-status'),
                style: styles.monoLabel.copyWith(color: statusColor),
              ),
            ],
          ),
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
  final _editorController = IntakeEditorController();

  @override
  void initState() {
    super.initState();
    _scheduleLandingIfNeeded();
  }

  @override
  void dispose() {
    _editorController.dispose();
    super.dispose();
  }

  /// Cierra la hoja de previsualización y, ya con el editor a la vista, lo
  /// desplaza hasta la sección pedida.
  void _selectSection(int index) {
    ref.read(intakePreviewOpenProvider.notifier).state = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _editorController.scrollToSection(index);
      }
    });
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
              : _IntakeFormColumn(
                  key: ValueKey(editingDraftId),
                  controller: _editorController,
                ),
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
              child: IntakePreviewPanel(onSelectSection: _selectSection),
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
                child: IntakeDraftsPane(
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
