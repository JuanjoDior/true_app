import '../../domain/case_draft.dart';
import '../dossier/dossier_facts_pending.dart';

/// Qué datos del borrador faltan, para que el expediente los diga «pendiente»
/// en lugar de enseñar los valores de relleno del caso de previsualización
/// («Por confirmar», año 0, coordenadas 0,0).
DossierPending draftPending(CaseDraft draft) {
  bool blank(String? value) => value == null || value.trim().isEmpty;
  return DossierPending(
    year: draft.year == null,
    category: draft.category == null,
    status: draft.status == null,
    region: blank(draft.regionOrCity),
    country: blank(draft.country),
    coordinates: draft.latitude == null || draft.longitude == null,
    summary: blank(draft.summary),
    victims: blank(draft.victim),
  );
}
