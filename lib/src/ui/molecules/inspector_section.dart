// Uma seção do painel Formatar: o título e os controles embaixo. O título
// agrupa os controles para o leitor de tela.
//
// O respiro (D-057b): 12 px entre um controle e o seguinte, e só 4 px entre o
// rótulo de um grupo ("Cor da fonte") e o controle dele, para o rótulo ficar
// colado no que nomeia e longe do grupo de cima.
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
    final bevel = t.component == ComponentStyle.bevel;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: title,
      child: Container(
        padding: EdgeInsets.fromLTRB(0, t.space.md, 0, t.space.lg),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: bevel ? t.colors.border : t.colors.border.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ExcludeSemantics(child: WLabel(title, heading: true)),
          SizedBox(height: t.space.md),
          for (final (i, c) in children.indexed) ...[
            if (i > 0) SizedBox(height: _isFieldLabel(children[i - 1]) ? t.space.sm : t.space.md),
            c,
          ],
        ]),
      ),
    );
  }
}

/// O rótulo pequeno de um grupo: o que vem embaixo dele é o controle dele.
bool _isFieldLabel(Widget w) => w is WLabel && w.small;

/// Um controle rotulado: o nome em cima, colado nele (D-062; antes, o nome
/// à esquerda e o controle espremido à direita).
class LabeledRow extends StatelessWidget {
  const LabeledRow({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      WLabel(label, small: true, tone: WLabelTone.muted),
      SizedBox(height: t.space.xs),
      child,
    ]);
  }
}
