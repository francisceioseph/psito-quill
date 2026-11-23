// O tema Clássico 97: a barra de menus completa e as barras de ferramentas
// Padrão e Formatação, no lugar da faixa. Os menus saem de `editorMenus`, e
// cada item é um comando do registro, com o atalho do jogo atual ao lado.
//
// Alt abre a barra de menus pelo teclado (o MenuBar do Flutter cuida das
// setas e do Esc).
import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../commands/command_registry.dart';
import '../../commands/commands_document.dart';
import '../../commands/commands_view.dart';
import '../../commands/menus.dart';
import '../../document/document_controller.dart';
import '../atoms/w_dropdown.dart';
import '../atoms/w_separator.dart';
import '../molecules/command_button.dart';
import '../style_labels.dart';
import '../tokens/tokens.dart';
import 'ribbon.dart' show fontSizes, formatPoints;

class ClassicMenuBar extends StatelessWidget {
  const ClassicMenuBar({super.key, required this.commands, required this.onRan, this.extraMenus = const []});

  final CommandRegistry commands;
  final VoidCallback onRan;

  /// Itens a mais no fim do menu Exibir (os temas, que dependem da página).
  final List<Widget> extraMenus;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final menus = editorMenus(l10n);
    return ListenableBuilder(
      listenable: commands,
      builder: (context, _) => Container(
        width: double.infinity,
        color: t.colors.frame,
        child: Row(children: [
          MenuBar(children: [
            for (final m in menus)
              SubmenuButton(
                menuChildren: [
                  for (final id in m.items)
                    if (id == null) const Divider(height: 8) else _item(context, id),
                  if (m.title == l10n.menuView) ...extraMenus,
                ],
                child: Text(m.title),
              ),
          ]),
        ]),
      ),
    );
  }

  Widget _item(BuildContext context, String id) {
    final t = QuillTokens.of(context);
    final c = commands[id];
    if (c == null) return const SizedBox.shrink();
    return MenuItemButton(
      leadingIcon: c.isActive != null
          ? Icon(c.active ? Icons.check : null, size: 16, color: t.colors.onFrame)
          : Icon(c.icon, size: 16, color: t.colors.onFrame),
      shortcut: commands.shortcutOf(id),
      onPressed: c.enabled
          ? () {
              commands.run(id);
              onRan();
            }
          : null,
      child: Text(c.label),
    );
  }
}

/// As barras Padrão e Formatação, uma embaixo da outra.
class ClassicToolbars extends StatelessWidget {
  const ClassicToolbars({super.key, required this.commands, required this.doc, required this.onRan});

  final CommandRegistry commands;
  final DocumentController doc;
  final VoidCallback onRan;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    Widget cmd(String id) => CommandButton(commands: commands, id: id, onRan: onRan);
    Widget bar(String name, List<Widget> children) => Semantics(
          container: true,
          label: name,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: t.space.sm, vertical: t.space.xs),
            decoration: BoxDecoration(
              color: t.colors.frame,
              border: Border(top: BorderSide(color: t.colors.bevelLight), bottom: BorderSide(color: t.colors.bevelDark)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: children),
            ),
          ),
        );
    final editable = doc.canEdit;
    final size = doc.fontSize;
    final styles = [
      for (final s in bookStyles)
        if (doc.paragraphStyles.isEmpty || doc.paragraphStyles.contains(s)) s,
      ...doc.customParagraphStyles,
    ];
    return ListenableBuilder(
      listenable: commands,
      builder: (context, _) => Column(mainAxisSize: MainAxisSize.min, children: [
        bar(l10n.toolbarStandard, [
          cmd(CommandIds.newDocument),
          cmd(CommandIds.open),
          cmd(CommandIds.save),
          const WSeparator(),
          cmd(CommandIds.cut),
          cmd(CommandIds.copy),
          cmd(CommandIds.paste),
          const WSeparator(),
          cmd(CommandIds.undo),
          cmd(CommandIds.redo),
          const WSeparator(),
          cmd(ViewCommandIds.find),
          cmd(ViewCommandIds.insertTable),
          cmd(ViewCommandIds.insertImage),
          const WSeparator(),
          cmd(CommandIds.spellOnline),
          cmd(CommandIds.formattingMarks),
          cmd(ViewCommandIds.inspector),
          const WSeparator(),
          cmd(CommandIds.zoomOut),
          cmd(CommandIds.zoomIn),
        ]),
        bar(l10n.toolbarFormatting, [
          WDropdown<String>(
            label: l10n.fieldStyle,
            text: doc.paragraphStyleId == null ? '' : styleLabel(l10n, doc.paragraphStyleId!),
            width: 150,
            items: [for (final s in styles) WDropdownItem(s, styleLabel(l10n, s))],
            onSelected: editable ? doc.applyParagraphStyle : null,
            onClosed: onRan,
          ),
          SizedBox(width: t.space.xs),
          WDropdown<String>(
            label: l10n.fieldFont,
            text: doc.fontName ?? '',
            width: 150,
            items: [for (final f in doc.fonts) WDropdownItem(f, f)],
            onSelected: editable && doc.fonts.isNotEmpty ? doc.setFontName : null,
            onClosed: onRan,
          ),
          SizedBox(width: t.space.xs),
          WDropdown<double>(
            label: l10n.fieldFontSize,
            text: size == null ? '' : formatPoints(size, locale),
            width: 60,
            items: [for (final s in fontSizes) WDropdownItem(s.toDouble(), formatPoints(s.toDouble(), locale))],
            onSelected: editable ? doc.setFontSize : null,
            onClosed: onRan,
          ),
          const WSeparator(),
          cmd(CommandIds.bold),
          cmd(CommandIds.italic),
          cmd(CommandIds.underline),
          const WSeparator(),
          cmd(CommandIds.alignLeft),
          cmd(CommandIds.alignCenter),
          cmd(CommandIds.alignRight),
          cmd(CommandIds.justify),
          const WSeparator(),
          cmd(CommandIds.numbering),
          cmd(CommandIds.bullets),
          cmd(CommandIds.indentLess),
          cmd(CommandIds.indentMore),
        ]),
      ]),
    );
  }
}
