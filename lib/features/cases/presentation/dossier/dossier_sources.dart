import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/design/design.dart';
import '../../domain/case_source.dart';

abstract final class DossierSourceKeys {
  static Key card(String id) => ValueKey('dossier-source-$id');
}

String dossierSourceHost(String url) {
  final host = Uri.tryParse(url)?.host ?? '';
  if (host.isEmpty) return url;
  return host.startsWith('www.') ? host.substring(4) : host;
}

class DossierSources extends StatelessWidget {
  const DossierSources({super.key, required this.sources, this.onOpenSource});

  final List<CaseSource> sources;
  final ValueChanged<CaseSource>? onOpenSource;

  Future<void> _open(CaseSource source) async {
    if (onOpenSource != null) {
      onOpenSource!(source);
      return;
    }
    final uri = Uri.tryParse(source.url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: DsMonoLabel('Fuentes citadas · ${sources.length}'),
        ),
        const SizedBox(height: DsSpacing.s12),
        for (var i = 0; i < sources.length; i++) ...[
          if (i > 0) const SizedBox(height: DsSpacing.s8),
          _SourceCard(source: sources[i], onTap: () => _open(sources[i])),
        ],
      ],
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.source, required this.onTap});

  final CaseSource source;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final host = dossierSourceHost(source.url);
    return Material(
      key: DossierSourceKeys.card(source.id),
      color: DsColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: DsRadii.controlBorder,
        side: BorderSide(color: DsColors.lineHairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64, minWidth: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DsSpacing.s16,
              vertical: DsSpacing.s14,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DsMonoLabel(
                        source.kind.label,
                        color: DsColors.accentGold,
                        letterSpacingEm: 0.14,
                      ),
                      const SizedBox(height: DsSpacing.s4),
                      Text(
                        source.title,
                        style: DsTextStyles.desktop.body.copyWith(
                          color: DsColors.textPrimary,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: DsSpacing.s4),
                      Text(
                        host,
                        style: DsTextStyles.desktop.monoData.copyWith(
                          color: DsColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: DsSpacing.s12),
                const Icon(Icons.north_east, size: 18, color: DsColors.textBody),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
