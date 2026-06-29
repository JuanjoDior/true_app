/// Relación bidireccional entre dos casos del archivo.
///
/// Modela la capa de "casos relacionados" de la Sala de Situación: una arista
/// con una etiqueta que explica el vínculo (geografía, época, patrón…).
class CaseConnection {
  const CaseConnection({
    required this.aId,
    required this.bId,
    required this.relation,
  });

  final String aId;
  final String bId;
  final String relation;

  /// Devuelve el id del caso del otro extremo si [caseId] participa en la
  /// conexión; en caso contrario, `null`.
  String? otherId(String caseId) {
    if (caseId == aId) return bId;
    if (caseId == bId) return aId;
    return null;
  }
}
