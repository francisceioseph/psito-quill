// Uma ação de painel (D-056): um botão com contorno na largura toda, com o
// ícone e o nome do comando. Uma embaixo da outra, os nomes longos ("Novo
// estilo a partir da seleção…") cabem, e o que não couber vai na dica.
import 'package:flutter/material.dart';

import '../../commands/command_registry.dart';
import '../atoms/w_button.dart';

class PanelAction extends StatelessWidget {
  const PanelAction({super.key, required this.commands, required this.id, this.onRan});

  final CommandRegistry commands;
  final String id;
  final VoidCallback? onRan;

  @override
  Widget build(BuildContext context) {
    final c = commands[id];
    if (c == null) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, box) => WControlSurface(
        width: box.maxWidth.isFinite ? box.maxWidth : null,
        outlined: true,
        icon: c.icon,
        text: c.label,
        tooltip: commands.tooltipOf(id),
        selected: false,
        onPressed: c.enabled
            ? () {
                commands.run(id);
                onRan?.call();
              }
            : null,
        semantics: (child) => Semantics(container: true, button: true, enabled: c.enabled, label: c.label, child: child),
      ),
    );
  }
}
