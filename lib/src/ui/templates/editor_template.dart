import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

/// A moldura do editor: a faixa em cima, um aviso opcional, o corpo e a
/// barra de status. As laterais (fichário, inspetor) entram nas fases 2 e 3.
class EditorTemplate extends StatelessWidget {
  const EditorTemplate({super.key, required this.ribbon, required this.body, required this.statusBar, this.banner});

  final Widget ribbon, body, statusBar;
  final Widget? banner;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: QuillTokens.of(context).colors.frame,
        child: Column(children: [
          ribbon,
          ?banner,
          Expanded(child: body),
          statusBar,
        ]),
      );
}
