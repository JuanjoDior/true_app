import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/case_draft_providers.dart';
import '../../../application/draft_validator.dart';
import '../../../domain/case_draft.dart';

/// Sección "Ubicación": país, código ISO, región o ciudad y coordenadas.
///
/// Es obligatoria para publicar. Sin coordenadas el caso no puede pintarse en
/// el mapa, que es el núcleo de navegación del producto [Spec: Location].
class LocationSection extends ConsumerWidget {
  const LocationSection({super.key});

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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                key: const Key('intake-field-country'),
                initialValue: draft.country,
                decoration: InputDecoration(
                  labelText: 'País',
                  errorText: validateCountry(draft.country),
                ),
                onChanged: (value) =>
                    edit((current) => current.copyWith(country: value)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                key: const Key('intake-field-country-code'),
                initialValue: draft.countryCode,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Código ISO',
                  hintText: 'ES',
                  errorText: validateCountryCode(draft.countryCode),
                ),
                onChanged: (value) =>
                    edit((current) => current.copyWith(countryCode: value)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('intake-field-region-or-city'),
          initialValue: draft.regionOrCity,
          decoration: InputDecoration(
            labelText: 'Región o ciudad',
            errorText: validateRegionOrCity(draft.regionOrCity),
          ),
          onChanged: (value) =>
              edit((current) => current.copyWith(regionOrCity: value)),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                key: const Key('intake-field-latitude'),
                initialValue: draft.latitude?.toString(),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Latitud',
                  hintText: '40.07',
                  errorText: validateLatitude(draft.latitude),
                ),
                onChanged: (value) {
                  // Texto a medio escribir ("-", "40.") no debe corromper el
                  // borrador: se ignora hasta que sea un número.
                  final parsed = double.tryParse(value.trim());
                  if (parsed != null) {
                    edit((current) => current.copyWith(latitude: parsed));
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                key: const Key('intake-field-longitude'),
                initialValue: draft.longitude?.toString(),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Longitud',
                  hintText: '-2.13',
                  errorText: validateLongitude(draft.longitude),
                ),
                onChanged: (value) {
                  final parsed = double.tryParse(value.trim());
                  if (parsed != null) {
                    edit((current) => current.copyWith(longitude: parsed));
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
