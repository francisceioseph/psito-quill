// Os comandos do livro (Fase 3, Etapa 1, D-071): novo, abrir, importar e
// fechar o livro, o fichário, e os capítulos e partes novos; e as cenas
// (Etapa 5, D-079): nova cena, dividir, juntar e converter os separadores;
// e os instantâneos (Etapa 7, D-081); e as notas (Etapa 8, D-082); e as
// metas (Etapa 9, D-083); e a cortiça (Etapa 10, D-084).
//
// Command com receptor, como os de tela: o que pede uma janela (o título do
// livro, a pasta, o manuscrito) é da página do editor, que implementa
// [BookViewActions].
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/gen/app_localizations.dart';
import '../document/document_controller.dart';
import '../document/workspace.dart';
import 'command_registry.dart';

abstract final class BookCommandIds {
  static const newBook = 'livro.novo';
  static const openBook = 'livro.abrir';
  static const importManuscript = 'livro.importar';
  static const closeBook = 'livro.fechar';
  static const binder = 'livro.fichario';
  static const newChapter = 'livro.novoCapitulo';
  static const newPart = 'livro.novaParte';
  // As cenas (Etapa 5, D-079).
  static const newScene = 'livro.novaCena';
  static const splitChapter = 'livro.dividir';
  static const joinChapter = 'livro.juntar';
  static const convertScenes = 'livro.converterCenas';
  // Os instantâneos (Etapa 7, D-081).
  static const takeSnapshot = 'livro.instantaneo';
  static const snapshots = 'livro.instantaneos';
  // As notas (Etapa 8, D-082).
  static const notes = 'livro.notas';
  static const newNote = 'livro.novaNota';
  // As metas (Etapa 9, D-083).
  static const goals = 'livro.metas';
  // A cortiça (Etapa 10, D-084).
  static const corkboard = 'livro.cortica';
}

/// O que a página do editor sabe abrir para o livro.
abstract interface class BookViewActions {
  void newBook();
  void openBook();
  void importManuscript();
  void toggleBinder();
  bool get binderOpen;
  void newChapter();
  void newPart();
  void newScene();
  void splitChapter();
  void joinChapter();
  void convertScenes();
  void takeSnapshot();
  void showSnapshots();
  void toggleNotes();
  bool get notesOpen;
  void newNote();
  void showGoals();
  void toggleCorkboard();
  bool get corkboardOpen;
}

void registerBookCommands(
  CommandRegistry registry, {
  required DocumentController doc,
  required Workspace workspace,
  required BookViewActions view,
  required AppLocalizations l10n,
}) {
  bool ready() => doc.kitStatus == KitStatus.ready;
  bool inBook() => workspace.book.isOpen;
  bool editable() => ready() && doc.canEdit && doc.busy == null;
  bool inChapter() => editable() && workspace.book.chapterAt(doc.path) != null;
  for (final c in [
    Command(id: BookCommandIds.newBook, label: l10n.commandNewBook, icon: Symbols.library_add_rounded, run: view.newBook, canRun: ready),
    Command(id: BookCommandIds.openBook, label: l10n.commandOpenBook, icon: Symbols.book_rounded, run: view.openBook, canRun: ready),
    Command(
      id: BookCommandIds.importManuscript,
      label: l10n.commandImportManuscript,
      icon: Symbols.upload_file_rounded,
      run: view.importManuscript,
      canRun: ready,
    ),
    Command(
      id: BookCommandIds.closeBook,
      label: l10n.commandCloseBook,
      icon: Symbols.book_rounded,
      run: () => workspace.closeBook(),
      canRun: inBook,
    ),
    Command(
      id: BookCommandIds.binder,
      label: l10n.commandBinder,
      icon: Symbols.account_tree_rounded,
      run: view.toggleBinder,
      isActive: () => view.binderOpen,
      canRun: inBook,
    ),
    Command(
      id: BookCommandIds.newChapter,
      label: l10n.commandNewChapter,
      icon: Symbols.note_add_rounded,
      run: view.newChapter,
      canRun: () => inBook() && ready(),
    ),
    Command(
      id: BookCommandIds.newPart,
      label: l10n.commandNewPart,
      icon: Symbols.create_new_folder_rounded,
      run: view.newPart,
      canRun: inBook,
    ),
    Command(
      id: BookCommandIds.newScene,
      label: l10n.commandNewScene,
      icon: Symbols.more_horiz_rounded,
      run: view.newScene,
      canRun: editable,
    ),
    Command(
      id: BookCommandIds.splitChapter,
      label: l10n.commandSplitChapter,
      icon: Symbols.call_split_rounded,
      run: view.splitChapter,
      canRun: inChapter,
    ),
    Command(
      id: BookCommandIds.joinChapter,
      label: l10n.commandJoinChapter,
      icon: Symbols.merge_rounded,
      run: view.joinChapter,
      canRun: () => inChapter() && workspace.nextChapter != null,
    ),
    Command(
      id: BookCommandIds.convertScenes,
      label: l10n.commandConvertScenes,
      icon: Symbols.auto_fix_high_rounded,
      run: view.convertScenes,
      canRun: editable,
    ),
    Command(
      id: BookCommandIds.takeSnapshot,
      label: l10n.commandTakeSnapshot,
      icon: Symbols.add_a_photo_rounded,
      run: view.takeSnapshot,
      canRun: () => ready() && doc.busy == null && workspace.book.chapterAt(doc.path) != null,
    ),
    Command(
      id: BookCommandIds.snapshots,
      label: l10n.commandSnapshots,
      icon: Symbols.history_rounded,
      run: view.showSnapshots,
      canRun: () => ready() && workspace.book.chapterAt(doc.path) != null,
    ),
    Command(
      id: BookCommandIds.notes,
      label: l10n.commandNotes,
      icon: Symbols.sticky_note_2_rounded,
      run: view.toggleNotes,
      isActive: () => view.notesOpen,
      canRun: inBook,
    ),
    Command(
      id: BookCommandIds.newNote,
      label: l10n.commandNewNote,
      icon: Symbols.note_stack_add_rounded,
      run: view.newNote,
      canRun: inBook,
    ),
    Command(
      id: BookCommandIds.goals,
      label: l10n.commandGoals,
      icon: Symbols.flag_rounded,
      run: view.showGoals,
      canRun: inBook,
    ),
    Command(
      id: BookCommandIds.corkboard,
      label: l10n.commandCorkboard,
      icon: Symbols.dashboard_rounded,
      run: view.toggleCorkboard,
      isActive: () => view.corkboardOpen,
      canRun: inBook,
    ),
  ]) {
    registry.register(c);
  }
}
