// Átomos de botão: WButton (ação) e WToggle (liga/desliga).
//
// Os dois leem só os tokens. O desenho muda com o ComponentStyle do tema
// (Strategy): moderno com raio e realce suave, ou bisel 3D do tema 97.
import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

class WButton extends StatelessWidget {
  const WButton({super.key, required this.icon, required this.label, this.onPressed, this.showLabel = false});

  final IconData icon;

  /// Também é o nome para o leitor de tela e a dica.
  final String label;
  final VoidCallback? onPressed;
  final bool showLabel;

  @override
  Widget build(BuildContext context) => _ControlSurface(
        icon: icon,
        label: label,
        showLabel: showLabel,
        onPressed: onPressed,
        selected: false,
        semantics: (child) => Semantics(button: true, enabled: onPressed != null, label: label, child: child),
      );
}

class WToggle extends StatelessWidget {
  const WToggle({super.key, required this.icon, required this.label, required this.value, this.onPressed});

  final IconData icon;
  final String label;

  /// Ligado? O valor vem do estado do motor, não do clique.
  final bool value;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => _ControlSurface(
        icon: icon,
        label: label,
        showLabel: false,
        onPressed: onPressed,
        selected: value,
        semantics: (child) =>
            Semantics(button: true, toggled: value, enabled: onPressed != null, label: label, child: child),
      );
}

class _ControlSurface extends StatefulWidget {
  const _ControlSurface({
    required this.icon,
    required this.label,
    required this.showLabel,
    required this.onPressed,
    required this.selected,
    required this.semantics,
  });

  final IconData icon;
  final String label;
  final bool showLabel;
  final VoidCallback? onPressed;
  final bool selected;
  final Widget Function(Widget) semantics;

  @override
  State<_ControlSurface> createState() => _ControlSurfaceState();
}

class _ControlSurfaceState extends State<_ControlSurface> {
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

    final content = Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(widget.icon, size: 20, color: fg),
      if (widget.showLabel) ...[
        SizedBox(width: t.space.sm),
        Text(widget.label, style: TextStyle(color: fg, fontSize: t.font.ui, fontFamily: t.font.family)),
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
          border: _focused ? Border.all(color: c.focusRing, width: 2) : null,
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

    return widget.semantics(
      Tooltip(
        message: widget.label,
        waitDuration: const Duration(milliseconds: 600),
        child: FocusableActionDetector(
          enabled: enabled,
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
              constraints: BoxConstraints(minHeight: t.density.control, minWidth: t.density.control),
              padding: EdgeInsets.symmetric(horizontal: t.space.md),
              alignment: Alignment.center,
              decoration: decoration,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
