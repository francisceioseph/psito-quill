// Integração com o LibreOffice de verdade, em passos: abrir o DOCX de 30
// páginas, digitar (também pelo IME), desfazer, negrito, copiar e colar,
// salvar em DOCX e em ODT, reabrir, a trava do LibreOffice, o clique triplo e
// o Lua.
//
// Roda com `./test.sh --integracao` (abre uma janela; precisa de sessão
// gráfica). O perfil do LibreOffice, os documentos, a área de transferência e
// as preferências são temporários: não toca nos do usuário.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:psito_quill/src/app.dart';
import 'package:psito_quill/src/document/document_controller.dart';
import 'package:psito_quill/src/document/text_clipboard.dart';
import 'package:psito_quill/src/document/workspace.dart';
import 'package:psito_quill/src/files/lo_lock.dart';
import 'package:psito_quill/src/files/recent_files.dart';
import 'package:psito_quill/src/kit/lok/lo_profile.dart';
import 'package:psito_quill/src/kit/lok/lok_quill_kit.dart';
import 'package:psito_quill/src/kit/lok/vcl_keys.dart';
import 'package:psito_quill/src/kit/quill_kit.dart';
import 'package:psito_quill/src/settings/settings.dart';
import 'package:psito_quill/src/ui/tokens/themes/themes.dart';

import '../test/support/harness.dart' show FakeFileDialogs, FakeAppWindow;

