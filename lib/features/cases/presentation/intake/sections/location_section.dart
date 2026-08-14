import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../home/presentation/widgets/situation/situation_styles.dart';
import '../../../application/case_draft_providers.dart';
import '../../../application/draft_validator.dart';
import '../../../domain/case_draft.dart';
import '../../../domain/coordinates_label.dart';
import '../location_picker_map.dart';
import 'intake_field_row.dart';

/// Sección "Ubicación": se señala el punto en el mapa y el resto se rellena
/// solo.
///
/// Es obligatoria para publicar: sin coordenadas el caso no puede pintarse en
/// el mapa, que es el núcleo de navegación del producto [Spec: Location].
/// Los campos de texto son el resultado del punto marcado, no la entrada;
/// siguen siendo editables porque el geocodificador puede fallar o acertar a
/// medias.
class LocationSection extends ConsumerStatefulWidget {
  const LocationSection({super.key});

  @override
  ConsumerState<LocationSection> createState() => _LocationSectionState();
}

class _LocationSectionState extends ConsumerState<LocationSection> {
  /// Identifica la última búsqueda lanzada: si se marca otro punto antes de
  /// que llegue la respuesta anterior, la vieja se descarta.
  int _lookup = 0;
  bool _resolving = false;

  /// Fuerza a reconstruir los campos de texto cuando el geocodificador los
  /// rellena. `TextFormField` ignora los cambios de `initialValue`, así que
  /// hace falta cambiar su clave para que recojan el valor nuevo.
  int _placeRevision = 0;

  Future<void> _selectPoint(String draftId, LatLng point) async {
    final notifier = ref.read(caseDraftsProvider.notifier);
    await notifier.editDraft(
      draftId,
      (current) => current.copyWith(
        latitude: point.latitude,
        longitude: point.longitude,
      ),
    );

    final lookup = ++_lookup;
    setState(() => _resolving = true);

    final place = await ref
        .read(reverseGeocoderProvider)
        .resolve(point.latitude, point.longitude);

    // Otro punto marcado mientras tanto, o la sección ya no está en pantalla.
    if (!mounted || lookup != _lookup) {
      return;
    }
    setState(() => _resolving = false);

    if (place == null) {
      // El nombre del lugar se escribe a mano; las coordenadas ya están.
      return;
    }

    await notifier.editDraft(
      draftId,
      (current) => current.withResolvedPlace(place),
    );
    if (mounted) {
      setState(() => _placeRevision++);
    }
  }

  @override
  Widget build(BuildContext context) {
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

    final latitude = draft.latitude;
    final longitude = draft.longitude;
    final point = latitude != null && longitude != null
        ? LatLng(latitude, longitude)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocationPickerMap(
          point: point,
          onPointSelected: (selected) => _selectPoint(draft.draftId, selected),
        ),
        const SizedBox(height: 10),
        _CoordinatesLine(
          latitude: latitude,
          longitude: longitude,
          resolving: _resolving,
        ),
        const SizedBox(height: 14),
        TextFormField(
          key: Key('intake-field-country-$_placeRevision'),
          initialValue: draft.country,
          decoration: InputDecoration(
            labelText: 'País',
            errorText: validateCountry(draft.country),
          ),
          onChanged: (value) =>
              edit((current) => current.copyWith(country: value)),
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: Key('intake-field-region-or-city-$_placeRevision'),
          initialValue: draft.regionOrCity,
          decoration: InputDecoration(
            labelText: 'Región o ciudad',
            errorText: validateRegionOrCity(draft.regionOrCity),
          ),
          onChanged: (value) =>
              edit((current) => current.copyWith(regionOrCity: value)),
        ),
        const SizedBox(height: 14),
        _FineTuning(draft: draft, placeRevision: _placeRevision, onEdit: edit),
      ],
    );
  }
}

/// Coordenadas del punto marcado, en el formato editorial del archivo.
class _CoordinatesLine extends StatelessWidget {
  const _CoordinatesLine({
    required this.latitude,
    required this.longitude,
    required this.resolving,
  });

  final double? latitude;
  final double? longitude;
  final bool resolving;

  String get _label {
    if (latitude == null || longitude == null) {
      return 'Sin punto marcado';
    }
    return formatCoordinates(latitude!, longitude!);
  }

  @override
  Widget build(BuildContext context) {
    final hasPoint = latitude != null && longitude != null;

    return Wrap(
      spacing: 12,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          _label,
          key: const Key('intake-coordinates-label'),
          style: SituationStyles.mono(
            size: 11,
            weight: FontWeight.w600,
            color: hasPoint ? AppColors.gold : AppColors.textFaint,
          ),
        ),
        if (resolving)
          // Agrupados en una sola fila para que el spinner y el texto nunca
          // se separen entre líneas del `Wrap`.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 11,
                height: 11,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
              const SizedBox(width: 7),
              Text(
                'Buscando el lugar…',
                key: const Key('intake-geocoding-status'),
                style: SituationStyles.sans(size: 11, color: AppColors.textSub),
              ),
            ],
          ),
      ],
    );
  }
}

/// Campos que el punto del mapa ya rellena y que casi nunca hay que tocar:
/// quedan a mano por si el geocodificador falla o hay que afinar.
class _FineTuning extends StatelessWidget {
  const _FineTuning({
    required this.draft,
    required this.placeRevision,
    required this.onEdit,
  });

  final CaseDraft draft;
  final int placeRevision;
  final void Function(CaseDraft Function(CaseDraft current)) onEdit;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      key: const Key('intake-location-fine-tuning'),
      title: Text(
        'Ajuste manual',
        style: SituationStyles.sans(size: 12, color: AppColors.textSub),
      ),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      children: [
        IntakeFieldRow(
          fields: [
            IntakeFieldSlot.flexible(
              TextFormField(
                key: Key('intake-field-country-code-$placeRevision'),
                initialValue: draft.countryCode,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Código ISO',
                  hintText: 'ES',
                  errorText: validateCountryCode(draft.countryCode),
                ),
                onChanged: (value) =>
                    onEdit((current) => current.copyWith(countryCode: value)),
              ),
            ),
            IntakeFieldSlot.flexible(
              TextFormField(
                key: Key('intake-field-latitude-$placeRevision'),
                initialValue: draft.latitude?.toString(),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Latitud',
                  errorText: validateLatitude(draft.latitude),
                ),
                onChanged: (value) {
                  // Texto a medio escribir ("-", "40.") no debe corromper el
                  // borrador: se ignora hasta que sea un número.
                  final parsed = double.tryParse(value.trim());
                  if (parsed != null) {
                    onEdit((current) => current.copyWith(latitude: parsed));
                  }
                },
              ),
            ),
            IntakeFieldSlot.flexible(
              TextFormField(
                key: Key('intake-field-longitude-$placeRevision'),
                initialValue: draft.longitude?.toString(),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Longitud',
                  errorText: validateLongitude(draft.longitude),
                ),
                onChanged: (value) {
                  final parsed = double.tryParse(value.trim());
                  if (parsed != null) {
                    onEdit((current) => current.copyWith(longitude: parsed));
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
