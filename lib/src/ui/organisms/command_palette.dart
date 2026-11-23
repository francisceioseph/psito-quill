// A paleta de comandos (Ctrl+K): digita o nome, Enter roda. Setas para
// cima e para baixo escolhem; Esc fecha.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../commands/command_registry.dart';
import '../../commands/menus.dart';
import '../../commands/palette_search.dart';
import '../atoms/w_label.dart';
import '../atoms/w_text_field.dart';
import '../tokens/tokens.dart';

/// Abre a paleta; devolve o id do comando rodado, ou null.
Future<String?> showCommandPalette(BuildContext context, CommandRegistry commands) => showDialog<String>(
      context: context,
      barrierColor: QuillTokens.of(context).colors.frame.withValues(alpha: 0),
      builder: (_) => CommandPalette(commands: commands),
    );

class CommandPalette extends StatefulWidget {
  const CommandPalette({super.key, required this.commands});
  final CommandRegistry commands;

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  final _query = TextEditingController();
  int _index = 0;

  List<PaletteEntry> _results(AppLocalizations l10n) =>
      searchCommands(widget.commands, editorMenus(l10n), _query.text);

  void _run(PaletteEntry e) {
    Navigator.of(context).pop(e.command.id);
    // Depois de fechar: o comando pode abrir outra tela.
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.commands.run(e.command.id));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final results = _results(l10n);
    _index = results.isEmpty ? 0 : _index.clamp(0, results.length - 1);
    return Align(
      alignment: const Alignment(0, -0.6),
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: 520,
          constraints: const BoxConstraints(maxHeight: 420),
          decoration: BoxDecoration(
            color: t.colors.frameRaised,
            borderRadius: BorderRadius.circular(t.radius.panel),
            border: Border.all(color: t.colors.border),
            boxShadow: [BoxShadow(color: t.colors.onFrame.withValues(alpha: 0.18), blurRadius: 24)],
          ),
          padding: EdgeInsets.all(t.space.md),
          child: Focus(
            onKeyEvent: (_, e) {
              if (e is KeyUpEvent) return KeyEventResult.ignored;
              if (e.logicalKey == LogicalKeyboardKey.arrowDown) {
                setState(() => _index = results.isEmpty ? 0 : (_index + 1) % results.length);
                return KeyEventResult.handled;
              }
              if (e.logicalKey == LogicalKeyboardKey.arrowUp) {
                setState(() => _index = results.isEmpty ? 0 : (_index - 1) % results.length);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              WTextField(
                label: l10n.commandPalette,
                hint: l10n.paletteHint,
                controller: _query,
                autofocus: true,
                onChanged: (_) => setState(() => _index = 0),
                onSubmitted: (_) {
                  if (results.isNotEmpty) _run(results[_index]);
                },
              ),
              SizedBox(height: t.space.sm),
              if (results.isEmpty)
                Padding(
                  padding: EdgeInsets.all(t.space.md),
                  child: WLabel(l10n.paletteEmpty, tone: WLabelTone.muted),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: results.length,
                    itemBuilder: (context, i) => _PaletteRow(
                      entry: results[i],
                      shortcut: widget.commands.shortcutLabelOf(results[i].command.id),
                      selected: i == _index,
                      onTap: () => _run(results[i]),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _PaletteRow extends StatelessWidget {
  const _PaletteRow({required this.entry, required this.shortcut, required this.selected, required this.onTap});

  final PaletteEntry entry;
  final String? shortcut;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final c = entry.command;
    return Semantics(
      button: true,
      selected: selected,
      label: c.label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          color: selected ? t.colors.accentSoft : null,
          padding: EdgeInsets.symmetric(horizontal: t.space.md, vertical: t.space.sm),
          child: ExcludeSemantics(
            child: Row(children: [
              Icon(c.icon, size: 18, color: t.colors.onFrame),
              SizedBox(width: t.space.md),
              Expanded(child: WLabel(c.label)),
              if (entry.menu case final m?) ...[
                WLabel(m, small: true, tone: WLabelTone.muted),
                SizedBox(width: t.space.md),
              ],
              if (shortcut case final s?) WLabel(s, small: true, tone: WLabelTone.muted),
            ]),
          ),
        ),
      ),
    );
  }
}
