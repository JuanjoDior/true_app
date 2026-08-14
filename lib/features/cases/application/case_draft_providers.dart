import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;

import '../data/case_drafts_store.dart';
import '../data/reverse_geocoder.dart';
import '../domain/case_category.dart';
import '../domain/case_draft.dart';
import '../domain/case_photo.dart';
import '../domain/case_source.dart';
import '../domain/case_status.dart';
import '../domain/case_timeline_event.dart';
import '../domain/true_crime_case.dart';

/// Store de borradores, sobreescribible en tests (mismo patrón que
/// `casesRepositoryProvider`).
final caseDraftsStoreProvider = Provider<CaseDraftsStore>((ref) {
  return SharedPreferencesCaseDraftsStore();
});

/// Traductor de coordenadas a lugar, sobreescribible en tests para no salir
/// a la red (mismo patrón que `caseDraftsStoreProvider`).
final reverseGeocoderProvider = Provider<ReverseGeocoder>((ref) {
  return const NominatimReverseGeocoder();
});

/// CRUD de borradores de Iván: crear, editar (autosave), reanudar y borrar.
class CaseDraftsNotifier extends AsyncNotifier<List<CaseDraft>> {
  @override
  FutureOr<List<CaseDraft>> build() async {
    final store = ref.watch(caseDraftsStoreProvider);
    return store.loadDrafts();
  }

  CaseDraftsStore get _store => ref.read(caseDraftsStoreProvider);

  /// Última escritura encolada. Cada guardado nuevo se encadena detrás.
  Future<void> _writes = Future<void>.value();

  /// Encola [snapshot] detrás de lo que ya estuviera pendiente.
  ///
  /// El estado se publica de forma síncrona, pero el disco no. Sin cola, dos
  /// mutaciones seguidas salen a la vez y la que tarde más aterriza la última,
  /// dejando escrita la instantánea VIEJA: una edición que se pierde, o un
  /// borrado al que le resucita el borrador. Encadenándolas, el orden en que
  /// aterrizan es el orden en que se pidieron [diseño D4].
  ///
  /// El fallo se propaga a quien llamó, pero no envenena la cola: `_writes`
  /// guarda la versión neutralizada para que la siguiente mutación siga
  /// pudiendo escribir.
  Future<void> _persist(List<CaseDraft> snapshot) {
    final write = _writes.then((_) => _store.saveDrafts(snapshot));
    _writes = write.catchError((Object _) {});
    return write;
  }

  /// Crea un borrador vacío y lo persiste de inmediato.
  Future<String> createDraft() async {
    final drafts = state.value ?? const <CaseDraft>[];
    final draftId = 'draft-${DateTime.now().millisecondsSinceEpoch}';
    final updated = [...drafts, CaseDraft(draftId: draftId)];
    state = AsyncData(updated);
    await _persist(updated);
    return draftId;
  }

  /// Reemplaza un borrador existente y autoguarda el cambio.
  Future<void> updateDraft(CaseDraft draft) async {
    final drafts = state.value ?? const <CaseDraft>[];
    final updated = [
      for (final existing in drafts)
        if (existing.draftId == draft.draftId) draft else existing,
    ];
    state = AsyncData(updated);
    await _persist(updated);
  }

  /// Aplica un cambio sobre el borrador **tal y como está ahora**, en vez de
  /// sobre una copia capturada antes.
  ///
  /// El formulario lee el borrador en su `build`, así que dos campos editados
  /// antes de que Flutter reconstruya parten del mismo borrador viejo. Con
  /// `updateDraft` el segundo pisaba lo escrito por el primero y la pérdida
  /// era silenciosa; recibiendo la transformación, cada edición se aplica
  /// sobre el estado vigente.
  Future<void> editDraft(
    String draftId,
    CaseDraft Function(CaseDraft current) update,
  ) async {
    final drafts = state.value ?? const <CaseDraft>[];
    if (!drafts.any((draft) => draft.draftId == draftId)) {
      return;
    }
    final updated = [
      for (final existing in drafts)
        if (existing.draftId == draftId) update(existing) else existing,
    ];
    state = AsyncData(updated);
    await _persist(updated);
  }

  /// Elimina un borrador y lo quita del almacenamiento local.
  Future<void> deleteDraft(String draftId) async {
    final drafts = state.value ?? const <CaseDraft>[];
    final updated = drafts
        .where((draft) => draft.draftId != draftId)
        .toList(growable: false);
    state = AsyncData(updated);
    await _persist(updated);
  }
}

