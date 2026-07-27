import '../domain/case_category.dart';
import '../domain/case_draft.dart';
import '../domain/case_status.dart';

/// Resultado de validar un borrador: errores de campos obligatorios más
/// avisos de enlaces mal formados (no bloqueantes) [Spec: Field Validation].
class DraftValidationResult {
  const DraftValidationResult({
    required this.titleError,
    required this.categoryError,
    required this.yearError,
    required this.statusError,
    required this.linkErrors,
    required this.photoErrors,
  });

  final String? titleError;
  final String? categoryError;
  final String? yearError;
  final String? statusError;

  /// Un elemento por enlace del borrador; `null` si ese enlace es válido.
  final List<String?> linkErrors;

  /// Un elemento por foto del borrador; `null` si esa URL es válida.
  final List<String?> photoErrors;

  bool get hasRequiredFieldErrors =>
      titleError != null ||
      categoryError != null ||
      yearError != null ||
      statusError != null;

  /// Válido para guardar/exportar: los enlaces y fotos mal formados NO
  /// bloquean, sólo se avisan.
  bool get isValid => !hasRequiredFieldErrors;

  bool get hasLinkWarnings => linkErrors.any((error) => error != null);

  bool get hasPhotoWarnings => photoErrors.any((error) => error != null);
}

DraftValidationResult validateDraft(CaseDraft draft) {
  return DraftValidationResult(
    titleError: validateTitle(draft.title),
    categoryError: validateCategory(draft.category),
    yearError: validateYear(draft.year),
    statusError: validateStatus(draft.status),
    linkErrors: draft.links
        .map((link) => validateLinkUrl(link.url))
        .toList(growable: false),
    photoErrors: draft.photos
        .map((photo) => validatePhotoUrl(photo.url))
        .toList(growable: false),
  );
}

String? validateTitle(String? title) {
  if (title == null || title.trim().isEmpty) {
    return 'El título es obligatorio';
  }
  return null;
}

String? validateCategory(CaseCategory? category) {
  if (category == null) {
    return 'La categoría es obligatoria';
  }
  return null;
}

String? validateYear(int? year) {
  if (year == null) {
    return 'El año es obligatorio';
  }
  return null;
}

String? validateStatus(CaseStatus? status) {
  if (status == null) {
    return 'El estado es obligatorio';
  }
  return null;
}

/// Valida el formato de una URL de enlace. Un enlace vacío no se considera
/// mal formado (el campo del enlace en sí es opcional).
String? validateLinkUrl(String? url) {
  if (url == null || url.trim().isEmpty) {
    return null;
  }
  return _isWellFormedUrl(url) ? null : 'El enlace no parece una URL válida';
}

/// Valida el formato de la URL de una foto. Mismo criterio que los enlaces:
/// una URL vacía no se considera mal formada y nunca bloquea el guardado.
String? validatePhotoUrl(String? url) {
  if (url == null || url.trim().isEmpty) {
    return null;
  }
  return _isWellFormedUrl(url) ? null : 'La foto no parece una URL válida';
}

bool _isWellFormedUrl(String url) {
  final uri = Uri.tryParse(url.trim());
  return uri != null &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty;
}
