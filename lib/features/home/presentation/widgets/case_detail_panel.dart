import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../cases/domain/case_source.dart';
import '../../../cases/domain/true_crime_case.dart';
import '../../../cases/presentation/case_category_presentation.dart';

class CaseDetailPanel extends StatelessWidget {
  const CaseDetailPanel({
    super.key,
    required this.crimeCase,
    required this.onClose,
    this.compact = false,
  });

  final TrueCrimeCase crimeCase;
  final VoidCallback onClose;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      key: Key(compact ? 'mobile-case-sheet' : 'detail-panel'),
      decoration: BoxDecoration(
        color: const Color(0xFF111317).withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(compact ? 28 : 30),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.34),
            blurRadius: 34,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 18, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CategoryBadge(crimeCase: crimeCase),
                      const SizedBox(height: 12),
                      Text(
                        crimeCase.title,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontFamily: 'NotoSerifDisplay',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${crimeCase.locationLabel} · ${crimeCase.year}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Cerrar ficha',
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: crimeCase.tags
                        .map((tag) {
                          return Chip(label: Text(tag));
                        })
                        .toList(growable: false),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    crimeCase.summary,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SourceSection(
                    title: CaseSourceKind.investigation.label,
                    description:
                        'Pistas de contexto, análisis y documentación editorial del caso.',
                    sources: crimeCase.investigationSources,
                  ),
                  const SizedBox(height: 20),
                  _SourceSection(
                    title: CaseSourceKind.podcast.label,
                    description:
                        'Escucha episodios o búsquedas curadas relacionadas con el caso.',
                    sources: crimeCase.podcastSources,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.crimeCase});

  final TrueCrimeCase crimeCase;

  @override
  Widget build(BuildContext context) {
    final presentation = crimeCase.category.presentation;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: presentation.color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: presentation.color.withValues(alpha: 0.42)),
      ),
      child: Text(
        presentation.label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SourceSection extends StatelessWidget {
  const _SourceSection({
    required this.title,
    required this.description,
    required this.sources,
  });

  final String title;
  final String description;
  final List<CaseSource> sources;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(description, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 14),
        if (sources.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.panelMuted,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'No hay un enlace curado todavía para esta sección.',
              style: theme.textTheme.bodyMedium,
            ),
          )
        else
          Column(
            children: sources
                .map((source) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SourceCard(source: source),
                  );
                })
                .toList(growable: false),
          ),
      ],
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.source});

  final CaseSource source;

  Future<void> _open() async {
    await launchUrl(Uri.parse(source.url));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panelMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              source.kind == CaseSourceKind.podcast
                  ? Icons.graphic_eq_rounded
                  : Icons.menu_book_rounded,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(source.title, style: theme.textTheme.titleMedium),
          ),
          const SizedBox(width: 12),
          FilledButton.tonal(onPressed: _open, child: const Text('Abrir')),
        ],
      ),
    );
  }
}
