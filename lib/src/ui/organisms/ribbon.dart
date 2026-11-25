// A faixa (temas modernos): Arquivo, Início, Inserir, Layout, Estilos,
// Revisão, Exibir, e as abas que aparecem com o contexto (Tabela, Imagem),
// como no Word. A aba Livro entra na Fase 3.
//
// Tudo sai do CommandRegistry; as listas (estilo, fonte, tamanho) mostram o
// estado que vem do motor.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../commands/command_registry.dart';
import '../../commands/commands_book.dart';
import '../../commands/commands_document.dart';
import '../../commands/commands_page.dart';
import '../../commands/commands_view.dart';
import '../../document/doc_colors.dart';
import '../../document/document_controller.dart';
import '../../document/fodt.dart';
import '../atoms/w_button.dart';
import '../atoms/w_dropdown.dart';
import '../atoms/w_chip.dart';
import '../molecules/adaptive_ribbon.dart';
import '../molecules/color_menu_button.dart';
import '../molecules/command_menu.dart';
import '../molecules/command_button.dart';
import '../molecules/command_check.dart';
import '../molecules/measure_field.dart';
import '../molecules/ribbon_group.dart';
import '../molecules/style_card.dart';
import '../style_labels.dart';
import '../tokens/tokens.dart';
import 'font_picker.dart';
import 'inspector.dart' show colorName, marginPresets, pageSizeLabel;
import 'styles_dialog.dart' show showStylesDropdown;

/// Os tamanhos de fonte da lista, como no Word.
const fontSizes = [8.0, 9, 10, 10.5, 11, 12, 14, 16, 18, 20, 22, 24, 28, 32, 36, 48, 72];

String formatPoints(double v, String locale) {
  final s = v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  return locale.startsWith('pt') ? s.replaceAll('.', ',') : s;
}

enum RibbonTab { home, insert, layout, styles, review, view, table, image }

