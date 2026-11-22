import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

/// A moldura do editor: barra de cima, corpo e barra de status. As laterais
/// (fichário, inspetor) entram na Fase 1.
class EditorTemplate extends StatelessWidget {
  const EditorTemplate({super.key, required this.toolbar, required this.body, required this.statusBar});

  final Widget toolbar, body, statusBar;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: QuillTokens.of(context).colors.frame,
        child: Column(children: [toolbar, Expanded(child: body), statusBar]),
      );
}
