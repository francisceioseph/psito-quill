// Os fluxos de arquivo: novo, abrir, salvar, salvar como, recentes e sair.
//
// Facade: junta o DocumentController (o motor), a trava do LibreOffice, os
// recentes e as janelas de arquivo. A UI só chama estes métodos; os comandos
// do CommandRegistry também.
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../book/book.dart';
import '../book/book_controller.dart';
import '../book/book_io.dart';
import '../files/file_dialogs.dart';
import '../files/lo_lock.dart';
import '../files/recent_files.dart';
import '../kit/quill_kit.dart';
import 'document_controller.dart';
import 'recovery.dart';

/// A resposta a "salvar as alterações?".
enum UnsavedChoice { save, discard, cancel }

/// Os textos das janelas de arquivo (vêm da l10n de quem chama).
class FileDialogLabels {
  const FileDialogLabels({required this.documents, required this.untitled, required this.formats});
  final String documents, untitled;
  final Map<DocFormat, String> formats;
}

class Workspace extends ChangeNotifier {
  Workspace({required this.doc, required this.recents, required this.dialogs, required this.locks})
      : book = BookController(doc.kit) {
    doc.addListener(_onDoc);
    // A cópia de recuperação de um capítulo guarda "Livro — Capítulo".
    doc.recoveryTitle = (path) {
      final c = book.chapterAt(path);
      return c == null ? null : '${book.book!.title} — ${c.title}';
    };
  }

  // ------------------------------------------- a recuperação (D-073) --

  /// As cópias de uma sessão que caiu, para a tela inicial oferecer.
  List<RecoveryEntry> recoverable = const [];

  /// Lê as cópias que sobraram (ao abrir o Quill).
  void loadRecoverable() {
    recoverable = doc.recovery?.pending() ?? const [];
    notifyListeners();
  }

  /// Abre a cópia [e] como um documento novo (sem arquivo, modificado). Ela
  /// fica no disco até a aba ser salva ou fechada.
  void recover(RecoveryEntry e) {
    recoverable = [for (final r in recoverable) if (r != e) r];
    notifyListeners();
    // Uma trava velha ao lado da cópia (a sessão caiu com ela aberta).
    final verdict = locks.inspect(e.copy);
    doc.open(e.copy, recovered: e, lockOwner: verdict is LockedBy ? verdict.lock.owner : null);
  }

  /// Apaga a cópia [e] de vez (a tela inicial pergunta antes).
  void discardRecovery(RecoveryEntry e) {
    doc.recovery?.delete(e.id);
    recoverable = [for (final r in recoverable) if (r != e) r];
    notifyListeners();
  }

  /// O livro aberto (Fase 3, D-071). Os capítulos abrem como abas.
  final BookController book;

  final DocumentController doc;
  final RecentFiles recents;
  final FileDialogs dialogs;
  final LockInspector locks;

  /// A UI pergunta "salvar as alterações?". Sem ninguém para perguntar, não
  /// descarta nada: cancela.
  Future<UnsavedChoice> Function()? onUnsaved;

  /// Os textos das janelas (a UI põe aqui ao montar).
  FileDialogLabels labels =
      const FileDialogLabels(documents: 'Documentos', untitled: 'Sem título', formats: {});

  String? _pendingRecent;
  String? _reopenAfterSave;
  DocStatus? _lastStatus;

  void _onDoc() {
    final status = doc.docStatus;
    if (status == _lastStatus) return;
    _lastStatus = status;
    final pending = _pendingRecent;
    if (pending == null) return;
    if (status == DocStatus.open) {
      recents.add(pending);
      _pendingRecent = null;
    } else if (status == DocStatus.failed) {
      if (!File(pending).existsSync()) recents.remove(pending);
      _pendingRecent = null;
    }
  }

  /// Um documento novo, vazio, numa aba nova (D-054).
  Future<void> newDocument() async => doc.open('');

  Future<void> openWithDialog() async {
    final path = await dialogs.pickOpen(label: labels.documents);
    if (path != null) _open(path);
  }

  /// Abre [path] (dos recentes, da linha de comando) numa aba nova. Um livro
  /// abre no fichário.
  Future<void> openPath(String path) async {
    if (isBookPath(path)) {
      await openBook(path);
    } else {
      _open(path);
    }
  }

  /// Abre o livro em [path]: fecha o que estava aberto (perguntando pelas
  /// abas dele), e abre o primeiro capítulo se nenhum documento está aberto.
  /// Devolve o erro, ou null.
  Future<BookError?> openBook(String path) async {
    final dir = bookDirOf(path);
    if (book.dir == dir) return null;
    if (book.isOpen && !await closeBook()) return null;
    try {
      await book.open(dir);
    } on BookException catch (e) {
      if (e.error == BookError.missing) recents.remove(path);
      return e.error;
    }
    recents.add(dir);
    _openFirstChapter();
    return null;
  }

