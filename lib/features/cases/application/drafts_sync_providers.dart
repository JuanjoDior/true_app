import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/supabase_case_drafts_store.dart';
import 'case_draft_providers.dart';

/// Estado cloud del store, o `null` cuando el formulario usa sólo un doble
/// local (por ejemplo, en los tests).
final draftsSyncStatusProvider = StreamProvider<DraftsSyncStatus?>((ref) {
  final store = ref.watch(caseDraftsStoreProvider);
  if (store is! SupabaseCaseDraftsStore) return Stream.value(null);
  return store.statusChanges.map<DraftsSyncStatus?>((status) => status);
});

/// Texto breve para quien escribe el borrador, sin detalles técnicos.
String draftsSyncStatusText(DraftsSyncStatus status) => switch (status) {
  DraftsSyncStatus.saved => 'Guardado en la nube',
  DraftsSyncStatus.saving => 'Guardando…',
  DraftsSyncStatus.offline ||
  DraftsSyncStatus.retrying => 'Sin conexión: guardado en este navegador',
  DraftsSyncStatus.conflict => 'Hay cambios que no se pudieron subir',
};
