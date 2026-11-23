import 'package:flutter/material.dart';

import '../atoms/w_label.dart';
import '../tokens/tokens.dart';

/// Um campo de texto da barra de status.
class StatusField {
  const StatusField(this.text, {this.tone = WLabelTone.muted, this.flex = false});
  final String text;
  final WLabelTone tone;

  /// Ocupa o espaço que sobra (a mensagem).
  final bool flex;
}

/// A barra de status: campos de texto e, no fim, controles (o zoom).
class StatusBar extends StatelessWidget {
  const StatusBar({super.key, required this.fields, this.trailing = const []});

  final List<StatusField> fields;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final bevel = t.component == ComponentStyle.bevel;
    // No tema 97, cada campo fica afundado (escuro em cima e à esquerda).
    Widget field(Widget child) => bevel
        ? Container(
            padding: EdgeInsets.symmetric(horizontal: t.space.sm, vertical: t.space.xs),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: t.colors.bevelDark),
                left: BorderSide(color: t.colors.bevelDark),
                bottom: BorderSide(color: t.colors.bevelLight),
                right: BorderSide(color: t.colors.bevelLight),
              ),
            ),
            child: child,
          )
        : child;
    return Container(
      height: t.density.statusBar + t.space.sm,
      padding: EdgeInsets.symmetric(horizontal: bevel ? t.space.xs : t.space.lg, vertical: bevel ? t.space.xs : 0),
      decoration: BoxDecoration(
        color: t.colors.frame,
        border: Border(top: BorderSide(color: t.colors.border)),
      ),
      child: Row(children: [
        for (final (i, f) in fields.indexed) ...[
          if (i > 0) SizedBox(width: bevel ? t.space.xs : t.space.xl),
          if (f.flex)
            Expanded(child: field(Semantics(liveRegion: true, child: WLabel(f.text, tone: f.tone, small: true))))
          else
            field(WLabel(f.text, tone: f.tone, small: true)),
        ],
        if (trailing.isNotEmpty) SizedBox(width: t.space.xl),
        ...trailing,
      ]),
    );
  }
}
