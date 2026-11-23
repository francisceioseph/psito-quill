// O menu do clique direito (Etapa 7, D-061): as sugestões de ortografia vêm
// do motor; o resto (recortar, copiar, colar, tabela, imagem, os submenus
// Estilo e Parágrafo) vem do CommandRegistry, com os ícones, os atalhos e o
// desenho dos menus de comandos da faixa.
//
// É um MenuAnchor (submenus, teclado e leitor de tela de graça) numa camada
// do Overlay que só existe enquanto o menu está aberto.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../commands/command_registry.dart';
import '../../commands/commands_document.dart';
import '../../commands/commands_view.dart';
import '../../document/document_controller.dart';
import '../../kit/quill_kit.dart';
import '../molecules/command_menu.dart';
import '../tokens/tokens.dart';

const _suggestion = '.uno:SpellCheckApplySuggestion';
const _ignore = '.uno:SpellCheckIgnore?';
const _ignoreAll = '.uno:SpellCheckIgnoreAll';

/// O que vai no menu.
sealed class ContextEntry {
  const ContextEntry();
}

/// Um comando do motor (as sugestões e o "Ignorar").
class EngineEntry extends ContextEntry {
  const EngineEntry(this.label, this.command);
  final String label, command;
}

/// Um comando do registro.
class CommandEntry extends ContextEntry {
  const CommandEntry(this.id);
  final String id;
}

class SeparatorEntry extends ContextEntry {
  const SeparatorEntry();
}

/// Um submenu de comandos do registro ([commandMenuDivider] separa).
class SubmenuEntry extends ContextEntry {
  const SubmenuEntry(this.label, this.icon, this.ids);
  final String label;
  final IconData icon;
  final List<String> ids;
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
  out.addAll([
    const SeparatorEntry(),
    SubmenuEntry(l10n.contextStyle, Symbols.style_rounded, const [
      ViewCommandIds.newStyle,
      ViewCommandIds.updateStyle,
      commandMenuDivider,
      ViewCommandIds.manageStyles,
    ]),
    SubmenuEntry(l10n.contextParagraph, Symbols.format_paragraph_rounded, const [
      CommandIds.keepWithNext,
      CommandIds.separateFromNext,
      commandMenuDivider,
      CommandIds.keepLines,
      CommandIds.splitLines,
      commandMenuDivider,
      CommandIds.pageBreak,
    ]),
    const CommandEntry(CommandIds.clearFormatting),
    const SeparatorEntry(),
    const CommandEntry(CommandIds.selectAll),
  ]);
  return out;
}

/// Os itens do menu (construídos só ao abrir).
List<Widget> contextMenuChildren(
  BuildContext context, {
  required List<ContextEntry> entries,
  required DocumentController doc,
  required CommandRegistry commands,
}) {
  final t = QuillTokens.of(context);
  final c = t.colors;
  final style = TextStyle(color: c.onFrame, fontSize: t.font.ui, fontFamily: t.font.family);
  final out = <Widget>[];
  for (final e in entries) {
    switch (e) {
      case SeparatorEntry():
        if (out.isNotEmpty && out.last is! Divider) out.add(Divider(height: t.space.md, color: c.border));
      case EngineEntry(:final label, :final command):
        final suggestion = command.startsWith(_suggestion);
        out.add(MenuItemButton(
          leadingIcon: Icon(
            suggestion ? Symbols.spellcheck_rounded : Symbols.visibility_off_rounded,
            size: t.density.icon - 2,
            color: c.onFrame,
          ),
          onPressed: () => doc.runEngineCommand(command),
          child: Text(label, style: suggestion ? style.copyWith(fontWeight: FontWeight.w600) : style),
        ));
      case CommandEntry(:final id):
        out.addAll(commandMenuItems(context, commands, [id]));
      case SubmenuEntry(:final label, :final icon, :final ids):
        final children = commandMenuItems(context, commands, ids);
        if (children.isEmpty) continue;
        out.add(SubmenuButton(
          leadingIcon: Icon(icon, size: t.density.icon - 2, color: c.onFrame),
          menuChildren: children,
          child: Text(label, style: style),
        ));
    }
  }
  if (out.isNotEmpty && out.last is Divider) out.removeLast();
  return out;
}

/// Mostra o menu em [position] (global) e espera ele fechar.
Future<void> showEngineContextMenu(
  BuildContext context, {
  required Offset position,
  required DocumentController doc,
  required CommandRegistry commands,
  required List<EngineMenuItem> engine,
}) async {
  final l10n = AppLocalizations.of(context);
  final entries = contextEntries(engine, l10n, inTable: doc.inTable, onImage: doc.graphic != null);
  final overlay = Overlay.of(context);
  final box = overlay.context.findRenderObject()! as RenderBox;
  final at = box.globalToLocal(position);
  final controller = MenuController();
  final closed = Completer<void>();
  final entry = OverlayEntry(
    builder: (context) => Positioned(
      left: at.dx,
      top: at.dy,
      child: MenuAnchor(
        controller: controller,
        onClose: () {
          if (!closed.isCompleted) closed.complete();
        },
        menuChildren: contextMenuChildren(context, entries: entries, doc: doc, commands: commands),
        child: const SizedBox(width: 1, height: 1),
      ),
    ),
  );
  overlay.insert(entry);
  SchedulerBinding.instance.addPostFrameCallback((_) {
    if (entry.mounted) controller.open();
  });
  await closed.future;
  // O item escolhido roda depois do quadro em que o menu fecha: a camada sai
  // só depois disso.
  SchedulerBinding.instance.addPostFrameCallback((_) => entry.remove());
}
