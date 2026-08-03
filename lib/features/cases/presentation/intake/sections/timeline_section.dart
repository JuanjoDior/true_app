import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/case_draft_providers.dart';
import '../../../domain/case_draft.dart';
import '../../../domain/case_timeline_event.dart';

/// Sección "Cronología": los hitos verificados del caso, en el orden en que
/// se añaden.
///
/// La fecha es texto libre a propósito: el archivo publica cosas como
/// "1968–69" o "Hoy", que ningún selector de fechas sabe expresar.
class TimelineSection extends ConsumerWidget {
  const TimelineSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(editingDraftProvider);
    if (draft == null) {
      return const SizedBox.shrink();
    }
    final notifier = ref.read(caseDraftsProvider.notifier);

    // Todas las mutaciones parten de la lista vigente, no de la capturada en
    // este `build`: editar dos campos seguidos no debe perder el primero.
    void replaceEvent(
      int index,
      DraftTimelineEvent Function(DraftTimelineEvent current) update,
    ) {
      notifier.editDraft(draft.draftId, (current) {
        if (index >= current.timeline.length) {
          return current;
        }
        final timeline = [...current.timeline];
        timeline[index] = update(timeline[index]);
        return current.copyWith(timeline: timeline);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < draft.timeline.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    key: Key('intake-field-timeline-date-$i'),
                    initialValue: draft.timeline[i].date,
                    decoration: const InputDecoration(
                      labelText: 'Fecha',
                      hintText: '1969',
                    ),
                    onChanged: (value) => replaceEvent(
                      i,
                      (event) => DraftTimelineEvent(
                        date: value,
                        title: event.title,
                        kind: event.kind,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    key: Key('intake-field-timeline-title-$i'),
                    initialValue: draft.timeline[i].title,
                    decoration: const InputDecoration(labelText: 'Qué ocurrió'),
                    onChanged: (value) => replaceEvent(
                      i,
                      (event) => DraftTimelineEvent(
                        date: event.date,
                        title: value,
                        kind: event.kind,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 170,
                  child: DropdownButtonFormField<CaseTimelineKind>(
                    key: Key('intake-field-timeline-kind-$i'),
                    initialValue:
                        draft.timeline[i].kind ?? CaseTimelineKind.process,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: [
                      for (final kind in CaseTimelineKind.values)
                        DropdownMenuItem(
                          value: kind,
                          child: Text(kind.label),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        replaceEvent(
                          i,
                          (event) => DraftTimelineEvent(
                            date: event.date,
                            title: event.title,
                            kind: value,
                          ),
                        );
                      }
                    },
                  ),
                ),
                IconButton(
                  key: Key('intake-field-timeline-remove-$i'),
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => notifier.editDraft(draft.draftId, (current) {
                    if (i >= current.timeline.length) {
                      return current;
                    }
                    return current.copyWith(
                      timeline: [...current.timeline]..removeAt(i),
                    );
                  }),
                ),
              ],
            ),
          ),
        TextButton.icon(
          key: const Key('intake-add-timeline-button'),
          onPressed: () => notifier.editDraft(
            draft.draftId,
            (current) => current.copyWith(
              timeline: [...current.timeline, const DraftTimelineEvent()],
            ),
          ),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Añadir hito'),
        ),
      ],
    );
  }
}
