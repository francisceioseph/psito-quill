// O salvamento automático e a recuperação (Fase 3, Etapa 2, D-073).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/document/document_controller.dart';
import 'package:psito_quill/src/document/recovery.dart';
import 'package:psito_quill/src/document/workspace.dart';

import '../support/harness.dart';

void main() {
  late Harness h;
  late Directory dir;
  late RecoveryStore store;

  final every = DocumentController.autosaveEvery, pause = DocumentController.autosavePause;
  setUpAll(() {
    DocumentController.autosaveEvery = const Duration(milliseconds: 60);
    DocumentController.autosavePause = const Duration(milliseconds: 30);
  });
  tearDownAll(() {
    DocumentController.autosaveEvery = every;
    DocumentController.autosavePause = pause;
  });

  setUp(() {
    h = Harness();
    dir = Directory('${h.dir.path}/recuperacao');
    store = RecoveryStore(dir, session: 'agora');
    h.doc.recovery = store;
  });
  tearDown(() => h.dispose());

  /// Uma cópia gravada por uma sessão que caiu.
  RecoveryEntry crashed(String id, {String? original, String? title, DateTime? at}) {
    final old = RecoveryStore(dir, session: id.split('-').first)..ensureDir();
    File(old.writingPath(id)).writeAsStringSync('odt');
    old.commit(id, original: original, title: title, at: at);
    return store.pending().firstWhere((e) => e.id == id);
  }

  List<String> files() {
    if (!dir.existsSync()) return [];
    return [for (final f in dir.listSync()) f.uri.pathSegments.last]..sort();
  }

  Future<void> wait([int ms = 150]) => Future<void>.delayed(Duration(milliseconds: ms));

  group('a pasta', () {
    test('as cópias de outra sessão são as que caíram, a mais nova primeiro', () {
      crashed('velha-1', original: '/livros/a.odt', at: DateTime(2026, 11, 20));
      crashed('velha-2', title: 'Dustland — A poeira', at: DateTime(2026, 11, 22));
      final mine = store..ensureDir();
      File(mine.writingPath(mine.idFor(1))).writeAsStringSync('odt');
      mine.commit(mine.idFor(1));
      final p = store.pending();
      expect([for (final e in p) e.id], ['velha-2', 'velha-1']);
      expect(p.last.name, 'a.odt');
      expect(p.first.name, 'Dustland — A poeira');
      expect(RecoveryEntry(id: 'x', copy: '', savedAt: DateTime(2026)).name, isNull);
    });

    test('sair apaga só as da sessão; uma gravação pela metade não é cópia', () {
      crashed('velha-1');
      File(store.writingPath('velha-3')).writeAsStringSync('meio');
      File(store.writingPath(store.idFor(1))).writeAsStringSync('odt');
      store.commit(store.idFor(1));
      store.deleteSession();
      expect([for (final e in store.pending()) e.id], ['velha-1']);
      expect(files(), ['velha-1.json', 'velha-1.odt'], reason: 'a pela metade saiu ao listar');
    });
  });

  group('o salvamento automático', () {
    test('com alterações, a cópia sai depois do intervalo e de uma pausa', () async {
      final p = h.file('cap.odt');
      await h.workspace.openPath(p);
      h.doc.insertText('Era uma vez');
      expect(h.kit.copies.where((c) => c.$2 == 'odt'), isEmpty, reason: 'nunca a cada tecla');
      await wait();
      expect(h.kit.copies.where((c) => c.$2 == 'odt'), hasLength(1));
      final id = store.idFor(h.doc.currentTab!.serial);
      expect(files(), ['$id.json', '$id.odt']);
      final e = RecoveryStore(dir, session: 'outra').pending().single;
      expect(e.original, p);
      // Sem nova alteração, nenhuma cópia nova.
      await wait();
      expect(h.kit.copies.where((c) => c.$2 == 'odt'), hasLength(1));
    });

    test('digitando sem parar, a cópia espera a pausa', () async {
      await h.workspace.openPath(h.file('cap.odt'));
      for (var i = 0; i < 8; i++) {
        h.doc.insertText('a');
        await wait(15);
      }
      expect(h.kit.copies.where((c) => c.$2 == 'odt'), isEmpty);
      await wait(60);
      expect(h.kit.copies.where((c) => c.$2 == 'odt'), hasLength(1));
    });

    test('salvar e fechar a aba apagam a cópia', () async {
      await h.workspace.openPath(h.file('cap.odt'));
      h.doc.insertText('x');
      await wait();
      expect(files(), hasLength(2));
      await h.workspace.save();
      expect(files(), isEmpty);
      h.doc.insertText('y');
      await wait();
      expect(files(), hasLength(2));
      await h.doc.closeTab(h.doc.currentTab!);
      expect(files(), isEmpty);
    });

    test('trocar de aba grava a cópia da que sai na hora', () async {
      await h.workspace.openPath(h.file('a.odt'));
      h.doc.insertText('x');
      final a = h.doc.currentTab!;
      await h.workspace.openPath(h.file('b.odt'));
      expect(h.kit.copies.where((c) => c.$2 == 'odt'), hasLength(1));
      expect(files(), contains('${store.idFor(a.serial)}.odt'));
    });

    test('desfazer tudo apaga a cópia; desligar não grava e apaga as da sessão', () async {
      await h.workspace.openPath(h.file('cap.odt'));
      h.doc.insertText('x');
      await wait();
      expect(files(), hasLength(2));
      h.kit.emitState('.uno:ModifiedStatus', 'false');
      h.doc.uno('.uno:Bold');
      await wait();
      expect(files(), isEmpty, reason: 'sem alterações, o arquivo já é o documento');
      h.doc.insertText('y');
      await wait();
      expect(files(), hasLength(2));
      h.doc.autosave = false;
      expect(files(), isEmpty);
      h.doc.insertText('z');
      await wait();
      expect(files(), isEmpty);
    });

    test('a aba que fecha no meio da gravação não deixa cópia', () async {
      await h.workspace.openPath(h.file('cap.odt'));
      h.kit.holdCopies = true;
      h.doc.insertText('x');
      await wait();
      expect(h.kit.heldCopies, hasLength(1));
      await h.doc.closeTab(h.doc.currentTab!);
      h.kit.finishCopy(h.kit.heldCopies.single);
      expect(files(), isEmpty);
    });
  });

  group('recuperar', () {
    test('abre a cópia como documento novo, modificado, com o nome de onde veio', () async {
      final e = crashed('velha-1', original: '${h.dir.path}/Dustland.odt');
      h.workspace.loadRecoverable();
      expect(h.workspace.recoverable, [e]);
      h.workspace.recover(e);
      expect(h.workspace.recoverable, isEmpty);
      expect(h.kit.opened.last, e.copy);
      expect(h.doc.isOpen, isTrue);
      expect(h.doc.path, isNull);
      expect(h.doc.recovered, e);
      expect(h.doc.modified, isTrue, reason: 'fechar pergunta se salva');
      expect(h.recents.paths, isEmpty, reason: 'a cópia não entra nos recentes');

      h.dialogs.saveAnswer = '${h.dir.path}/Dustland.odt';
      expect(await h.workspace.save(), isTrue);
      expect(h.dialogs.saves.last, 'Dustland.odt', reason: 'sugere o arquivo de onde veio');
      expect(h.kit.saved.last, ('${h.dir.path}/Dustland.odt', 'odt'));
      expect(h.doc.recovered, isNull);
      expect(h.doc.modified, isFalse);
      expect(files(), isEmpty, reason: 'salvou: a cópia sai');
    });

    test('a cópia nova da aba recuperada substitui a antiga', () async {
      final e = crashed('velha-1');
      h.workspace.recover(e);
      h.doc.insertText('mais');
      await wait();
      final id = store.idFor(h.doc.currentTab!.serial);
      expect(files(), ['$id.json', '$id.odt']);
    });

    test('descartar apaga; sair apaga as da sessão e deixa as não escolhidas', () async {
      final a = crashed('velha-1'), b = crashed('velha-2');
      h.workspace.loadRecoverable();
      h.workspace.discardRecovery(a);
      expect(h.workspace.recoverable, [b]);
      await h.workspace.openPath(h.file('cap.odt'));
      h.doc.insertText('x');
      await wait();
      h.workspace.onUnsaved = () async => UnsavedChoice.discard;
      expect(await h.workspace.requestExit(), isTrue);
      expect(files(), ['velha-2.json', 'velha-2.odt']);
    });
  });
}
