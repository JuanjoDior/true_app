import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/draft_submission_service.dart';
import 'case_draft_providers.dart';
import 'intake_session_providers.dart';

/// Servicio de «Enviar a revisión». Sin reintento automático: lo dispara la UI.
final draftSubmissionServiceProvider = Provider<DraftSubmissionService>((ref) {
  return DraftSubmissionService(
    auth: ref.watch(intakeAuthProvider),
    client: ref.watch(caseDraftsHttpClientProvider),
  );
});