/// A faixa do desenho da Fase 2B (Etapa 2): a fileira de abas sobre o tom
/// `surfaceContainer`, com o Arquivo preenchido, as abas de contexto na cor
/// terciária e, na ponta direita, o acesso rápido, a pesquisa (Ctrl+K) e o
/// Recolher (Ctrl+F1). Embaixo, os grupos num cartão de cantos redondos.
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
    this.collapsed = false,
    this.onToggleCollapsed,
    this.onSearch,
    this.onStylesPanel,
    this.recentFonts = const [],
    this.onFontUsed,
    this.trailing = const [],
  });

  /// As fontes escolhidas por último (as preferências), e quem guarda a
  /// escolhida.
  final List<String> recentFonts;
  final ValueChanged<String>? onFontUsed;

  final CommandRegistry commands;
  final DocumentController doc;

  /// O painel Arquivo está aberto (a aba Arquivo fica marcada).
  final bool fileOpen;
  final RibbonTab tab;
  final VoidCallback onFile;
  final ValueChanged<RibbonTab> onTab;

  /// Depois de um comando ou de fechar uma lista: o foco volta ao documento.
  final VoidCallback onRan;

  /// Só a fileira de abas (Ctrl+F1). Clicar numa aba mostra a faixa de novo.
  final bool collapsed;
  final VoidCallback? onToggleCollapsed;

  /// A pesquisa da ponta direita: abre a paleta de comandos.
  final VoidCallback? onSearch;

  /// O ícone "Painel de estilos" da galeria.
  final VoidCallback? onStylesPanel;
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
    final c = t.colors;
    final l10n = AppLocalizations.of(context);
    final current = shownTab;
    final contextual = current == RibbonTab.table || current == RibbonTab.image;
    Widget tabButton(RibbonTab id, String label, {WTone tone = WTone.normal}) =>
        WTextButton(label: label, tone: tone, tab: true, selected: !fileOpen && current == id, onPressed: () => onTab(id));
    final tabs = Container(
      height: t.density.control + t.space.lg,
      color: c.surfaceContainer,
      padding: EdgeInsets.symmetric(horizontal: t.space.lg),
      child: LayoutBuilder(
        builder: (context, box) {
          // Janela estreita: a pesquisa e o Recolher viram só o ícone, e as
          // abas rolam. Com o texto das abas maior (D-049), o limite subiu.
          final narrow = box.maxWidth < 1600;
          return Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Semantics(
                      container: true,
                      explicitChildNodes: true,
                      label: l10n.ribbonTabs,
                      child: Row(
                        children: [
                          // Acesso rápido, como no Word e no OnlyOffice: salvar,
                          // desfazer e refazer, antes do Arquivo (D-049).
                          for (final id in [CommandIds.save, CommandIds.undo, CommandIds.redo])
                            CommandButton(commands: commands, id: id, onRan: onRan),
                          SizedBox(width: t.space.md),
                          WTextButton(
                            label: l10n.ribbonFile,
                            icon: Symbols.menu_rounded,
                            tone: WTone.filled,
                            tab: true,
                            selected: fileOpen,
                            onPressed: onFile,
                          ),
                          SizedBox(width: t.space.sm),
                          for (final (id, label) in [
                            (RibbonTab.home, l10n.ribbonHome),
                            (RibbonTab.insert, l10n.ribbonInsert),
                            (RibbonTab.layout, l10n.ribbonLayout),
                            (RibbonTab.styles, l10n.ribbonStyles),
                            (RibbonTab.review, l10n.ribbonReview),
                            (RibbonTab.view, l10n.ribbonView),
                          ]) ...[tabButton(id, label), SizedBox(width: t.space.xs)],
                          if (doc.inTable) ...[
                            SizedBox(width: t.space.sm),
                            tabButton(RibbonTab.table, l10n.ribbonTable, tone: WTone.context),
                          ],
                          if (doc.graphic != null) ...[
                            SizedBox(width: t.space.sm),
                            tabButton(RibbonTab.image, l10n.ribbonImage, tone: WTone.context),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              ...trailing,
              SizedBox(width: t.space.sm),
              if (onSearch != null)
                narrow
                    ? WButton(
                        icon: Symbols.search_rounded,
                        label: l10n.searchCommands,
                        tooltip: commands.tooltipOf(ViewCommandIds.palette),
                        onPressed: onSearch,
                      )
                    : _SearchButton(
                        label: l10n.searchCommands,
                        shortcut: commands.tooltipOf(ViewCommandIds.palette),
                        onPressed: onSearch!,
                      ),
              SizedBox(width: t.space.sm),
              if (onToggleCollapsed != null && narrow)
                WButton(
                  icon: collapsed ? Symbols.expand_more_rounded : Symbols.expand_less_rounded,
                  label: l10n.ribbonCollapse,
                  tooltip: commands.tooltipOf(ViewCommandIds.collapseRibbon),
                  onPressed: onToggleCollapsed,
                )
              else if (onToggleCollapsed != null)
                WChip(
                  label: l10n.ribbonCollapse,
                  icon: collapsed ? Symbols.expand_more_rounded : Symbols.expand_less_rounded,
                  selected: collapsed,
                  onPressed: onToggleCollapsed,
                ),
            ],
          );
        },
      ),
    );
    if (fileOpen || collapsed) return ListenableBuilder(listenable: commands, builder: (context, _) => tabs);
    return ListenableBuilder(
      listenable: commands,
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          tabs,
          Container(
            color: c.surfaceContainer,
            padding: EdgeInsets.fromLTRB(t.space.md, 0, t.space.md, t.space.sm),
            child: Container(
              decoration: BoxDecoration(
                color: c.frameRaised,
                borderRadius: BorderRadius.circular(t.component == ComponentStyle.modern ? t.radius.panel : 0),
                border: contextual ? Border(top: BorderSide(color: c.tertiaryContainer, width: 3)) : null,
              ),
              padding: EdgeInsets.symmetric(vertical: t.space.sm, horizontal: t.space.xs),
              child: Semantics(
                container: true,
                explicitChildNodes: true,
                label: switch (current) {
                  RibbonTab.home => l10n.ribbonHome,
                  RibbonTab.insert => l10n.ribbonInsert,
                  RibbonTab.layout => l10n.ribbonLayout,
                  RibbonTab.styles => l10n.ribbonStyles,
                  RibbonTab.review => l10n.ribbonReview,
                  RibbonTab.view => l10n.ribbonView,
                  RibbonTab.table => l10n.ribbonTable,
                  RibbonTab.image => l10n.ribbonImage,
                },
                // O Início se adapta à largura (D-049); as outras abas, curtas,
                // rolam de lado se faltar espaço.
                child: current == RibbonTab.home
                    ? _HomeTab(
                        commands: commands,
                        doc: doc,
                        onRan: onRan,
                        onStylesPanel: onStylesPanel,
                        recentFonts: recentFonts,
                        onFontUsed: onFontUsed,
                      )
                    : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: IntrinsicHeight(
                    child: switch (current) {
                      RibbonTab.home => const SizedBox.shrink(),
                      RibbonTab.insert => _InsertTab(commands: commands, onRan: onRan),
                      RibbonTab.layout => _LayoutTab(commands: commands, doc: doc, onRan: onRan),
                      RibbonTab.styles => _StylesTab(
                        commands: commands,
                        doc: doc,
                        onRan: onRan,
                        onStylesPanel: onStylesPanel,
                      ),
                      RibbonTab.review => _groups(commands, onRan, [
                        (l10n.groupProofing, [CommandIds.spellOnline]),
                        (l10n.groupComments, [ViewCommandIds.newComment, ViewCommandIds.comments]),
                        (l10n.groupEditing, [ViewCommandIds.find, ViewCommandIds.replace]),
                      ]),
                      RibbonTab.view => _ViewTab(commands: commands, onRan: onRan),
                      RibbonTab.table => _groups(commands, onRan, [
                        (
                          l10n.groupRowsColumns,
                          [CommandIds.rowAbove, CommandIds.rowBelow, CommandIds.columnLeft, CommandIds.columnRight],
                        ),
                        (l10n.groupMerge, [CommandIds.mergeCells]),
                        (l10n.ribbonTable, [CommandIds.deleteRow, CommandIds.deleteColumn, CommandIds.deleteTable]),
                      ]),
                      RibbonTab.image => Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ImageSizeGroup(doc: doc, onRan: onRan),
                          _groups(commands, onRan, [
                            (l10n.groupArrange, [CommandIds.wrapOff, CommandIds.wrapIdeal, CommandIds.wrapThrough]),
                            (l10n.fieldPageSize, [CommandIds.imageLeft, CommandIds.imageCenter, CommandIds.imageRight]),
                          ]),
                        ],
                      ),
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A pesquisa da ponta direita da fileira de abas. Parece um campo, mas só
/// abre a paleta de comandos (que tem o campo de verdade).
class _SearchButton extends StatelessWidget {
  const _SearchButton({required this.label, required this.shortcut, required this.onPressed});
  final String label;

  /// A dica da paleta, com o atalho ("Paleta de comandos (Ctrl+K)").
  final String shortcut;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final c = t.colors;
    return WControlSurface(
      tooltip: shortcut,
      selected: false,
      outlined: true,
      pill: true,
      width: 300,
      onPressed: onPressed,
      semantics: (child) => Semantics(container: true, button: true, label: label, hint: shortcut, child: child),
      child: Row(
        children: [
          Icon(Symbols.search_rounded, size: t.density.icon - 2, color: c.onFrameMuted),
          SizedBox(width: t.space.sm),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: c.onFrameMuted, fontSize: t.font.ui, fontFamily: t.font.family),
            ),
          ),
        ],
      ),
    );
  }
}

/// Grupos só de botões de comando.
Widget _groups(CommandRegistry commands, VoidCallback onRan, List<(String, List<String>)> groups) => Row(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    for (final (i, (title, ids)) in groups.indexed)
      RibbonGroup(
        title: title,
        last: i == groups.length - 1,
        firstRow: [
          for (final id in ids) CommandButton(commands: commands, id: id, onRan: onRan, showLabel: ids.length <= 2),
        ],
      ),
  ],
);

/// Um comando do registro como botão grande (ícone em cima do nome).
Widget _big(CommandRegistry commands, String id, VoidCallback onRan, {double? width}) {
  final c = commands[id];
  if (c == null) return const SizedBox.shrink();
  return WBigButton(
    icon: c.icon,
    label: c.label,
    width: width,
    tooltip: commands.tooltipOf(id),
    onPressed: c.enabled
        ? () {
            commands.run(id);
            onRan();
          }
        : null,
  );
}

/// A aba Exibir (D-065): as caixas do que se mostra, a disposição das
/// páginas, o zoom com os ajustes, e os modos.
class _ViewTab extends StatelessWidget {
  const _ViewTab({required this.commands, required this.onRan});
  final CommandRegistry commands;
  final VoidCallback onRan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget check(String id) => CommandCheck(commands: commands, id: id, onRan: onRan);
    Widget cmd(String id) => CommandButton(commands: commands, id: id, onRan: onRan);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RibbonGroup(
          title: l10n.groupShow,
          firstRow: [check(ViewCommandIds.ruler), check(ViewCommandIds.statusBar), check(CommandIds.formattingMarks)],
          secondRow: [check(ViewCommandIds.outline), check(ViewCommandIds.inspector), check(ViewCommandIds.reveal)],
        ),
        RibbonGroup(
          title: l10n.groupPageLayout,
          firstRow: [
            _big(commands, ViewCommandIds.layoutSingle, onRan),
            _big(commands, ViewCommandIds.layoutMulti, onRan),
            _big(commands, ViewCommandIds.layoutBook, onRan),
          ],
        ),
        RibbonGroup(
          title: l10n.groupZoom,
          firstRow: [
            _big(commands, CommandIds.zoomReset, onRan),
            _big(commands, ViewCommandIds.fitPage, onRan),
            _big(commands, ViewCommandIds.fitWidth, onRan),
          ],
          secondRow: null,
          leading: Column(mainAxisAlignment: MainAxisAlignment.center, children: [cmd(CommandIds.zoomIn), cmd(CommandIds.zoomOut)]),
        ),
        RibbonGroup(title: l10n.groupModes, firstRow: [_big(commands, ViewCommandIds.zen, onRan), _big(commands, BookCommandIds.corkboard, onRan)]),
        RibbonGroup(
          title: l10n.groupWindow,
          last: true,
          firstRow: [_big(commands, ViewCommandIds.palette, onRan), _big(commands, ViewCommandIds.collapseRibbon, onRan)],
        ),
      ],
    );
  }
}

