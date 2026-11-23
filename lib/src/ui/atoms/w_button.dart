// Átomos de botão: WButton (ação), WToggle (liga/desliga) e WTextButton
// (só texto: abas da faixa, itens do painel Arquivo). Todos sobre a mesma
// superfície, WControlSurface, que o WDropdown também usa.
//
// Leem só os tokens. O desenho muda com o ComponentStyle do tema
// (Strategy): moderno com raio e realce suave, ou bisel 3D do tema 97.
import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

class WButton extends StatelessWidget {
  const WButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.showLabel = false,
    this.tooltip,
  });

  final IconData icon;

  /// Também é o nome para o leitor de tela e a dica.
  final String label;
  final VoidCallback? onPressed;
  final bool showLabel;

  /// A dica, se for diferente do rótulo ("Salvar (Ctrl+B)").
  final String? tooltip;

  @override
  Widget build(BuildContext context) => WControlSurface(
        icon: icon,
        text: showLabel ? label : null,
        tooltip: tooltip ?? label,
        onPressed: onPressed,
        selected: false,
        semantics: (child) => Semantics(container: true, button: true, enabled: onPressed != null, label: label, child: child),
      );
}

/// Um botão só de texto. [selected] marca a aba atual.
class WTextButton extends StatelessWidget {
  const WTextButton({super.key, required this.label, this.onPressed, this.selected = false, this.icon, this.autofocus = false});

  final String label;
  final bool autofocus;
  final VoidCallback? onPressed;
  final bool selected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => WControlSurface(
        icon: icon,
        text: label,
        tooltip: null,
        autofocus: autofocus,
        onPressed: onPressed,
        selected: selected,
        semantics: (child) =>
            Semantics(container: true, button: true, selected: selected, enabled: onPressed != null, label: label, child: child),
      );
}

class WToggle extends StatelessWidget {
  const WToggle({super.key, required this.icon, required this.label, required this.value, this.onPressed, this.tooltip});

  final IconData icon;
  final String label;
  final String? tooltip;

  /// Ligado? O valor vem do estado do motor, não do clique.
  final bool value;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => WControlSurface(
        icon: icon,
        tooltip: tooltip ?? label,
        onPressed: onPressed,
        selected: value,
        semantics: (child) =>
            Semantics(container: true, button: true, toggled: value, enabled: onPressed != null, label: label, child: child),
      );
}

/// A superfície comum dos controles: ícone e/ou texto, realce de mouse e de
/// foco, Enter/Espaço pelo teclado, e o desenho moderno ou bisel.
///
/// Clicar não tira o foco do documento (como na faixa do Word): só o Tab
/// foca um controle.
class WControlSurface extends StatefulWidget {
  const WControlSurface({
    super.key,
    this.icon,
    this.text,
    this.trailingIcon,
    this.width,
    this.outlined = false,
    this.autofocus = false,
    required this.tooltip,
    required this.onPressed,
    required this.selected,
    required this.semantics,
  });

  final IconData? icon;
  final String? text;

  /// Uma seta, nos campos de lista.
  final IconData? trailingIcon;

  /// Largura fixa (campos de lista); null: a do conteúdo.
  final double? width;

  /// Com contorno, como um campo (no estilo moderno).
  final bool outlined;
  final bool autofocus;
  final String? tooltip;
  final VoidCallback? onPressed;
  final bool selected;
  final Widget Function(Widget) semantics;

  @override
  State<WControlSurface> createState() => _ControlSurfaceState();
}

class _ControlSurfaceState extends State<WControlSurface> {
  bool _hover = false, _pressed = false, _focused = false;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final c = t.colors;
    final enabled = widget.onPressed != null;
    final fg = !enabled
        ? c.onFrameMuted.withValues(alpha: 0.5)
        : widget.selected && t.component == ComponentStyle.modern
            ? c.accent
            : c.onFrame;

    final text = widget.text;
    final label = text == null
        ? null
        : Text(text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: fg, fontSize: t.font.ui, fontFamily: t.font.family));
    final content = Row(mainAxisSize: widget.width == null ? MainAxisSize.min : MainAxisSize.max, children: [
      if (widget.icon case final icon?) Icon(icon, size: 20, color: fg),
      if (widget.icon != null && label != null) SizedBox(width: t.space.sm),
      if (label != null) widget.width == null ? Flexible(child: label) : Expanded(child: label),
      if (widget.trailingIcon case final trailing?) ...[
        SizedBox(width: t.space.xs),
        Icon(trailing, size: 18, color: fg),
      ],
    ]);

    final decoration = switch (t.component) {
      ComponentStyle.modern => BoxDecoration(
          color: widget.selected
              ? c.accentSoft
              : _pressed
                  ? c.border
                  : _hover
                      ? c.frameRaised
                      : null,
          borderRadius: BorderRadius.circular(t.radius.control),
          border: _focused
              ? Border.all(color: c.focusRing, width: 2)
              : widget.outlined
                  ? Border.all(color: c.border)
                  : null,
        ),
      // Bisel: claro em cima e à esquerda; afundado (invertido) se ligado ou
      // apertado.
      ComponentStyle.bevel => () {
          final down = widget.selected || _pressed;
          final hi = BorderSide(color: down ? c.bevelDark : c.bevelLight, width: 1.5);
          final lo = BorderSide(color: down ? c.bevelLight : c.bevelDark, width: 1.5);
          return BoxDecoration(
            color: c.frameRaised,
            border: Border(top: hi, left: hi, bottom: lo, right: lo),
            boxShadow: _focused ? [BoxShadow(color: c.focusRing, spreadRadius: 1)] : null,
          );
        }(),
    };

    final surface = FocusableActionDetector(
          enabled: enabled,
          autofocus: widget.autofocus,
          mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onShowHoverHighlight: (v) => setState(() => _hover = v),
          onShowFocusHighlight: (v) => setState(() => _focused = v),
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
              widget.onPressed?.call();
              return null;
            }),
          },
          child: GestureDetector(
            onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
            onTapCancel: () => setState(() => _pressed = false),
            onTap: enabled
                ? () {
                    setState(() => _pressed = false);
                    widget.onPressed!();
                  }
                : null,
            child: AnimatedContainer(
              duration: t.motion.fast,
              width: widget.width,
              constraints: BoxConstraints(minHeight: t.density.control, minWidth: t.density.control),
              padding: EdgeInsets.symmetric(horizontal: t.space.md),
              alignment: Alignment.center,
              decoration: decoration,
              // O nome para o leitor de tela vem do Semantics de fora.
              child: ExcludeSemantics(child: content),
            ),
          ),
        );
    final tip = widget.tooltip;
    return widget.semantics(
      tip == null ? surface : Tooltip(message: tip, waitDuration: const Duration(milliseconds: 600), child: surface),
    );
  }
}
