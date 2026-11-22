import 'package:flutter/material.dart';

import '../atoms/w_label.dart';
import '../tokens/tokens.dart';

/// Um campo da barra de status.
class StatusField {
  const StatusField(this.text, {this.tone = WLabelTone.muted, this.flex = false});
  final String text;
  final WLabelTone tone;

  /// Ocupa o espaço que sobra (a mensagem).
  final bool flex;
}

class StatusBar extends StatelessWidget {
  const StatusBar({super.key, required this.fields});

  final List<StatusField> fields;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    return Container(
      height: t.density.statusBar,
      padding: EdgeInsets.symmetric(horizontal: t.space.lg),
      decoration: BoxDecoration(
        color: t.colors.frame,
        border: Border(top: BorderSide(color: t.colors.border)),
      ),
      child: Row(children: [
        for (final (i, f) in fields.indexed) ...[
          if (i > 0) SizedBox(width: t.space.xl),
          if (f.flex)
            Expanded(child: WLabel(f.text, tone: f.tone, small: true))
          else
            WLabel(f.text, tone: f.tone, small: true),
        ],
      ]),
    );
  }
}
