import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/cases_providers.dart';
import '../../domain/case_draft.dart';
import '../../domain/true_crime_case.dart';
import '../dossier/dossier_body.dart';
import '../dossier/dossier_body_footer.dart';
import '../dossier/dossier_facts.dart';
import '../dossier/dossier_hero.dart';
import '../dossier/dossier_map_band.dart';
import 'intake_preview_pending.dart';
import 'preview_source_groups.dart';

/// El expediente completo de la página pública, pintado con el borrador
/// [Spec: Expediente Preview Parity].
///
/// Los componentes eligen escritorio o móvil por el ancho de `MediaQuery`, que
/// aquí sería el de la ventana y no el del panel; por eso se sustituye por el
/// ancho disponible. No lleva scroll propio: vive dentro del scroll del panel.
class IntakePreviewDossier extends ConsumerWidget {
  const IntakePreviewDossier({
    super.key,
    required this.previewCase,
    required this.draft,
  });

  final TrueCrimeCase previewCase;
  final CaseDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = draftPending(draft);
    final crimeCase = _withDraftSources(previewCase, draft.links);
    final catalog = ref.watch(casesProvider).value ?? const <TrueCrimeCase>[];
    // Sin coordenadas el borrador no entra en el mapa: su (0, 0) sería un
    // marcador inventado en mitad del océano.
    final mapCases = [
      for (final other in catalog)
        if (other.id != crimeCase.id) other,
      if (!pending.coordinates) crimeCase,
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            size: Size(constraints.maxWidth, media.size.height),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DossierHero(crimeCase: crimeCase, pending: pending),
              Transform.translate(
                offset: const Offset(0, -DossierHero.factsOverlap),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: DossierFacts(
                    crimeCase: crimeCase,
                    connectionsCount: 0,
                    pending: pending,
                  ),
                ),
              ),
              DossierMapBand(
                key: ValueKey(
                  'preview-map-${crimeCase.id}-${pending.coordinates}',
                ),
                dossierCase: crimeCase,
                cases: mapCases,
                // Un borrador no tiene conexiones ni casos relacionados.
                connections: const [],
                onOpenCase: (_) {},
                // Desde un borrador no se navega a otros casos.
                canOpenCase: false,
                pending: pending,
              ),
              DossierBody(
                crimeCase: crimeCase,
                relatedCases: const [],
                onOpenRelatedCase: (_) {},
                pending: pending,
              ),
              const DossierFooter(),
            ],
          ),
        );
      },
    );
  }
}

/// Las fuentes citadas son los enlaces del borrador, en el orden de los
/// grupos de la vista previa y sin repetir ninguna URL.
TrueCrimeCase _withDraftSources(TrueCrimeCase base, List<DraftLink> links) {
  final seen = <String>{};
  final sources = [
    for (final group in previewSourceGroups(links))
      for (final source in group.sources)
        if (seen.add(source.url)) source,
  ];
  return TrueCrimeCase(
    id: base.id,
    slug: base.slug,
    title: base.title,
    category: base.category,
    country: base.country,
    countryCode: base.countryCode,
    regionOrCity: base.regionOrCity,
    year: base.year,
    latitude: base.latitude,
    longitude: base.longitude,
    summary: base.summary,
    tags: base.tags,
    sources: sources,
    status: base.status,
    statusLabel: base.statusLabel,
    victim: base.victim,
    timeline: base.timeline,
    photos: base.photos,
    chapters: base.chapters,
  );
}
