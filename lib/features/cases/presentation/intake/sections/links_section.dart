import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/case_draft_providers.dart';
import '../../../application/draft_validator.dart';
import '../../../domain/case_draft.dart';
import 'intake_field_row.dart';

/// Sección "Enlaces": fuentes externas (investigación, podcast…), opcional
/// en v1. Los enlaces mal formados se marcan pero no bloquean el guardado
/// [Spec: Malformed link flagged].
class LinksSection extends ConsumerWidget {
  const LinksSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(editingDraftProvider);
    if (draft == null) {
      return const SizedBox.shrink();
    }
    final notifier = ref.read(caseDraftsProvider.notifier);

    // Todas las mutaciones parten de la lista vigente, no de la capturada en
    // este `build`: editar dos campos seguidos no debe perder el primero.
    void replaceLink(int index, DraftLink Function(DraftLink current) update) {
      notifier.editDraft(draft.draftId, (current) {
        if (index >= current.links.length) {
          return current;
        }
        final links = [...current.links];
        links[index] = update(links[index]);
        return current.copyWith(links: links);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < draft.links.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: IntakeFieldRow(
              fields: [
                IntakeFieldSlot.flexible(
                  TextFormField(
                    key: Key('intake-field-link-title-$i'),
                    initialValue: draft.links[i].title,
                    decoration:
                        const InputDecoration(labelText: 'Título del enlace'),
                    onChanged: (value) => replaceLink(
                      i,
                      (link) =>
                          DraftLink(title: value, url: link.url, kind: link.kind),
                    ),
                  ),
                ),
                IntakeFieldSlot.flexible(
                  TextFormField(
                    key: Key('intake-field-link-url-$i'),
                    initialValue: draft.links[i].url,
                    decoration: InputDecoration(
                      labelText: 'URL',
                      errorText: validateLinkUrl(draft.links[i].url),
                    ),
                    onChanged: (value) => replaceLink(
                      i,
                      (link) =>
                          DraftLink(title: link.title, url: value, kind: link.kind),
                    ),
                  ),
                ),
                IntakeFieldSlot.fixed(
                  DropdownButtonFormField<DraftLinkKind>(
                    key: Key('intake-field-link-kind-$i'),
                    initialValue: draft.links[i].kind ?? DraftLinkKind.other,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: [
                      for (final kind in DraftLinkKind.values)
                        DropdownMenuItem(
                          value: kind,
                          child: Text(kind.label),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        replaceLink(
                          i,
                          (link) => DraftLink(
                            title: link.title,
                            url: link.url,
                            kind: value,
                          ),
                        );
                      }
                    },
                  ),
                  width: 170,
                ),
              ],
              trailing: IconButton(
                key: Key('intake-field-link-remove-$i'),
                icon: const Icon(Icons.close, size: 16),
                onPressed: () => notifier.editDraft(draft.draftId, (current) {
                  if (i >= current.links.length) {
                    return current;
                  }
                  return current.copyWith(
                    links: [...current.links]..removeAt(i),
                  );
                }),
              ),
            ),
          ),
        TextButton.icon(
          key: const Key('intake-add-link-button'),
          onPressed: () => notifier.editDraft(
            draft.draftId,
            (current) => current.copyWith(
              links: [...current.links, const DraftLink()],
            ),
          ),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Añadir enlace'),
        ),
      ],
    );
  }
}
