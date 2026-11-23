// A faixa (temas modernos): Arquivo, Início, Inserir, Layout, Revisão,
// Exibir, e as abas que aparecem com o contexto (Tabela, Imagem), como no
// Word. A aba Livro entra na Fase 3.
//
// Tudo sai do CommandRegistry; as listas (estilo, fonte, tamanho) mostram o
// estado que vem do motor.
import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../commands/command_registry.dart';
import '../../commands/commands_document.dart';
import '../../commands/commands_view.dart';
import '../../document/document_controller.dart';
import '../atoms/w_button.dart';
import '../atoms/w_dropdown.dart';
import '../atoms/w_separator.dart';
import '../molecules/command_button.dart';
import '../molecules/ribbon_group.dart';
import '../style_labels.dart';
import '../tokens/tokens.dart';
import 'inspector.dart' show marginPresets, pageSizeLabel;

/// Os tamanhos de fonte da lista, como no Word.
const fontSizes = [8.0, 9, 10, 10.5, 11, 12, 14, 16, 18, 20, 22, 24, 28, 32, 36, 48, 72];

String formatPoints(double v, String locale) {
  final s = v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  return locale.startsWith('pt') ? s.replaceAll('.', ',') : s;
}

enum RibbonTab { home, insert, layout, review, view, table, image }

class Ribbon extends StatelessWidget {
  const Ribbon({
    super.key,
    required this.commands,
    required this.doc,
    required this.fileOpen,
    required this.tab,
    required this.onFile,
    required this.onTab,
    required this.onRan,
    this.trailing = const [],
  });

  final CommandRegistry commands;
  final DocumentController doc;

  /// O painel Arquivo está aberto (a aba Arquivo fica marcada).
  final bool fileOpen;
  final RibbonTab tab;
  final VoidCallback onFile;
  final ValueChanged<RibbonTab> onTab;

  /// Depois de um comando ou de fechar uma lista: o foco volta ao documento.
  final VoidCallback onRan;
  final List<Widget> trailing;

  /// A aba que aparece agora: as contextuais somem quando o contexto acaba.
  RibbonTab get shownTab => switch (tab) {
        RibbonTab.table when !doc.inTable => RibbonTab.home,
        RibbonTab.image when doc.graphic == null => RibbonTab.home,
        final t => t,
      };

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final current = shownTab;
    Widget tabButton(RibbonTab id, String label) =>
        WTextButton(label: label, selected: !fileOpen && current == id, onPressed: () => onTab(id));
    return ListenableBuilder(
      listenable: commands,
      builder: (context, _) => Container(
        decoration: BoxDecoration(
          color: t.colors.frame,
          border: Border(bottom: BorderSide(color: t.colors.border)),
        ),
        padding: EdgeInsets.symmetric(horizontal: t.space.md, vertical: t.space.xs),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            WTextButton(label: l10n.ribbonFile, selected: fileOpen, onPressed: onFile),
            SizedBox(width: t.space.xs),
            tabButton(RibbonTab.home, l10n.ribbonHome),
            tabButton(RibbonTab.insert, l10n.ribbonInsert),
            tabButton(RibbonTab.layout, l10n.ribbonLayout),
            tabButton(RibbonTab.review, l10n.ribbonReview),
            tabButton(RibbonTab.view, l10n.ribbonView),
            if (doc.inTable) ...[const WSeparator(), tabButton(RibbonTab.table, l10n.ribbonTable)],
            if (doc.graphic != null) ...[const WSeparator(), tabButton(RibbonTab.image, l10n.ribbonImage)],
            const Spacer(),
            // Acesso rápido, como no Word: salvar, desfazer, refazer.
            for (final id in [CommandIds.save, CommandIds.undo, CommandIds.redo])
              CommandButton(commands: commands, id: id, onRan: onRan),
            if (trailing.isNotEmpty) const WSeparator(),
            ...trailing,
          ]),
          if (!fileOpen) ...[
            SizedBox(height: t.space.xs),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: switch (current) {
                RibbonTab.home => _HomeTab(commands: commands, doc: doc, onRan: onRan),
                RibbonTab.insert => _InsertTab(commands: commands, onRan: onRan),
                RibbonTab.layout => _LayoutTab(commands: commands, doc: doc, onRan: onRan),
                RibbonTab.review => _groups(commands, onRan, [
                    (l10n.groupProofing, [CommandIds.spellOnline]),
                    (l10n.groupEditing, [ViewCommandIds.find, ViewCommandIds.replace]),
                  ]),
                RibbonTab.view => _groups(commands, onRan, [
                    (l10n.groupShow, [ViewCommandIds.inspector, ViewCommandIds.reveal, CommandIds.formattingMarks]),
                    (l10n.groupZoom, [CommandIds.zoomOut, CommandIds.zoomReset, CommandIds.zoomIn]),
                    (l10n.commandPalette, [ViewCommandIds.palette]),
                  ]),
                RibbonTab.table => _groups(commands, onRan, [
                    (
                      l10n.groupRowsColumns,
                      [CommandIds.rowAbove, CommandIds.rowBelow, CommandIds.columnLeft, CommandIds.columnRight]
                    ),
                    (l10n.groupMerge, [CommandIds.mergeCells]),
                    (l10n.ribbonTable, [CommandIds.deleteRow, CommandIds.deleteColumn, CommandIds.deleteTable]),
                  ]),
                RibbonTab.image => _groups(commands, onRan, [
                    (l10n.groupArrange, [CommandIds.wrapOff, CommandIds.wrapIdeal, CommandIds.wrapThrough]),
                    (l10n.fieldPageSize, [CommandIds.imageLeft, CommandIds.imageCenter, CommandIds.imageRight]),
                  ]),
              },
            ),
          ],
        ]),
      ),
    );
  }
}

