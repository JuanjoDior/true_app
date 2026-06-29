import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../../core/theme/app_theme.dart';
import 'situation_styles.dart';

/// Una actualización del archivo mostrada en el ticker.
typedef ArchiveUpdate = ({String text, String case_, String? year});

const List<ArchiveUpdate> _kUpdates = [
  (text: 'Caso reabierto', case_: 'Paso Diátlov', year: '2019'),
  (text: 'Identidad confirmada', case_: 'El hombre de Somerton', year: '2022'),
  (text: 'Nueva fuente añadida', case_: 'Black Dahlia', year: null),
  (text: 'Estado actualizado', case_: 'Golden State Killer', year: 'resuelto'),
];

/// Barra de actualizaciones recientes con desplazamiento continuo.
class UpdatesTicker extends StatefulWidget {
  const UpdatesTicker({super.key});

  @override
  State<UpdatesTicker> createState() => _UpdatesTickerState();
}

class _UpdatesTickerState extends State<UpdatesTicker>
    with SingleTickerProviderStateMixin {
  final ScrollController _scroll = ScrollController();
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  static const double _pxPerSecond = 42;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    if (!_scroll.hasClients) {
      _last = elapsed;
      return;
    }
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    final position = _scroll.position;
    final viewport = position.viewportDimension;
    // El contenido está duplicado: una copia mide la mitad del total + viewport.
    final copyWidth = (position.maxScrollExtent + viewport) / 2;
    if (copyWidth <= 0) return;
    var next = _scroll.offset + _pxPerSecond * dt;
    if (next >= copyWidth) {
      next -= copyWidth;
    }
    _scroll.jumpTo(next.clamp(0, position.maxScrollExtent));
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = [..._kUpdates, ..._kUpdates];
    return Container(
      height: 28,
      decoration: const BoxDecoration(
        color: AppColors.tickerBar,
        border: Border(bottom: BorderSide(color: AppColors.hairlineSoft)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 18),
          const _TickerHeader(),
          const SizedBox(width: 14),
          Expanded(
            child: IgnorePointer(
              child: SingleChildScrollView(
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Row(
                  children: [
                    for (final update in items) _TickerItem(update: update),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
        ],
      ),
    );
  }
}

class _TickerHeader extends StatelessWidget {
  const _TickerHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SituationDot(color: AppColors.accent, size: 6, glow: false),
        const SizedBox(width: 6),
        Text(
          'ACTUALIZACIONES RECIENTES',
          style: SituationStyles.mono(
            size: 9,
            weight: FontWeight.w600,
            color: AppColors.gold,
            letterSpacing: 1.8,
          ),
        ),
      ],
    );
  }
}

class _TickerItem extends StatelessWidget {
  const _TickerItem({required this.update});

  final ArchiveUpdate update;

  @override
  Widget build(BuildContext context) {
    final suffix = update.year == null ? '' : ' (${update.year})';
    return Padding(
      padding: const EdgeInsets.only(right: 34),
      child: Text.rich(
        TextSpan(
          style: SituationStyles.sans(
            size: 11,
            weight: FontWeight.w500,
            color: AppColors.textSub,
          ),
          children: [
            TextSpan(text: '${update.text} · '),
            TextSpan(
              text: update.case_,
              style: SituationStyles.sans(
                size: 11,
                weight: FontWeight.w500,
                color: AppColors.textSub2,
              ),
            ),
            TextSpan(text: suffix),
          ],
        ),
      ),
    );
  }
}
