import 'dart:math';

import '../application/draft_validator.dart';
import '../domain/case_draft.dart';

/// Estado del borrador en el servidor tras un envío aceptado.
enum DraftSubmissionStatus {
  draft,
  inReview,
  returned,
  published;

  static DraftSubmissionStatus? parse(Object? value) => switch (value) {
    'draft' => draft,
    'in_review' => inReview,
    'returned' => returned,
    'published' => published,
    _ => null,
  };
}

/// Confirmación del servidor de un envío.
class DraftSubmissionReceipt {
  const DraftSubmissionReceipt({
    required this.status,
    required this.submittedAt,
  });

  final DraftSubmissionStatus status;
  final DateTime submittedAt;
}

/// Una intención de envío a revisión: copia exacta del borrador en el momento
/// de pulsar «Enviar a revisión».
///
/// El servidor deduplica por [submissionId] y rechaza el mismo id con otro
/// contenido. Por eso la intención congela el contenido: todos los reintentos
/// mandan los mismos bytes aunque el borrador local siga cambiando. Una
/// intención nueva (por ejemplo, reenviar tras una devolución) usa otro id.
class DraftSubmission {
  DraftSubmission._({
    required this.draftId,
    required this.submissionId,
    required this.payload,
    required this.accountId,
  });

  /// Congela [draft] y genera el id de la intención.
  ///
  /// Lanza [SubmissionInvalidDraftException] si el borrador no pasa la
  /// validación; en ese caso no se genera ningún id.
  factory DraftSubmission.begin(
    CaseDraft draft, {
    required String accountId,
    String Function()? newSubmissionId,
  }) {
    if (!validateDraft(draft).isValid) {
      throw const SubmissionInvalidDraftException();
    }
    return DraftSubmission._(
      draftId: draft.draftId,
      submissionId: (newSubmissionId ?? _randomUuidV4)(),
      payload: _freeze(draft.toJson()) as Map<String, Object?>,
      accountId: accountId,
    );
  }

  final String draftId;
  final String submissionId;
  final Map<String, Object?> payload;

  /// Cuenta que creó la intención: sólo su sesión puede enviarla.
  final String accountId;
}

// Copia profunda e inmutable: así ni el borrador original ni quien reciba la
// intención pueden alterar lo que se reenvía.
Object? _freeze(Object? value) => switch (value) {
  Map() => Map<String, Object?>.unmodifiable({
    for (final entry in value.entries)
      entry.key as String: _freeze(entry.value),
  }),
  List() => List<Object?>.unmodifiable(value.map(_freeze)),
  _ => value,
};

String _randomUuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// Por qué falló un envío. Jerarquía sellada para que la interfaz pueda
/// hacer un `switch` exhaustivo. Ningún mensaje incluye el contenido del
/// borrador ni el token.
sealed class DraftSubmissionException implements Exception {
  const DraftSubmissionException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// El borrador no cumple los campos obligatorios: no se llegó a crear la
/// intención.
final class SubmissionInvalidDraftException extends DraftSubmissionException {
  const SubmissionInvalidDraftException()
    : super('El borrador tiene campos obligatorios sin completar.');
}

/// No hay sesión, ha caducado o es de otra cuenta. No hubo ningún efecto en
/// el servidor.
final class SubmissionSessionException extends DraftSubmissionException {
  const SubmissionSessionException()
    : super('No hay una sesión válida de la cuenta que creó el envío.');
}

/// El servidor no permite enviar este borrador a esta cuenta (definitivo).
final class SubmissionForbiddenException extends DraftSubmissionException {
  const SubmissionForbiddenException()
    : super('Esta cuenta no puede enviar este borrador.');
}

/// El servidor rechazó el contenido o el identificador (definitivo).
final class SubmissionRejectedException extends DraftSubmissionException {
  const SubmissionRejectedException({this.statusCode, this.code})
    : super('El servidor rechazó el envío.');

  final int? statusCode;
  final String? code;

  @override
  String toString() =>
      'SubmissionRejectedException: $message (HTTP $statusCode, código $code)';
}

/// Ya hay otro envío del borrador en revisión (definitivo).
final class SubmissionAlreadyInReviewException
    extends DraftSubmissionException {
  const SubmissionAlreadyInReviewException()
    : super('El borrador ya está en revisión.');
}

/// No se sabe si el servidor llegó a aceptar el envío (tiempo agotado, red
/// caída, error 5xx o respuesta ilegible). Ni es un éxito ni un fallo
/// definitivo: reintentar con [submission] (mismo id y contenido) es seguro.
final class SubmissionOutcomeUnknownException extends DraftSubmissionException {
  const SubmissionOutcomeUnknownException(this.submission)
    : super('No se pudo confirmar si el envío llegó al servidor.');

  final DraftSubmission submission;
}
