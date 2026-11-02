import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import 'case_form_section.dart';

/// Permite a quien aloja el [IntakeEditor] pedir que se desplace a una
/// sección, por ejemplo desde la lista de campos obligatorios.
class IntakeEditorController extends ChangeNotifier {
  int? _requested;
  int _revision = 0;

  /// Última sección pedida y un contador que distingue peticiones repetidas
  /// a la misma sección. Uso interno del editor.
  ({int index, int revision})? get request {
    final index = _requested;
    return index == null ? null : (index: index, revision: _revision);
  }

  /// Desplaza el editor hasta la tarjeta [index]. Un índice fuera del
  /// registro no hace nada.
  void scrollToSection(int index) {
    _requested = index;
    _revision++;
    notifyListeners();
  }
}

/// Editor central del formulario de casos: cada sección del registro es una
/// tarjeta numerada, con una navegación fija arriba que lleva a cada una.
/// No conoce los campos: los pinta cada sección tal como hoy.
class IntakeEditor extends StatefulWidget {
  const IntakeEditor({super.key, this.sections, this.controller, this.header});

  /// Secciones a mostrar; por defecto, el registro [kCaseFormSections].
  final List<CaseFormSection>? sections;

  final IntakeEditorController? controller;

  /// Cabecera opcional (título del borrador, estado) sobre la navegación.
  final Widget? header;

  @override
  State<IntakeEditor> createState() => _IntakeEditorState();
}

class _IntakeEditorState extends State<IntakeEditor> {
  final _scrollController = ScrollController();
  final _viewportKey = GlobalKey();
  late List<GlobalKey> _cardKeys;
  int _current = 0;

  /// Mientras un desplazamiento pedido (toque o controlador) está en marcha,
  /// el scroll no debe recalcular la pastilla activa: pasaría por las
  /// secciones intermedias y la barra parpadearía.
  int _navigations = 0;

  List<CaseFormSection> get _sections => widget.sections ?? kCaseFormSections;

  @override
  void initState() {
    super.initState();
    _cardKeys = _newKeys();
    widget.controller?.addListener(_onRequest);
    _scrollController.addListener(_syncCurrentWithScroll);
  }

  @override
  void didUpdateWidget(IntakeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onRequest);
      widget.controller?.addListener(_onRequest);
    }
    if (_cardKeys.length != _sections.length) {
      _cardKeys = _newKeys();
      _current = 0;
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onRequest);
    _scrollController.removeListener(_syncCurrentWithScroll);
    _scrollController.dispose();
    super.dispose();
  }

  List<GlobalKey> _newKeys() => [for (final _ in _sections) GlobalKey()];

  void _onRequest() {
    final request = widget.controller?.request;
    if (request != null) {
      unawaited(_goTo(request.index));
    }
  }

  /// Sección activa con el desplazamiento manual: la última tarjeta cuyo borde
  /// superior ya ha llegado (con un margen) a la parte alta del editor. Al
  /// final del recorrido, las últimas tarjetas no llegan arriba y gana la
  /// última.
  void _syncCurrentWithScroll() {
    if (_navigations > 0 || !_scrollController.hasClients) {
      return;
    }
    final viewport = _viewportKey.currentContext?.findRenderObject();
    if (viewport is! RenderBox || !viewport.attached) {
      return;
    }
    final viewportTop = viewport.localToGlobal(Offset.zero).dy;
    final position = _scrollController.position;
    var active = 0;
    if (position.maxScrollExtent > 0 &&
        position.pixels >= position.maxScrollExtent - 1) {
      active = _cardKeys.length - 1;
    } else {
      for (var i = 0; i < _cardKeys.length; i++) {
        final box = _cardKeys[i].currentContext?.findRenderObject();
        if (box is! RenderBox || !box.attached) {
          continue;
        }
        final top = box.localToGlobal(Offset.zero).dy - viewportTop;
        if (top <= _activationOffset) {
          active = i;
        }
      }
    }
    if (active != _current) {
      setState(() => _current = active);
    }
  }

  Future<void> _goTo(int index) async {
    if (index < 0 || index >= _cardKeys.length) {
      return;
    }
    setState(() => _current = index);
    final context = _cardKeys[index].currentContext;
    if (context == null) {
      return;
    }
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    _navigations++;
    try {
      await Scrollable.ensureVisible(
        context,
        alignment: 0,
        duration: DsMotion.resolve(DsMotion.hover, reduceMotion: reduceMotion),
        curve: DsMotion.easeUi,
      );
    } finally {
      _navigations--;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sections;
    final compact = MediaQuery.sizeOf(context).width < DsBreakpoints.desktop;
    final margin = compact ? DsSpacing.s16 : DsSpacing.s32;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.header != null) widget.header!,
        _SectionNav(
          sections: sections,
          current: _current,
          margin: margin,
          onSelected: (index) => unawaited(_goTo(index)),
        ),
        Expanded(
          child: KeyedSubtree(
            key: _viewportKey,
            child: SingleChildScrollView(
              key: const Key('intake-editor-scroll'),
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(margin, DsSpacing.s24, margin, 64),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < sections.length; i++) ...[
                    if (i > 0) const SizedBox(height: DsSpacing.s20),
                    _SectionCard(
                      key: _cardKeys[i],
                      cardKey: Key('intake-editor-card-$i'),
                      index: i,
                      section: sections[i],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Distancia bajo el borde superior del editor a partir de la cual una tarjeta
/// cuenta como la sección actual: el padding superior más un margen.
const _activationOffset = DsSpacing.s24 + 16;

String _number(int index) => (index + 1).toString().padLeft(2, '0');

/// Tarjeta numerada de una sección: número mono, título editorial y, si
/// procede, la etiqueta «Opcional».
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    super.key,
    required this.cardKey,
    required this.index,
    required this.section,
  });

  final Key cardKey;
  final int index;
  final CaseFormSection section;

  @override
  Widget build(BuildContext context) {
    final styles = DsTextStylesResolver.of(context);
    final compact = MediaQuery.sizeOf(context).width < DsBreakpoints.desktop;

    // `Material` y no `DecoratedBox`: las filas con `ListTile` pintan su
    // fondo sobre el `Material` más cercano y un fondo intermedio lo taparía.
    return Material(
      key: cardKey,
      color: DsColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: DsColors.lineHairline),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? DsSpacing.s16 : DsSpacing.s24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                DsMonoLabel(
                  _number(index),
                  color: DsColors.accentRedText,
                  letterSpacingEm: 0.14,
                ),
                const SizedBox(width: DsSpacing.s12),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      section.title,
                      style: styles.displaySection.copyWith(
                        fontSize: compact ? 20 : 24,
                      ),
                    ),
                  ),
                ),
                if (section.optional) ...[
                  const SizedBox(width: DsSpacing.s12),
                  const DsMonoLabel('Opcional'),
                ],
              ],
            ),
            const SizedBox(height: DsSpacing.s18),
            Builder(builder: section.builder),
          ],
        ),
      ),
    );
  }
}

