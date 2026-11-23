import 'package:flutter/widgets.dart';

import '../tokens/tokens.dart';

enum WLabelTone { normal, muted, danger }

/// Texto da interface (não do documento), com o tipo e a cor do tema.
class WLabel extends StatelessWidget {
  const WLabel(this.text, {super.key, this.tone = WLabelTone.normal, this.small = false, this.heading = false, this.maxLines = 1});

  final String text;
  final WLabelTone tone;
  final bool small;

  /// Título de seção (maior e mais forte).
  final bool heading;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final color = switch (tone) {
      WLabelTone.normal => t.colors.onFrame,
      WLabelTone.muted => t.colors.onFrameMuted,
      WLabelTone.danger => t.colors.danger,
    };
    return Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color,
        fontSize: heading ? t.font.title : (small ? t.font.small : t.font.ui),
        fontWeight: heading ? FontWeight.w600 : null,
        fontFamily: t.font.family,
      ),
    );
  }
}
