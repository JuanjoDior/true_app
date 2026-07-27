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
  });

  final String? titleError;
  final String? categoryError;
  final String? yearError;
  final String? statusError;

  /// Un elemento por enlace del borrador; `null` si ese enlace es válido.
  final List<String?> linkErrors;

  bool get hasRequiredFieldErrors =>
      titleError != null ||
      categoryError != null ||
      yearError != null ||
      statusError != null;

  /// Válido para guardar/exportar: los enlaces mal formados NO bloquean.
  bool get isValid => !hasRequiredFieldErrors;

  bool get hasLinkWarnings => linkErrors.any((error) => error != null);
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
  final uri = Uri.tryParse(url.trim());
  final isValid = uri != null &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty;
  return isValid ? null : 'El enlace no parece una URL válida';
}