/// Navegación fija entre secciones: una pastilla numerada por tarjeta. En
/// pantallas estrechas se desplaza en horizontal en vez de comprimirse.
class _SectionNav extends StatelessWidget {
  const _SectionNav({
    required this.sections,
    required this.current,
    required this.margin,
    required this.onSelected,
  });

  final List<CaseFormSection> sections;
  final int current;
  final double margin;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = [
      for (var i = 0; i < sections.length; i++)
        _NavItem(
          key: Key('intake-editor-nav-$i'),
          number: _number(i),
          label: sections[i].navLabel ?? sections[i].title,
          selected: i == current,
          onTap: () => onSelected(i),
        ),
    ];

    return Semantics(
      container: true,
      label: 'Secciones del formulario',
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: DsColors.surfaceChrome,
          border: Border(bottom: BorderSide(color: DsColors.lineHairline)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(
            horizontal: margin,
            vertical: DsSpacing.s10,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  // Ancho natural: con un mínimo fijo las siete pastillas no
                  // caben en el editor de escritorio (800 px a 1440).
                  items[i],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    super.key,
    required this.number,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String number;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  @override
  void didUpdateWidget(_NavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // En la barra horizontal estrecha la pastilla activa puede quedar fuera
    // de vista tras un desplazamiento pedido desde fuera.
    if (widget.selected && !oldWidget.selected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Scrollable.ensureVisible(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final styles = DsTextStylesResolver.of(context);
    final number = widget.number;
    final label = widget.label;
    final selected = widget.selected;

    return DsPressable(
      onTap: widget.onTap,
      semanticLabel: 'Sección $number, $label',
      selected: selected,
      minTapTarget: const Size(0, 48),
      builder: (context, state) {
        final background = selected
            ? DsColors.textPrimary
            : state.hovered
            ? DsColors.ctaGlass
            : DsColors.surfaceCard;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: DsRadii.controlBorder,
            border: Border.all(
              color: selected ? DsColors.textPrimary : DsColors.lineHairline,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DsSpacing.s12,
              vertical: 6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Text(
                    number,
                    style: styles.monoLabel.copyWith(
                      color: selected ? DsColors.ctaFg : DsColors.textMuted,
                    ),
                  ),
                ),
                ExcludeSemantics(
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    style: styles.uiButton.copyWith(
                      fontSize: 13,
                      color: selected ? DsColors.ctaFg : DsColors.textBody,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
