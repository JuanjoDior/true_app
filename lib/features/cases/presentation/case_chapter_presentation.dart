import '../domain/case_chapter.dart';

/// Cómo se titula cada capítulo editorial en la interfaz.
///
/// Vive en presentación y no en el dominio por la misma razón que
/// `case_category_presentation.dart` y `case_status_presentation.dart`: el
/// tipo de capítulo es un hecho del caso, su rótulo es una decisión editorial
/// que puede cambiar sin tocar los datos publicados ni el códec.
extension CaseChapterTypePresentation on CaseChapterType {
  String get label => switch (this) {
    CaseChapterType.background => 'Antecedentes',
    CaseChapterType.events => 'Los hechos',
    CaseChapterType.investigation => 'La investigación',
    CaseChapterType.currentStatus => 'Estado actual',
  };
}
