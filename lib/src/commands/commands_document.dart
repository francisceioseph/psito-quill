// Os comandos do documento: arquivo, editar, caractere, parágrafo, estilos
// de título, zoom (Fase 1); listas, entrelinhas, tabelas, imagens, página e
// ortografia (Fase 2). Os que abrem uma tela ficam em commands_view.dart.
//
// Os atalhos seguem o Word (PLANO 5.4): o jogo em português (Ctrl+N negrito,
// Ctrl+B salvar) e o em inglês (Ctrl+B negrito, Ctrl+S salvar).
import 'dart:async';

import 'package:flutter/material.dart' show Icons, IconData;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show SingleActivator;

import '../../l10n/gen/app_localizations.dart';
import '../document/document_controller.dart';
import '../document/workspace.dart';
import 'command_registry.dart';

abstract final class CommandIds {
  static const newDocument = 'arquivo.novo';
  static const open = 'arquivo.abrir';
  static const save = 'arquivo.salvar';
  static const saveAs = 'arquivo.salvarComo';

  static const undo = 'editar.desfazer';
  static const redo = 'editar.refazer';
  static const cut = 'editar.recortar';
  static const copy = 'editar.copiar';
  static const paste = 'editar.colar';
  static const selectAll = 'editar.selecionarTudo';

  static const bold = 'formatar.negrito';
  static const italic = 'formatar.italico';
  static const underline = 'formatar.sublinhado';
  static const strikeout = 'formatar.tachado';

  static const alignLeft = 'paragrafo.esquerda';
  static const alignCenter = 'paragrafo.centro';
  static const alignRight = 'paragrafo.direita';
  static const justify = 'paragrafo.justificar';
  static const bullets = 'paragrafo.marcadores';
  static const numbering = 'paragrafo.numeracao';

  static const heading1 = 'estilo.titulo1';
  static const heading2 = 'estilo.titulo2';
  static const heading3 = 'estilo.titulo3';
  static const bodyText = 'estilo.corpo';

  static const superscript = 'formatar.sobrescrito';
  static const subscript = 'formatar.subscrito';
  static const clearFormatting = 'formatar.limpar';

  static const indentMore = 'paragrafo.aumentarRecuo';
  static const indentLess = 'paragrafo.diminuirRecuo';
  static const lineSpacing1 = 'paragrafo.entrelinhas1';
  static const lineSpacing15 = 'paragrafo.entrelinhas15';
  static const lineSpacing2 = 'paragrafo.entrelinhas2';
  static const spaceMore = 'paragrafo.maisEspaco';
  static const spaceLess = 'paragrafo.menosEspaco';

  static const pageBreak = 'inserir.quebraPagina';

  static const rowAbove = 'tabela.linhaAcima';
  static const rowBelow = 'tabela.linhaAbaixo';
  static const columnLeft = 'tabela.colunaEsquerda';
  static const columnRight = 'tabela.colunaDireita';
  static const deleteRow = 'tabela.excluirLinha';
  static const deleteColumn = 'tabela.excluirColuna';
  static const deleteTable = 'tabela.excluir';
  static const mergeCells = 'tabela.mesclar';

  static const wrapOff = 'imagem.acimaAbaixo';
  static const wrapIdeal = 'imagem.emVolta';
  static const wrapThrough = 'imagem.atras';
  static const imageLeft = 'imagem.esquerda';
  static const imageCenter = 'imagem.centro';
  static const imageRight = 'imagem.direita';

  static const portrait = 'pagina.retrato';
  static const landscape = 'pagina.paisagem';

  static const spellOnline = 'revisao.ortografia';
  static const formattingMarks = 'exibir.marcas';

  static const zoomIn = 'exibir.zoomMais';
  static const zoomOut = 'exibir.zoomMenos';
  static const zoomReset = 'exibir.zoom100';
}

/// Os estilos de parágrafo da galeria: o nome do LibreOffice (o que o
/// `.uno:StyleApply` aceita) e o rótulo da l10n.
List<(String, String)> quickStyles(AppLocalizations l10n) => [
      ('Standard', l10n.styleDefault),
      ('Text body', l10n.styleBody),
      ('Title', l10n.styleTitle),
      ('Subtitle', l10n.styleSubtitle),
      ('Heading 1', l10n.styleHeading(1)),
      ('Heading 2', l10n.styleHeading(2)),
      ('Heading 3', l10n.styleHeading(3)),
      ('Quotations', l10n.styleQuote),
    ];

SingleActivator _ctrl(LogicalKeyboardKey k, {bool shift = false, bool alt = false}) =>
    SingleActivator(k, control: true, shift: shift, alt: alt);