final caseDraftsProvider =
    AsyncNotifierProvider<CaseDraftsNotifier, List<CaseDraft>>(
      CaseDraftsNotifier.new,
    );

/// Borrador que se está editando en el workspace de intake (null = ninguno).
final editingDraftIdProvider = StateProvider<String?>((ref) => null);

/// Narrow-workspace affordance: whether the draft-list overlay is open
/// (Diseño D3, `intake-responsive`).
final intakeDraftListOpenProvider = StateProvider<bool>((ref) => false);

/// Narrow-workspace affordance: whether the preview sheet is open
/// (Diseño D3, `intake-responsive`).
final intakePreviewOpenProvider = StateProvider<bool>((ref) => false);

/// Borrador actualmente en edición, resuelto a partir de
/// [editingDraftIdProvider] (mismo patrón que `selectedCaseProvider`).
final editingDraftProvider = Provider<CaseDraft?>((ref) {
  final draftId = ref.watch(editingDraftIdProvider);
  if (draftId == null) {
    return null;
  }
  final drafts = ref.watch(caseDraftsProvider).value ?? const <CaseDraft>[];
  for (final draft in drafts) {
    if (draft.draftId == draftId) {
      return draft;
    }
  }
  return null;
});

/// Convierte el borrador en edición en un `TrueCrimeCase` de solo
/// previsualización, para reutilizar `CaseDossierPanel` sin tocar el catálogo
/// publicado (diseño #5). Los campos aún sin rellenar usan placeholders.
final draftPreviewCaseProvider = Provider<TrueCrimeCase?>((ref) {
  final draft = ref.watch(editingDraftProvider);
  if (draft == null) {
    return null;
  }

  return TrueCrimeCase(
    id: draft.draftId,
    slug: draft.draftId,
    title: draft.title ?? 'Sin título',
    category: draft.category ?? CaseCategory.unsolved,
    country: draft.country?.trim().isNotEmpty ?? false
        ? draft.country!.trim()
        : 'Por confirmar',
    countryCode: draft.countryCode?.trim().isNotEmpty ?? false
        ? draft.countryCode!.trim().toUpperCase()
        : '--',
    regionOrCity: draft.regionOrCity?.trim().isNotEmpty ?? false
        ? draft.regionOrCity!.trim()
        : 'Por confirmar',
    year: draft.year ?? 0,
    latitude: draft.latitude ?? 0,
    longitude: draft.longitude ?? 0,
    summary: draft.summary ?? '',
    // A diferencia del resto de campos, los capítulos NO llevan placeholder: un
    // capítulo vacío se omite en vez de inventarle texto. El filtrado por
    // contenido significativo ya lo hace `CaseChapters`.
    chapters: draft.chapters,
    tags: draft.tags,
    victim: draft.victim?.trim().isNotEmpty ?? false
        ? draft.victim!.trim()
        : null,
    // Sólo se previsualizan los hitos que ya dicen algo.
    timeline: [
      for (final event in draft.timeline)
        if ((event.title?.trim().isNotEmpty ?? false) ||
            (event.date?.trim().isNotEmpty ?? false))
          CaseTimelineEvent(
            title: event.title?.trim() ?? '',
            date: event.date?.trim() ?? '',
            kind: event.kind ?? CaseTimelineKind.process,
          ),
    ],
    sources: [
      for (final link in draft.links)
        if (link.url != null && link.url!.trim().isNotEmpty)
          CaseSource(
            id: link.url!,
            title: link.title?.isNotEmpty == true ? link.title! : link.url!,
            url: link.url!,
            kind: link.kind == DraftLinkKind.podcast
                ? CaseSourceKind.podcast
                : CaseSourceKind.investigation,
          ),
    ],
    status: draft.status ?? CaseStatus.open,
    // Sólo se previsualizan las fotos que ya tienen URL; el resto todavía no
    // se puede pintar.
    photos: [
      for (final photo in draft.photos)
        if (photo.url?.trim().isNotEmpty ?? false)
          CasePhoto(
            url: photo.url!.trim(),
            caption: photo.caption?.trim().isNotEmpty ?? false
                ? photo.caption!.trim()
                : null,
          ),
    ],
  );
});
