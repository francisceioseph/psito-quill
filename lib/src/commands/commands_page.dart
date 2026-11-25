// Os comandos da página do livro (Fase 3, Etapa 3, D-075: o cabeçalho, o
// rodapé, os campos, a hifenização, a capitular e as quebras) e os da Etapa 4
// (D-076: o PDF, imprimir, as notas, os links e os caracteres especiais).
//
// Command com receptor, como os do livro: o que pede uma janela (onde gravar
// o PDF, o link, os caracteres, a confirmação de abrir um link) é da página
// do editor, que implementa [PageViewActions].
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show IconData, SingleActivator;
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/gen/app_localizations.dart';
import '../document/document_controller.dart';
import '../document/style_patch.dart' show PageSetup, dropCapBase;
import 'command_registry.dart';

abstract final class PageCommandIds {
  static const header = 'inserir.cabecalho';
  static const footer = 'inserir.rodape';
  static const removeHeader = 'inserir.tirarCabecalho';
  static const removeFooter = 'inserir.tirarRodape';
  static const firstPageDifferent = 'pagina.primeiraDiferente';
  static const leftRightDifferent = 'pagina.paresDiferentes';
  static const pageNumber = 'inserir.numeroPagina';
  static const pageCount = 'inserir.totalPaginas';
  static const date = 'inserir.data';
  static const time = 'inserir.hora';

  static const hyphenation = 'layout.hifenizacao';
  static const hyphenateParagraph = 'paragrafo.hifenizar';
  static const noHyphenateParagraph = 'paragrafo.naoHifenizar';
  static const dropCap2 = 'inserir.capitular2';
  static const dropCap3 = 'inserir.capitular3';
  static const removeDropCap = 'inserir.tirarCapitular';

  static const columnBreak = 'inserir.quebraColuna';
  static const blankPage = 'inserir.paginaBranco';

  static const exportPdf = 'arquivo.exportarPdf';
  static const print = 'arquivo.imprimir';

  static const footnote = 'inserir.notaRodape';
  static const endnote = 'inserir.notaFim';
  static const jumpFootnote = 'inserir.irParaNota';

  static const link = 'inserir.link';
  static const openLink = 'link.abrir';
  static const removeLink = 'link.remover';
  static const specialCharacter = 'inserir.caractereEspecial';
  static const paragraph = 'paragrafo.avancado';
}

/// O que a página do editor sabe abrir para estes comandos.
abstract interface class PageViewActions {
  void exportPdf();
  void printDocument();

  /// A janela do link (nova, ou a do link do cursor).
  void editLink();

  /// Pergunta antes de abrir: o Quill não abre nada na rede sozinho.
  void openLink(DocLink link);
  void specialCharacter();

  /// A janela do parágrafo: o fundo, o intervalo, as bordas e as
  /// tabulações (D-091).
  void paragraphDialog();
}

