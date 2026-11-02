import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/design.dart';
import '../../domain/case_connection.dart';
import '../../domain/true_crime_case.dart';
import '../design/case_connection_design.dart';
import '../design/case_design_mapping.dart';
import 'dossier_facts_pending.dart';
import 'dossier_map_keys.dart';

enum _MapView { world, focused, connections }

class _MapViewSelector extends StatefulWidget {
  const _MapViewSelector({required this.value, required this.onChanged});

  final _MapView value;
  final ValueChanged<_MapView> onChanged;

  @override
  State<_MapViewSelector> createState() => _MapViewSelectorState();
}

class _MapViewSelectorState extends State<_MapViewSelector> {
  static const _views = [
    _MapView.focused,
    _MapView.connections,
    _MapView.world,
  ];
  static const _labels = ['Caso', 'Conexiones', 'Mundo'];
  final _nodes = List.generate(3, (_) => FocusNode());

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _moveFocus(int delta) {
    final current = _nodes.indexWhere((node) => node.hasFocus);
    final target = current + delta;
    if (current >= 0 && target >= 0 && target < _nodes.length) {
      _nodes[target].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final textStyle = DsTextStylesResolver.of(
      context,
    ).uiButton.copyWith(fontSize: 14);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            _moveFocus(rtl ? 1 : -1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            _moveFocus(rtl ? -1 : 1),
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: DsColors.surfaceCard,
          borderRadius: DsRadii.controlBorder,
          border: Border.all(color: DsColors.lineHairline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Row(
            children: [
              for (var i = 0; i < _views.length; i++)
                Expanded(
                  flex: i == 1 ? 3 : 2,
                  child: DsPressable(
                    focusNode: _nodes[i],
                    semanticLabel: _labels[i],
                    selected: widget.value == _views[i],
                    inMutuallyExclusiveGroup: true,
                    onTap: widget.value == _views[i]
                        ? () {}
                        : () => widget.onChanged(_views[i]),
                    builder: (context, state) => Container(
                      height: DsSegmented.segmentHeight,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: widget.value == _views[i]
                            ? DsColors.ctaBg
                            : state.hovered
                            ? DsColors.lineHairline
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(
                          DsRadii.control - 4,
                        ),
                      ),
                      child: Text(
                        _labels[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textStyle.copyWith(
                          color: widget.value == _views[i]
                              ? DsColors.ctaFg
                              : DsColors.textBody,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class DossierMapBand extends StatefulWidget {
  const DossierMapBand({
    super.key,
    required this.dossierCase,
    required this.cases,
    required this.connections,
    required this.onOpenCase,
    this.pending = DossierPending.none,
    this.canOpenCase = true,
  });

  static const flyToCaseDelay = Duration(milliseconds: 1100);
  static const double heightDesktop = 600;
  static const double cardWidthDesktop = 360;
  final TrueCrimeCase dossierCase;
  final List<TrueCrimeCase> cases;
  final List<CaseConnection> connections;
  final ValueChanged<String> onOpenCase;

  /// Si se ofrece «Abrir expediente» al enfocar otro caso. Falso en la vista
  /// previa de un borrador, desde la que no se navega a otros casos.
  final bool canOpenCase;

  /// Datos que faltan en un borrador. Sin coordenadas el mapa se queda en
  /// Mundo y no coloca ningún marcador del caso.
  final DossierPending pending;

  @override
  State<DossierMapBand> createState() => _DossierMapBandState();
}

class _DossierMapBandState extends State<DossierMapBand> {
  late TrueCrimeCase _focus;
  late List<DsMapMarker> _markers;
  _MapView _view = _MapView.world;
  Timer? _timer;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _focus = widget.dossierCase;
    _markers = [for (final c in widget.cases) c.toMapMarker()];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    if (widget.pending.coordinates) {
      // No hay punto al que volar: se queda en la vista del mundo.
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _view = _MapView.focused;
    } else {
      _timer = Timer(DossierMapBand.flyToCaseDelay, () {
        if (mounted) setState(() => _view = _MapView.focused);
      });
    }
  }

  @override
  void didUpdateWidget(DossierMapBand oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.cases, widget.cases)) {
      _markers = [for (final c in widget.cases) c.toMapMarker()];
    }
    if (oldWidget.dossierCase.id != widget.dossierCase.id) {
      _focus = widget.dossierCase;
    } else {
      for (final c in widget.cases) {
        if (c.id == _focus.id) _focus = c;
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _select(_MapView view) {
    _timer?.cancel();
    setState(() => _view = view);
  }

  void _focusCase(TrueCrimeCase crimeCase) {
    _timer?.cancel();
    setState(() {
      _focus = crimeCase;
      _view = _MapView.focused;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 1200;
    final offset = mobile
        ? 0.0
        : DsMapProjection.verticalOffsetDesktopDossierBand;
    final byId = {
      for (final c in widget.cases) c.id: c,
      widget.dossierCase.id: widget.dossierCase,
    };
    final links = [
      for (final link in widget.connections)
        if (link.otherId(_focus.id) != null &&
            byId.containsKey(link.otherId(_focus.id)))
          link,
    ];
    final related = [for (final link in links) byId[link.otherId(_focus.id)]!];
    Offset point(TrueCrimeCase c) =>
        DsMapProjection.project(c.latitude, c.longitude) + Offset(0, offset);
    final layout = mobile ? DsMapLayout.mobile : DsMapLayout.desktop;
    // Lo pendiente es del caso del expediente; otro caso enfocado en el mapa
    // tiene sus propias coordenadas.
    final locationPending =
        widget.pending.coordinates && _focus.id == widget.dossierCase.id;
    final view = locationPending ? _MapView.world : _view;
    final camera = switch (view) {
      _MapView.world => DsMapCameraTargets.world(
        view: mobile ? DsMapWorldView.mobileBand : DsMapWorldView.desktop,
      ),
      _MapView.focused => DsMapCameraTargets.focusCase(
        casePoint: point(_focus),
        layout: layout,
      ),
      _MapView.connections => DsMapCameraTargets.connections(
        points: [point(_focus), ...related.map(point)],
        layout: layout,
      ),
    };
    final isWorld = view == _MapView.world;
    return SizedBox(
      key: DossierMapKeys.band,
      height: mobile ? 880 : DossierMapBand.heightDesktop,
      child: Stack(
        children: [
          Positioned.fill(
            child: DsMapScene(
              markers: _markers,
              camera: camera,
              selectedId: isWorld ? null : _focus.id,
              relatedIds: isWorld ? const {} : related.map((c) => c.id).toSet(),
              connections: isWorld
                  ? const []
                  : connectionsForCase(_focus.id, links),
              showConnectionLabels: view == _MapView.connections,
              mobile: mobile,
              verticalOffset: offset,
              onMarkerTap: (id) {
                final c = byId[id];
                if (c != null) _focusCase(c);
              },
            ),
          ),
          Positioned(
            left: mobile ? 16 : 80,
            top: mobile ? 16 : 64,
            width: mobile
                ? MediaQuery.sizeOf(context).width - 32
                : DossierMapBand.cardWidthDesktop,
            child: Container(
              key: DossierMapKeys.locationCard,
              constraints: BoxConstraints(maxHeight: mobile ? 600 : 420),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: DsColors.surfaceGlass,
                border: Border.all(color: DsColors.lineHairline),
                borderRadius: BorderRadius.circular(18),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'UBICACIÓN',
                      style: TextStyle(
                        color: DsColors.accentRedText,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      _focus.title,
                      style: const TextStyle(
                        color: DsColors.textStrong,
                        fontFamily: 'NotoSerifDisplay',
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                      ),
                    ),
                    Text(
                      _placeLine(),
                      style: const TextStyle(color: DsColors.textBody),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _coordinate(
                            'LATITUD',
                            _focus.latitude,
                            'N',
                            'S',
                            pending: locationPending,
                          ),
                        ),
                        Expanded(
                          child: _coordinate(
                            'LONGITUD',
                            _focus.longitude,
                            'E',
                            'O',
                            pending: locationPending,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'CASOS CONECTADOS',
                      style: TextStyle(color: DsColors.textMuted, fontSize: 11),
                    ),
                    if (links.isEmpty)
                      const Text(
                        'Sin conexiones documentadas.',
                        style: TextStyle(color: DsColors.textMuted),
                      ),
                    for (final link in links)
                      Builder(
                        builder: (context) {
                          final connected = byId[link.otherId(_focus.id)]!;
                          return DsPressable(
                            key: DossierMapKeys.connectedCase(connected.id),
                            semanticLabel:
                                '${connected.title}\n${link.relation}',
                            onTap: () => _focusCase(connected),
                            builder: (context, state) => Container(
                              constraints: const BoxConstraints(minHeight: 52),
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: DsColors.surfaceCard,
                                border: Border.all(
                                  color: DsColors.lineHairline,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: connected.category.designColor.dot,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          connected.title,
                                          style: const TextStyle(
                                            color: DsColors.textStrong,
                                            fontFamily: 'NotoSerifDisplay',
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          link.relation,
                                          style: const TextStyle(
                                            color: DsColors.textMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward,
                                    color: DsColors.textMuted,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    if (widget.canOpenCase &&
                        _focus.id != widget.dossierCase.id)
                      TextButton(
                        key: DossierMapKeys.openCase,
                        onPressed: () => widget.onOpenCase(_focus.slug),
                        child: const Text('Abrir expediente'),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: mobile ? 16 : 80,
            top: mobile ? 650 : 64,
            child: Container(
              key: DossierMapKeys.legend,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DsColors.surfaceGlass,
                border: Border.all(color: DsColors.lineHairline),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final entry in [
                    ('Asesinos en serie', DsCategoryColors.serialKiller.dot),
                    ('Asesinato aislado', DsCategoryColors.isolatedMurder.dot),
                    ('Secuestro', DsCategoryColors.kidnapping.dot),
                    ('Caso sin resolver', DsCategoryColors.unsolved.dot),
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: entry.$2,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            entry.$1,
                            style: const TextStyle(
                              color: DsColors.textBody,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            right: mobile ? 8 : 80,
            bottom: mobile ? 20 : 56,
            width: mobile
                ? (MediaQuery.sizeOf(context).width - 16).clamp(0.0, 344.0)
                : 344,
            child: Semantics(
              label: 'Vista del mapa',
              container: true,
              child: Container(
                key: DossierMapKeys.viewSwitcher,
                color: DsColors.surfaceGlass,
                child: _MapViewSelector(
                  value: view,
                  onChanged: locationPending ? (_) {} : _select,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Lugar · país · año del caso enfocado; lo que falta en un borrador se
  /// dice pendiente en lugar de inventarse.
  String _placeLine() {
    final pending = widget.pending;
    if (_focus.id != widget.dossierCase.id) {
      return '${_focus.regionOrCity} · ${_focus.country} · ${_focus.year}';
    }
    const missing = DossierPending.placeholder;
    return [
      pending.region ? missing : _focus.regionOrCity,
      pending.country ? missing : _focus.country,
      pending.year ? missing : '${_focus.year}',
    ].join(' · ');
  }

  Widget _coordinate(
    String label,
    double value,
    String positive,
    String negative, {
    bool pending = false,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: DsColors.textMuted, fontSize: 11),
      ),
      Text(
        pending
            ? DossierPending.placeholder
            : '${value.abs().toStringAsFixed(2)}° ${value >= 0 ? positive : negative}',
        style: TextStyle(
          color: pending ? DsColors.textMuted : DsColors.accentGold,
          fontSize: 14,
        ),
      ),
    ],
  );
}
