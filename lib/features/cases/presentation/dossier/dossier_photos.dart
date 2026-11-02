import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../domain/case_photo.dart';

class DossierPhotos extends StatelessWidget {
  const DossierPhotos({super.key, required this.photos});

  final List<CasePhoto> photos;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) return const SizedBox.shrink();
    return Column(
      key: const Key('case-photos'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(header: true, child: const DsMonoLabel('Fotografías')),
        const SizedBox(height: DsSpacing.s18),
        for (var i = 0; i < photos.length; i++) ...[
          if (i > 0) const SizedBox(height: DsSpacing.s24),
          Column(
            key: ValueKey('case-photo-$i'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: DsRadii.cardBorder,
                child: Image.network(
                  photos[i].url,
                  width: double.infinity,
                  height: 240,
                  fit: BoxFit.cover,
                  semanticLabel: photos[i].caption ?? 'Fotografía del caso',
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 160,
                    color: DsColors.surfaceCard,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined, color: DsColors.textMuted),
                  ),
                ),
              ),
              if (photos[i].caption != null && photos[i].caption!.trim().isNotEmpty) ...[
                const SizedBox(height: DsSpacing.s8),
                Text(photos[i].caption!, style: DsTextStyles.desktop.body.copyWith(color: DsColors.textMuted)),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
