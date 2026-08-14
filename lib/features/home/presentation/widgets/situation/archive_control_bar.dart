import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../cases/application/cases_providers.dart';
import 'situation_styles.dart';

/// Barra inferior del mapa: leyenda, línea de tiempo del archivo y vista.
class ArchiveControlBar extends ConsumerStatefulWidget {
  const ArchiveControlBar({
    super.key,
    required this.onWorld,
    required this.onDetail,
  });

  final VoidCallback onWorld;
  final VoidCallback onDetail;

  @override
  ConsumerState<ArchiveControlBar> createState() => _ArchiveControlBarState();
}

class _ArchiveControlBarState extends ConsumerState<ArchiveControlBar> {
  Timer? _timer;
  bool _playing = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _togglePlay() {
    if (_playing) {
      _stop();
      return;
    }
    final current = ref.read(timelineYearProvider);
    if (current >= kTimelineMaxYear) {
      ref.read(timelineYearProvider.notifier).state = kTimelineMinYear;
    }
    setState(() => _playing = true);
    _timer = Timer.periodic(const Duration(milliseconds: 70), (_) {
      final next = ref.read(timelineYearProvider) + 2;
      if (next >= kTimelineMaxYear) {
        ref.read(timelineYearProvider.notifier).state = kTimelineMaxYear;
        _stop();
      } else {
        ref.read(timelineYearProvider.notifier).state = next;
      }
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    if (mounted) setState(() => _playing = false);
  }

  @override
  Widget build(BuildContext context) {
    final year = ref.watch(timelineYearProvider);
    final visible = ref.watch(filteredCasesProvider).value?.length ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.bar.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF232A33)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 44,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 14,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          const _Legend(),
          SizedBox(
            width: 360,
            child: _Timeline(
              year: year,
              visible: visible,
              playing: _playing,
              onToggle: _togglePlay,
              onYear: (value) {
                _stop();
                ref.read(timelineYearProvider.notifier).state = value;
              },
            ),
          ),
          _ViewToggle(onWorld: widget.onWorld, onDetail: widget.onDetail),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    const items = <({Color color, String label})>[
      (color: AppColors.catSerie, label: 'Serie'),
      (color: AppColors.catIsolated, label: 'Aislado'),
      (color: AppColors.catKidnapping, label: 'Secuestro'),
      (color: AppColors.catUnsolved, label: 'Sin resolver'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 13,
          runSpacing: 6,
          children: [
            for (final item in items)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SituationDot(color: item.color, size: 8, glow: false),
                  const SizedBox(width: 6),
                  Text(
                    item.label,
                    style: SituationStyles.sans(
                      size: 10,
                      weight: FontWeight.w500,
                      color: AppColors.textSub,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'El halo indica densidad de casos · no severidad',
          style: SituationStyles.mono(size: 9, color: AppColors.textFaint2),
        ),
        const SizedBox(height: 2),
        Text(
          'Mapa © OpenStreetMap · CARTO',
          style: SituationStyles.mono(size: 9, color: Color(0xFF5C5852)),
        ),
      ],
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({
    required this.year,
    required this.visible,
    required this.playing,
    required this.onToggle,
    required this.onYear,
  });

  final int year;
  final int visible;
  final bool playing;
  final VoidCallback onToggle;
  final ValueChanged<int> onYear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'LÍNEA DE TIEMPO DEL ARCHIVO',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SituationStyles.mono(
                  size: 10,
                  weight: FontWeight.w600,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text.rich(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                TextSpan(
                  style: SituationStyles.sans(
                    size: 11,
                    weight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                  children: [
                    const TextSpan(text: 'Hasta '),
                    TextSpan(
                      text: '$year',
                      style: SituationStyles.mono(
                        size: 11,
                        weight: FontWeight.w600,
                        color: AppColors.gold,
                      ),
                    ),
                    const TextSpan(text: ' · '),
                    TextSpan(
                      text: '$visible',
                      style: SituationStyles.sans(
                        size: 11,
                        weight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const TextSpan(text: ' en el mapa'),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onToggle,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF15171D),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    playing ? '❚❚  Pausar' : '▶  Reproducir',
                    style: SituationStyles.sans(
                      size: 11,
                      weight: FontWeight.w600,
                      color: AppColors.textBody,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  activeTrackColor: AppColors.accent,
                  inactiveTrackColor: AppColors.border,
                  thumbColor: AppColors.textBody,
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14,
                  ),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 7,
                  ),
                ),
                child: Slider(
                  min: kTimelineMinYear.toDouble(),
                  max: kTimelineMaxYear.toDouble(),
                  value: year.toDouble().clamp(
                    kTimelineMinYear.toDouble(),
                    kTimelineMaxYear.toDouble(),
                  ),
                  onChanged: (value) => onYear(value.round()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.onWorld, required this.onDetail});

  final VoidCallback onWorld;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'VISTA',
          style: SituationStyles.mono(
            size: 10,
            color: AppColors.textFaint2,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(width: 9),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ToggleButton(
                label: 'Mundo',
                onTap: onWorld,
                color: AppColors.textMuted,
                border: true,
              ),
              _ToggleButton(
                label: 'Detalle',
                onTap: onDetail,
                color: AppColors.textBody,
                border: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    required this.onTap,
    required this.color,
    required this.border,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool border;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: border
                ? const Border(right: BorderSide(color: AppColors.border))
                : null,
          ),
          child: Text(
            label,
            style: SituationStyles.sans(
              size: 12,
              weight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
