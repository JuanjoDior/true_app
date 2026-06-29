import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../cases/application/cases_providers.dart';
import '../../../../cases/domain/case_status.dart';
import 'situation_styles.dart';

/// Chips para filtrar el mapa por estado de investigación.
class CaseStatusChips extends ConsumerWidget {
  const CaseStatusChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(statusFilterProvider);

    final items = <({String key, String label, CaseStatus? status})>[
      (key: 'all', label: 'Todos', status: null),
      (key: 'open', label: 'Sin resolver', status: CaseStatus.open),
      (key: 'solved', label: 'Resuelto', status: CaseStatus.solved),
      (
        key: 'progress',
        label: 'En investigación',
        status: CaseStatus.inProgress,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SituationSectionLabel('Filtrar por estado'),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final item in items)
                _StatusChip(
                  key: Key('status-chip-${item.key}'),
                  label: item.label,
                  selected: active == item.status,
                  onTap: () =>
                      ref.read(statusFilterProvider.notifier).state = item.status,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent
                : AppColors.card.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: SituationStyles.sans(
              size: 11,
              weight: FontWeight.w500,
              color: selected ? Colors.white : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
