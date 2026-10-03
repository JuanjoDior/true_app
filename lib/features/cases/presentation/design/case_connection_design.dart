import '../../../../core/design/design.dart';
import '../../domain/case_connection.dart';

extension CaseConnectionDesign on CaseConnection {
  DsMapConnection toMapConnection() {
    return DsMapConnection(fromId: aId, toId: bId, label: relation);
  }
}

List<DsMapConnection> connectionsForCase(
  String caseId,
  List<CaseConnection> all,
) {
  return [
    for (final connection in all)
      if (connection.otherId(caseId) != null) connection.toMapConnection(),
  ];
}

Set<String> relatedIdsOf(String caseId, List<CaseConnection> all) {
  return {for (final connection in all) ?connection.otherId(caseId)};
}