/// Grupos só de botões de comando.
Widget _groups(CommandRegistry commands, VoidCallback onRan, List<(String, List<String>)> groups) =>
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final (i, (title, ids)) in groups.indexed) ...[
        if (i > 0) const WSeparator(),
        RibbonGroup(title: title, children: [
          for (final id in ids) CommandButton(commands: commands, id: id, onRan: onRan, showLabel: ids.length == 1),
        ]),
      ],
    ]);

class _InsertTab extends StatelessWidget {
  const _InsertTab({required this.commands, required this.onRan});
  final CommandRegistry commands;
  final VoidCallback onRan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget big(String id) => CommandButton(commands: commands, id: id, onRan: onRan, showLabel: true);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      RibbonGroup(title: l10n.groupPages, children: [big(CommandIds.pageBreak)]),
      const WSeparator(),
      RibbonGroup(title: l10n.groupTables, children: [big(ViewCommandIds.insertTable)]),
      const WSeparator(),
      RibbonGroup(title: l10n.groupIllustrations, children: [big(ViewCommandIds.insertImage)]),
    ]);
  }
}

class _LayoutTab extends StatelessWidget {
  const _LayoutTab({required this.commands, required this.doc, required this.onRan});
  final CommandRegistry commands;
  final DocumentController doc;
  final VoidCallback onRan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget cmd(String id) => CommandButton(commands: commands, id: id, onRan: onRan);
    final editable = doc.canEdit;
    final margins = marginPresets(l10n);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      RibbonGroup(title: l10n.groupPageSetup, children: [
        cmd(CommandIds.portrait),
        cmd(CommandIds.landscape),
        WDropdown<PageSize>(
          label: l10n.fieldPageSize,
          text: l10n.fieldPageSize,
          width: 170,
          items: [for (final s in pageSizes) WDropdownItem(s, pageSizeLabel(l10n, s))],
          onSelected: editable ? doc.setPageSize : null,
          onClosed: onRan,
        ),
        WDropdown<int>(
          label: l10n.fieldMargins,
          text: l10n.fieldMargins,
          width: 170,
          items: [for (final (i, (label, _)) in margins.indexed) WDropdownItem(i, label)],
          onSelected: editable ? (i) => doc.setPageMargins(margins[i].$2) : null,
          onClosed: onRan,
        ),
      ]),
      const WSeparator(),
      RibbonGroup(title: l10n.groupSpacing, children: [
        cmd(CommandIds.indentLess),
        cmd(CommandIds.indentMore),
        cmd(CommandIds.spaceLess),
        cmd(CommandIds.spaceMore),
        cmd(CommandIds.lineSpacing1),
        cmd(CommandIds.lineSpacing15),
        cmd(CommandIds.lineSpacing2),
      ]),
    ]);
  }
}

