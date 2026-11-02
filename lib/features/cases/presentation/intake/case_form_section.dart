import 'package:flutter/widgets.dart';

import 'sections/basic_data_section.dart';
import 'sections/chapters_section.dart';
import 'sections/links_section.dart';
import 'sections/location_section.dart';
import 'sections/photos_section.dart';
import 'sections/summary_section.dart';
import 'sections/timeline_section.dart';

/// Sección independiente del formulario de intake: título editorial + un
/// builder de widget. Añadir secciones futuras (cronología, personas,
/// ubicaciones) es sumar una entrada aquí, sin tocar las existentes ni el
/// esquema de export (diseño #6).
class CaseFormSection {
  const CaseFormSection({
    required this.title,
    required this.builder,
    this.optional = false,
    this.navLabel,
  });

  final String title;

  /// Las secciones opcionales se rotulan así en el editor; el resto aporta
  /// campos obligatorios para validar el borrador.
  final bool optional;

  /// Texto corto para la navegación entre secciones; por defecto, [title].
  final String? navLabel;
  final WidgetBuilder builder;
}

/// Registro v1 de secciones del formulario de intake.
final List<CaseFormSection> kCaseFormSections = <CaseFormSection>[
  CaseFormSection(
    title: 'Datos básicos',
    builder: (context) => const BasicDataSection(),
  ),
  CaseFormSection(
    title: 'Ubicación',
    builder: (context) => const LocationSection(),
  ),
  CaseFormSection(
    title: 'Resumen y ficha',
    navLabel: 'Resumen',
    optional: true,
    builder: (context) => const SummarySection(),
  ),
  CaseFormSection(
    title: 'Cronología',
    optional: true,
    builder: (context) => const TimelineSection(),
  ),
  CaseFormSection(
    title: 'Enlaces',
    optional: true,
    builder: (context) => const LinksSection(),
  ),
  CaseFormSection(
    title: 'Fotografías',
    optional: true,
    builder: (context) => const PhotosSection(),
  ),
  CaseFormSection(
    title: 'Capítulos',
    optional: true,
    builder: (context) => const ChaptersSection(),
  ),
];
