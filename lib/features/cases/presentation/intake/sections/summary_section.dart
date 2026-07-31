import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/case_draft_providers.dart';

/// Sección "Resumen": texto largo del caso, opcional en v1.
class SummarySection extends ConsumerWidget {
  const SummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(editingDraftProvider);
    if (draft == null) {
      return const SizedBox.shrink();
    }
    final notifier = ref.read(caseDraftsProvider.notifier);

    return TextFormField(
      key: const Key('intake-field-summary'),
      initialValue: draft.summary,
      maxLines: 6,
      decoration: const InputDecoration(labelText: 'Resumen del caso'),
      // Se edita sobre el borrador vigente, no sobre el capturado en este
      // `build`: escribir en dos campos seguidos no debe perder el primero.
      onChanged: (value) => notifier.editDraft(
        draft.draftId,
        (current) => current.copyWith(summary: value),
      ),
    );
  }
}
