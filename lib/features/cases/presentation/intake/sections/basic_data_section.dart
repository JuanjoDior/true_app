import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/case_draft_providers.dart';
import '../../../application/draft_validator.dart';
import '../../../domain/case_category.dart';
import '../../../domain/case_draft.dart';
import '../../../domain/case_status.dart';

/// Sección "Datos básicos": título, categoría, año y estado — los cuatro
/// campos obligatorios v1 [Spec: Field Validation].
class BasicDataSection extends ConsumerWidget {
  const BasicDataSection({super.key});

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
          key: const Key('intake-field-title'),
          initialValue: draft.title,
          decoration: InputDecoration(
            labelText: 'Título',
            errorText: validateTitle(draft.title),
          ),
          onChanged: (value) =>
              edit((current) => current.copyWith(title: value)),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<CaseCategory>(
          key: const Key('intake-field-category'),
          initialValue: draft.category,
          decoration: InputDecoration(
            labelText: 'Categoría',
            errorText: validateCategory(draft.category),
          ),
          items: [
            for (final category in CaseCategory.values)
              DropdownMenuItem(value: category, child: Text(category.label)),
          ],
          onChanged: (value) {
            if (value != null) {
              edit((current) => current.copyWith(category: value));
            }
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('intake-field-year'),
          initialValue: draft.year?.toString(),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Año',
            errorText: validateYear(draft.year),
          ),
          onChanged: (value) {
            final parsed = int.tryParse(value);
            if (parsed != null) {
              edit((current) => current.copyWith(year: parsed));
            }
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<CaseStatus>(
          key: const Key('intake-field-status'),
          initialValue: draft.status,
          decoration: InputDecoration(
            labelText: 'Estado',
            errorText: validateStatus(draft.status),
          ),
          items: [
            for (final status in CaseStatus.values)
              DropdownMenuItem(value: status, child: Text(status.label)),
          ],
          onChanged: (value) {
            if (value != null) {
              edit((current) => current.copyWith(status: value));
            }
          },
        ),
      ],
    );
  }
}
