import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../application/cases_providers.dart';
import '../../domain/true_crime_case.dart';
import '../case_chapter_presentation.dart';
import 'dossier_body_keys.dart';
import 'dossier_facts_pending.dart';
import 'dossier_photos.dart';
import 'dossier_related.dart';
import 'dossier_sources.dart';
import 'dossier_timeline.dart';

class DossierBody extends StatelessWidget {
  const DossierBody({
    super.key,
    required this.crimeCase,
    required this.relatedCases,
    required this.onOpenRelatedCase,
    this.pending = DossierPending.none,
  });

  final TrueCrimeCase crimeCase;

  /// Datos que faltan en un borrador: se pintan como «pendiente».
  final DossierPending pending;
  final List<RelatedCase> relatedCases;
  final ValueChanged<TrueCrimeCase> onOpenRelatedCase;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= DsBreakpoints.desktop;
      final main = _MainColumn(key: DossierBodyKeys.detailPanel, crimeCase: crimeCase);
      final aside = _Aside(key: DossierBodyKeys.aside, crimeCase: crimeCase, relatedCases: relatedCases, onOpen: onOpenRelatedCase, pending: pending);
      return Padding(
        padding: EdgeInsets.fromLTRB(wide ? DsSpacing.pageMarginDesktop : DsSpacing.pageMarginMobile, DsSpacing.s40, wide ? DsSpacing.pageMarginDesktop : DsSpacing.pageMarginMobile, 0),
        child: wide
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: main),
                const SizedBox(width: DsSpacing.s80),
                SizedBox(width: DossierBodyMetrics.asideWidth, child: aside),
              ])
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [main, const SizedBox(height: DsSpacing.s48), aside]),
      );
    });
  }
}

class _MainColumn extends StatelessWidget {
  const _MainColumn({super.key, required this.crimeCase});
  final TrueCrimeCase crimeCase;

  @override
  Widget build(BuildContext context) {
    final chapters = crimeCase.chapters.orderedMeaningful;
    final victim = crimeCase.victim;
    final sections = <Widget>[
      if (victim != null && victim.trim().isNotEmpty) _Victim(victim: victim),
      if (crimeCase.timeline.isNotEmpty) DossierTimeline(events: crimeCase.timeline),
      if (crimeCase.tags.isNotEmpty) _Tags(tags: crimeCase.tags),
      for (final chapter in chapters) _Section(label: chapter.type.label, child: Text(chapter.content, style: DsTextStylesResolver.of(context).bodyLarge)),
      if (crimeCase.photos.isNotEmpty) DossierPhotos(photos: crimeCase.photos),
      if (chapters.isEmpty && crimeCase.photos.isEmpty) const _HonestNote(),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (var i = 0; i < sections.length; i++) ...[
        if (i > 0) const SizedBox(height: DsSpacing.s48),
        sections[i],
      ],
    ]);
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.child});
  final String label;
  final Widget child;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Semantics(header: true, child: DsMonoLabel(label)),
    const SizedBox(height: DsSpacing.s18),
    child,
  ]);
}

class _Victim extends StatelessWidget {
  const _Victim({required this.victim});
  final String victim;
  @override
  Widget build(BuildContext context) => _Section(
    label: 'Víctimas',
    child: Container(
      key: DossierBodyKeys.victims,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: DsSpacing.s24, vertical: DsSpacing.s20),
      decoration: BoxDecoration(color: DsColors.surfaceCard, borderRadius: DsRadii.controlBorder, border: Border.all(color: DsColors.lineHairline)),
      foregroundDecoration: const BoxDecoration(border: Border(left: BorderSide(color: DsColors.accentRed, width: 3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(victim, style: DsTextStyles.desktop.displayPoster),
        const SizedBox(height: DsSpacing.s4),
        Text('Las víctimas se nombran con respeto.', style: DsTextStyles.desktop.body.copyWith(color: DsColors.textFaint)),
      ]),
    ),
  );
}

class _Tags extends StatelessWidget {
  const _Tags({required this.tags});
  final List<String> tags;
  @override
  Widget build(BuildContext context) => _Section(label: 'Etiquetas', child: Wrap(spacing: DsSpacing.s8, runSpacing: DsSpacing.s8, children: [
    for (final tag in tags) Container(
      padding: const EdgeInsets.symmetric(horizontal: DsSpacing.s14, vertical: DsSpacing.s8),
      decoration: BoxDecoration(border: Border.all(color: DsColors.lineHairline), borderRadius: BorderRadius.circular(999)),
      child: Text(tag, style: DsTextStyles.desktop.monoData.copyWith(color: DsColors.textBody)),
    ),
  ]));
}

class _HonestNote extends StatelessWidget {
  const _HonestNote();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(DsSpacing.s18),
    decoration: BoxDecoration(border: Border.all(color: DsColors.lineHairline), borderRadius: DsRadii.controlBorder),
    child: Text.rich(TextSpan(style: DsTextStyles.desktop.body.copyWith(color: DsColors.textMuted), children: [
      const TextSpan(text: 'Expediente en curso.', style: TextStyle(fontWeight: FontWeight.w600, color: DsColors.textPrimary)),
      const TextSpan(text: ' Este caso aún no tiene capítulos ni fotografías documentadas. Se añadirán cuando estén verificados.'),
    ])),
  );
}

class _Aside extends StatelessWidget {
  const _Aside({super.key, required this.crimeCase, required this.relatedCases, required this.onOpen, required this.pending});
  final DossierPending pending;
  final TrueCrimeCase crimeCase;
  final List<RelatedCase> relatedCases;
  final ValueChanged<TrueCrimeCase> onOpen;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: _Stat(label: 'Año', value: pending.year ? DossierPending.placeholder : '${crimeCase.year}', pendingValue: pending.year)),
      const SizedBox(width: DsSpacing.s10),
      Expanded(child: _Stat(label: 'Conexiones', value: '${relatedCases.length}')),
    ]),
    if (crimeCase.sources.isNotEmpty) ...[const SizedBox(height: DsSpacing.s40), DossierSources(sources: crimeCase.sources)],
    if (relatedCases.isNotEmpty) ...[const SizedBox(height: DsSpacing.s40), DossierRelated(relatedCases: relatedCases, onOpen: onOpen)],
  ]);
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.pendingValue = false});
  final String label;
  final String value;
  final bool pendingValue;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(DsSpacing.s16),
    decoration: BoxDecoration(color: DsColors.surfaceCard, border: Border.all(color: DsColors.lineHairline), borderRadius: DsRadii.controlBorder),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      DsMonoLabel(label, letterSpacingEm: 0.14),
      const SizedBox(height: DsSpacing.s4),
      Text(value, style: DsTextStyles.desktop.displaySection.copyWith(color: pendingValue ? DsColors.textMuted : DsColors.accentGold)),
    ]),
  );
}
