// WSwitch: liga e desliga uma preferência (Foco sempre visível, Reduzir
// movimento). O desenho do Material 3: trilho de 52×32, a bolinha cresce
// quando liga. No Clássico 97 vira uma caixinha de marcar com bisel.
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../tokens/tokens.dart';

class WSwitch extends StatefulWidget {
  const WSwitch({super.key, required this.value, required this.label, this.onChanged});

  final bool value;

  /// O nome para o leitor de tela (o texto ao lado fica com quem usa).
  final String label;
  final ValueChanged<bool>? onChanged;

  @override
  State<WSwitch> createState() => _WSwitchState();
}

class _WSwitchState extends State<WSwitch> {
  bool _focused = false;

  void _toggle() => widget.onChanged?.call(!widget.value);

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final c = t.colors;
    final on = widget.value;
    final enabled = widget.onChanged != null;
    final Widget face;
    if (t.component == ComponentStyle.bevel) {
      final hi = BorderSide(color: c.bevelDark, width: 1.5), lo = BorderSide(color: c.bevelLight, width: 1.5);
      face = Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(color: c.surfaceLowest, border: Border(top: hi, left: hi, bottom: lo, right: lo)),
        child: on ? Icon(Symbols.check_rounded, size: 14, color: c.onFrame, weight: 700) : null,
      );
    } else {
      final knob = on ? 24.0 : 16.0;
      face = AnimatedContainer(
        duration: t.motion.fast,
        width: 52,
        height: 32,
        padding: EdgeInsets.symmetric(horizontal: on ? 2 : 6),
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: on ? c.accent : c.surfaceHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: on ? c.accent : c.outline, width: 2),
        ),
        child: AnimatedContainer(
          duration: t.motion.fast,
          width: knob,
          height: knob,
          decoration: BoxDecoration(color: on ? c.onAccent : c.outline, shape: BoxShape.circle),
        ),
      );
    }
    return Semantics(
      container: true,
      toggled: on,
      enabled: enabled,
      label: widget.label,
      child: FocusableActionDetector(
        enabled: enabled,
        mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
            _toggle();
            return null;
          }),
        },
        child: GestureDetector(
          onTap: enabled ? _toggle : null,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: _focused
                ? BoxDecoration(border: Border.all(color: c.focusRing, width: 2), borderRadius: BorderRadius.circular(20))
                : null,
            child: ExcludeSemantics(child: Opacity(opacity: enabled ? 1 : 0.38, child: face)),
          ),
        ),
      ),
    );
  }
}
