// Os fluxos de arquivo: novo, abrir, salvar, salvar como, recentes e sair.
//
// Facade: junta o DocumentController (o motor), a trava do LibreOffice, os
// recentes e as janelas de arquivo. A UI só chama estes métodos; os comandos
// do CommandRegistry também.
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../files/file_dialogs.dart';
import '../files/lo_lock.dart';
import '../files/recent_files.dart';
import '../kit/quill_kit.dart';
import 'document_controller.dart';

/// A resposta a "salvar as alterações?".
enum UnsavedChoice { save, discard, cancel }

/// Os textos das janelas de arquivo (vêm da l10n de quem chama).
class FileDialogLabels {
  const FileDialogLabels({required this.documents, required this.untitled, required this.formats});
  final String documents, untitled;
  final Map<DocFormat, String> formats;
}

class Workspace extends ChangeNotifier {
  Workspace({required this.doc, required this.recents, required this.dialogs, required this.locks}) {
    doc.addListener(_onDoc);
  }

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

  /// Um documento novo, vazio.
  Future<void> newDocument() async {
    if (!await _confirmDiscard()) return;
    doc.open('');
  }

  Future<void> openWithDialog() async {
    if (!await _confirmDiscard()) return;
    final path = await dialogs.pickOpen(label: labels.documents);
    if (path != null) _open(path);
  }

  /// Abre [path] (dos recentes, da linha de comando).
  Future<void> openPath(String path) async {
    if (!await _confirmDiscard()) return;
    _open(path);
  }

  void _open(String path) {
    final verdict = locks.inspect(path);
    _pendingRecent = path;
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
    final current = doc.path;
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
    if (ok && reopen != null) _open(reopen);
    return ok;
  }

  Future<bool> _nextSaveResult() => doc.kit.events
      .firstWhere((e) => e is DocumentSaved || e is SaveFailed)
      .then((e) => e is DocumentSaved)
      .timeout(const Duration(seconds: 60), onTimeout: () => false);

  /// Fechar a janela: pergunta se há alterações, e fecha o documento no
  /// motor (tira a trava). false: o usuário cancelou.
  Future<bool> requestExit() async {
    if (!await _confirmDiscard()) return false;
    await doc.close();
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
    doc.removeListener(_onDoc);
    super.dispose();
  }
}
