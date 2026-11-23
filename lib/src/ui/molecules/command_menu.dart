// Os menus de comandos (Fase 2B, Etapa 7, D-049): cada item com o ícone, o
// nome, o atalho à direita e a marca quando está ligado, como nos menus do
// Office. Servem à faixa (um grupo recolhido, o "mais" de um grupo) e ao
// menu de contexto. Os itens só existem enquanto o menu está aberto.
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../commands/command_registry.dart';
import '../atoms/w_button.dart';
import '../tokens/tokens.dart';

/// Um separador entre os itens de um menu de comandos.
const commandMenuDivider = '-';

/// Os itens de menu para os comandos [ids] ([commandMenuDivider] separa).
List<Widget> commandMenuItems(BuildContext context, CommandRegistry commands, List<String> ids, {VoidCallback? onRan}) {
  final t = QuillTokens.of(context);
  final c = t.colors;
  final items = <Widget>[];
  for (final id in ids) {
    if (id == commandMenuDivider) {
      if (items.isNotEmpty && items.last is! Divider) items.add(Divider(height: t.space.md, color: c.border));
      continue;
    }
    final cmd = commands[id];
    if (cmd == null) continue;
    final shortcut = commands.shortcutLabelOf(id);
    final on = cmd.active;
    final fg = cmd.enabled ? c.onFrame : c.onFrame.withValues(alpha: 0.38);
    items.add(MenuItemButton(
      leadingIcon: Icon(cmd.icon, size: t.density.icon - 2, color: fg, fill: on ? 1 : 0),
      trailingIcon: on
          ? Icon(Symbols.check_rounded, size: t.density.icon - 4, color: c.accent)
          : shortcut == null
              ? null
              : Padding(
                  padding: EdgeInsets.only(left: t.space.xl),
                  child: Text(shortcut, style: TextStyle(color: c.onFrameMuted, fontSize: t.font.small, fontFamily: t.font.family)),
                ),
      onPressed: cmd.enabled
          ? () {
              commands.run(id);
              onRan?.call();
            }
          : null,
      child: Text(cmd.label, style: TextStyle(color: fg, fontSize: t.font.ui, fontFamily: t.font.family)),
    ));
  }
  if (items.isNotEmpty && items.last is Divider) items.removeLast();
  return items;
}

/// Um botão que abre um menu de comandos: grande (um grupo recolhido da
/// faixa, com o nome do grupo) ou pequeno (o "mais" de um grupo).
class CommandMenuButton extends StatelessWidget {
  const CommandMenuButton({
    super.key,
    required this.commands,
    required this.ids,
    required this.icon,
    required this.label,
    this.big = false,
    this.width,
    this.onRan,
  });

  final CommandRegistry commands;
  final List<String> ids;
  final IconData icon;
  final String label;
  final bool big;
  final double? width;
  final VoidCallback? onRan;

  @override
  Widget build(BuildContext context) {
    final enabled = ids.any((id) => commands[id]?.enabled ?? false);
    return MenuAnchor(
      onClose: onRan,
      menuChildren: commandMenuItems(context, commands, ids),
      builder: (context, controller, _) {
        void toggle() => controller.isOpen ? controller.close() : controller.open();
        return big
            ? WBigButton(icon: icon, label: label, width: width, dropdown: true, onPressed: enabled ? toggle : null)
            : WButton(icon: icon, label: label, onPressed: enabled ? toggle : null);
      },
    );
  }
}
