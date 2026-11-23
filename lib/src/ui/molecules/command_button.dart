import 'package:flutter/widgets.dart';

import '../../commands/command_registry.dart';
import '../atoms/w_button.dart';

/// Um comando do registro como botão: WToggle se tem estado (negrito),
/// WButton se não. A dica traz o atalho do jogo atual.
class CommandButton extends StatelessWidget {
  const CommandButton({super.key, required this.commands, required this.id, this.onRan, this.showLabel = false});

  final CommandRegistry commands;
  final String id;

  /// Depois de rodar (a página devolve o foco ao documento).
  final VoidCallback? onRan;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final c = commands[id];
    if (c == null) return const SizedBox.shrink();
    final tip = commands.tooltipOf(id);
    final run = c.enabled
        ? () {
            commands.run(id);
            onRan?.call();
          }
        : null;
    return c.isActive != null
        ? WToggle(icon: c.icon, label: c.label, tooltip: tip, value: c.active, onPressed: run)
        : WButton(icon: c.icon, label: c.label, tooltip: tip, showLabel: showLabel, onPressed: run);
  }
}