  /// O livro recém-criado ou importado: entra nos recentes e abre o primeiro
  /// capítulo.
  void adoptBook(String dir, Book created) {
    book.adopt(dir, created);
    recents.add(dir);
    _openFirstChapter();
  }

  void _openFirstChapter() {
    if (doc.isOpen) return;
    final first = book.book?.chapters.firstOrNull;
    if (first != null) openChapter(first);
  }

  /// Abre o capítulo [node] do livro numa aba (ou só lhe dá a tela).
  void openChapter(BookNode node) {
    final path = book.pathOf(node);
    if (path != null) _open(path);
  }

  /// Fecha o livro: as abas dos capítulos dele fecham, perguntando se há
  /// alterações. false: o usuário cancelou.
  Future<bool> closeBook() async {
    if (!book.isOpen) return true;
    for (final t in [...doc.tabs]) {
      if (book.chapterAt(doc.tabPath(t)) == null) continue;
      if (!await closeTab(t)) return false;
    }
    book.close();
    return true;
  }

  void _open(String path) {
    // Já aberto: só ganha a tela.
    for (final t in doc.tabs) {
      if (doc.tabPath(t) == path) {
        doc.activateTab(t);
        recents.add(path);
        return;
      }
    }
    final verdict = locks.inspect(path);
    // Os capítulos do livro não entram nos recentes: o livro já está lá.
    _pendingRecent = book.chapterAt(path) == null ? path : null;
    doc.open(path, lockOwner: verdict is LockedBy ? verdict.lock.owner : null);
  }

  /// Salva; sem arquivo (ou só leitura), pergunta onde. Devolve se salvou.
  Future<bool> save() async {
    if (!doc.isOpen) return false;
    if (doc.path == null || doc.readOnly) return saveAs();
    final done = _nextSaveResult();
    doc.save();
    return done;
  }

  Future<bool> saveAs() async {
    if (!doc.isOpen) return false;
    // Uma cópia recuperada sugere o arquivo de onde veio.
    final current = doc.path ?? doc.recovered?.original;
    final target = await dialogs.pickSave(
      suggestedName: current == null ? '${labels.untitled}.odt' : File(current).uri.pathSegments.last,
      initialDirectory: current == null ? null : File(current).parent.path,
      labels: labels.formats,
    );
    if (target == null) return false;
    // Uma cópia de um arquivo só leitura: reabre a cópia, agora editável.
    if (doc.readOnly) _reopenAfterSave = target;
    final done = _nextSaveResult();
    doc.saveAs(target);
    final ok = await done;
    if (ok) recents.add(target);
    final reopen = _reopenAfterSave;
    _reopenAfterSave = null;
    if (ok && reopen != null) {
      // A aba só leitura dá lugar à cópia, editável.
      final old = doc.currentTab;
      if (old != null) await doc.closeTab(old);
      _open(reopen);
    }
    return ok;
  }

  /// Fecha uma aba (a da tela, sem [tab]): pergunta se há alterações, com a
  /// aba na tela. false: o usuário cancelou.
  Future<bool> closeTab([DocTab? tab]) async {
    final t = tab ?? doc.currentTab;
    if (t == null) return true;
    if (doc.tabModified(t) && t != doc.currentTab) doc.activateTab(t);
    if (t == doc.currentTab && !await _confirmDiscard()) return false;
    await doc.closeTab(t);
    return true;
  }

  Future<bool> _nextSaveResult() => doc.kit.events
      .firstWhere((e) => e is DocumentSaved || e is SaveFailed)
      .then((e) => e is DocumentSaved)
      .timeout(const Duration(seconds: 60), onTimeout: () => false);

  /// Fechar a janela: pergunta se há alterações, e fecha o documento no
  /// motor (tira a trava). false: o usuário cancelou.
  Future<bool> requestExit() async {
    // Uma pergunta por aba com alterações, cada uma na tela.
    for (final t in [...doc.tabs]) {
      if (!doc.tabModified(t)) continue;
      doc.activateTab(t);
      if (!await _confirmDiscard()) return false;
    }
    if (doc.tabs.isEmpty && !await _confirmDiscard()) return false;
    await doc.close();
    // Saiu direito: as cópias desta sessão não servem (as de uma sessão que
    // caiu e não foram escolhidas ficam).
    doc.recovery?.deleteSession();
    return true;
  }

  /// true: pode seguir (salvou ou descartou, ou não havia o que salvar).
  Future<bool> _confirmDiscard() async {
    if (!doc.isOpen || !doc.modified || doc.readOnly) return true;
    final ask = onUnsaved;
    final choice = ask == null ? UnsavedChoice.cancel : await ask();
    return switch (choice) {
      UnsavedChoice.save => save(),
      UnsavedChoice.discard => true,
      UnsavedChoice.cancel => false,
    };
  }

  @override
  void dispose() {
    book.dispose();
    doc.removeListener(_onDoc);
    super.dispose();
  }
}
