// Os comandos da Página Inicial, do Layout e do Inserir que vieram do
// OnlyOffice (Fase 4, Etapa 7, D-092): o pincel, maiúsculas e minúsculas, as
// listas de vários níveis, as colunas, os números de linha, a marca d'água,
// organizar as imagens e a caixa de texto. A marca d'água pede uma janela,
// que é da página do editor ([LayoutViewActions]).
import 'package:flutter/widgets.dart' show IconData;
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/gen/app_localizations.dart';
import '../document/document_controller.dart';
import 'command_registry.dart';

abstract final class LayoutCommandIds {
  static const paintbrush = 'formatar.pincel';
  static const caseSentence = 'formatar.caixaFrase';
  static const caseLower = 'formatar.caixaMinusculas';
  static const caseUpper = 'formatar.caixaMaiusculas';
  static const caseTitle = 'formatar.caixaTitulo';
  static const caseToggle = 'formatar.caixaInverter';
  static const listDecimal = 'lista.decimal';
  static const listRoman = 'lista.romana';
  static const listLetters = 'lista.letras';
  static const listParenthesis = 'lista.parenteses';
  static const listBullets = 'lista.marcadores';
  static const listLevelDown = 'lista.descerNivel';
  static const listLevelUp = 'lista.subirNivel';
  static const columns1 = 'layout.colunas1';
  static const columns2 = 'layout.colunas2';
  static const columns3 = 'layout.colunas3';
  static const lineNumbers = 'layout.numerosDeLinha';
  static const watermark = 'layout.marcaDagua';
  static const removeWatermark = 'layout.tirarMarcaDagua';
  static const arrangeFront = 'imagem.trazerParaFrente';
  static const arrangeForward = 'imagem.avancar';
  static const arrangeBackward = 'imagem.recuar';
  static const arrangeBack = 'imagem.enviarParaTras';
  static const textBox = 'inserir.caixaDeTexto';

  static const cases = [caseSentence, caseLower, caseUpper, caseTitle, caseToggle];
  static const lists = [listDecimal, listRoman, listLetters, listParenthesis, listBullets];
  static const columns = [columns1, columns2, columns3];
  static const arrange = [arrangeFront, arrangeForward, arrangeBackward, arrangeBack];
}

/// O que a página do editor abre para estes comandos.
abstract interface class LayoutViewActions {
  /// A janela da marca d'água: o texto, a cor e a direção.
  void watermark();
}

void registerLayoutCommands(
  CommandRegistry registry, {
  required DocumentController doc,
  required LayoutViewActions view,
  required AppLocalizations l10n,
}) {
  Command run(String id, String label, IconData icon, void Function() action, {bool Function()? when, bool Function()? active}) =>
      Command(
        id: id,
        label: label,
        icon: icon,
        run: action,
        canRun: () => doc.canEdit && (when?.call() ?? true),
        isActive: active,
      );
  bool onImage() => doc.graphic != null;

  for (final c in [
    run(LayoutCommandIds.paintbrush, l10n.commandPaintbrush, Symbols.format_paint_rounded, doc.formatPaintbrush,
        active: () => doc.paintbrushOn),
    run(LayoutCommandIds.caseSentence, l10n.commandCaseSentence, Symbols.match_case_rounded, () => doc.changeCase(TextCase.sentence),
        when: () => doc.hasSelection),
    run(LayoutCommandIds.caseLower, l10n.commandCaseLower, Symbols.lowercase_rounded, () => doc.changeCase(TextCase.lower),
        when: () => doc.hasSelection),
    run(LayoutCommandIds.caseUpper, l10n.commandCaseUpper, Symbols.uppercase_rounded, () => doc.changeCase(TextCase.upper),
        when: () => doc.hasSelection),
    run(LayoutCommandIds.caseTitle, l10n.commandCaseTitle, Symbols.title_rounded, () => doc.changeCase(TextCase.title),
        when: () => doc.hasSelection),
    run(LayoutCommandIds.caseToggle, l10n.commandCaseToggle, Symbols.swap_vert_rounded, () => doc.changeCase(TextCase.toggle),
        when: () => doc.hasSelection),
    run(LayoutCommandIds.listDecimal, l10n.commandListDecimal, Symbols.format_list_numbered_rounded,
        () => doc.setMultilevelList(MultilevelList.decimal)),
    run(LayoutCommandIds.listRoman, l10n.commandListRoman, Symbols.format_list_numbered_rounded,
        () => doc.setMultilevelList(MultilevelList.roman)),
    run(LayoutCommandIds.listLetters, l10n.commandListLetters, Symbols.format_list_numbered_rounded,
        () => doc.setMultilevelList(MultilevelList.letters)),
    run(LayoutCommandIds.listParenthesis, l10n.commandListParenthesis, Symbols.format_list_numbered_rounded,
        () => doc.setMultilevelList(MultilevelList.parenthesis)),
    run(LayoutCommandIds.listBullets, l10n.commandListBullets, Symbols.format_list_bulleted_rounded,
        () => doc.setMultilevelList(MultilevelList.bullets)),
    run(LayoutCommandIds.listLevelDown, l10n.commandListLevelDown, Symbols.format_indent_increase_rounded, doc.listLevelDown),
    run(LayoutCommandIds.listLevelUp, l10n.commandListLevelUp, Symbols.format_indent_decrease_rounded, doc.listLevelUp),
    for (final (i, id) in LayoutCommandIds.columns.indexed)
      run(id, l10n.commandColumns(i + 1), Symbols.view_column_rounded, () => doc.setPageColumns(i + 1),
          active: () => (doc.pageColumns ?? 1) == i + 1),
    run(LayoutCommandIds.lineNumbers, l10n.commandLineNumbers, Symbols.format_list_numbered_rounded,
        () => doc.setLineNumbers(!doc.snapshot.page.lineNumbers), active: () => doc.snapshot.page.lineNumbers),
    run(LayoutCommandIds.watermark, l10n.commandWatermark, Symbols.branding_watermark_rounded, view.watermark),
    run(LayoutCommandIds.removeWatermark, l10n.commandRemoveWatermark, Symbols.hide_source_rounded, () => doc.setWatermark(null),
        when: () => doc.snapshot.page.watermark != null),
    run(LayoutCommandIds.arrangeFront, l10n.commandArrangeFront, Symbols.flip_to_front_rounded, () => doc.arrange(Arrange.front),
        when: onImage),
    run(LayoutCommandIds.arrangeForward, l10n.commandArrangeForward, Symbols.arrow_upward_rounded, () => doc.arrange(Arrange.forward),
        when: onImage),
    run(LayoutCommandIds.arrangeBackward, l10n.commandArrangeBackward, Symbols.arrow_downward_rounded,
        () => doc.arrange(Arrange.backward), when: onImage),
    run(LayoutCommandIds.arrangeBack, l10n.commandArrangeBack, Symbols.flip_to_back_rounded, () => doc.arrange(Arrange.back),
        when: onImage),
    run(LayoutCommandIds.textBox, l10n.commandTextBox, Symbols.text_fields_rounded, doc.insertTextBox),
  ]) {
    registry.register(c);
  }
}
