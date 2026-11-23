import 'package:flutter/widgets.dart';

import '../atoms/w_label.dart';
import '../tokens/tokens.dart';

/// Um grupo da faixa: os controles em uma ou duas linhas e o nome embaixo,
/// como no Word, com a divisória à direita. O nome também agrupa os
/// controles para o leitor de tela.
///
/// [leading] fica à esquerda das linhas, na altura toda (o Colar grande).
class RibbonGroup extends StatelessWidget {
  const RibbonGroup({super.key, required this.title, required this.firstRow, this.secondRow, this.leading, this.last = false});

  final String title;
  final List<Widget> firstRow;
  final List<Widget>? secondRow;
  final Widget? leading;

  /// O último grupo não tem divisória (fica transparente, para todos terem a
  /// mesma largura de moldura).
  final bool last;

  /// O espaço entre dois controles de uma linha (e entre as linhas).
  static double gapOf(QuillTokens t) => t.space.sm;

  /// A largura de um botão grande (ícone em cima do nome).
  static double bigWidthOf(QuillTokens t) => t.density.control * 2 + t.space.md;

  /// O que a moldura do grupo ocupa de largura: as margens e a divisória.
  static double chromeOf(QuillTokens t) => _padOf(t) * 2 + 1;
  static double _padOf(QuillTokens t) => t.space.md + t.space.sm;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    Widget row(List<Widget> items) => Row(mainAxisSize: MainAxisSize.min, children: [
          for (final (i, c) in items.indexed) ...[
            if (i > 0) SizedBox(width: gapOf(t)),
            c,
          ],
        ]);
    final second = secondRow;
    final rows = Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      row(firstRow),
      if (second != null) ...[SizedBox(height: gapOf(t)), row(second)],
    ]);
    return Semantics(
      container: true,
      label: title,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: _padOf(t)),
        decoration: BoxDecoration(border: Border(right: BorderSide(color: last ? t.colors.border.withValues(alpha: 0) : t.colors.border))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (leading case final l?) ...[l, SizedBox(width: t.space.sm)],
            rows,
          ]),
          SizedBox(height: t.space.xs),
          ExcludeSemantics(child: WLabel(title, small: true, tone: WLabelTone.muted)),
        ]),
      ),
    );
  }
}