String unzip(String path, String member) => Process.runSync('unzip', ['-p', path, member]).stdout as String;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // O LOK só liga uma vez por processo: um teste só, em passos.
  testWidgets('motor real: editar, salvar, reabrir, trava, Lua', (tester) async {
    final tmp = Directory.systemTemp.createTempSync('quill-integracao-');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final source = File('test/fixtures/capitulo-30p.docx').absolute;
    final work = source.copySync('${tmp.path}/capitulo.docx').path;

    final profile = LoProfile(Directory('${tmp.path}/perfil'))..ensureSchemes(paperSchemes(builtInThemes));
    final kit = LokQuillKit(profile: profile);
    final clipboard = MemoryTextClipboard();
    final doc = DocumentController(kit, clipboard: clipboard);
    final dialogs = FakeFileDialogs();
    final workspace = Workspace(
      doc: doc,
      recents: RecentFiles(File('${tmp.path}/recentes.json')),
      dialogs: dialogs,
      locks: LockInspector(profileUrl: profile.url),
    );
    final events = <KitEvent>[];
    final sub = kit.events.listen(events.add);

    Future<void> until(bool Function() test, String what, {int seconds = 60}) async {
      final end = DateTime.now().add(Duration(seconds: seconds));
      while (!test()) {
        if (DateTime.now().isAfter(end)) fail('esperou demais: $what');
        await tester.pump(const Duration(milliseconds: 20));
      }
    }

    Future<void> settle([int ms = 300]) => tester.pump(Duration(milliseconds: ms));

    Future<void> openAndWait(String path) async {
      await workspace.openPath(path);
      await until(() => doc.docStatus != DocStatus.opening, 'abrir $path');
      expect(doc.docStatus, DocStatus.open, reason: '${doc.message}');
      await until(() => doc.tiles.isNotEmpty, 'os ladrilhos de $path');
    }

    doc.start();
    await tester.pumpWidget(QuillApp(
      workspace: workspace,
      settings: Settings(null),
      window: FakeAppWindow(),
      showMemory: false,
    ));
    await until(() => doc.kitStatus != KitStatus.starting, 'o motor ligar');
    expect(doc.kitStatus, KitStatus.ready, reason: '${doc.message}');
    expect(doc.engineVersion, contains('LibreOffice'));

    // 1. Abrir: 30 páginas A4 ≈ 30 × 16838 twips de altura.
    await openAndWait(work);
    expect(doc.documentSize.height, greaterThan(29 * 16838));
    expect(doc.tiles.every((t) => t.textureId >= 0), isTrue, reason: 'cada vaga é uma textura');
    expect(find.byType(Texture), findsWidgets);
    expect(workspace.recents.paths.first, work);
    // O cursor aparece logo ao abrir, sem precisar digitar.
    await until(() => doc.cursor != Rect.zero, 'a posição do cursor');
    expect(doc.cursorVisible, isTrue);

    // 2. A barra de status e a faixa leem o motor.
    await until(() => doc.page != null && doc.wordCount != null && doc.fonts.isNotEmpty, 'página, palavras, fontes');
    expect(doc.page!.$2, inInclusiveRange(29, 31));
    expect(doc.wordCount!.words, greaterThan(15000));
    expect(doc.fonts, contains('Liberation Serif'));
    expect(doc.modified, isFalse);

    // 3. Rolar até o meio pede ladrilhos de lá.
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable).first);
    scrollable.position.jumpTo(scrollable.position.maxScrollExtent / 2);
    await tester.pump();
    final middleRow = (scrollable.position.pixels * 15 / 3840).floor();
    await until(() => doc.tiles.any((t) => (t.key.row - middleRow).abs() <= 1), 'ladrilhos do meio');
    scrollable.position.jumpTo(0);
    await tester.pump();

    // 4. Digitar no começo do primeiro parágrafo, por tecla e pelo IME
    //    (´ + e = é, como no ABNT2).
    doc.postMouse(MouseEventType.down, const Offset(1700, 3200));
    doc.postMouse(MouseEventType.up, const Offset(1700, 3200));
    await settle();
    const marca = 'Quillteste', comAcento = 'Quillteste\u00e9';
    for (final c in marca.codeUnits) {
      doc.postKey(c, 0);
    }
    await until(() => kit.keyLatency().samples > 0, 'a tecla virar ladrilho');
    await until(() => doc.modified, 'o motor dizer "modificado"');
    expect(doc.canUndo, isTrue);
    doc.composeText('´');
    await settle(100);
    doc.insertText('é');
    await settle();

    // 5. Desfazer: um texto inserido de uma vez sai de uma vez.
    doc.insertText(' DESFEITO');
    await settle();
    doc.undo();
    await settle();

    // 6. Negrito na palavra digitada (Ctrl+Shift+Esquerda seleciona).
    doc.postKey(0, VclKey.left | VclKey.shift | VclKey.mod1);
    await until(() => doc.hasSelection, 'a seleção');
    doc.uno('.uno:Bold');
    await until(() => doc.isOn('.uno:Bold'), 'o negrito ligar', seconds: 10);

    // 7. Copiar (a área de transferência recebe o texto) e colar depois da
    //    palavra: cola do motor, com o negrito.
    doc.copy();
    await until(() => clipboard.text != null, 'copiar');
    expect(clipboard.text, contains(comAcento)); // o clique caiu no meio de uma palavra
    doc.postKey(0, VclKey.end);
    await settle();
    await doc.paste();
    await settle();

    // 8. Salvar (DOCX) e conferir no XML: o texto, o acento, o negrito, a
    //    cópia colada, e o desfeito fora.
    expect(await workspace.save(), isTrue);
    expect(doc.modified, isFalse);
    final xml = unzip(work, 'word/document.xml');
    final at = xml.indexOf(comAcento);
    expect(at, greaterThan(0), reason: 'o texto digitado (com o é do IME) foi salvo');
    expect(xml.substring(xml.lastIndexOf('<w:r>', at), at), contains('<w:b/>'), reason: 'em negrito');
    expect(comAcento.allMatches(xml).length, 2, reason: 'colado uma vez');
    expect(xml, isNot(contains('DESFEITO')));

    // 9. Salvar como ODT: o documento passa a ser o ODT.
    final odt = '${tmp.path}/capitulo.odt';
    dialogs.saveAnswer = odt;
    expect(await workspace.saveAs(), isTrue);
    expect(doc.path, odt);
    expect(unzip(odt, 'content.xml'), contains(comAcento));

    // 10. Trava de outro (um LibreOffice aberto): só leitura, o motor não
    //     edita, e "Salvar uma cópia" reabre a cópia editável.
    final alheio = source.copySync('${tmp.path}/alheio.docx').path;
    LoLock.fileFor(alheio).writeAsStringSync(',maria,outro-pc,22.11.2026 10:00,file:///home/maria/.config/libreoffice/4;');
    await openAndWait(alheio);
    expect(doc.readOnly, isTrue);
    expect(doc.lockOwner, 'maria');
    kit.postKey(KeyEventType.input, charCode: 0x78); // direto no motor, passando o app
    kit.postKey(KeyEventType.up, charCode: 0x78);
    await settle(500);
    expect(doc.modified, isFalse, reason: 'o LibreOffice também abriu só leitura');
    final copia = '${tmp.path}/copia.docx';
    dialogs.saveAnswer = copia;
    expect(await workspace.saveAs(), isTrue);
    await until(() => doc.docStatus == DocStatus.open && doc.path == copia && !doc.readOnly, 'reabrir a cópia');
    expect(LoLock.fileFor(alheio).existsSync(), isTrue, reason: 'a trava dos outros fica');

    // 11. Trava velha do próprio Quill (morreu sem fechar): apaga e abre
    //     editável.
    final velho = source.copySync('${tmp.path}/velho.docx').path;
    LoLock.fileFor(velho).writeAsStringSync(',eu,${Platform.localHostname},1,${profile.url};');
    await openAndWait(velho);
    expect(doc.readOnly, isFalse);
    doc.insertText('ok');
    await until(() => doc.modified, 'editar o que tinha trava velha');

    // 12. Clique triplo seleciona o parágrafo inteiro (vai como 4 ao motor;
    //     no LibreOffice, 3 seria só a frase).
    clipboard.text = null;
    for (final n in [1, 2, 4]) {
      doc.postMouse(MouseEventType.down, const Offset(2500, 3200), count: n);
      doc.postMouse(MouseEventType.up, const Offset(2500, 3200), count: n);
    }
    await until(() => doc.hasSelection, 'a seleção do parágrafo');
    doc.copy();
    await until(() => clipboard.text != null, 'copiar o parágrafo');
    expect(clipboard.text!.split('. ').length, greaterThan(3), reason: 'várias frases: o parágrafo, não uma frase');

    // 13. Lua: o "olá" e um laço infinito interrompido.
    kit.runLua('psito.log("olá, " .. _VERSION)', 'ola.lua');
    await until(() => events.whereType<PluginLog>().isNotEmpty, 'o log do Lua');
    expect(events.whereType<PluginLog>().first.text, 'olá, Lua 5.4');
    kit.runLua('while true do end', 'laco.lua', instructionLimit: 1000000);
    await until(() => events.whereType<PluginFinished>().length >= 2, 'o laço parar', seconds: 10);
    final laco = events.whereType<PluginFinished>().last;
    expect(laco.ok, isFalse);
    expect(laco.error, contains('interrompido'));

    // Fecha sem salvar (descarta), para não deixar trava.
    workspace.onUnsaved = () async => UnsavedChoice.discard;
    expect(await workspace.requestExit(), isTrue);
    expect(LoLock.fileFor(velho).existsSync(), isFalse);

    await sub.cancel();
    // Sem kit.dispose(): o destroy do LOK no fim do processo às vezes demora,
    // e o processo de teste termina logo em seguida.
  });
}