class _InsertTab extends StatelessWidget {
  const _InsertTab({required this.commands, required this.onRan});
  final CommandRegistry commands;
  final VoidCallback onRan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget menu(String label, IconData icon, List<String> ids) =>
        CommandMenuButton(commands: commands, ids: ids, icon: icon, label: label, big: true, onRan: onRan);
    // A Etapa 3 e a 4 da Fase 3 (D-075, D-076): o cabeçalho e o rodapé, as
    // notas, os links e os símbolos, como no OnlyOffice.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RibbonGroup(title: l10n.groupPages, firstRow: [
            _big(commands, CommandIds.pageBreak, onRan),
            _big(commands, BookCommandIds.newScene, onRan),
            menu(l10n.groupBreaks, Symbols.insert_page_break_rounded, const [
              CommandIds.pageBreak,
              PageCommandIds.blankPage,
              PageCommandIds.columnBreak,
            ]),
          ]),
          RibbonGroup(title: l10n.groupTables, firstRow: [_big(commands, ViewCommandIds.insertTable, onRan)]),
          RibbonGroup(title: l10n.groupIllustrations, firstRow: [_big(commands, ViewCommandIds.insertImage, onRan)]),
          RibbonGroup(title: l10n.groupHeaderFooter, firstRow: [
            menu(l10n.commandHeader, Symbols.vertical_align_top_rounded, const [
              PageCommandIds.header,
              PageCommandIds.removeHeader,
              commandMenuDivider,
              PageCommandIds.firstPageDifferent,
              PageCommandIds.leftRightDifferent,
            ]),
            menu(l10n.commandFooter, Symbols.vertical_align_bottom_rounded, const [
              PageCommandIds.footer,
              PageCommandIds.removeFooter,
              commandMenuDivider,
              PageCommandIds.firstPageDifferent,
              PageCommandIds.leftRightDifferent,
            ]),
            menu(l10n.groupFields, Symbols.tag_rounded, const [
              PageCommandIds.pageNumber,
              PageCommandIds.pageCount,
              PageCommandIds.date,
              PageCommandIds.time,
            ]),
          ]),
          RibbonGroup(title: l10n.groupNotes, firstRow: [
            _big(commands, PageCommandIds.footnote, onRan),
            menu(l10n.groupNotes, Symbols.more_horiz_rounded, const [
              PageCommandIds.footnote,
              PageCommandIds.endnote,
              commandMenuDivider,
              PageCommandIds.jumpFootnote,
            ]),
          ]),
          RibbonGroup(title: l10n.groupLinks, firstRow: [_big(commands, PageCommandIds.link, onRan)]),
          RibbonGroup(
            title: l10n.groupTypography,
            last: true,
            firstRow: [
              _big(commands, PageCommandIds.specialCharacter, onRan),
              menu(l10n.commandDropCap(3), Symbols.format_size_rounded, const [
                PageCommandIds.dropCap2,
                PageCommandIds.dropCap3,
                PageCommandIds.removeDropCap,
              ]),
            ],
          ),
        ],
      ),
    );
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RibbonGroup(
          title: l10n.groupPageSetup,
          firstRow: [
            WDropdown<PageSize>(
              label: l10n.fieldPageSize,
              text: l10n.fieldPageSize,
              width: 150,
              items: [for (final s in pageSizes) WDropdownItem(s, pageSizeLabel(l10n, s))],
              onSelected: editable ? doc.setPageSize : null,
              onClosed: onRan,
            ),
            WDropdown<int>(
              label: l10n.fieldMargins,
              text: l10n.fieldMargins,
              width: 150,
              items: [for (final (i, (label, _)) in margins.indexed) WDropdownItem(i, label)],
              onSelected: editable ? (i) => doc.setPageMargins(margins[i].$2) : null,
              onClosed: onRan,
            ),
          ],
          secondRow: [cmd(CommandIds.portrait), cmd(CommandIds.landscape)],
        ),
        RibbonGroup(
          title: l10n.groupHyphenation,
          firstRow: [CommandCheck(commands: commands, id: PageCommandIds.hyphenation, onRan: onRan)],
          secondRow: [cmd(PageCommandIds.hyphenateParagraph), cmd(PageCommandIds.noHyphenateParagraph)],
        ),
        RibbonGroup(
          title: l10n.groupSpacing,
          last: true,
          firstRow: [
            cmd(CommandIds.indentLess),
            cmd(CommandIds.indentMore),
            cmd(CommandIds.spaceLess),
            cmd(CommandIds.spaceMore),
          ],
          secondRow: [cmd(CommandIds.lineSpacing1), cmd(CommandIds.lineSpacing15), cmd(CommandIds.lineSpacing2)],
        ),
      ],
    );
  }
}

