import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/case_draft_providers.dart';
import '../../../domain/case_draft.dart';

/// Sección "Resumen y ficha": el texto del caso, la descripción de las
/// víctimas y los tags. Todo opcional, pero es lo que da cuerpo editorial al
/// expediente publicado.
class SummarySection extends ConsumerWidget {
  const SummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(editingDraftProvider);
    if (draft == null) {
      return const SizedBox.shrink();
    }
    final notifier = ref.read(caseDraftsProvider.notifier);

    // Se edita sobre el borrador vigente, no sobre el capturado en este
    // `build`: escribir en dos campos seguidos no debe perder el primero.
    void edit(CaseDraft Function(CaseDraft current) update) {
      notifier.editDraft(draft.draftId, update);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          key: const Key('intake-field-summary'),
          initialValue: draft.summary,
          maxLines: 6,
          decoration: const InputDecoration(labelText: 'Resumen del caso'),
          onChanged: (value) =>
              edit((current) => current.copyWith(summary: value)),
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('intake-field-victim'),
          initialValue: draft.victim,
          decoration: const InputDecoration(
            labelText: 'Víctimas',
            hintText: 'Al menos 5 víctimas confirmadas',
            helperText: 'Descríbelas con respeto, como en el resto del archivo',
          ),
          onChanged: (value) =>
              edit((current) => current.copyWith(victim: value)),
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('intake-field-tags'),
          initialValue: formatTags(draft.tags),
          decoration: const InputDecoration(
            labelText: 'Tags',
            hintText: '1960s, ee. uu., cifrado',
            helperText: 'Separados por comas',
          ),
          onChanged: (value) =>
              edit((current) => current.copyWith(tags: parseTags(value))),
        ),
      ],
    );
  }
}
