// Um comando de ligar e desligar como caixa de seleção (a aba Exibir, D-065):
// a caixa e o nome, como nas abas Ver do Word e do OnlyOffice.
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../commands/command_registry.dart';
import '../atoms/w_button.dart';

class CommandCheck extends StatelessWidget {
  const CommandCheck({super.key, required this.commands, required this.id, this.onRan, this.width = 168});

  final CommandRegistry commands;
  final String id;
  final VoidCallback? onRan;
  final double width;

  @override
  Widget build(BuildContext context) {
    final c = commands[id];
    if (c == null) return const SizedBox.shrink();
    final on = c.active;
    return WControlSurface(
      width: width,
      icon: on ? Symbols.check_box_rounded : Symbols.check_box_outline_blank_rounded,
      text: c.label,
      tooltip: commands.tooltipOf(id),
      selected: false,
      onPressed: c.enabled
          ? () {
              commands.run(id);
              onRan?.call();
            }
          : null,
      semantics: (child) => Semantics(
        container: true,
        checked: on,
        enabled: c.enabled,
        label: c.label,
        child: child,
      ),
    );
  }
}
