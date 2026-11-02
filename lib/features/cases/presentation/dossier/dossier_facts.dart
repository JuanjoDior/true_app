import 'package:flutter/widgets.dart';

import '../../../../core/design/tokens/ds_colors.dart';
import '../../domain/true_crime_case.dart';
import '../design/case_design_mapping.dart';
import 'dossier_facts_keys.dart';
import 'dossier_facts_pending.dart';

class DossierFacts extends StatelessWidget {
  const DossierFacts({
    super.key,
    required this.crimeCase,
    required this.connectionsCount,
    this.pending = DossierPending.none,
  });

  final TrueCrimeCase crimeCase;
  final int connectionsCount;

  /// Datos que faltan en un borrador: se pintan como «pendiente».
  final DossierPending pending;

  @override
  Widget build(BuildContext context) {
    final victim = crimeCase.victim?.trim();
    const missing = DossierPending.placeholder;
    final cells = <Widget>[
      _Fact(
        key: DossierFactsKeys.year,
        label: 'AÑO',
        value: pending.year ? missing : '${crimeCase.year}',
        highlighted: true,
        pending: pending.year,
      ),
      _Fact(
        key: DossierFactsKeys.place,
        label: 'LUGAR',
        value:
            '${pending.region ? missing : crimeCase.regionOrCity}\n'
            '${pending.country ? missing : crimeCase.country}',
        pending: pending.place,
      ),
      _Fact(
        key: DossierFactsKeys.victims,
        label: 'VÍCTIMAS',
        value: pending.victims
            ? missing
            : victim == null || victim.isEmpty
            ? 'No documentadas'
            : victim,
        pending: pending.victims,
      ),
      _Fact(
        key: DossierFactsKeys.status,
        label: 'ESTADO',
        value: pending.status
            ? missing
            : crimeCase.statusLabel?.trim().isNotEmpty == true
            ? crimeCase.statusLabel!
            : crimeCase.status.label,
        color: pending.status ? null : crimeCase.status.designColor,
        pending: pending.status,
      ),
      _Fact(
        key: DossierFactsKeys.connections,
        label: 'CONEXIONES',
        value: '$connectionsCount',
        highlighted: true,
      ),
    ];
    final columns = MediaQuery.sizeOf(context).width >= 1200 ? 5 : 2;
    return Container(
      key: DossierFactsKeys.strip,
      decoration: BoxDecoration(
        color: DsColors.surfaceGlass,
        border: Border.all(color: DsColors.lineHairline),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          for (var start = 0; start < cells.length; start += columns)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < columns; index++)
                    Expanded(
                      child: start + index < cells.length
                          ? cells[start + index]
                          : const SizedBox(),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({
    super.key,
    required this.label,
    required this.value,
    this.highlighted = false,
    this.color,
    this.pending = false,
  });
  final String label;
  final String value;
  final bool highlighted;
  final Color? color;

  /// Dato que falta: texto atenuado y sin el énfasis de un valor real.
  final bool pending;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'IBMPlexMono',
            fontSize: 11,
            color: DsColors.textMuted,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontFamily: highlighted && !pending ? 'NotoSerifDisplay' : null,
            fontSize: highlighted && !pending ? 26 : 15,
            height: 1.4,
            fontWeight: highlighted && !pending
                ? FontWeight.bold
                : FontWeight.normal,
            color: pending
                ? DsColors.textMuted
                : color ??
                      (highlighted
                          ? DsColors.accentGold
                          : DsColors.textPrimary),
          ),
        ),
      ],
    ),
  );
}
