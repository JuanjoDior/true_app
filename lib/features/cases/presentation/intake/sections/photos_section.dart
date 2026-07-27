import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/case_draft_providers.dart';
import '../../../application/draft_validator.dart';
import '../../../domain/case_draft.dart';

/// Sección "Fotografías": imágenes ya alojadas, referenciadas por URL. v1 no
/// sube archivos (política "sin backend, sin CMS") [Diseño #14]. Las URLs mal
/// formadas se marcan pero no bloquean el guardado.
class PhotosSection extends ConsumerWidget {
  const PhotosSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(editingDraftProvider);
    if (draft == null) {
      return const SizedBox.shrink();
    }
    final notifier = ref.read(caseDraftsProvider.notifier);

    void replacePhoto(int index, DraftPhoto Function(DraftPhoto current) update) {
      final photos = [...draft.photos];
      photos[index] = update(photos[index]);
      notifier.updateDraft(draft.copyWith(photos: photos));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < draft.photos.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    key: Key('intake-field-photo-url-$i'),
                    initialValue: draft.photos[i].url,
                    decoration: InputDecoration(
                      labelText: 'URL de la imagen',
                      errorText: validatePhotoUrl(draft.photos[i].url),
                    ),
                    onChanged: (value) => replacePhoto(
                      i,
                      (photo) =>
                          DraftPhoto(url: value, caption: photo.caption),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    key: Key('intake-field-photo-caption-$i'),
                    initialValue: draft.photos[i].caption,
                    decoration: const InputDecoration(
                      labelText: 'Pie de foto (opcional)',
                    ),
                    onChanged: (value) => replacePhoto(
                      i,
                      (photo) => DraftPhoto(url: photo.url, caption: value),
                    ),
                  ),
                ),
                IconButton(
                  key: Key('intake-field-photo-remove-$i'),
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () {
                    final photos = [...draft.photos]..removeAt(i);
                    notifier.updateDraft(draft.copyWith(photos: photos));
                  },
                ),
              ],
            ),
          ),
        TextButton.icon(
          key: const Key('intake-add-photo-button'),
          onPressed: () {
            final photos = [...draft.photos, const DraftPhoto()];
            notifier.updateDraft(draft.copyWith(photos: photos));
          },
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Añadir fotografía'),
        ),
      ],
    );
  }
}
