import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/case_draft_providers.dart';
import '../../../application/draft_validator.dart';
import '../../../domain/case_draft.dart';
import '../../../domain/case_source.dart';

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

    void replaceLink(int index, DraftLink Function(DraftLink current) update) {
      final links = [...draft.links];
      links[index] = update(links[index]);
      notifier.updateDraft(draft.copyWith(links: links));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < draft.links.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
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
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
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
                const SizedBox(width: 10),
                DropdownButton<String>(
                  key: Key('intake-field-link-kind-$i'),
                  value: draft.links[i].kind ?? CaseSourceKind.investigation.name,
                  items: [
                    for (final kind in CaseSourceKind.values)
                      DropdownMenuItem(
                        value: kind.name,
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
                IconButton(
                  key: Key('intake-field-link-remove-$i'),
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () {
                    final links = [...draft.links]..removeAt(i);
                    notifier.updateDraft(draft.copyWith(links: links));
                  },
                ),
              ],
            ),
          ),
        TextButton.icon(
          key: const Key('intake-add-link-button'),
          onPressed: () {
            final links = [...draft.links, const DraftLink()];
            notifier.updateDraft(draft.copyWith(links: links));
          },
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Añadir enlace'),
        ),
      ],
    );
  }
}
