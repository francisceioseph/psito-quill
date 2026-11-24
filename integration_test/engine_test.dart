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
import 'package:psito_quill/src/book/odt_zip.dart';
import 'package:psito_quill/src/book/docx_import.dart';
import 'package:psito_quill/src/book/book_io.dart';
import 'package:psito_quill/src/app.dart';
import 'package:psito_quill/src/document/document_controller.dart';
import 'package:psito_quill/src/document/recovery.dart';
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

    workspace.onUnsaved = () async => UnsavedChoice.discard;
    expect(await workspace.closeBook(), isTrue);

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
