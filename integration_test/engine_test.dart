// Integração com o LibreOffice de verdade, em passos: abrir o DOCX de 30
// páginas, digitar (também pelo IME), desfazer, negrito, copiar e colar,
// salvar em DOCX e em ODT, reabrir, a trava do LibreOffice, o clique triplo e
// o Lua. Da Fase 2: localizar e substituir, a ortografia pelo clique direito,
// estilo novo, recuo, tabela, imagem, página, e o ODT que sai disso.
//
// Roda com `./test.sh --integracao` (abre uma janela; precisa de sessão
// gráfica). O perfil do LibreOffice, os documentos, a área de transferência e
// as preferências são temporários: não toca nos do usuário.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:psito_quill/src/plugins/plugin_host.dart';
import 'package:psito_quill/src/book/book_search.dart';
import 'package:psito_quill/src/book/compile.dart';
import 'package:psito_quill/src/book/compile_models.dart';
import 'package:psito_quill/src/book/odt_zip.dart';
import 'package:psito_quill/src/book/docx_import.dart';
import 'package:psito_quill/src/book/book_io.dart';
import 'package:psito_quill/src/app.dart';
import 'package:psito_quill/src/document/comments.dart';
import 'package:psito_quill/src/document/document_controller.dart';
import 'package:psito_quill/src/document/paragraph_format.dart';
import 'package:psito_quill/src/document/recovery.dart';
import 'package:psito_quill/src/document/references.dart';
import 'package:psito_quill/src/document/search.dart';
import 'package:psito_quill/src/document/style_patch.dart';
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

    final profile = LoProfile(Directory('${tmp.path}/perfil'))..ensureSettings(paperSchemes(builtInThemes));
    final kit = LokQuillKit(profile: profile);
    final clipboard = MemoryTextClipboard();
    final doc = DocumentController(kit, clipboard: clipboard, deferOpenWork: true);
    final dialogs = FakeFileDialogs();
    final workspace = Workspace(
      doc: doc,
      recents: RecentFiles(File('${tmp.path}/recentes.json')),
      dialogs: dialogs,
      locks: LockInspector(profileUrl: profile.url),
    );
    final events = <KitEvent>[];
    final sub = kit.events.listen(events.add);

    Future<void> until(bool Function() test, String what, {int seconds = 60, String Function()? detail}) async {
      final end = DateTime.now().add(Duration(seconds: seconds));
      while (!test()) {
        if (DateTime.now().isAfter(end)) fail('esperou demais: $what ${detail?.call() ?? ''}');
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

    // 0. O dicionário na tela inicial (D-069): o documento oculto abre, o
    //    arquivo some, e o primeiro capítulo abre por cima normalmente.
    final preloadDir = Directory(DocumentController.copyDir);
    bool preloadLeft() => preloadDir
        .listSync()
        .any((f) => f.path.endsWith('${DocumentController.copyPrefixOfThisProcess}ortografia.fodt'));
    doc.preloadSpelling();
    expect(preloadLeft(), isTrue);
    await until(() => !preloadLeft(), 'o motor apagar o arquivo do dicionário');

    // 1. Abrir: 30 páginas A4 ≈ 30 × 16838 twips de altura. O motor avisa o
    //    fim do carregamento pelo callback do escritório (D-066).
    final beforeOpen = events.length;
    await openAndWait(work);
    expect(events.skip(beforeOpen).whereType<ProgressFinished>(), isNotEmpty, reason: 'o progresso vem do motor');
    expect(doc.busy, isNull);
    expect(doc.progress, isNull);
    expect(doc.documentSize.height, greaterThan(29 * 16838));
    expect(doc.tiles.every((t) => t.textureId >= 0), isTrue, reason: 'cada vaga é uma textura');
    expect(find.byType(Texture), findsWidgets);
    expect(workspace.recents.paths.first, work);
    // O cursor aparece logo ao abrir, sem precisar digitar.
    await until(() => doc.cursor != Rect.zero, 'a posição do cursor');
    expect(doc.cursorVisible, isTrue);

    // 2. A barra de status e a faixa leem o motor.
    await until(() => doc.page != null && doc.wordCount != null && doc.fonts.isNotEmpty, 'página, palavras, fontes',
        detail: () => '(página ${doc.page}, palavras ${doc.wordCount}, ${doc.fonts.length} fontes)');
    expect(doc.page!.$2, inInclusiveRange(29, 31));
    expect(doc.wordCount!.words, greaterThan(15000));
    expect(doc.fonts, contains('Liberation Serif'));
    expect(doc.modified, isFalse);

    // 2b. A cópia temporária (D-044): os estilos com as propriedades e os
    // títulos; o arquivo some, e o documento não muda. E o fontconfig
    // classifica as fontes (D-045).
    await until(() => doc.snapshot.styles.isNotEmpty, 'a cópia temporária lida');
    expect(doc.snapshot.styles['Heading 1']?.bold, isTrue);
    expect(doc.snapshot.outline, isNotEmpty);
    expect(doc.modified, isFalse);
    expect(doc.path, endsWith('.docx'));
    expect(
      Directory(DocumentController.copyDir).listSync().where((f) => f.path.contains(DocumentController.copyPrefixOfThisProcess)),
      isEmpty,
      reason: 'a cópia tem o texto do livro',
    );
    expect(doc.fontClasses['Liberation Mono'], FontClass.mono);
    expect(doc.fontClasses['Liberation Serif'], FontClass.serif);
    // 2c. A régua (D-046): o callback 35 chega ao abrir, e as margens da
    // página vêm da cópia (2 cm e 1 cm no capítulo).
    await until(() => doc.ruler != null, 'a régua do motor');
    expect(doc.ruler!.pageWidth, inInclusiveRange(20990, 21010));
    expect(doc.ruler!.leftMargin, inInclusiveRange(1990, 2010));
    expect(doc.snapshot.pageMargins!.left, closeTo(2, 0.01));
    // 2d. A Estrutura e as várias páginas (D-047): o salto ao último título
    // pela busca, e três páginas lado a lado pelo .uno:ViewLayout.
    final last = doc.snapshot.outline.last;
    doc.goToHeading(last);
    await until(() => (doc.page?.$1 ?? 0) >= last.page - 1, 'o salto ao último título (página ${last.page})');
    // O título cujo texto aparece mais vezes antes dele (D-072): o salto
    // conta as ocorrências do começo e seleciona exatamente o título.
    final tricky = doc.snapshot.outline.reduce((a, b) => b.occurrence > a.occurrence ? b : a);
    clipboard.text = null;
    doc.goToHeading(tricky);
    await settle(800);
    doc.copy();
    await until(() => clipboard.text != null, 'copiar o título do salto');
    expect(clipboard.text!.trim(), tricky.searchKey, reason: '${tricky.text}: ${tricky.occurrence} antes');
    expect(doc.search.query, isNull, reason: 'o salto não acende o Localizar');
    clipboard.text = null;
    final single = doc.documentSize.width;
    doc.setViewLayout(columns: 3);
    await until(() => doc.documentSize.width > single * 2.5, 'três páginas de largura');
    doc.setViewLayout(columns: 1);
    await until(() => (doc.documentSize.width - single).abs() < 10, 'uma página de novo');
    doc.postKey(0, VclKey.home | VclKey.mod1);
    // 2e. A busca única (D-050): as ocorrências vêm de uma cópia, e o salto
    // a uma delas pela expressão com o contexto seleciona só ela, na página
    // certa. Fechar a busca apaga a cópia.
    final textHits = await doc.searchText(const SearchQuery('que'), limit: 400);
    expect(textHits.total, greaterThan(50));
    final far = textHits.hits.firstWhere((h) => h.page >= 5);
    // Antes, o Ctrl+Home do passo anterior precisa ter chegado (a página e a
    // seleção do salto ao título ainda podem ser as velhas).
    await until(() => doc.page?.$1 == 1 && !doc.hasSelection, 'o começo do documento');
    doc.goToHit(far);
    await until(() => doc.hasSelection && (doc.page?.$1 ?? 0) >= far.page - 1, 'o salto à ocorrência da página ${far.page}');
    expect(doc.page!.$1, inInclusiveRange(far.page - 1, far.page + 1));
    doc.endTextSearch();
    expect(
      Directory(DocumentController.copyDir).listSync().where((f) => f.path.contains(DocumentController.copyPrefixOfThisProcess)),
      isEmpty,
      reason: 'a cópia da busca saiu',
    );
    doc.postKey(0, VclKey.home | VclKey.mod1);

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
    final saving = workspace.save();
    expect(doc.busy, BusyKind.saving, reason: 'a tela trava enquanto salva');
    expect(await saving, isTrue);
    expect(doc.busy, isNull);
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

    // 13. Lua: o plugin "olá" (só para os testes desde o D-070; o app não o
    //     roda ao abrir) e um laço infinito interrompido.
    await PluginHost(kit).runBundled('ola');
    await until(() => events.whereType<PluginLog>().isNotEmpty, 'o log do Lua');
    expect(events.whereType<PluginLog>().first.text, 'olá do Lua (Lua 5.4)');
    kit.runLua('while true do end', 'laco.lua', instructionLimit: 1000000);
    await until(() => events.whereType<PluginFinished>().length >= 2, 'o laço parar', seconds: 10);
    final laco = events.whereType<PluginFinished>().last;
    expect(laco.ok, isFalse);
    expect(laco.error, contains('interrompido'));

    // 13b. As abas (D-054): os documentos de antes continuam abertos no
    //      motor, cada um com o seu desfazer, e o texto vai só para o da tela.
    expect(doc.tabs.map(doc.tabPath), [odt, copia, velho]);
    doc.activateTab(doc.tabs.first);
    await until(() => doc.path == odt && doc.tiles.isNotEmpty && doc.page != null, 'voltar à aba do ODT');
    expect(doc.modified, isFalse, reason: 'foi salvo no passo 9');
    expect(doc.canUndo, isTrue, reason: 'o desfazer da aba continua');
    doc.insertText('Abas ');
    await until(() => doc.modified, 'editar na aba do ODT');
    doc.activateTab(doc.tabs.last);
    await until(() => doc.path == velho && doc.tiles.isNotEmpty, 'ir à aba do velho');
    expect(doc.modified, isTrue, reason: 'o "ok" do passo 11');
    doc.cycleTab();
    await until(() => doc.path == odt && doc.tiles.isNotEmpty, 'dar a volta até o ODT');
    expect(doc.modified, isTrue);
    expect(await workspace.save(), isTrue);
    expect(unzip(odt, 'content.xml'), contains('Abas '));
    expect(unzip(copia, 'word/document.xml'), isNot(contains('Abas ')));
    // Fechar a aba do meio (a cópia, salva) não pergunta nada.
    expect(await workspace.closeTab(doc.tabs[1]), isTrue);
    expect(doc.tabs.map(doc.tabPath), [odt, velho]);
    expect(doc.path, odt);

    // ------------------------------------------------------------ Fase 2 --
    workspace.onUnsaved = () async => UnsavedChoice.discard;
    await workspace.newDocument();
    await until(() => doc.docStatus == DocStatus.open && doc.path == null && doc.tiles.isNotEmpty, 'o documento novo');
    doc.insertText('Um texto com erru de grafia. Outro texto aqui.');
    await until(() => doc.wordCount?.words == 9, 'o texto novo');

    // 14. Ortografia: com a lista do LOK_ALLOWLIST_LANGUAGES, o motor liga o
    // corretor (o pt-BR aparece nas línguas). O clique direito traz o menu do
    // motor, e a página o mostra. As sugestões não vêm sob o integration_test,
    // embora venham no lok_script com as mesmas chamadas (D-033).
    final langs = events.length;
    kit.requestCommandValues('.uno:LanguageStatus');
    await until(
      () => events.skip(langs).whereType<CommandValues>().any((c) => c.command == '.uno:LanguageStatus'),
      'as línguas do corretor',
    );
    expect(
      events.skip(langs).whereType<CommandValues>().firstWhere((c) => c.command == '.uno:LanguageStatus').json,
      contains('pt-BR'),
    );
    final found = events.length;
    doc.find(const SearchQuery('erru'));
    await until(() => events.skip(found).whereType<SearchResult>().isNotEmpty, 'achar erru');
    final mark = events.length;
    doc.requestContextMenu(doc.selection.first.center);
    await until(() => events.skip(mark).whereType<ContextMenuReady>().isNotEmpty, 'o menu de contexto');
    await until(() => find.text('Copiar').evaluate().isNotEmpty, 'o menu na tela');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle();
    expect(find.text('Copiar'), findsNothing);

    // 15. Localizar: todas, maiúsculas, nada; substituir todas conta.
    doc.findAll(const SearchQuery('texto'));
    await until(() => doc.search.count != null, 'achar todas');
    expect(doc.search.count, 2);
    doc.find(const SearchQuery('Texto', matchCase: true));
    await until(() => doc.search.notFound, 'não achar com maiúsculas');
    doc.replaceAll(const SearchQuery(r't\w+o', regex: true), 'livro');
    await until(() => doc.search.replaced != null, 'substituir todas');
    expect(doc.search.replaced, 3, reason: 'texto, "tro" de Outro, texto');
    clipboard.text = null;
    doc.selectAll();
    await until(() => doc.hasSelection, 'selecionar tudo');
    doc.copy();
    await until(() => clipboard.text != null, 'copiar o texto trocado');
    expect(clipboard.text, 'Um livro com erru de grafia. Oulivro livro aqui.');

    // 16. Estilo novo a partir do parágrafo, e recuo pelo painel.
    doc.postKey(0, VclKey.end);
    doc.newStyleFromSelection('Cena');
    await until(() => doc.paragraphStyles.contains('Cena') && doc.paragraphStyleId == 'Cena', 'o estilo Cena');
    expect(doc.customParagraphStyles, ['Cena']);
    doc.setIndents(left: 1.0);
    await until(() => (doc.paragraphIndents['left'] ?? 0) > 0.9, 'o recuo à esquerda');
    expect(doc.paragraphIndents['left'], closeTo(1.0, 0.02));

    // 17. Tabela: inserir liga o contexto; uma linha a mais.
    doc.postKey(13, VclKey.enter);
    doc.insertTable(2, 3);
    await until(() => doc.inTable, 'entrar na tabela');
    doc.insertText('célula');
    doc.uno('.uno:InsertRowsAfter');
    await settle();

    // 18. Imagem: inserir seleciona; arrastar a alça diminui.
    for (var i = 0; i < 4; i++) {
      doc.postKey(0, VclKey.down);
    }
    final png = File('${tmp.path}/ponto.png')..writeAsBytesSync(base64Decode(_png));
    doc.insertImage(png.path);
    await until(() => doc.graphic != null, 'a imagem selecionada');
    final before = doc.graphic!;
    doc.dragGraphic(before.bottomRight, before.bottomRight - Offset(before.width / 2, before.height / 2));
    await until(() => doc.graphic != null && doc.graphic!.width < before.width - 10, 'a imagem diminuir');
    // 18b. A aba Imagem: o tamanho em cm pelas alças (D-043). Com a
    // proporção, a do canto; sem, a da direita e depois a de baixo.
    const cm = 1440 / 2.54;
    doc.setGraphicSizeCm(width: 2, keepRatio: true);
    await until(() => (doc.graphic!.width - 2 * cm).abs() < 30, 'a largura de 2 cm, com a proporção');
    final ratio = doc.graphic!.height / doc.graphic!.width;
    expect(ratio, closeTo(before.height / before.width, 0.05));
    doc.setGraphicSizeCm(width: 3, height: 1, keepRatio: false);
    await until(() => (doc.graphic!.width - 3 * cm).abs() < 30 && (doc.graphic!.height - cm).abs() < 30, '3 × 1 cm, sem a proporção');

    // 19. Página: A5 deitada.
    final width = doc.documentSize.width;
    doc.setPageSize(pageSizes.firstWhere((s) => s.id == 'a5'));
    await until(() => doc.documentSize.width < width - 1000, 'a página A5');
    final a5 = doc.documentSize.width;
    doc.setLandscape(true);
    await until(() => doc.landscape && doc.documentSize.width > a5 + 3000, 'a página deitada');

    // 20. O ODT guarda tudo.
    final fase2 = '${tmp.path}/fase2.odt';
    dialogs.saveAnswer = fase2;
    expect(await workspace.saveAs(), isTrue);
    final styles = unzip(fase2, 'styles.xml'), content = unzip(fase2, 'content.xml');
    expect(styles, contains('style:name="Cena"'));
    expect(content, contains('<table:table '));
    expect(content, contains('<draw:frame '));
    // O motor arredonda: 21000 vira "21.001cm".
    expect(styles, matches(RegExp(r'fo:page-width="21(\.00\d)?cm"')));
    expect(styles, matches(RegExp(r'fo:page-height="14\.80\dcm"')));
    expect(styles, contains('style:print-orientation="landscape"'));
    expect(content, contains('Um livro com erru de grafia'));

    // 21. O documento para o leitor de tela (D-067): ligado, o motor manda o
    //     parágrafo do cursor; desligado, para.
    doc.setAccessibility(true);
    doc.insertText('Z');
    await until(() => doc.a11yParagraph != null, 'o parágrafo para o leitor de tela');
    expect(doc.a11yParagraph, contains('Z'));
    doc.setAccessibility(false);
    expect(doc.a11yParagraph, isNull);

    // 22. O livro (D-071): importar o DOCX de teste pelo motor (oculto, sem
    //     tocar nas abas), abrir dois capítulos pelo fichário, editar e
    //     salvar um, e as palavras dele mudam no livro.json.
    final importer = DocxImporter(kit);
    final manuscript = await importer.read(File('test/fixtures/livro-teste.docx').absolute.path);
    expect(manuscript.headingLevels, [1, 2]);
    final drafts = manuscript.chapters(manuscript.suggestedLevel);
    expect(drafts.length, 4, reason: 'a dedicatória e os três capítulos');
    final bookDir = '${tmp.path}/Teste.psitobook';
    final imported = await importer.create(dir: bookDir, title: 'Teste', m: manuscript, drafts: drafts, untitled: 'Abertura');
    for (final c in imported.chapters) {
      final xml = readOdtContent('$bookDir/${c.file}');
      expect(xml, isNotNull, reason: 'o motor gravou ${c.file} em ODT');
    }
    expect(readOdtContent('$bookDir/${imported.chapters.elementAt(1).file}'), contains('<text:note '),
        reason: 'a nota de rodapé sobrevive ao corte');
    final tabsBefore = doc.tabs.length;
    workspace.adoptBook(bookDir, imported);
    final second = imported.chapters.elementAt(2);
    workspace.openChapter(second);
    await until(() => doc.path == '$bookDir/${second.file}' && doc.docStatus == DocStatus.open, 'abrir o capítulo 2');
    expect(doc.tabs.length, tabsBefore + 1);
    final wordsBefore = second.words;
    doc.insertText('Mais quatro palavras aqui. ');
    await settle();
    expect(await workspace.save(), isTrue);
    await until(() => second.words != wordsBefore, 'recontar as palavras do capítulo salvo', seconds: 20);
    expect(second.words, wordsBefore + 4);
    expect(readBook(bookDir).find(second.id)!.$1.words, second.words);
    expect(await workspace.closeBook(), isTrue);
    expect(doc.tabs.length, tabsBefore, reason: 'fechar o livro fecha as abas dele');

    // 23. O salvamento automático (D-073): a cópia de recuperação é um ODT
    //     com o texto novo, e o documento continua o mesmo arquivo,
    //     modificado. Depois de "cair" (outra sessão lê a pasta), a cópia
    //     abre como um documento novo, e fechar a apaga.
    final recDir = Directory('${tmp.path}/recuperacao');
    doc.recovery = RecoveryStore(recDir, session: 'integracao');
    DocumentController.autosaveEvery = const Duration(milliseconds: 400);
    DocumentController.autosavePause = const Duration(milliseconds: 200);
    final recSource = source.copySync('${tmp.path}/recuperavel.docx').path;
    await openAndWait(recSource);
    doc.insertText('Recuperavel ');
    final recTab = doc.currentTab!;
    final recCopy = '${recDir.path}/${doc.recovery!.idFor(recTab.serial)}.odt';
    await until(() => File(recCopy).existsSync(), 'a cópia de recuperação', seconds: 20);
    expect(readOdtContent(recCopy), contains('Recuperavel'));
    expect(doc.path, recSource, reason: 'a cópia não muda o arquivo do documento');
    expect(doc.modified, isTrue, reason: 'nem o "modificado"');
    expect(recDir.listSync().where((f) => f.path.contains('gravando')), isEmpty);
    final crash = RecoveryStore(recDir, session: 'depois').pending().single;
    expect(crash.original, recSource);
    workspace.recover(crash);
    await until(() => doc.docStatus == DocStatus.open && doc.recovered == crash, 'abrir a cópia');
    await until(() => doc.tiles.isNotEmpty, 'os ladrilhos da cópia');
    expect(doc.path, isNull, reason: 'um documento novo');
    expect(doc.modified, isTrue);
    expect(doc.readOnly, isFalse);
    workspace.onUnsaved = () async => UnsavedChoice.discard;
    expect(await workspace.closeTab(), isTrue);
    expect(await workspace.closeTab(recTab), isTrue);
    expect(recDir.listSync().whereType<File>(), isEmpty, reason: 'fechar apaga as cópias');
    doc.recovery = null;

    // 24. A página do livro (D-075) e as notas, os links e o PDF (D-076), num
    //     DOCX novo. O cabeçalho liga pelo comando do motor; desligar, a
    //     primeira página e as pares diferentes, a hifenização e a capitular
    //     vão pela cópia dos estilos e o LoadStyles.
    final pageSource = source.copySync('${tmp.path}/pagina.docx').path;
    await openAndWait(pageSource);
    Future<void> pageIs(bool Function(PageSetup p) test, String what) async {
      doc.refreshSnapshot();
      await until(() => test(doc.snapshot.page), what, seconds: 30, detail: () => '${doc.snapshot.page.header}');
    }

    doc.insertHeaderFooter(footer: false);
    await pageIs((p) => p.header, 'o cabeçalho ligado');
    doc.insertField(DocField.pageNumber);
    await settle();
    expect(await doc.setFirstPageDifferent(true), isTrue);
    await pageIs((p) => p.firstDifferent, 'a primeira página diferente');
    expect(await doc.setLeftRightDifferent(true), isTrue);
    await pageIs((p) => p.leftDifferent, 'as pares diferentes');
    expect(await doc.setDocumentHyphenation(true), isTrue);
    await pageIs((p) => p.hyphenation, 'a hifenização do documento');
    expect(doc.snapshot.page.header, isTrue, reason: 'os outros estilos voltam iguais');
    expect(await doc.removeHeaderFooter(footer: false), isTrue);
    await pageIs((p) => !p.header, 'o cabeçalho desligado');
    expect(doc.snapshot.page.hyphenation, isTrue);
    expect(doc.docStatus, DocStatus.open, reason: 'nada travou o motor');

    // A capitular, no parágrafo do corpo (o cursor sai do cabeçalho).
    doc.uno('.uno:GoToStartOfDoc');
    for (var i = 0; i < 3; i++) {
      doc.postKey(0, VclKey.down);
    }
    await until(() => doc.paragraphStyle != null, 'o estilo do parágrafo');
    final bodyStyle = doc.paragraphStyle!;
    expect(await doc.setDropCap(2), isTrue);
    await until(() => doc.paragraphStyle == '$bodyStyle$dropCapSuffix 2', 'o estilo da capitular',
        detail: () => '${doc.paragraphStyle}');
    expect(await doc.setDropCap(0), isTrue);
    await until(() => doc.paragraphStyle == bodyStyle, 'tirar a capitular');

    // O link e a nota de rodapé. As teclas e o texto vão ao motor de forma
    // assíncrona, e o pump não espera o tempo real: pausas de verdade.
    Future<void> pause(int ms) {
      final end = DateTime.now().add(Duration(milliseconds: ms));
      return until(() => DateTime.now().isAfter(end), 'a pausa');
    }

    doc.uno('.uno:GoToEndOfPara');
    doc.insertText(' ');
    await pause(400);
    doc.insertLink('o site', 'https://exemplo.org');
    await pause(400);
    doc.postKey(0, VclKey.left);
    doc.postKey(0, VclKey.left);
    await until(() => doc.link?.url == 'https://exemplo.org', 'o link no cursor', detail: () => '${doc.link?.url}');
    doc.uno('.uno:GoToEndOfPara');
    await pause(300);
    doc.insertFootnote();
    await pause(400);
    doc.insertText('Nota da integracao');
    await pause(400);
    doc.jumpFootnote();
    await pause(300);
    doc.postKey(0, VclKey.end);
    final pageOdt = '${tmp.path}/pagina.odt';
    dialogs.saveAnswer = pageOdt;
    expect(await workspace.saveAs(), isTrue);
    final pageStyles = unzip(pageOdt, 'styles.xml'), pageContent = unzip(pageOdt, 'content.xml');
    expect(pageContent, contains('Nota da integracao'));
    expect(pageContent, contains('<text:note '));
    expect(pageContent, contains('xlink:href="https://exemplo.org'));
    // O cabeçalho foi tirado (com a primeira página dele).
    expect(pageStyles, isNot(contains('<style:header>')));
    expect(pageStyles, isNot(contains('style:header-first')));
    expect(pageStyles, contains('fo:hyphenate="true"'));
    expect(pageStyles, contains('capitular 2'), reason: 'o estilo da capitular fica no documento');

    // O PDF.
    final pdf = '${tmp.path}/pagina.pdf';
    expect(await doc.exportPdf(pdf), isTrue);
    expect(String.fromCharCodes(File(pdf).readAsBytesSync().take(5)), '%PDF-');

    // O papel escuro (D-074): o motor desenha o claro, e o kit inverte.
    final lumaLight = kit.debugTilesLuma();
    final dark = builtInThemes.firstWhere((t) => t.brightness == Brightness.dark);
    final paper = enginePaper(dark);
    doc.setPaperScheme(paper.scheme, invert: paper.invert);
    await settle(1500);
    final lumaDark = kit.debugTilesLuma();
    expect(lumaLight, greaterThan(150));
    expect(lumaDark, lessThan(100), reason: 'claro $lumaLight, escuro $lumaDark');
    final light = enginePaper(builtInThemes.firstWhere((t) => t.brightness == Brightness.light));
    doc.setPaperScheme(light.scheme, invert: light.invert);
    await settle(1500);
    expect(kit.debugTilesLuma(), greaterThan(150));

    // 25. As cenas (D-079): o importador converte os "* * *" do capítulo de
    //     teste para o estilo Cena, e as cenas vêm da cópia. Dividir no
    //     separador de uma cena (o salto o seleciona) faz um capítulo novo
    //     que começa nela, sem o separador; juntar devolve o texto. A cena
    //     nova entra pelo motor.
    final sceneImporter = DocxImporter(kit);
    final sceneManuscript = await sceneImporter.read(source.path);
    expect(sceneManuscript.sceneSeparators, greaterThan(2));
    final sceneDir = '${tmp.path}/Cenas.psitobook';
    final sceneBook = await sceneImporter.create(
      dir: sceneDir,
      title: 'Cenas',
      m: sceneManuscript,
      drafts: sceneManuscript.chapters(sceneManuscript.suggestedLevel),
      untitled: 'Abertura',
    );
    final withScenes = sceneBook.chapters.firstWhere((c) => c.scenes.length == 3);
    final sceneCount = withScenes.scenes.length;
    workspace.adoptBook(sceneDir, sceneBook);
    workspace.openChapter(withScenes);
    final scenePath = '$sceneDir/${withScenes.file}';
    await until(() => doc.path == scenePath && doc.docStatus == DocStatus.open, 'abrir o capítulo com cenas');
    await until(() => doc.snapshot.scenes.length == sceneCount, 'as cenas da cópia',
        detail: () => '${doc.snapshot.scenes.length} de $sceneCount');
    expect(doc.hasSceneStyle, isTrue);
    expect([for (final s in doc.snapshot.scenes) s.label], withScenes.scenes, reason: 'a cópia e o content.xml dizem o mesmo');
    expect(await doc.convertSceneSeparators(), 0, reason: 'o importador já converteu todos');

    final wordsAll = withScenes.words;
    // Cada capítulo do arquivo de teste tem três cenas (dois separadores).
    // O corte no segundo deixa a primeira cena na tela (sem separador, ela
    // não conta como cena) e as outras duas no capítulo novo.
    final cutScene = doc.snapshot.scenes[1];
    doc.goToScene(cutScene);
    await until(() => doc.hasSelection, 'o salto ao separador da cena 2');
    final split = await workspace.splitChapterHere(fallbackTitle: 'Continuação');
    expect(split.error, isNull);
    final rest = split.created!;
    await until(() => rest.words > 0 && rest.scenes.isNotEmpty, 'as palavras e as cenas do capítulo novo', seconds: 20);
    expect(rest.scenes.first, cutScene.label, reason: 'o capítulo novo começa na cena do cursor');
    expect(rest.scenes.length, sceneCount - 1);
    await until(() => doc.snapshot.scenes.isEmpty, 'o capítulo da tela fica só com a primeira cena, sem separador',
        detail: () => '${doc.snapshot.scenes.length}');
    expect(doc.modified, isFalse, reason: 'dividir salva o capítulo da tela');
    expect(withScenes.words + rest.words, inInclusiveRange(wordsAll - 6, wordsAll), reason: 'só o separador some');
    expect([for (final c in workspace.book.book!.chapters) c.id].indexOf(rest.id),
        [for (final c in workspace.book.book!.chapters) c.id].indexOf(withScenes.id) + 1);

    expect(workspace.nextChapter?.id, rest.id);
    expect(await workspace.joinWithNext(), isNull);
    expect(workspace.book.book!.find(rest.id), isNull);
    expect(File('$sceneDir/lixeira/${rest.file!.split('/').last}').existsSync(), isTrue);
    // O separador saiu no corte: as cenas 2 e 3 viram uma.
    await until(() => doc.snapshot.scenes.length == sceneCount - 1, 'o texto de volta, numa cena a menos',
        detail: () => '${doc.snapshot.scenes.length}');
    await until(() => withScenes.words >= wordsAll - 6, 'as palavras de volta', seconds: 20);

    // A cena nova num parágrafo de texto (depois do título, a primeira cena
    // ficaria sem texto antes, e não contaria).
    doc.postKey(0, VclKey.home | VclKey.mod1);
    doc.postKey(0, VclKey.down);
    doc.postKey(0, VclKey.down);
    await settle();
    expect(await doc.insertScene(), isTrue);
    await until(() => doc.snapshot.scenes.length == sceneCount, 'a cena nova', detail: () => '${doc.snapshot.scenes.length}');
    expect(doc.snapshot.scenes[1].searchKey, sceneSeparatorText);

    // 26. A busca no livro (D-080): o capítulo da tela com alterações vale o
    //     do motor; os fechados, o content.xml; uma aba de fundo com
    //     alterações, a cópia de recuperação que sair dela gravou. O clique
    //     volta ao capítulo e seleciona a ocorrência.
    doc.recovery = RecoveryStore(Directory('${tmp.path}/rec-busca'), session: 'busca');
    doc.uno('.uno:GoToEndOfDoc');
    doc.uno('.uno:InsertText', '{"Text":{"type":"string","value":" Zumbizal"}}');
    await settle();
    const unique = SearchQuery('zumbizal');
    var inBook = await workspace.searchBook(unique);
    expect(inBook.chapters.map((c) => c.id), [withScenes.id], reason: 'só na tela, pela cópia do motor (modificado: ${doc.modified})');
    expect(inBook.chapters.single.hits.single.match, 'Zumbizal');
    final common = await workspace.searchBook(const SearchQuery('cidade', wholeWord: true));
    expect(common.chapters.length, greaterThan(2), reason: 'os capítulos fechados, pelo content.xml');
    expect(common.unread, 0);
    expect(common.chapters.every((c) => c.hits.length <= bookHitsPerChapter), isTrue);

    final other = workspace.book.book!.chapters.firstWhere((c) => c.id != withScenes.id);
    workspace.openChapter(other);
    await until(() => doc.path == '$sceneDir/${other.file}' && doc.docStatus == DocStatus.open, 'abrir outro capítulo');
    // A cópia entra na fila do motor atrás da abertura do outro capítulo.
    await until(() => doc.backgroundCopyOf(scenePath) != null, 'a cópia de recuperação da aba de fundo', seconds: 20,
        detail: () => '${Directory('${tmp.path}/rec-busca').existsSync() ? Directory('${tmp.path}/rec-busca').listSync().map((f) => f.path.split('/').last).toList() : 'sem pasta'} '
            '${[for (final t in doc.tabs) '${t.serial} ${t.path == scenePath} ${t.modified} ${t == doc.currentTab}']}');
    inBook = await workspace.searchBook(unique);
    expect(inBook.chapters.map((c) => c.id), [withScenes.id], reason: 'a aba de fundo vale a cópia, não o arquivo');
    workspace.openBookHit(withScenes.id, inBook.chapters.single.hits.single);
    await until(() => doc.path == scenePath && doc.hasSelection, 'voltar ao capítulo e selecionar a ocorrência');
    doc.recovery = null;

    // 27. Os instantâneos (D-081): o do capítulo da tela sai do motor, com o
    //     que não foi salvo. Comparar abre o instantâneo numa aba ao lado,
    //     só para leitura. Restaurar guarda o atual antes, fecha a aba e
    //     abre o capítulo com o texto do instantâneo.
    final snap = await workspace.takeSnapshot(withScenes, name: 'com zumbizal');
    expect(snap, isNotNull);
    final snapFile = workspace.snapshotFile(withScenes, snap!)!;
    expect(readOdtContent(snapFile), contains('Zumbizal'), reason: 'o instantâneo leva o que não foi salvo');
    expect(snap.words, greaterThan(100));
    expect(File(snapFile).parent.listSync().where((f) => f.path.contains('.~lock')), isEmpty);
    expect(readOdtContent(scenePath), isNot(contains('Zumbizal')), reason: 'o capítulo no disco não muda');

    doc.uno('.uno:GoToEndOfDoc');
    doc.uno('.uno:InsertText', '{"Text":{"type":"string","value":" Xiquexique"}}');
    await settle();
    // Comparar é abrir o instantâneo ao lado, só para leitura (o
    // CompareDocuments derruba o motor ao fechar o documento, D-081).
    expect(workspace.viewSnapshot(withScenes, snap, label: 'agora'), isTrue);
    await until(() => doc.path == snapFile && doc.docStatus == DocStatus.open, 'o instantâneo numa aba ao lado');
    expect(doc.readOnly, isTrue);
    expect(doc.viewing, 'agora');
    expect(doc.canEdit, isFalse);
    expect((await doc.searchText(unique, fresh: true)).total, 1);
    expect((await doc.searchText(const SearchQuery('xiquexique'), fresh: true)).total, 0, reason: 'o instantâneo é de antes');
    expect(await workspace.closeTab(), isTrue);
    await until(() => doc.path == scenePath && doc.docStatus == DocStatus.open, 'de volta ao capítulo');
    expect(doc.viewing, isNull);
    expect((await doc.searchText(const SearchQuery('xiquexique'), fresh: true)).total, 1);
    await until(() => File(snapFile).parent.listSync().every((f) => !f.path.contains('.~lock')), 'a trava do instantâneo sai ao fechar');

    doc.uno('.uno:InsertText', '{"Text":{"type":"string","value":" Quixeramobim"}}');
    await settle();
    expect(await workspace.restoreSnapshot(withScenes, snap, beforeName: 'Antes de restaurar'), isTrue);
    await until(() => doc.path == scenePath && doc.docStatus == DocStatus.open && doc.busy == null, 'o capítulo restaurado, aberto de novo');
    expect(doc.modified, isFalse);
    expect(readOdtContent(scenePath), contains('Zumbizal'));
    final kept = workspace.snapshotsOf(withScenes);
    expect(kept.map((s) => s.name), containsAll(['Antes de restaurar', 'com zumbizal']));
    final beforeFile = workspace.snapshotFile(withScenes, kept.firstWhere((s) => s.name == 'Antes de restaurar'))!;
    expect(readOdtContent(beforeFile), contains('Quixeramobim'), reason: 'o "antes" tem o que não foi salvo');
    expect((await doc.searchText(const SearchQuery('quixeramobim'), fresh: true)).total, 0);

    // 28. O compilar (D-086): o livro inteiro, com o capítulo da tela pelo
    //     motor (o que não foi salvo entra), num FODT só, e o motor grava o
    //     PDF com o sumário atualizado, o EPUB com o título, o DOCX e o ODT.
    doc.uno('.uno:GoToEndOfDoc');
    doc.uno('.uno:InsertText', '{"Text":{"type":"string","value":" Compiladíssimo"}}');
    await settle();
    final bookNow = workspace.book.book!;
    final chapterCount = bookNow.chapters.length;
    for (final f in CompileFormat.values) {
      final out = '${tmp.path}/compilado.${f.extension}';
      final stages = <CompileStage>{};
      final r = await workspace.compileBook(
          CompileJob(kit), CompileSettings(title: 'Cenas', author: 'Fulano', format: f), out,
          onProgress: (s, _, _) => stages.add(s));
      expect(r.outcome, CompileOutcome.done, reason: 'compilar em ${f.extension}');
      expect(stages, CompileStage.values.toSet());
      expect(File(out).lengthSync(), greaterThan(1000));
    }
    final compiledPdf = File('${tmp.path}/compilado.pdf').readAsBytesSync();
    expect(latin1.decode(compiledPdf.sublist(0, 5)), '%PDF-');
    final pdftotext = await Process.run('pdftotext', ['-layout', '${tmp.path}/compilado.pdf', '-']);
    if (pdftotext.exitCode == 0) {
      final text = pdftotext.stdout as String;
      expect(text, contains('Compiladíssimo'), reason: 'o capítulo da tela vale o do motor');
      expect(RegExp(r'Sumário[\s\S]*\.{5,}\s*\d').hasMatch(text), isTrue, reason: 'o sumário com as páginas');
    }
    final opf = readZipEntry(File('${tmp.path}/compilado.epub').readAsBytesSync(), 'OEBPS/content.opf');
    expect(opf, isNotNull);
    expect(utf8.decode(opf!), contains('<dc:title>Cenas</dc:title>'));
    final odtBody = readOdtContent('${tmp.path}/compilado.odt')!;
    expect(odtBody, contains('Compiladíssimo'));
    expect(RegExp('<text:h ').allMatches(odtBody).length, greaterThanOrEqualTo(chapterCount));
    final docxXml = readZipEntry(File('${tmp.path}/compilado.docx').readAsBytesSync(), 'word/document.xml');
    expect(utf8.decode(docxXml!), contains('Compiladíssimo'));
    expect(doc.path, scenePath, reason: 'o compilar não toca nas abas');
    expect((await doc.searchText(const SearchQuery('compiladíssimo'), fresh: true)).total, 1, reason: 'o capítulo da tela continua com o texto');

    // 29. Os modelos (D-087): o 6×9 sai em 15,24 × 22,86 cm, com o título
    //     do livro no cabeçalho das pares; o Manuscrito, em DOCX com espaço
    //     duplo, Times e o cabeçalho "Sobrenome / TÍTULO / página".
    final sixPdf = '${tmp.path}/modelo-6x9.pdf';
    expect((await workspace.compileBook(CompileJob(kit),
                BuiltInModel.sixByNine.settings.copyWith(title: 'Cenas', author: 'Fulano de Tal'), sixPdf))
            .outcome,
        CompileOutcome.done);
    final info = await Process.run('pdfinfo', [sixPdf]);
    if (info.exitCode == 0) {
      expect(info.stdout as String, contains('Page size:       432 x 648 pts'));
      final text = (await Process.run('pdftotext', ['-layout', sixPdf, '-'])).stdout as String;
      expect(RegExp(r'\b\d+\s+Cenas\b').hasMatch(text), isTrue, reason: 'o título do livro no cabeçalho das pares');
    }
    final manuscriptDocx = '${tmp.path}/modelo-manuscrito.docx';
    expect((await workspace.compileBook(CompileJob(kit),
                BuiltInModel.manuscript.settings.copyWith(title: 'Cenas', author: 'Fulano de Tal'), manuscriptDocx))
            .outcome,
        CompileOutcome.done);
    final docxBytes = File(manuscriptDocx).readAsBytesSync();
    final docxStyles = utf8.decode(readZipEntry(docxBytes, 'word/styles.xml')!);
    expect(docxStyles, contains('w:line="480"'));
    expect(docxStyles, contains('Times New Roman'));
    final headers = [
      for (var i = 1; i <= 4; i++)
        if (readZipEntry(docxBytes, 'word/header$i.xml') case final h?) utf8.decode(h),
    ].join();
    expect(headers, contains('Tal / CENAS / '));
    // O índice de figuras e o remissivo do compilar (D-090): o motor lê o
    // FODT com eles e grava os dois no ODT, com os títulos.
    final indexed = '${tmp.path}/compilado-indices.odt';
    expect((await workspace.compileBook(
                CompileJob(kit),
                const CompileSettings(
                    title: 'Cenas', format: CompileFormat.odt, figures: true, figuresTitle: 'Figuras', index: true, indexTitle: 'Remissivo'),
                indexed))
            .outcome,
        CompileOutcome.done);
    final indexedXml = readOdtContent(indexed)!;
    expect(indexedXml, contains('<text:illustration-index '));
    expect(indexedXml, contains('<text:alphabetical-index '));
    expect(indexedXml, contains('>Remissivo</text:p>'));

    workspace.onUnsaved = () async => UnsavedChoice.discard;
    expect(await workspace.closeBook(), isTrue);

    // 30. Os comentários (D-088): o autor vale no documento aberto depois;
    //     comentar a primeira palavra, responder, resolver; salvar e reabrir
    //     traz a conversa (a lista do ViewAnnotations), e o content.xml conta
    //     os abertos sem abrir.
    doc.author = 'Ana "Revisora" Teste';
    final commented = File('test/fixtures/capitulo-curto.odt').copySync('${tmp.path}/comentado.odt').path;
    final commentsMark = events.length;
    await openAndWait(commented);
    await until(() => events.skip(commentsMark).any((e) => e is CommandValues && e.command == '.uno:ViewAnnotations'),
        'a lista vazia ao abrir');
    expect(doc.comments, isEmpty);
    doc.uno('.uno:GoToStartOfDoc');
    doc.uno('.uno:WordRightSel');
    doc.insertComment('Dedicar a quem?');
    await until(() => doc.comments.length == 1, 'o comentário novo');
    final first = doc.comments.single;
    expect(first.author, 'Ana "Revisora" Teste');
    expect(first.text, 'Dedicar a quem?');
    expect(first.range, isNotEmpty, reason: 'o trecho da palavra');
    doc.replyComment(first.id, 'À avó.');
    await until(() => doc.comments.length == 2, 'a resposta');
    doc.toggleResolved(first.id);
    await until(() => doc.comments.firstWhere((c) => c.id == first.id).resolved, 'resolver');
    doc.uno('.uno:GoToEndOfDoc');
    doc.uno('.uno:WordLeftSel');
    doc.insertComment('Aberto');
    await until(() => doc.comments.length == 3, 'o segundo comentário');
    await workspace.save();
    await until(() => !doc.modified && doc.busy == null, 'salvar o comentado');
    expect(openCommentsInContent(readOdtContent(commented)!), 1, reason: 'um resolvido e uma resposta não contam');
    expect(await workspace.closeTab(), isTrue);
    await until(() => doc.path != commented && doc.busy == null, 'fechar o comentado');
    await openAndWait(commented);
    await until(() => doc.comments.length == 3, 'a conversa de volta ao reabrir');
    final threads = commentThreads(doc.comments);
    expect(threads.map((t) => t.root.text), ['Dedicar a quem?', 'Aberto'], reason: 'na ordem do texto');
    expect(threads.first.resolved, isTrue);
    expect(threads.first.replies.single.text, 'À avó.');
    doc.deleteComment(threads.last.root.id);
    await until(() => doc.comments.length == 2, 'excluir');
    expect(await workspace.closeTab(), isTrue);

    // 31. O controle de alterações (D-089): a Revisão marca o que se digita e
    //     o que se apaga; a lista vem só com o painel (liveChanges); aceitar
    //     uma pelo índice, rejeitar as outras; a Leitura não deixa editar; o
    //     ODT guarda a alteração que ficou.
    final revised = File('test/fixtures/capitulo-curto.odt').copySync('${tmp.path}/revisado.odt').path;
    await openAndWait(revised);
    doc.liveChanges = true;
    doc.setTracking(true);
    await until(() => doc.tracking, 'ligar a Revisão');
    // Apagar uma inserção da própria Revisão some com ela: apaga antes.
    doc.uno('.uno:GoToStartOfDoc');
    doc.uno('.uno:WordRightSel');
    doc.uno('.uno:Delete');
    doc.uno('.uno:GoToStartOfDoc');
    doc.uno('.uno:InsertText', '{"Text":{"type":"string","value":"Aceita "}}');
    doc.uno('.uno:GoToEndOfDoc');
    doc.uno('.uno:InsertText', '{"Text":{"type":"string","value":" Rejeitada"}}');
    await until(() => doc.changes.length == 3 && doc.hasChanges, 'a lista das alterações',
        detail: () => '${doc.changes.map((c) => c.description)}');
    expect(doc.changes.where((c) => c.kind == TrackedChangeKind.delete), hasLength(1));
    final accepted = doc.changes.firstWhere((c) => c.description.contains('Aceita'));
    expect(accepted.kind, TrackedChangeKind.insert);
    expect(accepted.author, 'Ana "Revisora" Teste');
    expect(accepted.range, isNotEmpty);
    doc.acceptChange(accepted.index);
    await until(() => doc.changes.every((c) => c.index != accepted.index), 'aceitar uma');
    doc.rejectAllChanges();
    await until(() => doc.changes.isEmpty && !doc.hasChanges, 'rejeitar as outras');
    expect((await doc.searchText(const SearchQuery('Rejeitada'), fresh: true)).total, 0);
    doc.uno('.uno:GoToEndOfDoc');
    doc.uno('.uno:InsertText', '{"Text":{"type":"string","value":" Pendente"}}');
    await until(() => doc.changes.length == 1, 'a que fica pendente');
    doc.reading = true;
    expect(doc.canEdit, isFalse);
    doc.acceptAllChanges();
    await settle(500);
    expect(doc.changes, hasLength(1), reason: 'na Leitura, nada se aceita');
    doc.reading = false;
    doc.setTracking(false);
    await until(() => !doc.tracking, 'desligar a Revisão');
    await workspace.save();
    await until(() => !doc.modified && doc.busy == null, 'salvar o revisado');
    final revisedXml = readOdtContent(revised)!;
    expect(revisedXml, contains('Aceita'));
    expect(revisedXml, contains('<text:changed-region'));
    expect(revisedXml, isNot(contains('Rejeitada')));
    doc.liveChanges = false;
    expect(await workspace.closeTab(), isTrue);

    // 32. As referências (D-090): pelas macros do perfil (novo: o motor
    //     trocou a lista das bibliotecas ao ligar), na aba da tela e não na
    //     outra; o sumário, a legenda da tabela e a da imagem, o marcador, as
    //     referências a um título, a um marcador e a uma legenda, o índice de
    //     figuras e o remissivo, atualizar, e a edição segue depois.
    final otherTab = File('test/fixtures/capitulo-curto.odt').copySync('${tmp.path}/outra-aba.odt').path;
    final referenced = File('test/fixtures/capitulo-curto.odt').copySync('${tmp.path}/referencias.odt').path;
    await openAndWait(otherTab);
    await openAndWait(referenced);
    String style(String name) => '{"Style":{"type":"string","value":"$name"},"FamilyName":{"type":"string","value":"ParagraphStyles"}}';
    void type(String text) => doc.uno('.uno:InsertText', '{"Text":{"type":"string","value":${jsonEncode(text)}}}');
    doc.uno('.uno:GoToEndOfDoc');
    doc.uno('.uno:InsertPara');
    doc.uno('.uno:StyleApply', style('Heading 1'));
    type('Mapas do rio');
    doc.uno('.uno:InsertPara');
    doc.uno('.uno:StyleApply', style('Text Body'));
    type('Quixadá');
    doc.uno('.uno:WordLeftSel');
    await until(() => doc.hasSelection, 'selecionar a palavra');
    doc.markIndexEntry(all: true);
    doc.uno('.uno:GoToEndOfDoc');
    type(' fica longe. Aqui.');
    doc.insertBookmark('fim do rio');
    type(' Mais.');
    await until(() => doc.snapshot.bookmarks.contains('fim do rio'), 'o marcador na cópia', detail: () => '${doc.snapshot.bookmarks}');
    doc.uno('.uno:InsertPara');
    doc.insertTable(2, 2);
    await until(() => doc.inTable, 'a tabela das referências');
    type('Distância');
    doc.insertCaption(CaptionKind.table, 'Tabela');
    type('Léguas');
    doc.uno('.uno:GoToEndOfDoc');
    doc.uno('.uno:InsertPara');
    doc.insertImage(png.path);
    await until(() => doc.graphic != null, 'a imagem das referências');
    doc.insertCaption(CaptionKind.figure, 'Figura');
    await until(() => doc.graphic == null, 'a legenda tira a seleção da imagem');
    type('O rio');
    doc.refreshSnapshot();
    await until(() => doc.snapshot.captions.any((c) => c.text == 'Figura 1: O rio') && doc.snapshot.bookmarks.contains('fim do rio'), 'a cópia com as legendas',
        detail: () => '${doc.snapshot.captions.map((c) => c.text)} ${doc.snapshot.bookmarks}');
    final figure = doc.snapshot.captions.firstWhere((c) => c.sequence == 'Figure');
    expect(figure.text, 'Figura 1: O rio');
    expect(doc.snapshot.captions.firstWhere((c) => c.sequence == 'Table').text, 'Tabela 1: Léguas');
    final heading = doc.snapshot.outline.indexWhere((h) => h.text == 'Mapas do rio');
    expect(heading, greaterThanOrEqualTo(0));
    doc.uno('.uno:GoToEndOfDoc');
    doc.uno('.uno:InsertPara');
    type('Ver ');
    doc.insertHeadingRef(heading, RefFormat.text);
    type(', na página ');
    doc.insertHeadingRef(heading, RefFormat.page);
    type(', o ');
    doc.insertBookmarkRef('fim do rio', RefFormat.page);
    type(' e a ');
    doc.insertCaptionRef(figure, RefFormat.text);
    type('.');
    doc.uno('.uno:InsertPara');
    doc.insertIndex('Remissivo');
    doc.uno('.uno:GoToStartOfDoc');
    doc.insertToc('Sumário');
    doc.insertCaptionTable('Figuras', CaptionKind.figure);
    doc.updateIndexes();
    doc.goToBookmark('fim do rio');
    type('[aqui]');
    doc.uno('.uno:GoToEndOfDoc');
    type('Depois de atualizar.');
    await workspace.save();
    await until(() => !doc.modified && doc.busy == null, 'salvar as referências');
    final refXml = readOdtContent(referenced)!;
    String plain(String tag) {
      final m = RegExp('<text:$tag[\\s>][\\s\\S]*?</text:$tag>').firstMatch(refXml);
      return m == null ? '' : m[0]!.replaceAll(RegExp(r'<[^>]+>'), ' ').replaceAll(RegExp(r'\s+'), ' ');
    }
    expect(plain('table-of-content'), contains('Mapas do rio'), reason: 'o sumário preenchido');
    expect(plain('illustration-index'), contains('Figura 1: O rio'), reason: 'o índice de figuras');
    expect(plain('alphabetical-index'), contains('Quixadá'), reason: 'o remissivo');
    expect(refXml, contains('<text:sequence text:ref-name="refTable0" text:name="Table"'));
    expect(refXml, contains('<text:bookmark-ref text:reference-format="text" text:ref-name="__RefHeading__quill_'));
    expect(RegExp(r'<text:bookmark-ref text:reference-format="text"[^>]*>Mapas do rio<').hasMatch(refXml), isTrue);
    expect(RegExp(r'<text:sequence-ref [^>]*>Figura 1<').hasMatch(refXml), isTrue, reason: 'a referência à legenda');
    expect(refXml, contains('<text:bookmark-ref text:reference-format="page" text:ref-name="fim do rio">'));
    if (Platform.environment['QUILL_REF_OUT'] case final copy?) File(copy).writeAsStringSync(refXml);
    expect(refXml, contains('Aqui.<text:bookmark text:name="fim do rio"/>[aqui] Mais.'), reason: 'ir ao marcador');
    expect(refXml, contains('Depois de atualizar.'), reason: 'a edição segue depois de atualizar');
    expect(await workspace.closeTab(), isTrue);
    await until(() => doc.path == otherTab && doc.busy == null, 'a outra aba');
    expect((await doc.searchText(const SearchQuery('Mapas do rio'), fresh: true)).total, 0, reason: 'as macros só na aba da tela');
    expect(doc.modified, isFalse);
    expect(await workspace.closeTab(), isTrue);

    // 33. O parágrafo avançado e as propriedades (D-091): o fundo pelo motor,
    //     o intervalo, as bordas e as tabulações pelas macros, nos parágrafos
    //     da seleção; as propriedades no meta.xml; e a cópia as lê de volta.
    final formatted = File('test/fixtures/capitulo-curto.odt').copySync('${tmp.path}/paragrafo.odt').path;
    await openAndWait(formatted);
    doc.uno('.uno:GoToEndOfDoc');
    doc.uno('.uno:InsertPara');
    type('Linha um');
    doc.uno('.uno:InsertPara');
    type('Linha dois');
    doc.uno('.uno:GoUp');
    doc.uno('.uno:GoToStartOfLine');
    doc.uno('.uno:EndOfDocumentSel');
    // Um retângulo por linha: as duas.
    await until(() => doc.selection.length >= 2, 'selecionar os dois parágrafos', detail: () => '${doc.selection}');
    doc.applyParagraph(const ParagraphChanges(
      background: 0xFFFF00,
      noSpaceSameStyle: true,
      borders: BorderSpec(sides: BorderSides.top | BorderSides.bottom, weight: BorderWeight.medium, color: 0x0000FF),
      tabs: [TabStopSpec(positionMm100: 3000), TabStopSpec(positionMm100: 8000, align: TabAlign.right, leader: TabLeader.dots)],
    ));
    await until(() => doc.paragraphBorderSides == (BorderSides.top | BorderSides.bottom), 'o motor diz as bordas',
        detail: () => '${doc.commandStates['.uno:BorderOuter']}');
    doc.setDocumentProperties(const DocProperties(title: 'Dustland', subject: 'Deserto', author: 'Quem escreve', keywords: ['um', 'dois & três'], comment: 'Nota'));
    await until(() => doc.snapshot.properties.title == 'Dustland', 'a cópia com as propriedades', detail: () => doc.snapshot.properties.title);
    expect(doc.snapshot.properties.keywords, ['um', 'dois & três']);
    expect(doc.snapshot.paragraphs, greaterThan(2));
    expect(doc.snapshot.charactersNoSpaces, lessThan(doc.snapshot.characters!));
    expect(doc.modified, isTrue);
    await workspace.save();
    await until(() => !doc.modified && doc.busy == null, 'salvar o parágrafo');
    final paraXml = readOdtContent(formatted)!;
    // Cada parágrafo pode ter o seu estilo automático (o rsid muda).
    final autos = {
      for (final m in RegExp(r'<style:style style:name="(P\d+)"[^>]*>((?:(?!</style:style>)[\s\S])*)</style:style>').allMatches(paraXml))
        m[1]!: m[2]!,
    };
    final lines = RegExp(r'<text:p text:style-name="(P\d+)">Linha (um|dois)</text:p>').allMatches(paraXml).toList();
    expect(lines, hasLength(2), reason: 'os dois parágrafos, com estilo automático');
    for (final l in lines) {
      final styleXml = autos[l[1]]!;
      expect(styleXml, contains('fo:background-color="#ffff00"'), reason: 'o fundo em "${l[2]}"');
      expect(styleXml, contains('style:contextual-spacing="true"'));
      expect(styleXml, contains('fo:border-top="1.5pt solid #0000ff"'));
      expect(styleXml, contains('fo:border-bottom="1.5pt solid #0000ff"'));
      expect(styleXml, contains('fo:border-left="none"'));
      expect(styleXml, contains('style:leader-text="."'));
    }
    final metaXml = utf8.decode(readZipEntry(File(formatted).readAsBytesSync(), 'meta.xml')!);
    expect(metaXml, contains('<dc:title>Dustland</dc:title>'));
    expect(metaXml, contains('<meta:initial-creator>Quem escreve</meta:initial-creator>'));
    expect(metaXml, contains('<meta:keyword>dois &amp; três</meta:keyword>'));
    // As tabulações voltam às do estilo, e a borda sai.
    doc.setTabStops(const []);
    doc.setParagraphBorders(const BorderSpec(sides: 0));
    await until(() => doc.paragraphBorderSides == 0, 'sem bordas');
    workspace.onUnsaved = () async => UnsavedChoice.discard;
    expect(await workspace.closeTab(), isTrue);

        // Fecha sem salvar (descarta), para não deixar trava.
    workspace.onUnsaved = () async => UnsavedChoice.discard;
    expect(await workspace.requestExit(), isTrue);
    expect(LoLock.fileFor(velho).existsSync(), isFalse);

    await sub.cancel();
    // Sem kit.dispose(): o destroy do LOK no fim do processo às vezes demora,
    // e o processo de teste termina logo em seguida.
  });
}

/// Uma imagem PNG de 8×8 px, cinza.
const _png = 'iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAAAAADhZOFXAAAADklEQVR4nGNogAIGyhgAgIQgAQ2AJGEAAAAASUVORK5CYII=';
