// Uma seção do painel Formatar: o título e os controles embaixo. O título
// agrupa os controles para o leitor de tela.
import 'package:flutter/material.dart';

import '../atoms/w_label.dart';
import '../tokens/tokens.dart';

class InspectorSection extends StatelessWidget {
  const InspectorSection({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: title,
      child: Container(
        padding: EdgeInsets.all(t.space.md),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.colors.border))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ExcludeSemantics(child: WLabel(title, heading: true)),
          SizedBox(height: t.space.sm),
          for (final (i, c) in children.indexed) ...[
            if (i > 0) SizedBox(height: t.space.sm),
            c,
          ],
        ]),
      ),
    );
  }
}

/// Uma linha rotulada: o nome à esquerda e o controle à direita.
class LabeledRow extends StatelessWidget {
  const LabeledRow({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: WLabel(label, small: true, tone: WLabelTone.muted)),
        child,
      ]);
}
