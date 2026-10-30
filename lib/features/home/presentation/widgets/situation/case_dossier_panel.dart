import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../cases/application/cases_providers.dart';
import '../../../../cases/domain/true_crime_case.dart';
import 'case_dossier_content.dart';
import 'dossier_source_group.dart';

/// Expediente compacto: el host que ata [CaseDossierContent] al estado de la
/// Sala de Situación.
///
/// El renderizado entero vive en el contenido; aquí sólo se resuelven los casos
/// relacionados y se traducen sus acciones en escrituras sobre los providers.
/// Separarlos es lo que permite que la página de detalle ampliada reutilice el
/// mismo renderizador con otro host [diseño D7].
///
/// **Todos los parámetros más allá del caso son opcionales, y omitirlos deja el
/// comportamiento de hoy intacto** [diseño D12]. No es cosmética: si
/// `relatedCases` fuese obligatorio, los call sites tendrían que cambiar en la
/// misma edición que lo introduce y no quedaría ningún estado intermedio que
/// compile. Eso es lo que permite entregar la extracción por partes.
class CaseDossierPanel extends ConsumerWidget {
  const CaseDossierPanel({
    super.key,
    required this.crimeCase,
    this.relatedCases,
    this.onOpenRelatedCase,
    this.sourceGroups,
  });

  final TrueCrimeCase crimeCase;

  /// `null` significa "derívalos tú", que es lo que el panel ha hecho siempre.
  /// Sólo lo pasan los hosts que ya tienen la lista en la mano.
  final List<RelatedCase>? relatedCases;

  /// Si el host no dice otra cosa, abrir un caso relacionado lo selecciona.
  final ValueChanged<TrueCrimeCase>? onOpenRelatedCase;

  final List<DossierSourceGroup>? sourceGroups;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CaseDossierContent(
      crimeCase: crimeCase,
      relatedCases:
          relatedCases ?? ref.watch(relatedCasesProvider(crimeCase.id)),
      onOpenRelatedCase:
          onOpenRelatedCase ??
          (related) =>
              ref.read(selectedCaseIdProvider.notifier).state = related.id,
      sourceGroups: sourceGroups,
    );
  }
}
