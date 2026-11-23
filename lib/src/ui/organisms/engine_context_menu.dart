// O menu do clique direito: as sugestões de ortografia vêm do motor; o
// resto (recortar, copiar, colar, tabela, imagem) vem do CommandRegistry.
import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../commands/command_registry.dart';
import '../../commands/commands_document.dart';
import '../../document/document_controller.dart';
import '../../kit/quill_kit.dart';
import '../tokens/tokens.dart';

const _suggestion = '.uno:SpellCheckApplySuggestion';
const _ignore = '.uno:SpellCheckIgnore?';
const _ignoreAll = '.uno:SpellCheckIgnoreAll';

/// O que vai no menu. Um item é um comando do motor (String que começa com
/// ".uno:") ou um id do registro.
sealed class ContextEntry {
  const ContextEntry();
}

class EngineEntry extends ContextEntry {
  const EngineEntry(this.label, this.command);
  final String label, command;
}

class CommandEntry extends ContextEntry {
  const CommandEntry(this.id);
  final String id;
}

class SeparatorEntry extends ContextEntry {
  const SeparatorEntry();
}

/// Monta o menu a partir do que o motor mandou. Função pura, testada.
List<ContextEntry> contextEntries(
  List<EngineMenuItem> engine,
  AppLocalizations l10n, {
  required bool inTable,
  required bool onImage,
}) {
  final out = <ContextEntry>[];
  for (final i in engine) {
    if (i.command.startsWith(_suggestion)) {
      out.add(EngineEntry(i.text, i.command));
    } else if (i.command.startsWith(_ignore)) {
      out.add(EngineEntry(l10n.contextIgnore, i.command));
    } else if (i.command.startsWith(_ignoreAll)) {
      out.add(EngineEntry(l10n.contextIgnoreAll, i.command));
    }
  }
  if (out.isNotEmpty) out.add(const SeparatorEntry());
  out.addAll(const [CommandEntry(CommandIds.cut), CommandEntry(CommandIds.copy), CommandEntry(CommandIds.paste)]);
  if (inTable) {
    out.addAll(const [
      SeparatorEntry(),
      CommandEntry(CommandIds.rowAbove),
      CommandEntry(CommandIds.rowBelow),
      CommandEntry(CommandIds.columnLeft),
      CommandEntry(CommandIds.columnRight),
      CommandEntry(CommandIds.deleteRow),
      CommandEntry(CommandIds.deleteColumn),
    ]);
  }
  if (onImage) {
    out.addAll(const [
      SeparatorEntry(),
      CommandEntry(CommandIds.wrapOff),
      CommandEntry(CommandIds.wrapIdeal),
      CommandEntry(CommandIds.wrapThrough),
    ]);
  }
  return out;
}

/// Mostra o menu em [position] (global) e roda o escolhido.
Future<void> showEngineContextMenu(
  BuildContext context, {
  required Offset position,
  required DocumentController doc,
  required CommandRegistry commands,
  required List<EngineMenuItem> engine,
}) async {
  final t = QuillTokens.of(context);
  final l10n = AppLocalizations.of(context);
  final entries = contextEntries(engine, l10n, inTable: doc.inTable, onImage: doc.graphic != null);
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  final style = TextStyle(color: t.colors.onFrame, fontSize: t.font.ui, fontFamily: t.font.family);
  final chosen = await showMenu<ContextEntry>(
    context: context,
    position: RelativeRect.fromRect(position & const Size(1, 1), Offset.zero & overlay.size),
    items: [
      for (final e in entries)
        switch (e) {
          SeparatorEntry() => const PopupMenuDivider(),
          EngineEntry(:final label) => PopupMenuItem(
              value: e,
              height: t.density.control,
              child: Text(label, style: style.copyWith(fontWeight: FontWeight.w600)),
            ),
          CommandEntry(:final id) => PopupMenuItem(
              value: e,
              height: t.density.control,
              enabled: commands[id]?.enabled ?? false,
              child: Row(children: [
                Icon(commands[id]?.icon, size: 18, color: t.colors.onFrame),
                SizedBox(width: t.space.md),
                Expanded(child: Text(commands[id]?.label ?? id, style: style)),
                if (commands.shortcutLabelOf(id) case final s?)
                  Text(s, style: style.copyWith(color: t.colors.onFrameMuted, fontSize: t.font.small)),
              ]),
            ),
        },
    ],
  );
  switch (chosen) {
    case EngineEntry(:final command):
      doc.runEngineCommand(command);
    case CommandEntry(:final id):
      commands.run(id);
    case SeparatorEntry() || null:
      break;
  }
}