/// A amostra de um estilo para os cartões: as propriedades da cópia
/// temporária (D-044), se já chegaram; senão, uma genérica pelo tipo.
StyleSample styleSample(AppLocalizations l10n, String id, [StyleProps? props]) {
  final heading = id == 'Title' || id == 'Subtitle' || id.startsWith('Heading');
  final text = heading
      ? l10n.styleSampleHeading
      : id == 'Quotations'
      ? l10n.styleSampleQuote
      : l10n.styleSampleBody;
  if (props != null) {
    return StyleSample(
      text: text,
      scale: ((props.sizePt ?? 12) / 12).clamp(0.75, 1.5),
      bold: props.bold ?? false,
      italic: props.italic ?? false,
      center: props.align == 'center',
      fontFamily: props.fontName,
      rgb: props.color,
    );
  }
  return switch (id) {
    'Title' => StyleSample(text: text, scale: 1.3, bold: true, center: true),
    'Subtitle' => StyleSample(text: text, scale: 1.1, center: true),
    'Heading 1' => StyleSample(text: text, scale: 1.25, bold: true),
    'Heading 2' => StyleSample(text: text, scale: 1.1, bold: true),
    'Heading 3' => StyleSample(text: text, bold: true),
    'Quotations' => StyleSample(text: text, italic: true),
    _ => StyleSample(text: text),
  };
}

