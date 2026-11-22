import 'package:flutter/widgets.dart';

import '../tokens/tokens.dart';

enum WLabelTone { normal, muted, danger }

/// Texto da interface (não do documento), com o tipo e a cor do tema.
class WLabel extends StatelessWidget {
  const WLabel(this.text, {super.key, this.tone = WLabelTone.normal, this.small = false});

  final String text;
  final WLabelTone tone;
  final bool small;

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
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: color, fontSize: small ? t.font.small : t.font.ui, fontFamily: t.font.family),
    );
  }
}