void registerPageCommands(
  CommandRegistry registry, {
  required DocumentController doc,
  required PageViewActions view,
  required AppLocalizations l10n,
}) {
  bool editable() => doc.canEdit;
  PageSetup page() => doc.snapshot.page;
  bool hasHeaderOrFooter() => page().header || page().footer;

  Command run(String id, String label, IconData icon, void Function() action,
          {bool Function()? when, bool Function()? active, Map<ShortcutScheme, SingleActivator> keys = const {}}) =>
      Command(
        id: id,
        label: label,
        icon: icon,
        run: action,
        canRun: () => editable() && (when?.call() ?? true),
        isActive: active,
        shortcuts: keys,
      );

  Map<ShortcutScheme, SingleActivator> both(SingleActivator a) => {ShortcutScheme.wordPt: a, ShortcutScheme.wordEn: a};

  for (final c in [
    // O cabeçalho e o rodapé: o primeiro clique liga; com ele ligado, leva o
    // cursor até ele.
    run(PageCommandIds.header, l10n.commandHeader, Symbols.vertical_align_top_rounded,
        () => page().header ? doc.editHeaderFooter(footer: false) : doc.insertHeaderFooter(footer: false)),
    run(PageCommandIds.footer, l10n.commandFooter, Symbols.vertical_align_bottom_rounded,
        () => page().footer ? doc.editHeaderFooter(footer: true) : doc.insertHeaderFooter(footer: true)),
    run(PageCommandIds.removeHeader, l10n.commandRemoveHeader, Symbols.hide_rounded,
        () => unawaited(doc.removeHeaderFooter(footer: false)), when: () => page().header),
    run(PageCommandIds.removeFooter, l10n.commandRemoveFooter, Symbols.hide_rounded,
        () => unawaited(doc.removeHeaderFooter(footer: true)), when: () => page().footer),
    run(PageCommandIds.firstPageDifferent, l10n.commandFirstPageDifferent, Symbols.counter_1_rounded,
        () => unawaited(doc.setFirstPageDifferent(!page().firstDifferent)),
        when: hasHeaderOrFooter, active: () => page().firstDifferent),
    run(PageCommandIds.leftRightDifferent, l10n.commandLeftRightDifferent, Symbols.auto_stories_rounded,
        () => unawaited(doc.setLeftRightDifferent(!page().leftDifferent)),
        when: hasHeaderOrFooter, active: () => page().leftDifferent),
    run(PageCommandIds.pageNumber, l10n.commandPageNumber, Symbols.tag_rounded, () => doc.insertField(DocField.pageNumber)),
    run(PageCommandIds.pageCount, l10n.commandPageCount, Symbols.numbers_rounded, () => doc.insertField(DocField.pageCount)),
    run(PageCommandIds.date, l10n.commandDateField, Symbols.calendar_today_rounded, () => doc.insertField(DocField.date)),
    run(PageCommandIds.time, l10n.commandTimeField, Symbols.schedule_rounded, () => doc.insertField(DocField.time)),

    // A hifenização e a capitular
    run(PageCommandIds.hyphenation, l10n.commandHyphenation, Symbols.wrap_text_rounded,
        () => unawaited(doc.setDocumentHyphenation(!page().hyphenation)), active: () => page().hyphenation),
    run(PageCommandIds.hyphenateParagraph, l10n.commandHyphenateParagraph, Symbols.text_select_end_rounded,
        () => doc.setParagraphHyphenation(true)),
    run(PageCommandIds.noHyphenateParagraph, l10n.commandNoHyphenateParagraph, Symbols.text_select_start_rounded,
        () => doc.setParagraphHyphenation(false)),
    run(PageCommandIds.dropCap2, l10n.commandDropCap(2), Symbols.format_size_rounded, () => unawaited(doc.setDropCap(2))),
    run(PageCommandIds.dropCap3, l10n.commandDropCap(3), Symbols.format_size_rounded, () => unawaited(doc.setDropCap(3))),
    run(PageCommandIds.removeDropCap, l10n.commandRemoveDropCap, Symbols.format_clear_rounded,
        () => unawaited(doc.setDropCap(0)), when: () => dropCapBase(doc.paragraphStyle) != null),

    // As quebras
    run(PageCommandIds.columnBreak, l10n.commandColumnBreak, Symbols.view_column_rounded, doc.insertColumnBreak),
    run(PageCommandIds.blankPage, l10n.commandBlankPage, Symbols.note_rounded, doc.insertBlankPage),

    // O PDF e a impressão
    Command(
      id: PageCommandIds.exportPdf,
      label: l10n.commandExportPdf,
      icon: Symbols.picture_as_pdf_rounded,
      run: view.exportPdf,
      canRun: () => doc.isOpen,
    ),
    Command(
      id: PageCommandIds.print,
      label: l10n.commandPrint,
      icon: Symbols.print_rounded,
      run: view.printDocument,
      canRun: () => doc.isOpen,
      shortcuts: both(const SingleActivator(LogicalKeyboardKey.keyP, control: true)),
    ),

    // As notas (os atalhos do Word)
    run(PageCommandIds.footnote, l10n.commandFootnote, Symbols.format_list_numbered_rounded, doc.insertFootnote,
        keys: both(const SingleActivator(LogicalKeyboardKey.keyF, control: true, alt: true))),
    run(PageCommandIds.endnote, l10n.commandEndnote, Symbols.format_list_numbered_rtl_rounded, doc.insertEndnote,
        keys: both(const SingleActivator(LogicalKeyboardKey.keyD, control: true, alt: true))),
    Command(
      id: PageCommandIds.jumpFootnote,
      label: l10n.commandJumpFootnote,
      icon: Symbols.swap_vert_rounded,
      run: doc.jumpFootnote,
      canRun: () => doc.isOpen,
    ),

    // Os links
    run(PageCommandIds.link, l10n.commandLink, Symbols.link_rounded, view.editLink),
    Command(
      id: PageCommandIds.openLink,
      label: l10n.commandOpenLink,
      icon: Symbols.open_in_new_rounded,
      run: () {
        if (doc.link case final l?) view.openLink(l);
      },
      canRun: () => doc.isOpen && doc.link != null,
    ),
    run(PageCommandIds.removeLink, l10n.commandRemoveLink, Symbols.link_off_rounded, doc.removeLink,
        when: () => doc.link != null),
    run(PageCommandIds.specialCharacter, l10n.commandSpecialCharacter, Symbols.special_character_rounded, view.specialCharacter),
    run(PageCommandIds.paragraph, l10n.commandParagraph, Symbols.format_paragraph_rounded, view.paragraphDialog),
  ]) {
    registry.register(c);
  }
}
