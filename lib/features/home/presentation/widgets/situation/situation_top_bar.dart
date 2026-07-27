import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../cases/application/cases_providers.dart';
import 'situation_styles.dart';

/// Barra superior de la Sala de Situación: marca, buscador y métricas.
class SituationTopBar extends ConsumerStatefulWidget {
  const SituationTopBar({super.key, this.compact = false});

  /// En modo compacto se ocultan las métricas y el selector global.
  final bool compact;

  @override
  ConsumerState<SituationTopBar> createState() => _SituationTopBarState();
}

class _SituationTopBarState extends ConsumerState<SituationTopBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(searchQueryProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(archiveStatsProvider);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: AppColors.bar,
        border: Border(bottom: BorderSide(color: AppColors.panelMuted)),
      ),
      child: Row(
        children: [
          const _Wordmark(),
          const SizedBox(width: 16),
          Expanded(child: Center(child: _SearchField(controller: _controller))),
          const SizedBox(width: 12),
          const _IntakeEntryButton(),
          const SizedBox(width: 16),
          if (!widget.compact) ...[
            _Stat(value: '${stats.documented}', label: 'DOCUMENTADOS'),
            const SizedBox(width: 20),
            _Stat(
              value: '${stats.unsolved}',
              label: 'SIN RESOLVER',
              valueColor: AppColors.statusOpen,
            ),
            const SizedBox(width: 20),
            _Stat(value: '${stats.yearsCovered}', label: 'AÑOS CUBIERTOS'),
            const SizedBox(width: 20),
            _Stat(
              value: '${stats.sources}',
              label: 'FUENTES CITADAS',
              valueColor: AppColors.gold,
            ),
            const SizedBox(width: 16),
            const _GlobalPill(),
          ],
        ],
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.45),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            'T',
            style: SituationStyles.serif(size: 18, color: Colors.white, height: 1),
          ),
        ),
        const SizedBox(width: 11),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'TRUE',
              style: SituationStyles.serif(
                size: 17,
                color: AppColors.textPrimary,
                height: 1,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'ARCHIVO DE CASOS',
              style: SituationStyles.mono(
                size: 8,
                weight: FontWeight.w600,
                color: AppColors.textFaint,
                letterSpacing: 2.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SearchField extends ConsumerWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, size: 16, color: AppColors.textSoft),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                key: const Key('case-search-field'),
                controller: controller,
                onChanged: (value) =>
                    ref.read(searchQueryProvider.notifier).state = value,
                cursorColor: AppColors.accent,
                style: SituationStyles.sans(size: 13, color: AppColors.textBody),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'Buscar por nombre, lugar o año…',
                  hintStyle:
                      SituationStyles.sans(size: 13, color: AppColors.textFaint2),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.border),
              ),
              child: Text('⌘K', style: SituationStyles.mono(size: 10)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Entrada al workspace de intake de Iván, visible también en móvil (donde
/// el rail lateral desaparece por falta de espacio).
class _IntakeEntryButton extends ConsumerWidget {
  const _IntakeEntryButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        key: const Key('top-bar-intake-entry'),
        onTap: () =>
            ref.read(workspaceProvider.notifier).state = Workspace.intake,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.add_box_outlined,
            size: 17,
            color: AppColors.textSoft,
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    this.valueColor = AppColors.textPrimary,
  });

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: SituationStyles.sans(
            size: 15,
            weight: FontWeight.w600,
            color: valueColor,
            height: 1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: SituationStyles.mono(
            size: 8,
            weight: FontWeight.w500,
            color: AppColors.textFaint,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _GlobalPill extends StatelessWidget {
  const _GlobalPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        'Global ▾',
        style: SituationStyles.sans(
          size: 12,
          weight: FontWeight.w500,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
