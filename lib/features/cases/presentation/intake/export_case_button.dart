import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/case_draft_providers.dart';
import '../../application/case_exporter.dart';
import '../../application/cases_providers.dart';
import '../../application/draft_validator.dart';
import '../../domain/case_draft.dart';
import '../../domain/true_crime_case.dart';

/// Copia el borrador en edición al portapapeles con el esquema del catálogo.
///
/// El paso final del flujo es manual y a propósito: no hay backend ni CMS, así
/// que Iván copia el JSON y se pega en `assets/data/cases.json` al publicar
/// [Diseño #7]. Sólo se habilita cuando el borrador está completo, porque un
/// caso sin ubicación no puede entrar en el catálogo.
class ExportCaseButton extends ConsumerWidget {
  const ExportCaseButton({super.key, this.compact = false});

  /// A partir del workspace estrecho, el botón se reduce a un icono en la
  /// barra superior compacta [Diseño D7]. Misma `Key`, mismo `Tooltip`,
  /// mismas condiciones de habilitado y la misma acción de portapapeles: no
  /// se duplica lógica de exportación, sólo la presentación.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(editingDraftProvider);
    if (draft == null) {
      return const SizedBox.shrink();
    }

    final isPublishable = validateDraft(draft).isValid;

    // Identidades ya ocupadas: las de los casos publicados y las que
    // producirían los demás borradores. Sin esto, dos títulos que se
    // escriben casi igual exportarían el mismo `id` [Diseño #4].
    final published = ref.watch(casesProvider).value ?? const <TrueCrimeCase>[];
    final drafts = ref.watch(caseDraftsProvider).value ?? const <CaseDraft>[];
    final takenSlugs = <String>{
      for (final crimeCase in published) crimeCase.slug,
      for (final other in drafts)
        if (other.draftId != draft.draftId &&
            (other.title?.trim().isNotEmpty ?? false))
          caseSlug(other.title!.trim()),
    };

    Future<void> copyToClipboard() async {
      final messenger = ScaffoldMessenger.of(context);
      await Clipboard.setData(
        ClipboardData(
          text: encodeDraftAsCaseJson(draft, takenSlugs: takenSlugs),
        ),
      );
      messenger.showSnackBar(
        const SnackBar(
          content: Text('JSON copiado. Pégalo en assets/data/cases.json'),
        ),
      );
    }

    return Tooltip(
      message: isPublishable
          ? 'Copia el caso en formato JSON'
          : 'Completa los campos obligatorios para poder exportar',
      child: compact
          ? IconButton(
              key: const Key('intake-export-button'),
              onPressed: isPublishable ? copyToClipboard : null,
              icon: const Icon(Icons.copy_all, size: 18),
            )
          : TextButton.icon(
              key: const Key('intake-export-button'),
              onPressed: isPublishable ? copyToClipboard : null,
              icon: const Icon(Icons.copy_all, size: 16),
              label: const Text('Copiar JSON'),
            ),
    );
  }
}
