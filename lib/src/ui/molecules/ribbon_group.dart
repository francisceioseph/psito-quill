import 'package:flutter/widgets.dart';

import '../atoms/w_label.dart';
import '../tokens/tokens.dart';

/// Um grupo da faixa: os controles numa linha e o nome embaixo, como no
/// Word. O nome também agrupa os controles para o leitor de tela.
class RibbonGroup extends StatelessWidget {
  const RibbonGroup({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    return Semantics(
      container: true,
      label: title,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: t.space.sm),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            for (final (i, c) in children.indexed) ...[
              if (i > 0) SizedBox(width: t.space.xs),
              c,
            ],
          ]),
          SizedBox(height: t.space.xs),
          ExcludeSemantics(child: WLabel(title, small: true, tone: WLabelTone.muted)),
        ]),
      ),
    );
  }
}