/// A galeria de estilos: os de um livro e os do autor, com o atual marcado.
/// "Gerenciar estilos" abre a lista inteira.
class StyleGallery extends StatelessWidget {
  const StyleGallery({super.key, required this.commands, required this.doc, required this.onRan});
  final CommandRegistry commands;
  final DocumentController doc;
  final VoidCallback onRan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = doc.paragraphStyleId;
    final styles = [
      for (final s in bookStyles)
        if (doc.paragraphStyles.isEmpty || doc.paragraphStyles.contains(s)) s,
      ...doc.customParagraphStyles,
    ];
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (final s in styles)
        WTextButton(
          label: styleLabel(l10n, s),
          selected: s == current,
          onPressed: doc.canEdit
              ? () {
                  doc.applyParagraphStyle(s);
                  onRan();
                }
              : null,
        ),
      CommandButton(commands: commands, id: ViewCommandIds.newStyle, onRan: onRan),
      CommandButton(commands: commands, id: ViewCommandIds.manageStyles, onRan: onRan),
    ]);
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.commands, required this.doc, required this.onRan});

  final CommandRegistry commands;
  final DocumentController doc;
  final VoidCallback onRan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    Widget cmd(String id) => CommandButton(commands: commands, id: id, onRan: onRan);
    final editable = doc.canEdit;
    final size = doc.fontSize;

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      RibbonGroup(
        title: l10n.groupClipboard,
        children: [cmd(CommandIds.paste), cmd(CommandIds.cut), cmd(CommandIds.copy)],
      ),
      const WSeparator(),
      RibbonGroup(title: l10n.groupStyles, children: [StyleGallery(commands: commands, doc: doc, onRan: onRan)]),
      const WSeparator(),
      RibbonGroup(title: l10n.groupFont, children: [
        WDropdown<String>(
          label: l10n.fieldFont,
          text: doc.fontName ?? '',
          width: 170,
          items: [for (final f in doc.fonts) WDropdownItem(f, f)],
          onSelected: editable && doc.fonts.isNotEmpty ? doc.setFontName : null,
          onClosed: onRan,
        ),
        WDropdown<double>(
          label: l10n.fieldFontSize,
          text: size == null ? '' : formatPoints(size, locale),
          width: 76,
          items: [for (final s in fontSizes) WDropdownItem(s.toDouble(), formatPoints(s.toDouble(), locale))],
          onSelected: editable ? doc.setFontSize : null,
          onClosed: onRan,
        ),
        cmd(CommandIds.bold),
        cmd(CommandIds.italic),
        cmd(CommandIds.underline),
        cmd(CommandIds.strikeout),
      ]),
      const WSeparator(),
      RibbonGroup(title: l10n.groupParagraph, children: [
        cmd(CommandIds.alignLeft),
        cmd(CommandIds.alignCenter),
        cmd(CommandIds.alignRight),
        cmd(CommandIds.justify),
        cmd(CommandIds.bullets),
        cmd(CommandIds.numbering),
        cmd(CommandIds.indentLess),
        cmd(CommandIds.indentMore),
      ]),
      const WSeparator(),
      RibbonGroup(title: l10n.groupEditing, children: [cmd(ViewCommandIds.find), cmd(ViewCommandIds.replace)]),
    ]);
  }
}
