import 'package:flutter/material.dart';

import '../theme/ds_text_styles_resolver.dart';
import '../tokens/tokens.dart';

class DsFormField extends StatefulWidget {
  const DsFormField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.errorText,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.maxLines = 1,
    this.autofillHints,
    this.focusNode,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? helper;

  /// Con valor, el campo pasa a estado de error y el texto sustituye al de ayuda.
  final String? errorText;
  final bool enabled;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;

  /// Filas visibles: con más de una, el campo mide esas filas de alto.
  final int maxLines;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;

  static const Key boxKey = ValueKey('ds-form-field-box');
  static const double minHeight = 48;
  static const double haloSpread = 3;
  static const double _haloAlpha = 0.25;
  static const double _borderWidth = 1;
  // 48 de alto = línea de 24 + 2 × 11 + borde de 1 px por lado
  static const double _verticalPadding = 11;

  @override
  State<DsFormField> createState() => _DsFormFieldState();
}

class _DsFormFieldState extends State<DsFormField> {
  FocusNode? _ownNode;
  bool _focused = false;

  FocusNode get _node => widget.focusNode ?? (_ownNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(DsFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownNode)?.removeListener(_onFocusChange);
      _node.addListener(_onFocusChange);
      _focused = _node.hasFocus;
    }
  }

  @override
  void dispose() {
    _node.removeListener(_onFocusChange);
    _ownNode?.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focused != _node.hasFocus) setState(() => _focused = _node.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final styles = DsTextStylesResolver.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final errorText = widget.errorText;
    final helper = widget.helper;
    final hasError = errorText != null;
    final focused = widget.enabled && _focused;

    final borderColor = hasError
        ? DsColors.accentRedText
        : focused
        ? DsColors.accentRed
        : DsColors.lineInput;
    final inputStyle = styles.body.copyWith(
      color: widget.enabled ? DsColors.textPrimary : DsColors.textPlaceholder,
    );
    final labelStyle = styles.uiButton.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: DsColors.textBody,
    );
    final noteStyle = styles.body.copyWith(fontSize: 12, height: 1.4);

    // TextField con decoración colapsada dentro de un contenedor propio: el
    // halo exterior no cabe en InputDecoration y TextField conserva selección,
    // autocompletado e IME. El relleno va en contentPadding para que todo el
    // contenedor reciba el toque
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(child: Text(widget.label, style: labelStyle)),
        const SizedBox(height: DsSpacing.s8),
        AnimatedContainer(
          key: DsFormField.boxKey,
          duration: DsMotion.resolve(
            DsMotion.press,
            reduceMotion: reduceMotion,
          ),
          curve: DsMotion.easeUi,
          constraints: const BoxConstraints(minHeight: DsFormField.minHeight),
          decoration: BoxDecoration(
            color: DsColors.surfaceInput,
            borderRadius: DsRadii.controlBorder,
            border: Border.all(
              color: borderColor,
              width: DsFormField._borderWidth,
            ),
            // Siempre una sombra: así el halo solo cambia de color, sin saltos
            boxShadow: [
              BoxShadow(
                color: focused
                    ? DsColors.accentRed.withValues(
                        alpha: DsFormField._haloAlpha,
                      )
                    : DsColors.transparent,
                spreadRadius: DsFormField.haloSpread,
              ),
            ],
          ),
          child: Semantics(
            label: widget.label,
            textField: true,
            enabled: widget.enabled,
            child: TextField(
              controller: widget.controller,
              focusNode: _node,
              enabled: widget.enabled,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              autofillHints: widget.autofillHints,
              maxLines: widget.maxLines,
              minLines: widget.maxLines,
              style: inputStyle,
              cursorColor: DsColors.accentRedText,
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                hoverColor: DsColors.transparent,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: DsSpacing.s16,
                  vertical: DsFormField._verticalPadding,
                ),
                hintText: widget.hint,
                hintStyle: inputStyle.copyWith(color: DsColors.textPlaceholder),
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: DsSpacing.s8),
            child: Semantics(
              liveRegion: true,
              container: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: ExcludeSemantics(
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: 16,
                        color: DsColors.accentRedText,
                      ),
                    ),
                  ),
                  const SizedBox(width: DsSpacing.s8),
                  Expanded(
                    child: Text(
                      errorText,
                      style: noteStyle.copyWith(color: DsColors.accentRedText),
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (helper != null)
          Padding(
            padding: const EdgeInsets.only(top: DsSpacing.s8),
            child: Text(
              helper,
              style: noteStyle.copyWith(color: DsColors.textFaint),
            ),
          ),
      ],
    );
  }
}
