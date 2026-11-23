// O controlador nos recursos da Fase 2, com o kit falso: estilos, busca,
// menu de contexto, imagens, tabelas, parágrafo e página. E as funções
// puras da paleta, do menu e das alças.
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart' show Icons;
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/l10n/gen/app_localizations_pt.dart';
import 'package:psito_quill/src/commands/command_registry.dart';
import 'package:psito_quill/src/commands/menus.dart';
import 'package:psito_quill/src/commands/palette_search.dart';
import 'package:psito_quill/src/document/document_controller.dart';
import 'package:psito_quill/src/document/search.dart';
import 'package:psito_quill/src/kit/fake/fake_quill_kit.dart';
import 'package:psito_quill/src/kit/quill_kit.dart';
import 'package:psito_quill/src/ui/molecules/measure_field.dart';
import 'package:psito_quill/src/ui/organisms/document_view.dart';
import 'package:psito_quill/src/ui/organisms/engine_context_menu.dart';

void main() {
  late FakeQuillKit kit;
  late DocumentController doc;

  setUp(() {
    kit = FakeQuillKit();
    doc = DocumentController(kit)..start();
    doc.open('/livro/cap.odt');
  });
  tearDown(() => doc.dispose());

  Map<String, dynamic> lastArgs() => jsonDecode(kit.unoArgs.last) as Map<String, dynamic>;

  group('estilos', () {
    test('a lista vem ao abrir, e os do autor se separam', () {
      expect(doc.paragraphStyles, contains('Heading 1'));
      expect(doc.customParagraphStyles, isEmpty);
      doc.newStyleFromSelection('Cena');
      expect(kit.unoCommands, contains('.uno:StyleNewByExample'));
      expect(doc.customParagraphStyles, ['Cena']);
      expect(doc.paragraphStyleId, 'Cena');
    });

    test('o estado em português vira o nome de programa', () {
      kit.emitState('.uno:StyleApply', 'Título 2');
      expect(doc.paragraphStyle, 'Título 2');
      expect(doc.paragraphStyleId, 'Heading 2');
    });

    test('estilo de caractere vai pela família certa', () {
      doc.applyCharacterStyle('Emphasis');
      expect((lastArgs()['FamilyName'] as Map)['value'], 'CharacterStyles');
    });
  });

  group('localizar e substituir', () {
    setUp(() => doc.insertText('Um texto e outro texto.'));

    test('achar a próxima seleciona; achar todas conta', () {
      doc.find(const SearchQuery('texto'));
      expect(doc.selection, hasLength(1));
      expect(doc.search.notFound, isFalse);
      doc.findAll(const SearchQuery('texto'));
      expect(doc.search.count, 2);
      expect(doc.searchHighlights, hasLength(2));
    });

    test('nada encontrado', () {
      doc.find(const SearchQuery('nada'));
      expect(doc.search.notFound, isTrue);
      expect(doc.searchHighlights, isEmpty);
    });

    test('substituir todas diz quantas trocou', () {
      doc.replaceAll(const SearchQuery('texto'), 'livro');
      expect(kit.text, 'Um livro e outro livro.');
      expect(doc.search.replaced, 2);
      expect(doc.searchHighlights, isEmpty);
    });

    test('expressão regular e maiúsculas', () {
      doc.findAll(const SearchQuery('T[a-z]+o', regex: true, matchCase: true));
      expect(doc.search.notFound, isTrue);
      // "texto", "tro" (de "outro") e "texto".
      doc.findAll(const SearchQuery('t[a-z]+o', regex: true));
      expect(doc.search.count, 3);
    });

    test('só leitura não troca', () {
      doc.open('/x.odt', lockOwner: 'Ana');
      doc.replaceAll(const SearchQuery('texto'), 'livro');
      expect(kit.unoCommands.where((c) => c == '.uno:ExecuteSearch'), isEmpty);
    });
  });

  group('menu de contexto', () {
    test('o clique direito vai ao motor como botão 4, e o menu fica pendente', () {
      kit.misspelled = {'erru': ['erro', 'errou']};
      doc.insertText('um erru aqui');
      doc.requestContextMenu(const Offset(3000, 1500));
      expect(kit.mice.last, (MouseEventType.up, 3000, 1500, 1));
      final menu = doc.contextMenu!;
      expect(menu.twips, const Offset(3000, 1500));
      expect(menu.items.first.text, 'erro');
      doc.runEngineCommand(menu.items.first.command);
      expect(kit.text, 'um erro aqui');
      doc.clearContextMenu();
      expect(doc.contextMenu, isNull);
    });

    test('o menu junta as sugestões do motor e os comandos do Quill', () {
      final l10n = AppLocalizationsPt();
      final entries = contextEntries(const [
        EngineMenuItem(text: 'erro', command: '.uno:SpellCheckApplySuggestion?ApplyRule:string=Spelling_erro'),
        EngineMenuItem.separator(),
        EngineMenuItem(text: '~Ignorar', command: '.uno:SpellCheckIgnore?Type:string=Spelling'),
        EngineMenuItem(text: 'Ignorar sempre', command: '.uno:SpellCheckIgnoreAll?Type:string=Spelling'),
        EngineMenuItem(text: 'Ortografia…', command: '.uno:SpellingAndGrammarDialog'),
      ], l10n, inTable: true, onImage: false);
      final labels = [
        for (final e in entries)
          switch (e) {
            EngineEntry(:final label) => label,
            CommandEntry(:final id) => id,
            SeparatorEntry() => '—',
          }
      ];
      expect(labels.take(4), ['erro', 'Ignorar', 'Ignorar sempre', '—']);
      // O diálogo de ortografia do LibreOffice não aparece (não há janelas
      // do motor no Quill).
      expect(labels, isNot(contains('Ortografia…')));
      expect(labels, contains('tabela.linhaAcima'));
      expect(labels, isNot(contains('imagem.emVolta')));
    });
  });

  group('imagens e tabelas', () {
    test('inserir imagem manda a URL do arquivo; o motor seleciona', () {
      doc.insertImage('/home/ana/foto de capa.png');
      expect(kit.unoCommands, contains('.uno:InsertGraphic'));
      final i = kit.unoCommands.lastIndexOf('.uno:InsertGraphic');
      expect(kit.unoArgs[i], contains('file:///home/ana/foto%20de%20capa.png'));
      expect(doc.graphic, isNotNull);
      expect(doc.graphicSizeCm, const Size(5.08, 5.08));
    });

    test('arrastar a alça manda início e fim ao motor', () {
      doc.insertImage('/a.png');
      doc.dragGraphic(const Offset(4320, 4880), const Offset(5000, 5500));
      expect(kit.graphicDrags, [(GraphicDrag.start, 4320, 4880), (GraphicDrag.end, 5000, 5500)]);
      expect(doc.graphic!.bottomRight, const Offset(5000, 5500));
    });

    test('a tabela liga o contexto', () {
      expect(doc.inTable, isFalse);
      doc.insertTable(2, 3);
      expect((lastArgs()['Columns'] as Map)['value'], 3);
      expect(doc.inTable, isTrue);
      kit.emit(const TableSelected(false));
      expect(doc.inTable, isFalse);
    });

    test('as alças e a prévia do arraste', () {
      const r = Rect.fromLTWH(100, 100, 200, 100);
      expect(graphicHandles(r), hasLength(8));
      expect(graphicHandles(r).last, const Offset(300, 200));
      expect(graphicDragPreview(r, 7, const Offset(50, 20)), const Rect.fromLTWH(100, 100, 250, 120));
      expect(graphicDragPreview(r, null, const Offset(10, 10)), const Rect.fromLTWH(110, 110, 200, 100));
      expect(graphicDragPreview(r, 0, const Offset(-10, 0)).left, 90);
    });
  });

  group('parágrafo e página', () {
    test('recuos em cm viram centésimos de milímetro, com os nomes que o 24.2 aceita', () {
      doc.setIndents(left: 1.25, firstLine: 0.5);
      expect(kit.unoCommands.last, '.uno:LeftRightParaMargin');
      expect((lastArgs()['LRSpace.LeftMargin'] as Map)['value'], 1250);
      expect((lastArgs()['LRSpace.FirstLineIndent'] as Map)['value'], 500);
      expect(lastArgs().containsKey('LRSpace.RightMargin'), isFalse);
    });

    test('os recuos e o entrelinhas vêm dos estados', () {
      kit.emitState('.uno:LeftRightParaMargin', '{"left":"0,5","right":"0,0","firstline":"0,0","unit":"inch"}');
      expect(doc.paragraphIndents['left'], closeTo(1.27, 1e-9));
      kit.emitState('.uno:SpacePara15', 'true');
      expect(doc.lineSpacing, 150);
      doc.setLineSpacing(130);
      expect((lastArgs()['LineSpacing.Height'] as Map)['value'], 130);
    });

    test('tamanho da página troca largura e altura na paisagem', () {
      doc.setPageSize(pageSizes.first);
      expect((lastArgs()['AttributePageSize.Width'] as Map)['value'], 21000);
      kit.emitState('.uno:Orientation', 'IsLandscape');
      expect(doc.landscape, isTrue);
      doc.setPageSize(pageSizes.first);
      expect((lastArgs()['AttributePageSize.Width'] as Map)['value'], 29700);
    });

    test('deitar troca largura e altura antes da marca (D-036)', () async {
      // A5 com 3 páginas, como o motor mede: 284 twips em volta e entre elas.
      final k = FakeQuillKit(documentSize: const Size(8959, 36854));
      final d = DocumentController(k)..start();
      addTearDown(d.dispose);
      d.open('/livro/a5.odt');
      await Future<void>.delayed(Duration.zero);
      k.emitState('.uno:StatePageNumber', 'Página 1 de 3');
      // Os twips arredondam: 14800 volta como 14801, e fica nisso.
      expect(d.pageSizeMm100, (14801, 21001));
      d.setLandscape(true);
      expect(k.unoCommands.reversed.take(2), ['.uno:AttributePage', '.uno:AttributePageSize']);
      final size = jsonDecode(k.unoArgs[k.unoArgs.length - 2]) as Map<String, dynamic>;
      expect((size['AttributePageSize.Width'] as Map)['value'], 21001);
      expect((size['AttributePageSize.Height'] as Map)['value'], 14801);
    });

    test('ladrilho e cursor não sobem a revisão dos estados (D-037)', () async {
      await Future<void>.delayed(Duration.zero);
      final r = doc.stateRevision;
      kit.emit(const CursorMoved(Rect.fromLTWH(0, 0, 20, 280)));
      kit.emit(const CursorVisibility(true));
      await Future<void>.delayed(Duration.zero);
      expect(doc.stateRevision, r);
      kit.emitState('.uno:Bold', 'true');
      await Future<void>.delayed(Duration.zero);
      expect(doc.stateRevision, greaterThan(r));
    });

    test('margens: duas chamadas, em centésimos de milímetro', () {
      doc.setPageMargins((left: 3, right: 2, top: 3, bottom: 2));
      expect(kit.unoCommands.reversed.take(2), ['.uno:PageULMargin', '.uno:PageLRMargin']);
      expect((lastArgs()['PageULMargin.Lower'] as Map)['value'], 2000);
    });

    test('cor da fonte: null é a automática (-1)', () {
      doc.setFontColor(null);
      expect((lastArgs()['Color.Color'] as Map)['value'], -1);
      kit.emitState('.uno:Color', '16711680');
      expect(doc.fontColor, 0xFF0000);
      kit.emitState('.uno:Color', '-1');
      expect(doc.fontColor, isNull);
    });
  });

  group('paleta e medidas', () {
    CommandRegistry registry() => CommandRegistry()
      ..register(Command(id: 'a', label: 'Negrito', icon: Icons.abc, run: () {}))
      ..register(Command(id: 'b', label: 'Inserir quebra de página', icon: Icons.abc, run: () {}))
      ..register(Command(id: 'c', label: 'Ação desligada', icon: Icons.abc, run: () {}, canRun: () => false));

    test('sem acento, sem maiúsculas, o começo primeiro', () {
      expect(foldForSearch('Ação…'), 'acao');
      final r = registry();
      expect(searchCommands(r, const [], 'NEG').map((e) => e.command.id), ['a']);
      expect(searchCommands(r, const [], 'quebra pag').map((e) => e.command.id), ['b']);
      expect(searchCommands(r, const [], 'acao'), isEmpty, reason: 'o que não pode rodar não aparece');
      expect(searchCommands(r, const [], ''), hasLength(2));
    });

    test('o nome do menu também casa', () {
      final r = registry();
      final hits = searchCommands(r, const [MenuSpec('Formatar', ['a'])], 'formatar');
      expect(hits.single.menu, 'Formatar');
    });

    test('medidas em cm nos dois idiomas', () {
      expect(formatCm(1.25, 'pt-BR'), '1,25');
      expect(formatCm(2.0, 'en'), '2');
      expect(formatCm(0.5, 'en'), '0.5');
      expect(parseCm('1,5 cm'), 1.5);
      expect(parseCm('abc'), isNull);
    });
  });
}
