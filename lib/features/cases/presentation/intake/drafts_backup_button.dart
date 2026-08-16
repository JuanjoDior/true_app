import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/case_draft_providers.dart';
import '../../application/drafts_backup.dart';
import '../../data/drafts_file_transfer.dart';
import '../../domain/case_draft.dart';

/// Copia de seguridad de TODOS los borradores, en las dos direcciones.
///
/// **Existe porque los borradores viven en el navegador y ahí no los protege
/// nadie.** Limpiar datos de navegación, cambiar de equipo o reinstalar Chrome
/// se lleva por delante meses de investigación. El botón de exportar caso no
/// cubre este hueco: sólo se habilita con el caso TERMINADO, y el trabajo largo
/// vive precisamente en borradores a medias.
///
/// A diferencia de aquél, éste **siempre está disponible**: guardar la copia no
/// puede depender de haber acabado nada.
class DraftsBackupButton extends ConsumerWidget {
  const DraftsBackupButton({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drafts = ref.watch(caseDraftsProvider).value ?? const <CaseDraft>[];

    Future<void> copyBackup() async {
      final messenger = ScaffoldMessenger.of(context);
      await Clipboard.setData(ClipboardData(text: encodeDraftsBackup(drafts)));
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            drafts.length == 1
                ? 'Copia de 1 borrador en el portapapeles. Pégala en un fichero '
                      'y guárdalo.'
                : 'Copia de ${drafts.length} borradores en el portapapeles. '
                      'Pégala en un fichero y guárdalo.',
          ),
        ),
      );
    }

    /// Mete en el workspace el texto de una copia, venga de un fichero o del
    /// portapapeles. Un único camino: si la lectura falla, falla igual en los
    /// dos sitios y dice lo mismo.
    Future<void> applyBackupText(String text) async {
      final messenger = ScaffoldMessenger.of(context);
      final result = decodeDraftsBackup(text);
      final error = result.error;
      if (error != null) {
        messenger.showSnackBar(SnackBar(content: Text(error)));
        return;
      }

      await ref.read(caseDraftsProvider.notifier).importDrafts(result.drafts);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Cargados ${result.drafts.length} casos. Los que ya tenías siguen '
            'aquí.',
          ),
        ),
      );
    }

    Future<void> saveToFile() async {
      final messenger = ScaffoldMessenger.of(context);
      final saved = await ref
          .read(draftsFileTransferProvider)
          .save(
            fileName: draftsBackupFileName(DateTime.now()),
            contents: encodeDraftsBackup(drafts),
          );
      if (!saved) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Trabajo guardado. Ya puedes enviar ese fichero.'),
        ),
      );
    }

    Future<void> loadFromFile() async {
      final text = await ref.read(draftsFileTransferProvider).pickText();
      if (text != null) {
        await applyBackupText(text);
      }
    }

    Future<void> restoreFromText() async {
      final pasted = await showDialog<String>(
        context: context,
        builder: (_) => const _RestoreDialog(),
      );
      if (pasted != null) {
        await applyBackupText(pasted);
      }
    }

    return MenuAnchor(
      builder: (context, controller, _) {
        void toggle() =>
            controller.isOpen ? controller.close() : controller.open();
        return compact
            ? IconButton(
                key: const Key('drafts-backup-button'),
                tooltip: 'Copia de seguridad',
                icon: const Icon(Icons.save_outlined, size: 18),
                onPressed: toggle,
              )
            : TextButton.icon(
                key: const Key('drafts-backup-button'),
                onPressed: toggle,
                icon: const Icon(Icons.save_outlined, size: 16),
                label: const Text('Copia de seguridad'),
              );
      },
      menuChildren: [
        // Los ficheros van primero y con el nombre más llano posible: son el
        // camino para quien sólo abre una URL y no sabe qué es un portapapeles
        // ni un JSON.
        MenuItemButton(
          key: const Key('drafts-backup-save-file'),
          leadingIcon: const Icon(Icons.download, size: 16),
          onPressed: saveToFile,
          child: const Text('Guardar mi trabajo en un fichero'),
        ),
        MenuItemButton(
          key: const Key('drafts-backup-load-file'),
          leadingIcon: const Icon(Icons.upload_file, size: 16),
          onPressed: loadFromFile,
          child: const Text('Cargar trabajo desde un fichero'),
        ),
        const Divider(height: 1),
        MenuItemButton(
          key: const Key('drafts-backup-copy'),
          leadingIcon: const Icon(Icons.copy_all, size: 16),
          onPressed: copyBackup,
          child: const Text('Copiar como texto'),
        ),
        MenuItemButton(
          key: const Key('drafts-backup-restore'),
          leadingIcon: const Icon(Icons.content_paste, size: 16),
          onPressed: restoreFromText,
          child: const Text('Pegar un texto copiado'),
        ),
      ],
    );
  }
}

/// Pide el texto de la copia y lo devuelve, o `null` si se cancela.
class _RestoreDialog extends StatefulWidget {
  const _RestoreDialog();

  @override
  State<_RestoreDialog> createState() => _RestoreDialogState();
}

class _RestoreDialogState extends State<_RestoreDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('drafts-restore-dialog'),
      title: const Text('Restaurar borradores'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pega aquí el texto de una copia. Lo que ya tengas en este equipo '
              'se conserva; sólo se sustituyen los borradores que coincidan.',
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('drafts-restore-field'),
              controller: _controller,
              minLines: 4,
              maxLines: 10,
              decoration: const InputDecoration(
                hintText: '{"schemaVersion": 1, "drafts": [...]}',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('drafts-restore-confirm'),
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Restaurar'),
        ),
      ],
    );
  }
}
