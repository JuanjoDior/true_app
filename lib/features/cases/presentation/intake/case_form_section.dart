import 'package:flutter/widgets.dart';

import 'sections/basic_data_section.dart';
import 'sections/links_section.dart';
import 'sections/photos_section.dart';
import 'sections/summary_section.dart';

/// Sección independiente del formulario de intake: título editorial + un
/// builder de widget. Añadir secciones futuras (cronología, personas,
/// ubicaciones) es sumar una entrada aquí, sin tocar las existentes ni el
/// esquema de export (diseño #6).
class CaseFormSection {
  const CaseFormSection({required this.title, required this.builder});

  final String title;
  final WidgetBuilder builder;
}

/// Registro v1 de secciones del formulario de intake.
final List<CaseFormSection> kCaseFormSections = <CaseFormSection>[
  CaseFormSection(
    title: 'Datos básicos',
    builder: (context) => const BasicDataSection(),
  ),
  CaseFormSection(
    title: 'Resumen',
    builder: (context) => const SummarySection(),
  ),
  CaseFormSection(
    title: 'Enlaces',
    builder: (context) => const LinksSection(),
  ),
  CaseFormSection(
    title: 'Fotografías',
    builder: (context) => const PhotosSection(),
  ),
];
