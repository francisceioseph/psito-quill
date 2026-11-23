import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

/// A moldura do editor: em cima, a faixa (ou os menus e as barras do tema
/// 97); um aviso e a barra de localizar, opcionais; a página com o painel
/// Formatar à direita; a barra de status. O fichário, à esquerda, entra na
/// Fase 3.
class EditorTemplate extends StatelessWidget {
  const EditorTemplate({
    super.key,
    required this.top,
    required this.body,
    required this.statusBar,
    this.banner,
    this.findBar,
    this.sidePanel,
  });

  final Widget top, body, statusBar;
  final Widget? banner, findBar, sidePanel;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: QuillTokens.of(context).colors.frame,
        child: Column(children: [
          top,
          ?banner,
          ?findBar,
          Expanded(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(child: body),
              ?sidePanel,
            ]),
          ),
          statusBar,
        ]),
      );
}
