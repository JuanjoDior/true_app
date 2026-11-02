import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../cases/domain/case_connection.dart';
import '../../../cases/domain/true_crime_case.dart';
import '../../../cases/presentation/design/case_design_mapping.dart';

/// Selección editorial del artboard, resuelta contra el catálogo y sus aristas.
class PortadaConnections extends StatelessWidget {
  const PortadaConnections({super.key, required this.cases, required this.connections, required this.onOpenCase});

  final List<TrueCrimeCase> cases;
  final List<CaseConnection> connections;
  final ValueChanged<TrueCrimeCase> onOpenCase;

  @override
  Widget build(BuildContext context) {
    final byId = {for (final c in cases) c.id: c};
    const pairs = [('isdal', 'somerton'), ('zodiac', 'goldenstate'), ('kercher', 'mccann')];
    final cards = <Widget>[];
    for (final (a, b) in pairs) {
      final first = byId[a];
      final second = byId[b];
      if (first == null || second == null) continue;
      final matches = connections.where((c) => (c.aId == a && c.bId == b) || (c.aId == b && c.bId == a));
      if (matches.isEmpty) continue;
      cards.add(_ConnectionCard(first: first, second: second, relation: matches.first.relation, onOpenCase: onOpenCase));
    }
    if (cards.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 900 ? 3 : constraints.maxWidth >= 600 ? 2 : 1;
      final width = (constraints.maxWidth - DsSpacing.s16 * (columns - 1)) / columns;
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Semantics(header: true, child: Text('Conexiones del archivo', style: DsTextStylesResolver.of(context).displaySection)),
        const DsMonoLabel('Casos que comparten un hilo'),
        const SizedBox(height: DsSpacing.s20),
        Wrap(spacing: DsSpacing.s16, runSpacing: DsSpacing.s16, children: [for (final card in cards) SizedBox(width: width, child: card)]),
      ]);
    });
  }
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({required this.first, required this.second, required this.relation, required this.onOpenCase});
  final TrueCrimeCase first;
  final TrueCrimeCase second;
  final String relation;
  final ValueChanged<TrueCrimeCase> onOpenCase;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(DsSpacing.s24),
    decoration: BoxDecoration(color: DsColors.surfaceCard, border: Border.all(color: DsColors.lineHairline), borderRadius: DsRadii.cardBorder),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const DsMonoLabel('Conexión curada'),
      SizedBox(height: 96, width: double.infinity, child: CustomPaint(painter: _ArcPainter(first.category.designColor.dot, second.category.designColor.dot))),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: _Endpoint(crimeCase: first, onTap: () => onOpenCase(first))),
        const SizedBox(width: DsSpacing.s12),
        Expanded(child: _Endpoint(crimeCase: second, right: true, onTap: () => onOpenCase(second))),
      ]),
      const SizedBox(height: DsSpacing.s16),
      Container(width: double.infinity, decoration: const BoxDecoration(border: Border(top: BorderSide(color: DsColors.lineHairline))), padding: const EdgeInsets.only(top: DsSpacing.s12), child: Text(relation, textAlign: TextAlign.center, style: DsTextStylesResolver.of(context).displayPoster)),
    ]),
  );
}

class _Endpoint extends StatelessWidget {
  const _Endpoint({required this.crimeCase, required this.onTap, this.right = false});
  final TrueCrimeCase crimeCase;
  final VoidCallback onTap;
  final bool right;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: DsRadii.controlBorder,
    child: ConstrainedBox(constraints: const BoxConstraints(minHeight: 52), child: Column(
      crossAxisAlignment: right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(crimeCase.title, textAlign: right ? TextAlign.right : TextAlign.left, style: DsTextStylesResolver.of(context).displayPoster),
        Text('${crimeCase.regionOrCity} · ${crimeCase.year}', textAlign: right ? TextAlign.right : TextAlign.left, style: DsTextStylesResolver.of(context).monoData.copyWith(color: DsColors.textMuted)),
      ],
    )),
  );
}

class _ArcPainter extends CustomPainter {
  _ArcPainter(this.left, this.right);
  final Color left;
  final Color right;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(6, size.height - 8)..quadraticBezierTo(size.width / 2, -14, size.width - 6, size.height - 8);
    final paint = Paint()..color = DsColors.accentGold..style = PaintingStyle.stroke..strokeWidth = 1.8;
    for (final metric in path.computeMetrics()) {
      for (double distance = 0; distance < metric.length; distance += 14) {
        canvas.drawPath(metric.extractPath(distance, (distance + 7).clamp(0, metric.length)), paint);
      }
    }
    for (final (point, color) in [(Offset(6, size.height - 8), left), (Offset(size.width - 6, size.height - 8), right)]) {
      canvas.drawCircle(point, 6, Paint()..color = color);
      canvas.drawCircle(point, 6, paint..strokeWidth = 2);
    }
  }
  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) => left != oldDelegate.left || right != oldDelegate.right;
}
