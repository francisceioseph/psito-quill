// Os comandos do livro (Fase 3, Etapa 1, D-071): novo, abrir, importar e
// fechar o livro, o fichário, e os capítulos e partes novos.
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
  ]) {
    registry.register(c);
  }
}
