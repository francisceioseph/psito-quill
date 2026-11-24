// WCheckbox: uma caixa de marcar com o texto ao lado, para listas de escolha
// (os capítulos do compilar). O clique no texto também marca. No Clássico 97,
// a caixinha com bisel, como a do WSwitch.
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../tokens/tokens.dart';
import 'w_label.dart';

class WCheckbox extends StatefulWidget {
  const WCheckbox({super.key, required this.value, required this.label, this.onChanged, this.trailing, this.muted = false});

  final bool value;

  /// O texto ao lado e o nome para o leitor de tela.
  final String label;
  final ValueChanged<bool>? onChanged;

  /// O que vem na ponta direita (as palavras do capítulo), sem nome próprio.
  final String? trailing;

  /// O texto mais apagado (uma parte, que não se marca sozinha).
  final bool muted;

  @override
  State<WCheckbox> createState() => _WCheckboxState();
}

class _WCheckboxState extends State<WCheckbox> {
  bool _focused = false;

  void _toggle() => widget.onChanged?.call(!widget.value);

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final c = t.colors;
    final on = widget.value;
    final enabled = widget.onChanged != null;
    final Widget box;
    if (t.component == ComponentStyle.bevel) {
      final hi = BorderSide(color: c.bevelDark, width: 1.5), lo = BorderSide(color: c.bevelLight, width: 1.5);
      box = Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(color: c.surfaceLowest, border: Border(top: hi, left: hi, bottom: lo, right: lo)),
        child: on ? Icon(Symbols.check_rounded, size: 14, color: c.onFrame, weight: 700) : null,
      );
    } else {
      box = Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: on ? c.accent : null,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: on ? c.accent : c.outline, width: 2),
        ),
        child: on ? Icon(Symbols.check_rounded, size: 14, color: c.onAccent, weight: 700) : null,
      );
    }
    return Semantics(
      container: true,
      checked: on,
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
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? _toggle : null,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: t.space.xs, vertical: t.space.xs),
            decoration: _focused
                ? BoxDecoration(border: Border.all(color: c.focusRing, width: 2), borderRadius: BorderRadius.circular(t.radius.control))
                : null,
            child: ExcludeSemantics(
              child: Opacity(
                opacity: enabled ? 1 : 0.38,
                child: Row(children: [
                  box,
                  SizedBox(width: t.space.sm),
                  Expanded(child: WLabel(widget.label, tone: widget.muted ? WLabelTone.muted : WLabelTone.normal)),
                  if (widget.trailing != null) WLabel(widget.trailing!, small: true, tone: WLabelTone.muted),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
