import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/case_draft_providers.dart';
import '../../application/case_exporter.dart';
import '../../application/draft_validator.dart';

/// Copia el borrador en edición al portapapeles con el esquema del catálogo.
///
/// El paso final del flujo es manual y a propósito: no hay backend ni CMS, así
/// que Iván copia el JSON y se pega en `assets/data/cases.json` al publicar
/// [Diseño #7]. Sólo se habilita cuando el borrador está completo, porque un
/// caso sin ubicación no puede entrar en el catálogo.
class ExportCaseButton extends ConsumerWidget {
  const ExportCaseButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(editingDraftProvider);
    if (draft == null) {
      return const SizedBox.shrink();
    }

    final isPublishable = validateDraft(draft).isValid;

    return Tooltip(
      message: isPublishable
          ? 'Copia el caso en formato JSON'
          : 'Completa los campos obligatorios para poder exportar',
      child: TextButton.icon(
        key: const Key('intake-export-button'),
        onPressed: isPublishable
            ? () async {
                final messenger = ScaffoldMessenger.of(context);
                await Clipboard.setData(
                  ClipboardData(text: encodeDraftAsCaseJson(draft)),
                );
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('JSON copiado. Pégalo en assets/data/cases.json'),
                  ),
                );
              }
            : null,
        icon: const Icon(Icons.copy_all, size: 16),
        label: const Text('Copiar JSON'),
      ),
    );
  }
}
