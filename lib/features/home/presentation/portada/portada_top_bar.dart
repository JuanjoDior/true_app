import 'package:flutter/material.dart'
    show Icons, InputBorder, InputDecoration, TextField;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/design/design.dart';
import 'portada_shell_keys.dart';

/// Barra superior de la portada: marca, enlaces y búsqueda sobre el héroe.
///
/// En anchos estrechos queda la marca y un icono que despliega el buscador.
/// Buscar no filtra aquí: entrega la consulta a [onSubmitSearch].
class PortadaTopBar extends StatefulWidget {
  const PortadaTopBar({
    super.key,
    required this.initialQuery,
    required this.onHome,
    required this.onOpenForm,
    this.onSubmitSearch,
    this.onOpenMap,
    this.onOpenArchive,
  });

  final String initialQuery;
  final VoidCallback onHome;
  final VoidCallback onOpenForm;

  /// Nulo oculta el buscador, también la lupa de la versión estrecha.
  final ValueChanged<String>? onSubmitSearch;

  /// Nulo oculta el enlace «Mapa».
  final VoidCallback? onOpenMap;

  /// Nulo oculta el enlace: sin navegación no hay directorio al que ir.
  final VoidCallback? onOpenArchive;

  static const double desktopHeight = 96;
  static const double compactHeight = 68;
  static const double searchWidth = 300;
  static const double controlHeight = 44;

  @override
  State<PortadaTopBar> createState() => _PortadaTopBarState();
}

class _PortadaTopBarState extends State<PortadaTopBar> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialQuery,
  );
  bool _searchOpen = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String value) => widget.onSubmitSearch?.call(value.trim());

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < DsBreakpoints.desktop;
    return DecoratedBox(
      key: PortadaShellKeys.topBar,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            DsColors.bgBase.withValues(alpha: 0.85),
            DsColors.bgBase.withValues(alpha: 0),
          ],
        ),
      ),
      child: SizedBox(
        height: compact
            ? PortadaTopBar.compactHeight
            : PortadaTopBar.desktopHeight,
        child: compact ? _compactRow() : _desktopRow(),
      ),
    );
  }

  Widget _desktopRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.pageMarginDesktop,
      ),
      child: Row(
        spacing: DsSpacing.s48,
        children: [
          const _Logo(compact: false),
          Row(
            spacing: DsSpacing.s8,
            children: [
              _NavLink(
                key: PortadaShellKeys.topBarHome,
                label: 'Inicio',
                selected: true,
                onTap: widget.onHome,
              ),
              if (widget.onOpenMap != null)
                _NavLink(
                  key: PortadaShellKeys.topBarMap,
                  label: 'Mapa',
                  onTap: widget.onOpenMap!,
                ),
              if (widget.onOpenArchive != null)
                _NavLink(
                  key: PortadaShellKeys.topBarArchive,
                  label: 'Archivo',
                  onTap: widget.onOpenArchive!,
                ),
              _NavLink(
                key: PortadaShellKeys.topBarForm,
                label: 'Formulario',
                onTap: widget.onOpenForm,
              ),
            ],
          ),
          if (widget.onSubmitSearch != null)
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: PortadaTopBar.searchWidth,
                  ),
                  child: _SearchPill(
                    controller: _controller,
                    onSubmit: _submit,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _compactRow() {
    final searchable = widget.onSubmitSearch != null;
    return Padding(
      padding: const EdgeInsets.only(
        left: DsSpacing.pageMarginMobile,
        right: DsSpacing.s12,
      ),
      child: Row(
        spacing: DsSpacing.s8,
        children: [
          if (searchable && _searchOpen)
            Expanded(
              child: _SearchPill(
                controller: _controller,
                onSubmit: _submit,
                autofocus: true,
              ),
            )
          else ...[
            const _Logo(compact: true),
            const Spacer(),
          ],
          if (searchable)
            DsIconButton(
              key: PortadaShellKeys.searchToggle,
              icon: _searchOpen ? Icons.close_rounded : Icons.search_rounded,
              semanticLabel: _searchOpen ? 'Cerrar búsqueda' : 'Buscar',
              onPressed: () => setState(() => _searchOpen = !_searchOpen),
            ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final styles = DsTextStylesResolver.of(context);
    final side = compact ? 32.0 : 36.0;
    final fontSize = compact ? 18.0 : 20.0;
    return Row(
      spacing: compact ? DsSpacing.s10 : DsSpacing.s12,
      children: [
        Container(
          width: side,
          height: side,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: DsColors.accentRed,
            borderRadius: BorderRadius.circular(compact ? 9 : 10),
          ),
          child: Text(
            'T',
            style: styles.displaySection.copyWith(
              fontSize: fontSize,
              color: DsColors.textStrong,
            ),
          ),
        ),
        Text(
          'TRUE',
          style: styles.displaySection.copyWith(
            fontSize: fontSize,
            letterSpacing: fontSize * 0.1,
            color: DsColors.textStrong,
          ),
        ),
      ],
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final styles = DsTextStylesResolver.of(context);
    return DsPressable(
      onTap: onTap,
      semanticLabel: label,
      selected: selected,
      minTapTarget: const Size(0, PortadaTopBar.controlHeight),
      builder: (context, state) => Container(
        height: PortadaTopBar.controlHeight,
        padding: const EdgeInsets.symmetric(horizontal: DsSpacing.s16),
        alignment: Alignment.center,
        child: Text(
          label,
          style: styles.body.copyWith(
            fontSize: 15,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected || state.hovered
                ? DsColors.textStrong
                : DsColors.textBody,
          ),
        ),
      ),
    );
  }
}

class _SearchPill extends StatefulWidget {
  const _SearchPill({
    required this.controller,
    required this.onSubmit,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmit;
  final bool autofocus;

  @override
  State<_SearchPill> createState() => _SearchPillState();
}

class _SearchPillState extends State<_SearchPill> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final styles = DsTextStylesResolver.of(context);
    final fieldStyle = styles.body.copyWith(
      fontSize: 14,
      color: DsColors.textStrong,
    );
    return Container(
      height: PortadaTopBar.controlHeight,
      padding: const EdgeInsets.symmetric(horizontal: DsSpacing.s16),
      decoration: BoxDecoration(
        color: DsColors.lineHairline,
        borderRadius: DsRadii.pillBorder,
        border: Border.all(
          color: _focused ? DsColors.accentRedText : DsColors.ctaGlass,
        ),
      ),
      child: Row(
        spacing: DsSpacing.s10,
        children: [
          const Icon(
            Icons.search_rounded,
            size: DsSpacing.s18,
            color: DsColors.textBody,
          ),
          Expanded(
            child: Semantics(
              label: 'Buscar casos',
              child: Focus(
                canRequestFocus: false,
                onFocusChange: (value) => setState(() => _focused = value),
                child: TextField(
                  key: PortadaShellKeys.searchField,
                  controller: widget.controller,
                  autofocus: widget.autofocus,
                  textInputAction: TextInputAction.search,
                  onSubmitted: widget.onSubmit,
                  cursorColor: DsColors.accentRed,
                  style: fieldStyle,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: 'Buscar por nombre, lugar o año…',
                    hintStyle: fieldStyle.copyWith(
                      color: DsColors.textPlaceholder,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