/// A galeria de estilos: os de um livro e os do autor em cartões, com o
/// atual marcado. O ▾ ("Mais estilos") desce a galeria inteira, com a busca;
/// o outro ícone abre o painel Estilos.
class StyleGallery extends StatelessWidget {
  const StyleGallery({
    super.key,
    required this.commands,
    required this.doc,
    required this.onRan,
    this.onStylesPanel,
    this.max,
    this.width,
  });
  final CommandRegistry commands;
  final DocumentController doc;
  final VoidCallback onRan;
  final VoidCallback? onStylesPanel;

  /// Quantos cartões, no máximo (a aba Início mostra menos que a Estilos).
  final int? max;

  /// A largura que a galeria tem (a faixa adaptável dá a sobra): cabem
  /// quantos cartões couberem, ao lado da coluna de botões.
  final double? width;

  /// A largura de um cartão mais o espaço até o próximo.
  static double cardStep(QuillTokens t) => 92 + t.space.xs;

  /// A coluna dos botões Gerenciar e Painel, à direita dos cartões.
  static double sideWidth(QuillTokens t) => t.density.control + t.space.xs;

  /// A largura mínima: três cartões e a coluna.
  static double minWidth(QuillTokens t) => 3 * cardStep(t) + sideWidth(t);

  /// Quando não cabem todos, ficam os mais usados num livro (na ordem da
  /// galeria), e o atual sempre.
  static const _mostUsed = ['Text body', 'Heading 1', 'Heading 2', 'Title', 'First line indent', 'Quotations', 'Subtitle'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = QuillTokens.of(context);
    final current = doc.paragraphStyleId;
    var styles = [
      for (final s in bookStyles)
        if (doc.paragraphStyles.isEmpty || doc.paragraphStyles.contains(s)) s,
      ...doc.customParagraphStyles,
    ];
    if (max case final m? when styles.length > m) styles = styles.take(m).toList();
    if (width case final w?) {
      final fit = ((w - sideWidth(t)) / cardStep(t)).floor().clamp(1, 1 << 20);
      if (styles.length > fit) {
        final keep = <String>{
          if (styles.contains(current)) current!,
          for (final s in _mostUsed)
            if (styles.contains(s)) s,
          ...styles,
        }.take(fit).toSet();
        styles = [for (final s in styles) if (keep.contains(s)) s];
      }
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final s in styles) ...[
          StyleCard(
            name: styleLabel(l10n, s),
            sample: styleSample(l10n, s, doc.snapshot.styles[s]),
            semanticLabel: s == current
                ? l10n.styleCardApplied(styleLabel(l10n, s))
                : l10n.styleCard(styleLabel(l10n, s)),
            selected: s == current,
            onPressed: doc.canEdit
                ? () {
                    doc.applyParagraphStyle(s);
                    onRan();
                  }
                : null,
          ),
          SizedBox(width: t.space.xs),
        ],
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // O ▾ abre a galeria inteira por cima desta, como no Word (D-055).
            Builder(
              builder: (buttonContext) => WButton(
                icon: Symbols.expand_more_rounded,
                label: l10n.stylesMore,
                onPressed: () {
                  final box = context.findRenderObject() as RenderBox?;
                  if (box == null || !box.hasSize) return;
                  final anchor = box.localToGlobal(Offset.zero) & box.size;
                  unawaited(showStylesDropdown(buttonContext, doc, anchor: anchor, commands: commands).then((_) => onRan()));
                },
              ),
            ),
            if (onStylesPanel != null)
              WButton(icon: Symbols.style_rounded, label: l10n.commandStylesPanel, onPressed: onStylesPanel),
          ],
        ),
      ],
    );
  }
}

