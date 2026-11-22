// Integração com o LibreOffice de verdade: abrir, digitar, negrito, salvar e
// reabrir o DOCX de 30 páginas, e o Lua na caixa de areia.
//
// Roda com `./test.sh --integracao` (abre uma janela; precisa de sessão
// gráfica). O perfil do LibreOffice é temporário: não toca no do usuário.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:psito_quill/src/app.dart';
import 'package:psito_quill/src/document/document_controller.dart';
import 'package:psito_quill/src/kit/lok/lo_profile.dart';
import 'package:psito_quill/src/kit/lok/lok_quill_kit.dart';
import 'package:psito_quill/src/kit/lok/vcl_keys.dart';
import 'package:psito_quill/src/kit/quill_kit.dart';
import 'package:psito_quill/src/ui/tokens/themes/themes.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // O LOK só liga uma vez por processo: um teste só, em passos.
  testWidgets('motor real: abrir, digitar, negrito, salvar, reabrir, Lua', (tester) async {
    final tmp = Directory.systemTemp.createTempSync('quill-integracao-');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final source = File('test/fixtures/capitulo-30p.docx').absolute;
    final work = source.copySync('${tmp.path}/capitulo.docx').path;

    final profile = LoProfile(Directory('${tmp.path}/perfil'))..ensureSchemes(paperSchemes(builtInThemes));
    final kit = LokQuillKit(profile: profile);
    final doc = DocumentController(kit);
    final events = <KitEvent>[];
    final sub = kit.events.listen(events.add);

    Future<void> until(bool Function() test, String what, {int seconds = 60}) async {
      final end = DateTime.now().add(Duration(seconds: seconds));
      while (!test()) {
        if (DateTime.now().isAfter(end)) fail('esperou demais: $what');
        await tester.pump(const Duration(milliseconds: 20));
      }
    }

    doc.start();
    await tester.pumpWidget(QuillApp(doc: doc, showMemory: false));
    await until(() => doc.kitStatus != KitStatus.starting, 'o motor ligar');
    expect(doc.kitStatus, KitStatus.ready, reason: '${doc.message}');
    expect(doc.engineVersion, contains('LibreOffice'));

    // Abrir: 30 páginas A4 ≈ 30 × 16838 twips de altura.
    doc.open(work);
    await until(() => doc.docStatus != DocStatus.opening, 'abrir');
    expect(doc.docStatus, DocStatus.open);
    expect(doc.documentSize.height, greaterThan(29 * 16838));
    await until(() => doc.tiles.isNotEmpty, 'os primeiros ladrilhos');
    expect(doc.tiles.every((t) => t.textureId >= 0), isTrue, reason: 'cada vaga é uma textura');
    expect(find.byType(Texture), findsWidgets);

    // Rolar até o meio pede ladrilhos de lá.
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable).first);
    scrollable.position.jumpTo(scrollable.position.maxScrollExtent / 2);
    await tester.pump();
    final middleRow = (scrollable.position.pixels * 15 / 3840).floor();
    await until(() => doc.tiles.any((t) => (t.key.row - middleRow).abs() <= 1), 'ladrilhos do meio');
    scrollable.position.jumpTo(0);
    await tester.pump();

    // Digitar no começo do primeiro parágrafo.
    doc.postMouse(MouseEventType.down, const Offset(1700, 3200));
    doc.postMouse(MouseEventType.up, const Offset(1700, 3200));
    await tester.pump(const Duration(milliseconds: 300));
    const marca = 'Quillteste';
    for (final c in marca.codeUnits) {
      doc.postKey(c, 0);
    }
    await until(() => kit.keyLatency().samples > 0, 'a tecla virar ladrilho');

    // Negrito na palavra digitada (Ctrl+Shift+Esquerda seleciona).
    doc.postKey(0, VclKey.left | VclKey.shift | VclKey.mod1);
    await tester.pump(const Duration(milliseconds: 300));
    doc.uno('.uno:Bold');
    await until(() => doc.isOn('.uno:Bold'), 'o negrito ligar', seconds: 10);

    // Salvar e conferir no XML do DOCX: o texto está lá, em negrito.
    expect(doc.save(), isTrue);
    await until(() => doc.message is SavedMessage, 'salvar');
    final xml = Process.runSync('unzip', ['-p', work, 'word/document.xml']).stdout as String;
    final at = xml.indexOf(marca);
    expect(at, greaterThan(0), reason: 'o texto digitado foi salvo');
    final run = xml.substring(xml.lastIndexOf('<w:r>', at), at);
    expect(run, contains('<w:b/>'), reason: 'em negrito');

    // Reabrir o salvo.
    doc.open(work);
    await until(() => doc.docStatus == DocStatus.open && doc.tiles.isNotEmpty, 'reabrir');

    // Lua: o "olá" e um laço infinito interrompido.
    kit.runLua('psito.log("olá, " .. _VERSION)', 'ola.lua');
    await until(() => events.whereType<PluginLog>().isNotEmpty, 'o log do Lua');
    expect(events.whereType<PluginLog>().first.text, 'olá, Lua 5.4');
    kit.runLua('while true do end', 'laco.lua', instructionLimit: 1000000);
    await until(() => events.whereType<PluginFinished>().length >= 2, 'o laço parar', seconds: 10);
    final laco = events.whereType<PluginFinished>().last;
    expect(laco.ok, isFalse);
    expect(laco.error, contains('interrompido'));

    await sub.cancel();
    // Sem kit.dispose(): o destroy do LOK no fim do processo às vezes demora,
    // e o processo de teste termina logo em seguida.
  });
}
