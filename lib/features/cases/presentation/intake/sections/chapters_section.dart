import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/case_draft_providers.dart';
import '../../../domain/case_chapter.dart';
import '../../case_chapter_presentation.dart';

/// Sección "Capítulos": la lectura larga del expediente, en cuatro bloques
/// fijos [spec: case-editorial-chapters].
///
/// **No hay botón de añadir, borrar ni reordenar, y es a propósito.** Los
/// cuatro tipos y su orden son parte del contrato editorial: si el formulario
/// dejara inventar capítulos o moverlos, el orden fijo que garantizan la
/// exportación y el expediente publicado dejaría de significar nada. Un
/// capítulo se "borra" vaciando su campo.
class ChaptersSection extends ConsumerWidget {
  const ChaptersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(editingDraftProvider);
    if (draft == null) {
      return const SizedBox.shrink();
    }
    final notifier = ref.read(caseDraftsProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final type in CaseChapterType.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextFormField(
              // La clave lleva el borrador dentro porque `TextFormField`
              // ignora los cambios de `initialValue`: al cambiar de borrador,
              // sin esto el campo seguiría enseñando el texto del anterior.
              key: Key('intake-field-chapter-${draft.draftId}-${type.name}'),
              initialValue: draft.chapters.contentFor(type),
              minLines: 3,
              maxLines: 12,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                labelText: type.label,
                alignLabelWithHint: true,
              ),
              // Se transforma el borrador VIGENTE, no la copia capturada en
              // este `build`: escribir en dos capítulos seguidos antes de que
              // Flutter reconstruya no puede perder el primero.
              onChanged: (value) => notifier.editDraft(
                draft.draftId,
                (current) => current.copyWith(
                  chapters: current.chapters.withContent(type, value),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