class _StylesTab extends StatelessWidget {
  const _StylesTab({required this.commands, required this.doc, required this.onRan, this.onStylesPanel});
  final CommandRegistry commands;
  final DocumentController doc;
  final VoidCallback onRan;
  final VoidCallback? onStylesPanel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RibbonGroup(
          title: l10n.groupStyles,
          firstRow: [StyleGallery(commands: commands, doc: doc, onRan: onRan, onStylesPanel: onStylesPanel)],
        ),
        RibbonGroup(
          title: l10n.ribbonStyles,
          last: true,
          firstRow: [
            CommandButton(commands: commands, id: ViewCommandIds.newStyle, onRan: onRan, showLabel: true),
            CommandButton(commands: commands, id: ViewCommandIds.manageStyles, onRan: onRan, showLabel: true),
          ],
          secondRow: [CommandButton(commands: commands, id: ViewCommandIds.updateStyle, onRan: onRan, showLabel: true)],
        ),
      ],
    );
  }
}

/// O tamanho seguinte da lista, para cima ou para baixo (Aumentar e
/// Diminuir a fonte, como o Ctrl+] do Word).
double nextFontSize(double? current, {required bool up}) {
  final now = current ?? 12;
  if (up) {
    for (final s in fontSizes) {
      if (s > now + 0.01) return s.toDouble();
    }
    return fontSizes.last.toDouble();
  }
  for (final s in fontSizes.reversed) {
    if (s < now - 0.01) return s.toDouble();
  }
  return fontSizes.first.toDouble();
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.commands,
    required this.doc,
    required this.onRan,
    this.onStylesPanel,
    this.recentFonts = const [],
    this.onFontUsed,
  });

  final List<String> recentFonts;
  final ValueChanged<String>? onFontUsed;

  final CommandRegistry commands;
  final DocumentController doc;
  final VoidCallback onRan;
  final VoidCallback? onStylesPanel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    Widget cmd(String id) => CommandButton(commands: commands, id: id, onRan: onRan);
    final editable = doc.canEdit;
    final size = doc.fontSize;
    final fontColor = doc.fontColor;
    final highlight = doc.highlightColor;
    String nameOf(List<(DocColorName, int)> list, int? rgb, String none) => rgb == null
        ? none
        : list.where((c) => c.$2 == rgb).map((c) => colorName(l10n, c.$1)).firstOrNull ??
              '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';

    final t = QuillTokens.of(context);
    final m = RibbonMetrics(t);
    final colorFont = ColorMenuButton(
      icon: Symbols.format_color_text_rounded,
      label: l10n.fieldFontColor,
      current: fontColor,
      currentName: nameOf(fontColorChoices, fontColor, l10n.colorAutomatic),
      noneLabel: l10n.colorAutomatic,
      choices: [for (final (n, rgb) in fontColorChoices) (colorName(l10n, n), rgb)],
      onSelected: editable ? doc.setFontColor : null,
      onClosed: onRan,
    );
    final colorHighlight = ColorMenuButton(
      icon: Symbols.ink_highlighter_rounded,
      label: l10n.fieldHighlight,
      current: highlight,
      currentName: nameOf(highlightChoices, highlight, l10n.highlightNone),
      noneLabel: l10n.highlightNone,
      choices: [for (final (n, rgb) in highlightChoices) (colorName(l10n, n), rgb)],
      onSelected: editable ? doc.setHighlight : null,
      onClosed: onRan,
    );
    // A primeira linha do Fonte: a fonte, −, o tamanho e +. A fonte fica com
    // o que sobra da largura do tamanho escolhido.
    const sizeWidth = 64.0;
    final fixedFontRow = 2 * m.button + sizeWidth + 3 * m.gap;
    Widget fontRow(double width) => Row(mainAxisSize: MainAxisSize.min, children: [
          FontPicker(
            width: width - fixedFontRow,
            current: doc.fontName,
            fonts: doc.fonts,
            inDocument: doc.snapshot.fonts,
            recent: recentFonts,
            classes: doc.fontClasses,
            onSelected: editable && doc.fonts.isNotEmpty
                ? (f) {
                    doc.setFontName(f);
                    onFontUsed?.call(f);
                  }
                : null,
            onClosed: onRan,
          ),
          SizedBox(width: m.gap),
          WButton(
            icon: Symbols.remove_rounded,
            label: l10n.fontShrink,
            onPressed: editable
                ? () {
                    doc.setFontSize(nextFontSize(size, up: false));
                    onRan();
                  }
                : null,
          ),
          SizedBox(width: m.gap),
          WDropdown<double>(
            label: l10n.fieldFontSize,
            text: size == null ? '' : formatPoints(size, locale),
            width: sizeWidth,
            items: [for (final s in fontSizes) WDropdownItem(s.toDouble(), formatPoints(s.toDouble(), locale))],
            onSelected: editable ? doc.setFontSize : null,
            onClosed: onRan,
          ),
          SizedBox(width: m.gap),
          WButton(
            icon: Symbols.add_rounded,
            label: l10n.fontGrow,
            onPressed: editable
                ? () {
                    doc.setFontSize(nextFontSize(size, up: true));
                    onRan();
                  }
                : null,
          ),
        ]);
    Widget line(List<Widget> items) => Row(mainAxisSize: MainAxisSize.min, children: [
          for (final (i, w) in items.indexed) ...[if (i > 0) SizedBox(width: m.gap), w],
        ]);
    Widget rows(Widget first, Widget second) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [first, SizedBox(height: m.gap), second],
        );
    const paragraphIds = [
      CommandIds.bullets,
      CommandIds.numbering,
      CommandIds.indentLess,
      CommandIds.indentMore,
      CommandIds.alignLeft,
      CommandIds.alignCenter,
      CommandIds.alignRight,
      CommandIds.justify,
      CommandIds.formattingMarks,
    ];
    final fontWide = m.row(9);
    final fontNarrow = [m.row(7), 150 + fixedFontRow].reduce((a, b) => a > b ? a : b);

    return AdaptiveRibbon(groups: [
      RibbonGroupSpec(title: l10n.groupClipboard, priority: 1, levels: [
        RibbonLevel(m.big + m.gap + m.button, (_) => line([
              _big(commands, CommandIds.paste, onRan, width: m.big),
              Column(mainAxisSize: MainAxisSize.min, children: [cmd(CommandIds.cut), SizedBox(height: m.gap), cmd(CommandIds.copy)]),
            ])),
        RibbonLevel(m.big, (_) => _big(commands, CommandIds.paste, onRan, width: m.big)),
      ]),
      RibbonGroupSpec(title: l10n.groupFont, priority: 9, levels: [
        RibbonLevel(fontWide, (_) => rows(
              fontRow(fontWide),
              line([
                cmd(CommandIds.bold),
                cmd(CommandIds.italic),
                cmd(CommandIds.underline),
                cmd(CommandIds.strikeout),
                cmd(CommandIds.superscript),
                cmd(CommandIds.subscript),
                colorFont,
                colorHighlight,
                cmd(CommandIds.clearFormatting),
              ]),
            )),
        // Sem espaço: sobrescrito, subscrito e limpar vão para o "mais".
        RibbonLevel(fontNarrow, (_) => rows(
              fontRow(fontNarrow),
              line([
                cmd(CommandIds.bold),
                cmd(CommandIds.italic),
                cmd(CommandIds.underline),
                cmd(CommandIds.strikeout),
                colorFont,
                colorHighlight,
                CommandMenuButton(
                  commands: commands,
                  ids: const [CommandIds.superscript, CommandIds.subscript, commandMenuDivider, CommandIds.clearFormatting],
                  icon: Symbols.more_horiz_rounded,
                  label: l10n.ribbonMoreFont,
                  onRan: onRan,
                ),
              ]),
            )),
      ]),
      RibbonGroupSpec(title: l10n.groupParagraph, priority: 3, levels: [
        RibbonLevel(m.row(5), (_) => rows(
              line([
                cmd(CommandIds.bullets),
                cmd(CommandIds.numbering),
                cmd(CommandIds.indentLess),
                cmd(CommandIds.indentMore),
                _LineSpacingMenu(commands: commands, onRan: onRan),
              ]),
              line([
                cmd(CommandIds.alignLeft),
                cmd(CommandIds.alignCenter),
                cmd(CommandIds.alignRight),
                cmd(CommandIds.justify),
                cmd(CommandIds.formattingMarks),
              ]),
            )),
        // Recolhido: um botão com o nome do grupo, que abre tudo num menu.
        RibbonLevel(m.big, (_) => CommandMenuButton(
              commands: commands,
              ids: const [
                ...paragraphIds,
                commandMenuDivider,
                CommandIds.lineSpacing1,
                CommandIds.lineSpacing15,
                CommandIds.lineSpacing2,
              ],
              icon: Symbols.format_align_left_rounded,
              label: l10n.groupParagraph,
              big: true,
              width: m.big,
              onRan: onRan,
            )),
      ]),
      RibbonGroupSpec(
        title: l10n.groupStyles,
        minFill: StyleGallery.minWidth(t),
        fill: (context, width) => StyleGallery(
          commands: commands,
          doc: doc,
          onRan: onRan,
          onStylesPanel: onStylesPanel,
          width: width,
        ),
      ),
      RibbonGroupSpec(title: l10n.groupEditing, priority: 2, levels: [
        RibbonLevel(2 * m.big + m.gap, (_) => line([
              _big(commands, ViewCommandIds.find, onRan, width: m.big),
              _big(commands, ViewCommandIds.replace, onRan, width: m.big),
            ])),
        RibbonLevel(m.button, (_) => Column(mainAxisSize: MainAxisSize.min, children: [
              cmd(ViewCommandIds.find),
              SizedBox(height: m.gap),
              cmd(ViewCommandIds.replace),
            ])),
      ]),
    ]);
  }
}

