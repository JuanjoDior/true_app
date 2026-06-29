import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/config/map_config.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../cases/application/cases_providers.dart';
import '../../../../cases/domain/case_source.dart';
import '../../../../cases/domain/case_timeline_event.dart';
import '../../../../cases/domain/true_crime_case.dart';
import '../../../../cases/presentation/case_category_presentation.dart';
import '../../../../cases/presentation/case_status_presentation.dart';
import 'situation_styles.dart';

/// Expediente del caso seleccionado: cronología, fuentes y casos relacionados.
class CaseDossierPanel extends ConsumerWidget {
  const CaseDossierPanel({super.key, required this.crimeCase});

  final TrueCrimeCase crimeCase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final related = ref.watch(relatedCasesProvider(crimeCase.id));

    return Column(
      key: const Key('detail-panel'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(crimeCase: crimeCase),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatsGrid(crimeCase: crimeCase, connections: related.length),
                const SizedBox(height: 18),
                Text(
                  crimeCase.summary,
                  style: SituationStyles.sans(
                    size: 14,
                    color: AppColors.textSub2,
                    height: 1.65,
                  ),
                ),
                if (crimeCase.timeline.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  const SituationSectionLabel('Cronología verificada'),
                  const SizedBox(height: 13),
                  _Timeline(events: crimeCase.timeline),
                ],
                if (crimeCase.sources.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const SituationSectionLabel('Fuentes citadas'),
                  const SizedBox(height: 12),
                  for (final source in crimeCase.sources)
                    _SourceCard(source: source),
                ],
                if (related.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const SituationSectionLabel('Casos relacionados'),
                  const SizedBox(height: 12),
                  for (final r in related)
                    _RelatedCard(
                      related: r,
                      onTap: () => ref
                          .read(selectedCaseIdProvider.notifier)
                          .state = r.crimeCase.id,
                    ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        _Footer(
          onCenter: () {
            ref.read(mapRecenterTickProvider.notifier).state++;
          },
        ),
      ],
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.crimeCase});

  final TrueCrimeCase crimeCase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () =>
                        ref.read(selectedCaseIdProvider.notifier).state = null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.arrow_back, size: 13, color: AppColors.textSoft),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            'VOLVER AL MAPA',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SituationStyles.mono(
                              size: 10,
                              weight: FontWeight.w600,
                              color: AppColors.textSoft,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_border_rounded, size: 16, color: AppColors.textMuted),
                  SizedBox(width: 10),
                  Icon(Icons.ios_share_rounded, size: 14, color: AppColors.textMuted),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SituationBadge(
                label: crimeCase.category.presentation.label,
                color: crimeCase.category.presentation.color,
                filled: true,
              ),
              SituationBadge(
                label: crimeCase.statusLabel ?? crimeCase.status.label,
                color: crimeCase.status.color,
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(crimeCase.title, style: SituationStyles.serif(size: 32, height: 1.04)),
          const SizedBox(height: 9),
          Text(
            crimeCase.locationLabel,
            style: SituationStyles.mono(size: 11, color: AppColors.textSub),
          ),
          if (crimeCase.victim != null) ...[
            const SizedBox(height: 11),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.statusOpen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: AppColors.statusOpen.withValues(alpha: 0.22),
                ),
              ),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'VÍCTIMA(S) · ',
                      style: SituationStyles.mono(
                        size: 10,
                        color: AppColors.textFaint,
                        letterSpacing: 0.8,
                      ),
                    ),
                    TextSpan(
                      text: crimeCase.victim,
                      style: SituationStyles.sans(
                        size: 12,
                        weight: FontWeight.w500,
                        color: AppColors.textSub2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.crimeCase, required this.connections});

  final TrueCrimeCase crimeCase;
  final int connections;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.panelMuted),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          _StatCell(label: 'AÑO', value: '${crimeCase.year}'),
          const _StatDivider(),
          _StatCell(label: 'CONEXIONES', value: '$connections'),
          const _StatDivider(),
          _StatCell(
            label: 'COORDS',
            value: crimeCase.coordsLabel,
            valueColor: AppColors.gold,
            mono: true,
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 52, color: AppColors.panelMuted);
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    this.valueColor = AppColors.textPrimary,
    this.mono = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        color: AppColors.card,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: SituationStyles.mono(
                size: 8,
                color: AppColors.textFaint,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: mono
                  ? SituationStyles.mono(
                      size: 11,
                      weight: FontWeight.w600,
                      color: valueColor,
                    )
                  : SituationStyles.sans(
                      size: 15,
                      weight: FontWeight.w600,
                      color: valueColor,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.events});

  final List<CaseTimelineEvent> events;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < events.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    SituationDot(color: events[i].kind.color, size: 9),
                    if (i != events.length - 1)
                      Expanded(
                        child: Container(
                          width: 1,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: AppColors.panelMuted,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        events[i].title,
                        style: SituationStyles.sans(
                          size: 12,
                          weight: FontWeight.w600,
                          color: AppColors.textBody,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        events[i].date,
                        style: SituationStyles.mono(
                          size: 10,
                          color: AppColors.textFaint,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.source});

  final CaseSource source;

  String get _host {
    final uri = Uri.tryParse(source.url);
    return uri?.host.isNotEmpty == true ? uri!.host : source.url;
  }

  Future<void> _open() async {
    final uri = Uri.tryParse(source.url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _open,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppColors.panelMuted),
            ),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.statusOpen,
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        source.title,
                        style: SituationStyles.sans(
                          size: 12,
                          weight: FontWeight.w600,
                          color: AppColors.textBody,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _host,
                        style: SituationStyles.mono(
                          size: 10,
                          color: AppColors.textFaint2,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.north_east_rounded, size: 13, color: AppColors.textSoft),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RelatedCard extends StatelessWidget {
  const _RelatedCard({required this.related, required this.onTap});

  final RelatedCase related;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppColors.panelMuted),
            ),
            child: Row(
              children: [
                SituationDot(color: related.crimeCase.category.presentation.color),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        related.crimeCase.title,
                        style: SituationStyles.serif(size: 13, height: 1.1),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        related.relation,
                        style: SituationStyles.sans(
                          size: 10,
                          weight: FontWeight.w500,
                          color: AppColors.textSub,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward, size: 15, color: AppColors.textFaint2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.onCenter});

  final VoidCallback onCenter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.bar,
        border: Border(top: BorderSide(color: AppColors.panelMuted)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                'Seguir el caso',
                style: SituationStyles.sans(
                  size: 13,
                  weight: FontWeight.w600,
                  color: const Color(0xFF080A0E),
                ),
              ),
            ),
          ),
          const SizedBox(width: 9),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onCenter,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'Centrar',
                  style: SituationStyles.sans(
                    size: 13,
                    weight: FontWeight.w600,
                    color: AppColors.textBody,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
