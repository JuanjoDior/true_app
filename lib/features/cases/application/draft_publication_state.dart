import 'case_exporter.dart';
import 'draft_validator.dart';
import '../domain/case_draft.dart';

/// Estado de publicación de un borrador: cuatro valores excluyentes que
/// combinan validación, marcador de entrega y catálogo cargado [diseño §6.4].
enum DraftPublicationState { incomplete, ready, handedOff, published }

/// Estado de publicación de un borrador, combinando su validación, el
/// marcador de entrega y el catálogo que esta pestaña cargó.
///
/// El slug efectivo es `draft.handoffSlug` si no es nulo — el que se le
/// asignó de verdad en el lote, que puede llevar sufijo — y si no, el
/// derivado del título. Un borrador anterior a este cambio decodifica con
/// ambos marcadores en `null` y se comporta exactamente como antes.
DraftPublicationState draftPublicationState(
  CaseDraft draft, {
  required Set<String> publishedSlugs,
}) {
  if (!validateDraft(draft).isValid) {
    return DraftPublicationState.incomplete;
  }

  final effectiveSlug = draft.handoffSlug ?? caseSlug(draft.title!.trim());

  if (publishedSlugs.contains(effectiveSlug)) {
    return DraftPublicationState.published;
  }

  if (draft.handoffSlug != null) {
    return DraftPublicationState.handedOff;
  }

  return DraftPublicationState.ready;
}