/// O grupo Tamanho da aba Imagem: largura e altura em cm e o cadeado da
/// proporção (ligado ao abrir). O motor não aceita o tamanho por comando; o
/// controlador o manda pelas alças (D-043).
class ImageSizeGroup extends StatefulWidget {
  const ImageSizeGroup({super.key, required this.doc, required this.onRan});
  final DocumentController doc;
  final VoidCallback onRan;

  @override
  State<ImageSizeGroup> createState() => _ImageSizeGroupState();
}

class _ImageSizeGroupState extends State<ImageSizeGroup> {
  bool _lock = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final doc = widget.doc;
    final size = doc.graphicSizeCm;
    final editable = doc.canEdit && size != null;
    return RibbonGroup(
      title: l10n.groupSize,
      leading: WToggle(
        icon: _lock ? Symbols.lock_rounded : Symbols.lock_open_rounded,
        label: l10n.keepRatio,
        value: _lock,
        onPressed: () => setState(() => _lock = !_lock),
      ),
      firstRow: [
        SizedBox(
          width: 150,
          child: MeasureField(
            label: l10n.fieldWidth,
            value: size?.width,
            unit: l10n.unitCm,
            onDone: widget.onRan,
            onChanged: editable ? (v) => doc.setGraphicSizeCm(width: v, keepRatio: _lock) : null,
          ),
        ),
      ],
      secondRow: [
        SizedBox(
          width: 150,
          child: MeasureField(
            label: l10n.fieldHeight,
            value: size?.height,
            unit: l10n.unitCm,
            onDone: widget.onRan,
            onChanged: editable ? (v) => doc.setGraphicSizeCm(height: v, keepRatio: _lock) : null,
          ),
        ),
      ],
    );
  }
}

