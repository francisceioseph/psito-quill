import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/document/document_controller.dart';
import 'package:psito_quill/src/document/workspace.dart';
import 'package:psito_quill/src/files/lo_lock.dart';

import '../support/harness.dart';

void main() {
  late Harness h;
  setUp(() => h = Harness());
  tearDown(() => h.dispose());

  test('abrir põe nos recentes', () async {
    final p = h.file('cap.odt');
    await h.workspace.openPath(p);
    expect(h.doc.isOpen, isTrue);
    expect(h.recents.paths, [p]);
  });

  test('arquivo que sumiu sai dos recentes quando não abre', () async {
    h.kit.openFails = true;
    h.recents.add('/nao/existe.odt');
    await h.workspace.openPath('/nao/existe.odt');
    expect(h.doc.docStatus, DocStatus.failed);
    expect(h.recents.paths, isEmpty);
  });

  test('trava velha do próprio Quill é apagada, e abre editável', () async {
    final p = h.file('cap.odt');
    h.lock(p);
    await h.workspace.openPath(p);
    expect(LoLock.fileFor(p).existsSync(), isFalse);
    expect(h.doc.readOnly, isFalse);
  });

  test('trava de outro abre só leitura, com o nome de quem está com o arquivo', () async {
    final p = h.file('cap.odt');
    h.lock(p, profile: 'file:///home/eu/.config/libreoffice/4', user: 'maria');
    await h.workspace.openPath(p);
    expect(h.doc.readOnly, isTrue);
    expect(h.doc.lockOwner, 'maria');
    h.doc.uno('.uno:Bold');
    expect(h.kit.unoCommands, isEmpty, reason: 'só leitura não edita');
  });

  test('salvar sem arquivo pergunta onde; cancelar não salva', () async {
    h.doc.open('');
    expect(await h.workspace.save(), isFalse);
    expect(h.dialogs.saves, ['Sem título.odt']);
    expect(h.kit.saved, isEmpty);
    h.dialogs.saveAnswer = '${h.dir.path}/novo.docx';
    expect(await h.workspace.save(), isTrue);
    expect(h.kit.saved.single, ('${h.dir.path}/novo.docx', 'docx'));
    expect(h.doc.path, '${h.dir.path}/novo.docx');
  });

  test('alterações: Cancelar não troca de documento; Salvar salva antes', () async {
    final p = h.file('cap.odt');
    await h.workspace.openPath(p);
    h.doc.insertText('olá');
    expect(h.doc.modified, isTrue);

    h.workspace.onUnsaved = () async => UnsavedChoice.cancel;
    await h.workspace.newDocument();
    expect(h.doc.path, p);

    h.workspace.onUnsaved = () async => UnsavedChoice.save;
    await h.workspace.newDocument();
    expect(h.kit.saved.single.$1, p);
    expect(h.kit.opened.last, '');
  });

  test('sem ninguém para perguntar, nada se perde (cancela)', () async {
    await h.workspace.openPath(h.file('cap.odt'));
    h.doc.insertText('x');
    expect(await h.workspace.requestExit(), isFalse);
    expect(h.doc.isOpen, isTrue);
  });

  test('sair sem alterações fecha o documento no motor', () async {
    await h.workspace.openPath(h.file('cap.odt'));
    expect(await h.workspace.requestExit(), isTrue);
    expect(h.doc.docStatus, DocStatus.none);
  });

  test('Abrir pelo diálogo; cancelar não faz nada', () async {
    await h.workspace.openWithDialog();
    expect(h.kit.opened, isEmpty);
    h.dialogs.openAnswer = h.file('b.docx');
    await h.workspace.openWithDialog();
    expect(h.kit.opened.single, h.dialogs.openAnswer);
  });
}
