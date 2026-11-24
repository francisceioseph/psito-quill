// Os fluxos das cenas pelo motor falso (Fase 3, Etapa 5, D-079): a nova
// cena, converter os separadores, saltar a uma cena, dividir e juntar.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/book/book.dart';
import 'package:psito_quill/src/book/book_io.dart';
import 'package:psito_quill/src/document/document_controller.dart';
import 'package:psito_quill/src/document/fodt.dart';
import 'package:psito_quill/src/document/outline.dart';
import 'package:psito_quill/src/document/workspace.dart';
import 'package:psito_quill/src/kit/quill_kit.dart';

import '../support/harness.dart';

void main() {
  late Harness h;
  setUp(() => h = Harness());
  tearDown(() => h.dispose());

  /// Espera a fila do falso e os isolates.
  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 50));

  /// Um livro com três capítulos, o primeiro aberto.
  Future<String> openBook() async {
    final dir = '${h.dir.path}/Livro.psitobook';
    createBookDir(dir);
    for (final f in ['001-um', '002-dois', '003-tres']) {
      File('$dir/capitulos/$f.odt').writeAsStringSync('x');
    }
    writeBook(
      dir,
      Book(title: 'Livro', nodes: [
        BookNode(id: 'a', kind: BookNodeKind.chapter, title: 'Um', file: 'capitulos/001-um.odt'),
        BookNode(id: 'b', kind: BookNodeKind.chapter, title: 'Dois', file: 'capitulos/002-dois.odt'),
        BookNode(id: 'c', kind: BookNodeKind.chapter, title: 'Três', file: 'capitulos/003-tres.odt'),
      ]),
    );
    await h.workspace.openPath(dir);
    await settle();
    return dir;
  }

  String styleArg(int i) => '${((jsonDecode(h.kit.unoArgs[i]) as Map)['Style'] as Map)['value']}';

  group('a nova cena', () {
    test('sem o estilo, ele vem pela cópia; depois, o separador e um parágrafo embaixo', () async {
      await h.workspace.openPath(h.file('cap.odt'));
      await settle();
      h.kit.loadStylesAdds = sceneStyleName;
      h.kit.unoCommands.clear();
      h.kit.unoArgs.clear();
      h.kit.keys.clear();
      expect(await h.doc.insertScene(), isTrue);
      final c = h.kit.unoCommands;
      expect(c, [
        '.uno:LoadStyles',
        '.uno:GoToEndOfPara',
        '.uno:InsertPara',
        '.uno:InsertPara',
        '.uno:GoUp',
        '.uno:InsertText',
        '.uno:StyleApply',
        '.uno:GoDown',
      ]);
      expect(styleArg(c.indexOf('.uno:StyleApply')), sceneStyleName);
      expect(h.kit.unoArgs[c.indexOf('.uno:InsertText')], contains(sceneSeparatorText));
      // Nenhuma tecla: a tecla chega ao motor depois dos comandos.
      expect(h.kit.keys, isEmpty);

      // A cópia seguinte já tem o estilo: a segunda cena não o carrega de novo.
      await settle();
      expect(h.doc.hasSceneStyle, isTrue);
      h.kit.unoCommands.clear();
      expect(await h.doc.insertScene(), isTrue);
      expect(h.kit.unoCommands, isNot(contains('.uno:LoadStyles')));
    });

    test('só leitura, não', () async {
      final p = h.file('cap.odt');
      h.lock(p, profile: 'file:///home/eu/.config/libreoffice/4', user: 'maria');
      await h.workspace.openPath(p);
      expect(await h.doc.insertScene(), isFalse);
      expect(h.kit.unoCommands, isEmpty);
    });
  });

  group('converter os separadores', () {
    test('conta pela cópia, busca todos e aplica o estilo', () async {
      await h.workspace.openPath(h.file('cap.odt'));
      await settle();
      h.kit.paragraphStyles = [...h.kit.paragraphStyles, sceneStyleName];
      h.kit.bodyParagraphs = ['Um.', '* * *', 'Dois.', '#', 'Três.'];
      h.kit.unoCommands.clear();
      h.kit.unoArgs.clear();
      // O estilo já existe na cópia de agora.
      h.doc.refreshSnapshot();
      await settle();
      expect(await h.doc.convertSceneSeparators(), 2);
      final c = h.kit.unoCommands;
      expect(c, containsAllInOrder(['.uno:ExecuteSearch', '.uno:StyleApply']));
      expect(c, isNot(contains('.uno:LoadStyles')));
      final search = jsonDecode(h.kit.unoArgs[c.indexOf('.uno:ExecuteSearch')]) as Map;
      expect((search['SearchItem.Command'] as Map)['value'], 1, reason: 'selecionar todos');
      expect((search['SearchItem.AlgorithmType2'] as Map)['value'], 2, reason: 'expressão regular');
      final regex = RegExp('${(search['SearchItem.SearchString'] as Map)['value']}');
      expect(['* * *', '#', ' *** '].every(regex.hasMatch), isTrue);
      expect(['Um.', '* a *'].any(regex.hasMatch), isFalse);
      // A resposta da busca não acende o Localizar.
      h.kit.emit(const SearchResult([], all: true));
      expect(h.doc.search.query, isNull);
    });

    test('sem separador solto, nada muda', () async {
      await h.workspace.openPath(h.file('cap.odt'));
      await settle();
      h.kit.bodyParagraphs = ['Um.', 'Dois.'];
      h.kit.unoCommands.clear();
      expect(await h.doc.convertSceneSeparators(), 0);
      expect(h.kit.unoCommands, isEmpty);
    });
  });

  group('saltar a uma cena', () {
    test('a primeira vai ao começo; as outras, ao separador pela busca, contando os de antes', () async {
      await h.workspace.openPath(h.file('cap.odt'));
      await settle();
      h.kit.unoCommands.clear();
      h.doc.goToScene(const SceneEntry(label: 'a'));
      expect(h.kit.unoCommands, ['.uno:GoToStartOfDoc']);
      h.kit.unoCommands.clear();
      h.doc.goToScene(const SceneEntry(label: 'b', searchKey: '* * *', occurrence: 2));
      expect(h.kit.unoCommands, ['.uno:GoToStartOfDoc', '.uno:ExecuteSearch', '.uno:ExecuteSearch', '.uno:ExecuteSearch']);
    });

    test('num capítulo que vai abrir, quando a cópia dele chega', () async {
      final dir = await openBook();
      h.kit.paragraphStyles = [...h.kit.paragraphStyles, sceneStyleName];
      h.kit.unoCommands.clear();
      final dois = h.workspace.book.book!.find('b')!.$1;
      h.workspace.openChapter(dois, scene: 0);
      await settle();
      expect(h.doc.path, '$dir/capitulos/002-dois.odt');
      // O falso não tem cenas: o pedido some sem saltar.
      expect(h.kit.unoCommands, isNot(contains('.uno:GoToStartOfDoc')));
    });
  });

  group('juntar com o próximo', () {
    test('insere o arquivo do próximo no fim, salva, e o próximo vai para a lixeira', () async {
      final dir = await openBook();
      h.kit.unoCommands.clear();
      h.kit.unoArgs.clear();
      expect(h.workspace.nextChapter?.id, 'b');
      expect(await h.workspace.joinWithNext(), isNull);
      final c = h.kit.unoCommands;
      expect(c, containsAllInOrder(['.uno:GoToEndOfDoc', '.uno:InsertPara', '.uno:InsertDoc']));
      final args = jsonDecode(h.kit.unoArgs[c.indexOf('.uno:InsertDoc')]) as Map;
      expect((args['Name'] as Map)['value'], Uri.file('$dir/capitulos/002-dois.odt').toString());
      expect(h.kit.saved.last.$1, '$dir/capitulos/001-um.odt');
      expect(h.workspace.book.book!.find('b'), isNull);
      expect(File('$dir/lixeira/002-dois.odt').existsSync(), isTrue);
      expect(readBook(dir).chapters.map((n) => n.id), ['a', 'c']);
      expect(h.doc.busy, isNull);
    });

    test('o próximo aberto e modificado: não junta', () async {
      await openBook();
      h.workspace.openChapter(h.workspace.book.book!.find('b')!.$1);
      await settle();
      h.doc.insertText('x');
      h.workspace.openChapter(h.workspace.book.book!.find('a')!.$1);
      await settle();
      h.kit.unoCommands.clear();
      expect(await h.workspace.joinWithNext(), ChapterEditError.nextModified);
      expect(h.kit.unoCommands, isNot(contains('.uno:InsertDoc')));
      expect(h.workspace.book.book!.find('b'), isNotNull);
    });

    test('o último capítulo não tem próximo', () async {
      await openBook();
      h.workspace.openChapter(h.workspace.book.book!.find('c')!.$1);
      await settle();
      expect(h.workspace.nextChapter, isNull);
      expect(await h.workspace.joinWithNext(), ChapterEditError.noNext);
    });

    test('fora do livro, não', () async {
      await h.workspace.openPath(h.file('solto.odt'));
      expect(await h.workspace.joinWithNext(), ChapterEditError.notInBook);
    });
  });

  group('dividir no cursor', () {
    test('o resto vira um capítulo logo depois; o da tela apaga até o fim e é salvo', () async {
      final dir = await openBook();
      h.kit.bodyParagraphs = ['Primeira parte do texto.', 'Segunda parte do texto.'];
      h.kit.bookmarkParagraph = 1;
      h.kit.unoCommands.clear();
      final r = await h.workspace.splitChapterHere(fallbackTitle: 'Um (continuação)');
      expect(r.error, isNull);
      final created = r.created!;
      expect(created.title, 'Um (continuação)');
      final ids = [for (final c in h.workspace.book.book!.chapters) c.id];
      expect(ids.indexOf(created.id), 1, reason: 'logo depois do capítulo dividido');
      // O motor converteu o resto (um FODT temporário) para o arquivo novo.
      final conv = h.kit.conversions.last;
      expect(conv.$1, endsWith('.fodt'));
      expect(conv.$2, '$dir/${created.file}');
      expect(File('$dir/${created.file}').readAsStringSync(), contains('Segunda parte'));
      expect(File('$dir/${created.file}').readAsStringSync(), isNot(contains('Primeira parte')));
      final c = h.kit.unoCommands;
      // No começo de um parágrafo depois de outro: o vazio que sobra junta.
      expect(
        c,
        containsAllInOrder(['.uno:InsertBookmark', '.uno:EndOfDocumentSel', '.uno:Delete', '.uno:SwBackspace', '.uno:DeleteBookmark']),
      );
      expect(h.kit.saved.last.$1, '$dir/capitulos/001-um.odt');
      expect(h.doc.busy, isNull);
      // A cópia e o resto temporários saíram.
      expect(
        Directory(DocumentController.copyDir).listSync().where((f) => f.path.contains('dividir')),
        isEmpty,
      );
    });

    test('no começo do capítulo, não há o que dividir, e o marcador sai', () async {
      await openBook();
      h.kit.bodyParagraphs = ['Tudo.'];
      h.kit.bookmarkParagraph = 0;
      h.kit.unoCommands.clear();
      final r = await h.workspace.splitChapterHere(fallbackTitle: 'x');
      expect(r.error, ChapterEditError.nothingToSplit);
      expect(h.kit.unoCommands.last, '.uno:DeleteBookmark');
      expect(h.kit.unoCommands, isNot(contains('.uno:Delete')));
      expect(h.workspace.book.book!.chapters, hasLength(3));
    });

    test('o motor não grava o capítulo novo: nada muda no da tela', () async {
      await openBook();
      h.kit.bodyParagraphs = ['Um.', 'Dois.'];
      h.kit.bookmarkParagraph = 1;
      h.kit.failConversions = true;
      h.kit.unoCommands.clear();
      final r = await h.workspace.splitChapterHere(fallbackTitle: 'x');
      expect(r.error, ChapterEditError.failed);
      expect(h.kit.unoCommands, isNot(contains('.uno:Delete')));
      expect(h.kit.unoCommands.last, '.uno:DeleteBookmark');
    });
  });
}