/// O botão Entrelinhas: abre 1, 1,5 e 2 (os comandos do registro), com o
/// atual marcado.
class _LineSpacingMenu extends StatelessWidget {
  const _LineSpacingMenu({required this.commands, required this.onRan});
  final CommandRegistry commands;
  final VoidCallback onRan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = QuillTokens.of(context);
    final ids = [CommandIds.lineSpacing1, CommandIds.lineSpacing15, CommandIds.lineSpacing2];
    final enabled = ids.any((id) => commands[id]?.enabled ?? false);
    return MenuAnchor(
      onClose: onRan,
      menuChildren: [
        for (final id in ids)
          if (commands[id] case final c?)
            MenuItemButton(
              leadingIcon: Icon(c.active ? Symbols.check_rounded : null, size: 16, color: t.colors.onFrame),
              onPressed: c.enabled ? () => commands.run(id) : null,
              child: Text(
                c.label,
                style: TextStyle(color: t.colors.onFrame, fontSize: t.font.ui, fontFamily: t.font.family),
              ),
            ),
      ],
      builder: (context, controller, _) => WButton(
        icon: Symbols.format_line_spacing_rounded,
        label: l10n.commandLineSpacingMenu,
        onPressed: enabled ? () => controller.isOpen ? controller.close() : controller.open() : null,
      ),
    );
  }
}
