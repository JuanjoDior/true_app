import 'package:flutter/widgets.dart';

import '../../../../core/design/design.dart';
import '../../domain/case_timeline_event.dart';

class DossierTimeline extends StatelessWidget {
  const DossierTimeline({super.key, required this.events});

  final List<CaseTimelineEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: const DsMonoLabel('Cronología verificada'),
        ),
        const SizedBox(height: DsSpacing.s24),
        LayoutBuilder(
          builder: (context, constraints) {
            final dateWidth = constraints.maxWidth < 500 ? 88.0 : 140.0;
            return IntrinsicHeight(
              child: Stack(
                children: [
                  Positioned(
                    left: dateWidth + DsSpacing.s24,
                    top: DsSpacing.s12,
                    bottom: DsSpacing.s12,
                    width: 2,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            DsColors.accentRed,
                            DsColors.accentGold,
                            DsStatusColors.open,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      for (var i = 0; i < events.length; i++)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: i == events.length - 1 ? 0 : DsSpacing.s32,
                          ),
                          child: _Milestone(
                            event: events[i],
                            dateWidth: dateWidth,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _Milestone extends StatelessWidget {
  const _Milestone({required this.event, required this.dateWidth});

  final CaseTimelineEvent event;
  final double dateWidth;

  @override
  Widget build(BuildContext context) {
    final color = switch (event.kind) {
      CaseTimelineKind.initial => DsColors.accentRed,
      CaseTimelineKind.process => DsColors.accentGold,
      CaseTimelineKind.open => DsStatusColors.open,
      CaseTimelineKind.solved => DsStatusColors.solved,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: dateWidth,
          child: Text(
            event.date,
            textAlign: TextAlign.right,
            style: DsTextStyles.desktop.displaySection.copyWith(color: color),
          ),
        ),
        SizedBox(
          width: DsSpacing.s48,
          child: Padding(
            padding: const EdgeInsets.only(top: DsSpacing.s8),
            child: Center(
              child: Container(
                width: DsSpacing.s12,
                height: DsSpacing.s12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: color, blurRadius: 18)],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DsMonoLabel(
                event.kind.label,
                color: color,
                letterSpacingEm: 0.14,
              ),
              const SizedBox(height: DsSpacing.s4),
              Text(
                event.title,
                style: DsTextStyles.desktop.bodyLarge.copyWith(
                  color: DsColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