Map<ShortcutScheme, SingleActivator> _both(SingleActivator a) => {ShortcutScheme.wordPt: a, ShortcutScheme.wordEn: a};

Map<ShortcutScheme, SingleActivator> _schemes(SingleActivator pt, SingleActivator en) =>
    {ShortcutScheme.wordPt: pt, ShortcutScheme.wordEn: en};

void registerEditorCommands(
  CommandRegistry registry, {
  required DocumentController doc,
  required Workspace workspace,
  required AppLocalizations l10n,
}) {
  bool editable() => doc.canEdit;
  bool open() => doc.isOpen;

  Command toggle(String id, String label, IconData icon, String uno, Map<ShortcutScheme, SingleActivator> keys) =>
      Command(
        id: id,
        label: label,
        icon: icon,
        run: () => doc.uno(uno),
        isActive: () => doc.isOn(uno),
        canRun: editable,
        shortcuts: keys,
      );

  Command action(String id, String label, IconData icon, String uno, {bool Function()? when}) => Command(
        id: id,
        label: label,
        icon: icon,
        run: () => doc.uno(uno),
        canRun: () => editable() && (when?.call() ?? true),
      );

  bool inTable() => doc.inTable;
  bool onImage() => doc.graphic != null;

  Command style(String id, String label, String style, IconData icon, LogicalKeyboardKey digit) => Command(
        id: id,
        label: label,
        icon: icon,
        run: () => doc.applyParagraphStyle(style),
        canRun: editable,
        shortcuts: _both(_ctrl(digit, alt: true)),
      );

  for (final c in [
    // Arquivo
    Command(
      id: CommandIds.newDocument,
      label: l10n.commandNew,
      icon: Icons.note_add_outlined,
      run: () => unawaited(workspace.newDocument()),
      canRun: () => doc.kitStatus == KitStatus.ready,
      shortcuts: _schemes(_ctrl(LogicalKeyboardKey.keyO), _ctrl(LogicalKeyboardKey.keyN)),
    ),
    Command(
      id: CommandIds.open,
      label: l10n.commandOpen,
      icon: Icons.folder_open_outlined,
      run: () => unawaited(workspace.openWithDialog()),
      canRun: () => doc.kitStatus == KitStatus.ready,
      shortcuts: _schemes(_ctrl(LogicalKeyboardKey.keyA), _ctrl(LogicalKeyboardKey.keyO)),
    ),
    Command(
      id: CommandIds.save,
      label: l10n.commandSave,
      icon: Icons.save_outlined,
      run: () => unawaited(workspace.save()),
      canRun: open,
      shortcuts: _schemes(_ctrl(LogicalKeyboardKey.keyB), _ctrl(LogicalKeyboardKey.keyS)),
    ),
    Command(
      id: CommandIds.saveAs,
      label: l10n.commandSaveAs,
      icon: Icons.save_as_outlined,
      run: () => unawaited(workspace.saveAs()),
      canRun: open,
      shortcuts: _both(const SingleActivator(LogicalKeyboardKey.f12)),
    ),

    // Editar
    Command(
      id: CommandIds.undo,
      label: l10n.commandUndo,
      icon: Icons.undo,
      run: doc.undo,
      canRun: () => doc.canUndo,
      shortcuts: _both(_ctrl(LogicalKeyboardKey.keyZ)),
    ),
    Command(
      id: CommandIds.redo,
      label: l10n.commandRedo,
      icon: Icons.redo,
      run: doc.redo,
      canRun: () => doc.canRedo,
      shortcuts: _schemes(_ctrl(LogicalKeyboardKey.keyR), _ctrl(LogicalKeyboardKey.keyY)),
    ),
    Command(
      id: CommandIds.cut,
      label: l10n.commandCut,
      icon: Icons.content_cut,
      run: doc.cut,
      canRun: () => doc.canEdit && doc.hasSelection,
      shortcuts: _both(_ctrl(LogicalKeyboardKey.keyX)),
    ),
    Command(
      id: CommandIds.copy,
      label: l10n.commandCopy,
      icon: Icons.content_copy,
      run: doc.copy,
      canRun: () => doc.isOpen && doc.hasSelection,
      shortcuts: _both(_ctrl(LogicalKeyboardKey.keyC)),
    ),
    Command(
      id: CommandIds.paste,
      label: l10n.commandPaste,
      icon: Icons.content_paste,
      run: () => unawaited(doc.paste()),
      canRun: editable,
      shortcuts: _both(_ctrl(LogicalKeyboardKey.keyV)),
    ),
    Command(
      id: CommandIds.selectAll,
      label: l10n.commandSelectAll,
      icon: Icons.select_all,
      run: doc.selectAll,
      canRun: open,
      shortcuts: _schemes(_ctrl(LogicalKeyboardKey.keyT), _ctrl(LogicalKeyboardKey.keyA)),
    ),

    // Caractere
    toggle(CommandIds.bold, l10n.commandBold, Icons.format_bold, '.uno:Bold',
        _schemes(_ctrl(LogicalKeyboardKey.keyN), _ctrl(LogicalKeyboardKey.keyB))),
    toggle(CommandIds.italic, l10n.commandItalic, Icons.format_italic, '.uno:Italic',
        _both(_ctrl(LogicalKeyboardKey.keyI))),
    toggle(CommandIds.underline, l10n.commandUnderline, Icons.format_underlined, '.uno:Underline',
        _schemes(_ctrl(LogicalKeyboardKey.keyS), _ctrl(LogicalKeyboardKey.keyU))),
    toggle(CommandIds.strikeout, l10n.commandStrikeout, Icons.format_strikethrough, '.uno:Strikeout', const {}),

    // Parágrafo
    toggle(CommandIds.alignLeft, l10n.commandAlignLeft, Icons.format_align_left, '.uno:LeftPara',
        _schemes(_ctrl(LogicalKeyboardKey.keyQ), _ctrl(LogicalKeyboardKey.keyL))),
    toggle(CommandIds.alignCenter, l10n.commandAlignCenter, Icons.format_align_center, '.uno:CenterPara',
        _both(_ctrl(LogicalKeyboardKey.keyE))),
    toggle(CommandIds.alignRight, l10n.commandAlignRight, Icons.format_align_right, '.uno:RightPara',
        _schemes(_ctrl(LogicalKeyboardKey.keyG), _ctrl(LogicalKeyboardKey.keyR))),
    toggle(CommandIds.justify, l10n.commandJustify, Icons.format_align_justify, '.uno:JustifyPara',
        _both(_ctrl(LogicalKeyboardKey.keyJ))),
    toggle(CommandIds.bullets, l10n.commandBullets, Icons.format_list_bulleted, '.uno:DefaultBullet', const {}),
    toggle(CommandIds.numbering, l10n.commandNumbering, Icons.format_list_numbered, '.uno:DefaultNumbering',
        const {}),

    // Estilos de título (Ctrl+Alt+1..3, nos dois jogos)
    style(CommandIds.heading1, l10n.styleHeading(1), 'Heading 1', Icons.title, LogicalKeyboardKey.digit1),
    style(CommandIds.heading2, l10n.styleHeading(2), 'Heading 2', Icons.title, LogicalKeyboardKey.digit2),
    style(CommandIds.heading3, l10n.styleHeading(3), 'Heading 3', Icons.title, LogicalKeyboardKey.digit3),
    style(CommandIds.bodyText, l10n.styleBody, 'Text body', Icons.notes, LogicalKeyboardKey.digit0),

    // Caractere e parágrafo (Fase 2)
    toggle(CommandIds.superscript, l10n.commandSuperscript, Icons.superscript, '.uno:SuperScript', const {}),
    toggle(CommandIds.subscript, l10n.commandSubscript, Icons.subscript, '.uno:SubScript', const {}),
    Command(
      id: CommandIds.clearFormatting,
      label: l10n.commandClearFormatting,
      icon: Icons.format_clear,
      run: () => doc.uno('.uno:ResetAttributes'),
      canRun: editable,
      shortcuts: _both(_ctrl(LogicalKeyboardKey.space)),
    ),
    action(CommandIds.indentMore, l10n.commandIndentMore, Icons.format_indent_increase, '.uno:IncrementIndent'),
    action(CommandIds.indentLess, l10n.commandIndentLess, Icons.format_indent_decrease, '.uno:DecrementIndent'),
    toggle(CommandIds.lineSpacing1, l10n.commandLineSpacing1, Icons.density_small, '.uno:SpacePara1', const {}),
    toggle(CommandIds.lineSpacing15, l10n.commandLineSpacing15, Icons.density_medium, '.uno:SpacePara15', const {}),
    toggle(CommandIds.lineSpacing2, l10n.commandLineSpacing2, Icons.density_large, '.uno:SpacePara2', const {}),
    Command(
      id: CommandIds.spaceMore,
      label: l10n.commandSpaceMore,
      icon: Icons.expand,
      run: () => doc.changeParagraphSpacing(increase: true),
      canRun: editable,
    ),
    Command(
      id: CommandIds.spaceLess,
      label: l10n.commandSpaceLess,
      icon: Icons.compress,
      run: () => doc.changeParagraphSpacing(increase: false),
      canRun: editable,
    ),
    action(CommandIds.pageBreak, l10n.commandPageBreak, Icons.insert_page_break_outlined, '.uno:InsertPagebreak'),

    // Tabela (só com o cursor numa tabela)
    action(CommandIds.rowAbove, l10n.commandRowAbove, Icons.table_rows_outlined, '.uno:InsertRowsBefore', when: inTable),
    action(CommandIds.rowBelow, l10n.commandRowBelow, Icons.table_rows_outlined, '.uno:InsertRowsAfter', when: inTable),
    action(CommandIds.columnLeft, l10n.commandColumnLeft, Icons.view_column_outlined, '.uno:InsertColumnsBefore',
        when: inTable),
    action(CommandIds.columnRight, l10n.commandColumnRight, Icons.view_column_outlined, '.uno:InsertColumnsAfter',
        when: inTable),
    action(CommandIds.deleteRow, l10n.commandDeleteRow, Icons.playlist_remove, '.uno:DeleteRows', when: inTable),
    action(CommandIds.deleteColumn, l10n.commandDeleteColumn, Icons.remove_road, '.uno:DeleteColumns', when: inTable),
    action(CommandIds.deleteTable, l10n.commandDeleteTable, Icons.grid_off, '.uno:DeleteTable', when: inTable),
    action(CommandIds.mergeCells, l10n.commandMergeCells, Icons.call_merge, '.uno:MergeCells', when: inTable),

    // Imagem (só com uma imagem selecionada)
    action(CommandIds.wrapOff, l10n.commandWrapOff, Icons.vertical_align_center, '.uno:WrapOff', when: onImage),
    action(CommandIds.wrapIdeal, l10n.commandWrapIdeal, Icons.wrap_text, '.uno:WrapIdeal', when: onImage),
    action(CommandIds.wrapThrough, l10n.commandWrapThrough, Icons.flip_to_back, '.uno:WrapThrough', when: onImage),
    action(CommandIds.imageLeft, l10n.commandImageLeft, Icons.align_horizontal_left, '.uno:ObjectAlignLeft',
        when: onImage),
    action(CommandIds.imageCenter, l10n.commandImageCenter, Icons.align_horizontal_center, '.uno:AlignCenter',
        when: onImage),
    action(CommandIds.imageRight, l10n.commandImageRight, Icons.align_horizontal_right, '.uno:ObjectAlignRight',
        when: onImage),

    // Página
    Command(
      id: CommandIds.portrait,
      label: l10n.commandPortrait,
      icon: Icons.crop_portrait,
      run: () => doc.setLandscape(false),
      isActive: () => !doc.landscape,
      canRun: editable,
    ),
    Command(
      id: CommandIds.landscape,
      label: l10n.commandLandscape,
      icon: Icons.crop_landscape,
      run: () => doc.setLandscape(true),
      isActive: () => doc.landscape,
      canRun: editable,
    ),

    // Revisão e exibição
    Command(
      id: CommandIds.spellOnline,
      label: l10n.commandSpellOnline,
      icon: Icons.spellcheck,
      run: doc.toggleSpellOnline,
      isActive: () => doc.isOn('.uno:SpellOnline'),
      canRun: open,
    ),
    Command(
      id: CommandIds.formattingMarks,
      label: l10n.commandFormattingMarks,
      icon: Icons.format_textdirection_l_to_r,
      run: () => doc.kit.uno('.uno:ControlCodes'),
      isActive: () => doc.isOn('.uno:ControlCodes'),
      canRun: open,
      shortcuts: _both(_ctrl(LogicalKeyboardKey.digit8, shift: true)),
    ),

    // Zoom
    Command(
      id: CommandIds.zoomIn,
      label: l10n.commandZoomIn,
      icon: Icons.zoom_in,
      run: doc.zoomIn,
      canRun: () => doc.zoom < maxZoom,
      shortcuts: _both(_ctrl(LogicalKeyboardKey.equal)),
    ),
    Command(
      id: CommandIds.zoomOut,
      label: l10n.commandZoomOut,
      icon: Icons.zoom_out,
      run: doc.zoomOut,
      canRun: () => doc.zoom > minZoom,
      shortcuts: _both(_ctrl(LogicalKeyboardKey.minus)),
    ),
    Command(
      id: CommandIds.zoomReset,
      label: l10n.commandZoomReset,
      icon: Icons.fit_screen_outlined,
      run: () => doc.setZoom(1),
      shortcuts: _both(_ctrl(LogicalKeyboardKey.digit0)),
    ),
  ]) {
    registry.register(c);
  }
}
