import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

/// A moldura do editor (Fase 2B): em cima, a faixa (ou os menus e as barras
/// do tema 97); um aviso, opcional; no meio, o
/// trilho e o painel da esquerda, a página (com a régua, na Etapa 4) e o
/// painel Formatar à direita, com o trilho das seções dele na ponta (Etapa
/// 7, D-062); embaixo, a barra de status.
class EditorTemplate extends StatelessWidget {
  const EditorTemplate({
    super.key,
    required this.top,
    required this.body,
    required this.statusBar,
    this.banner,
    this.rail,
    this.leftPanel,
    this.ruler,
    this.sidePanel,
    this.rightRail,
  });

  final Widget top, body, statusBar;
  final Widget? banner, rail, leftPanel, ruler, sidePanel, rightRail;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final c = t.colors;
    final modern = t.component == ComponentStyle.modern;
    // A página fica sobre o tom de trás, num cartão de cantos redondos no
    // desenho moderno; os painéis, sobre a superfície da janela.
    final page = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ?ruler,
      Expanded(child: body),
    ]);
    return ColoredBox(
      color: c.frame,
      child: Column(children: [
        top,
        ?banner,
        Expanded(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ?rail,
            ?leftPanel,
            Expanded(
              child: modern
                  ? Padding(
                      padding: EdgeInsets.only(top: t.space.sm, left: rail == null && leftPanel == null ? t.space.sm : 0, right: sidePanel == null && rightRail == null ? t.space.sm : 0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(t.radius.panel)),
                        child: ColoredBox(color: c.backdrop, child: page),
                      ),
                    )
                  : page,
            ),
            ?sidePanel,
            ?rightRail,
          ]),
        ),
        statusBar,
      ]),
    );
  }
}
