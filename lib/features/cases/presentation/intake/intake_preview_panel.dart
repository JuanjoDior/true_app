import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home/presentation/widgets/situation/situation_styles.dart';
import '../../application/case_draft_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../home/presentation/widgets/situation/case_dossier_panel.dart';
import '../../domain/case_draft.dart';

/// Previsualización del borrador con el mismo `CaseDossierPanel` que usan los
/// casos publicados [Spec: Expediente Preview Parity], más los enlaces
/// agrupados por tipo [Spec: Links grouped in preview].
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
    final groups = _groupLinksByKind(draft?.links ?? const <DraftLink>[]);
    // Sólo se previsualizan las fotos que ya tienen URL.
    final photos = (draft?.photos ?? const <DraftPhoto>[])
        .where((photo) => photo.url?.trim().isNotEmpty == true)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: CaseDossierPanel(crimeCase: previewCase)),
        if (groups.isNotEmpty || photos.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final entry in groups.entries)
                    _LinkGroup(kind: entry.key, links: entry.value),
                  if (photos.isNotEmpty) _PhotoStrip(photos: photos),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Tira horizontal de fotografías del borrador. Una URL rota muestra un
/// marcador de posición en lugar de romper la previsualización.
class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.photos});

  final List<DraftPhoto> photos;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('intake-preview-photos'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SituationSectionLabel('Fotografías'),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final photo = photos[index];
              return SizedBox(
                key: Key('intake-preview-photo-$index'),
                width: 150,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          photo.url!,
                          width: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const _PhotoPlaceholder(),
                        ),
                      ),
                    ),
                    if (photo.caption?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        photo.caption!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: SituationStyles.sans(
                          size: 11,
                          color: AppColors.textSub,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      color: AppColors.textSub.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        size: 18,
        color: AppColors.textSub,
      ),
    );
  }
}

/// Agrupa los enlaces por tipo conservando el orden del enum. Los enlaces sin
/// tipo se unen a [DraftLinkKind.other] ("Sin clasificar").
Map<DraftLinkKind, List<DraftLink>> _groupLinksByKind(List<DraftLink> links) {
  final grouped = <DraftLinkKind, List<DraftLink>>{};
  for (final kind in DraftLinkKind.values) {
    final matching = links
        .where((link) => (link.kind ?? DraftLinkKind.other) == kind)
        .toList(growable: false);
    if (matching.isNotEmpty) {
      grouped[kind] = matching;
    }
  }
  return grouped;
}

class _LinkGroup extends StatelessWidget {
  const _LinkGroup({required this.kind, required this.links});

  final DraftLinkKind kind;
  final List<DraftLink> links;

  /// Etiqueta del grupo: los enlaces sin tipo explícito se muestran como
  /// pendientes de clasificar, no como un tipo real.
  String get _groupLabel =>
      kind == DraftLinkKind.other ? 'Sin clasificar' : kind.label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: Key('intake-preview-link-group-${kind.name}'),
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SituationSectionLabel(_groupLabel),
          const SizedBox(height: 6),
          for (final link in links)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                link.title?.isNotEmpty == true
                    ? link.title!
                    : (link.url ?? 'Enlace sin título'),
                style: SituationStyles.sans(
                  size: 13,
                  color: AppColors.textSub2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
