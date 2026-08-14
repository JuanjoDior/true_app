import '../../../home/presentation/widgets/situation/dossier_source_group.dart';
import '../../domain/case_draft.dart';
import '../../domain/case_source.dart';

/// Convierte los enlaces de un borrador en grupos de fuentes para la
/// previsualización [diseño §9.3].
///
/// Es una función pura y no un método del widget para poder probar sus tres
/// reglas frágiles sin montar un árbol. Las tres las tenía ya el panel de
/// previsualización y las tres se pierden con el cambio más natural:
///
/// 1. **Un enlace sin tipo cae en `other`.** Recorrer `link.kind` directamente
///    dejaría fuera de la previsualización todos los enlaces sin clasificar.
/// 2. **`other` se rotula "Sin clasificar", no "Otro".** Su `label` es 'Otro',
///    y presentar como un tipo real algo que nadie ha clasificado es mentir
///    sobre el estado del borrador.
/// 3. **Aquí no se recorta.** El exportador sí lo hace; la previsualización
///    enseña lo que hay escrito. Son decisiones distintas a propósito.
List<DossierSourceGroup> previewSourceGroups(List<DraftLink> links) {
  final groups = <DossierSourceGroup>[];
  // Se recorre el enum, no los enlaces, para que el orden de los grupos sea el
  // orden declarado y no el accidental de escritura.
  for (final kind in DraftLinkKind.values) {
    final sources = [
      for (final link in links)
        if ((link.kind ?? DraftLinkKind.other) == kind && _hasUrl(link))
          CaseSource(
            id: link.url!,
            title: link.title?.isNotEmpty == true ? link.title! : link.url!,
            url: link.url!,
            kind: kind == DraftLinkKind.podcast
                ? CaseSourceKind.podcast
                : CaseSourceKind.investigation,
          ),
    ];
    if (sources.isNotEmpty) {
      groups.add(DossierSourceGroup(label: _labelFor(kind), sources: sources));
    }
  }
  return groups;
}

bool _hasUrl(DraftLink link) => link.url != null && link.url!.isNotEmpty;

String _labelFor(DraftLinkKind kind) =>
    kind == DraftLinkKind.other ? 'Sin clasificar' : kind.label;
