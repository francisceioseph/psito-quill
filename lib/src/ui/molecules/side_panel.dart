// Um painel ao lado da página (Estrutura e Estilos à esquerda, Formatar à
// direita): o título, o botão de fechar e o conteúdo. O título também é o
// nome do painel para o leitor de tela.
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../atoms/w_button.dart';
import '../atoms/w_label.dart';
import '../tokens/tokens.dart';

class SidePanel extends StatelessWidget {
  const SidePanel({
    super.key,
    required this.title,
    required this.closeLabel,
    required this.onClose,
    required this.child,
    this.width = 280,
    this.side = AxisDirection.right,
  });

  final String title;

  /// "Fechar o painel (F10)".
  final String closeLabel;
  final VoidCallback onClose;
  final Widget child;
  final double width;

  /// De que lado da página fica: a divisória é do lado dela (no Clássico 97).
  final AxisDirection side;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final c = t.colors;
    final bevel = t.component == ComponentStyle.bevel;
    final edge = BorderSide(color: bevel ? c.border : c.border.withValues(alpha: 0.5));
    final horiz = t.space.lg + t.space.sm; // 12 + 4 = 16 px equilibrados
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: title,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: c.frame,
          border: Border(
            left: side == AxisDirection.right ? edge : BorderSide.none,
            right: side == AxisDirection.left ? edge : BorderSide.none,
          ),
        ),
        padding: EdgeInsets.fromLTRB(horiz, t.space.md, horiz, t.space.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Semantics(header: true, child: WLabel(title, heading: true))),
            WButton(icon: Symbols.close_rounded, label: closeLabel, onPressed: onClose),
          ]),
          SizedBox(height: t.space.sm),
          Expanded(child: child),
        ]),
      ),
    );
  }
}
