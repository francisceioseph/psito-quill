// Um cartão de estilo na galeria da faixa: uma amostra desenhada no papel e
// o nome embaixo, como no Office 2007. O aplicado tem a borda da marca.
//
// A amostra usa as propriedades de verdade do estilo (a cópia temporária,
// D-044): a fonte, o tamanho relativo, o peso, o itálico, o alinhamento e a
// cor. Sem a cópia ainda, uma amostra genérica pelo tipo do estilo.
import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

/// Como a amostra é desenhada: o tamanho relativo, o peso e o itálico.
@immutable
class StyleSample {
  const StyleSample({
    required this.text,
    this.scale = 1,
    this.bold = false,
    this.italic = false,
    this.center = false,
    this.fontFamily,
    this.rgb,
  });
  final String text;
  final double scale;
  final bool bold, italic, center;

  /// A fonte do estilo (do sistema, pelo fontconfig); null: uma com serifa.
  final String? fontFamily;

  /// A cor do estilo (0xRRGGBB, do documento); null: a tinta do papel.
  final int? rgb;
}

const _opaque = 0xFF000000;

class StyleCard extends StatefulWidget {
  const StyleCard({
    super.key,
    required this.name,
    required this.sample,
    required this.semanticLabel,
    required this.selected,
    this.onPressed,
    this.shortcut,
    this.width = 92,
  });

  /// O atalho do estilo ("Ctrl+Alt+1"), na galeria aberta.
  final String? shortcut;
  final double width;

  final String name;
  final StyleSample sample;

  /// "Estilo Título 1" ou "Estilo Corpo de texto, aplicado".
  final String semanticLabel;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  State<StyleCard> createState() => _StyleCardState();
}

class _StyleCardState extends State<StyleCard> {
  bool _hover = false, _focused = false;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final c = t.colors;
    final modern = t.component == ComponentStyle.modern;
    final s = widget.sample;
    final enabled = widget.onPressed != null;
    final edge = _focused
        ? BorderSide(color: c.focusRing, width: 2)
        : widget.selected
            ? BorderSide(color: modern ? c.accent : c.onFrame, width: 2)
            : BorderSide(color: _hover ? c.outline : c.border);
    final card = Container(
      width: widget.width,
      height: t.density.control * 2 - 6,
      padding: EdgeInsets.symmetric(horizontal: 8 - (edge.width - 1), vertical: 5 - (edge.width - 1)),
      decoration: BoxDecoration(
        color: c.paper,
        border: Border.fromBorderSide(edge),
        borderRadius: BorderRadius.circular(modern ? t.radius.control : 0),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(
          s.text,
          maxLines: 1,
          overflow: TextOverflow.clip,
          softWrap: false,
          textAlign: s.center ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            // A cor do documento, menos o preto (some no papel escuro).
            color: s.rgb == null || s.rgb == 0 ? c.paperInk : Color(s.rgb! | _opaque),
            fontSize: 13 * s.scale,
            height: 1.1,
            fontWeight: s.bold ? FontWeight.w700 : FontWeight.w400,
            fontStyle: s.italic ? FontStyle.italic : FontStyle.normal,
            fontFamily: s.fontFamily ?? 'serif',
          ),
        ),
        Row(children: [
          Expanded(
            child: Text(
              widget.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: c.onFrameMuted, fontSize: 10, fontWeight: FontWeight.w500, fontFamily: t.font.family),
            ),
          ),
          if (widget.shortcut case final k?)
            Text(k, style: TextStyle(color: c.onFrameMuted, fontSize: 9, fontFamily: t.font.family)),
        ]),
      ]),
    );
    return Semantics(
      container: true,
      button: true,
      selected: widget.selected,
      enabled: enabled,
      label: widget.semanticLabel,
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
        child: GestureDetector(onTap: widget.onPressed, child: ExcludeSemantics(child: card)),
      ),
    );
  }
}
