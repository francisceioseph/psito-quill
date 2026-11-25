// Os comandos das referências (Fase 4, Etapa 5, D-090): o sumário, as
// legendas e as tabelas delas, os marcadores, a referência cruzada e o
// índice remissivo. O marcador e a referência pedem uma janela, que é da
// página do editor ([ReferenceViewActions]).
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show IconData, SingleActivator;
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/gen/app_localizations.dart';
import '../document/document_controller.dart';
import '../document/references.dart';
import 'command_registry.dart';

abstract final class ReferenceCommandIds {
  static const toc = 'referencias.sumario';
  static const updateIndexes = 'referencias.atualizar';
  static const caption = 'referencias.legenda';
  static const figureTable = 'referencias.tabelaFiguras';
  static const tableTable = 'referencias.tabelaTabelas';
  static const bookmark = 'referencias.marcador';
  static const crossReference = 'referencias.referenciaCruzada';
  static const markEntry = 'referencias.marcarEntrada';
  static const markAll = 'referencias.marcarTodas';
  static const index = 'referencias.indice';
}

/// O que a página do editor abre para estes comandos.
abstract interface class ReferenceViewActions {
  /// A janela dos marcadores: um novo, ir a um, apagar.
  void bookmarks();

  /// A janela da referência cruzada.
  void crossReference();
}

void registerReferenceCommands(
  CommandRegistry registry, {
  required DocumentController doc,
  required ReferenceViewActions view,
  required AppLocalizations l10n,
}) {
  Command run(String id, String label, IconData icon, void Function() action,
          {bool Function()? when, Map<ShortcutScheme, SingleActivator> keys = const {}}) =>
      Command(
        id: id,
        label: label,
        icon: icon,
        run: action,
        canRun: () => doc.canEdit && (when?.call() ?? true),
        shortcuts: keys,
      );

  Map<ShortcutScheme, SingleActivator> both(SingleActivator a) => {ShortcutScheme.wordPt: a, ShortcutScheme.wordEn: a};

  for (final c in [
    run(ReferenceCommandIds.toc, l10n.commandTocHere, Symbols.toc_rounded, () => doc.insertToc(l10n.tocTitleDefault)),
    run(ReferenceCommandIds.updateIndexes, l10n.commandUpdateIndexes, Symbols.refresh_rounded, doc.updateIndexes),
    run(
      ReferenceCommandIds.caption,
      l10n.commandCaption,
      Symbols.subtitles_rounded,
      () => doc.graphic != null
          ? doc.insertCaption(CaptionKind.figure, l10n.captionFigure)
          : doc.insertCaption(CaptionKind.table, l10n.captionTable),
      when: () => doc.graphic != null || doc.inTable,
    ),
    run(ReferenceCommandIds.figureTable, l10n.commandFigureTable, Symbols.photo_library_rounded,
        () => doc.insertCaptionTable(l10n.figureTableTitle, CaptionKind.figure)),
    run(ReferenceCommandIds.tableTable, l10n.commandTableTable, Symbols.table_view_rounded,
        () => doc.insertCaptionTable(l10n.tableTableTitle, CaptionKind.table)),
    // Ctrl+Shift+F5, como no Word.
    run(ReferenceCommandIds.bookmark, l10n.commandBookmark, Symbols.bookmark_add_rounded, view.bookmarks,
        keys: both(const SingleActivator(LogicalKeyboardKey.f5, control: true, shift: true))),
    run(ReferenceCommandIds.crossReference, l10n.commandCrossReference, Symbols.move_down_rounded, view.crossReference),
    // Alt+Shift+X, como no Word.
    run(ReferenceCommandIds.markEntry, l10n.commandMarkEntry, Symbols.bookmark_rounded, () => doc.markIndexEntry(),
        when: () => doc.hasSelection, keys: both(const SingleActivator(LogicalKeyboardKey.keyX, alt: true, shift: true))),
    run(ReferenceCommandIds.markAll, l10n.commandMarkAll, Symbols.bookmarks_rounded, () => doc.markIndexEntry(all: true),
        when: () => doc.hasSelection),
    run(ReferenceCommandIds.index, l10n.commandIndex, Symbols.sort_by_alpha_rounded, () => doc.insertIndex(l10n.indexTitle)),
  ]) {
    registry.register(c);
  }
}
