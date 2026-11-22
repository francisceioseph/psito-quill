import 'package:flutter/material.dart';

import '../../commands/command_registry.dart';
import '../atoms/w_button.dart';
import '../tokens/tokens.dart';

/// Barra de ferramentas mínima da Fase 0: os botões saem do CommandRegistry.
/// Comandos com estado (isActive) viram WToggle; os outros, WButton.
class Toolbar extends StatelessWidget {
  const Toolbar({super.key, required this.commands, required this.ids, this.trailing = const []});

  final CommandRegistry commands;
  final List<String> ids;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    return ListenableBuilder(
      listenable: commands,
      builder: (context, _) => Container(
        height: t.density.toolbar,
        padding: EdgeInsets.symmetric(horizontal: t.space.md),
        decoration: BoxDecoration(
          color: t.colors.frame,
          border: Border(bottom: BorderSide(color: t.colors.border)),
        ),
        child: Row(children: [
          for (final id in ids)
            if (commands[id] case final c?)
              Padding(
                padding: EdgeInsets.only(right: t.space.sm),
                child: c.isActive != null
                    ? WToggle(icon: c.icon, label: c.label, value: c.active, onPressed: c.enabled ? c.run : null)
                    : WButton(icon: c.icon, label: c.label, onPressed: c.enabled ? c.run : null),
              ),
          const Spacer(),
          ...trailing,
        ]),
      ),
    );
  }
}
