// O livro (Fase 3, Etapa 1, D-071): o leitor de zip, o corte do manuscrito,
// o `livro.json` e o controlador.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/book/book.dart';
import 'package:psito_quill/src/book/book_controller.dart';
import 'package:psito_quill/src/book/book_io.dart';
import 'package:psito_quill/src/book/docx_import.dart';
import 'package:psito_quill/src/book/fodt_split.dart';
import 'package:psito_quill/src/book/odt_zip.dart';
import 'package:psito_quill/src/document/document_controller.dart';
import 'package:psito_quill/src/document/fodt.dart';
import 'package:psito_quill/src/kit/fake/fake_quill_kit.dart';
import 'package:psito_quill/src/kit/quill_kit.dart';

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('quill-livro-'));
  tearDown(() => tmp.deleteSync(recursive: true));

  group('o zip do ODT', () {
    test('lê o content.xml de um ODT do motor', () {
      final xml = readOdtContent('test/fixtures/capitulo-curto.odt');
      expect(xml, isNotNull);
      expect(xml, contains('<office:text'));
      expect(xml, contains('Capítulo 1: A poeira'));
    });

    test('um arquivo que não é zip, ou sem a entrada, dá null', () {
      final f = File('${tmp.path}/x.odt')..writeAsStringSync('não é zip');
      expect(readOdtContent(f.path), isNull);
      expect(readZipEntry(File('test/fixtures/capitulo-curto.odt').readAsBytesSync(), 'nada.xml'), isNull);
      expect(readOdtContent('${tmp.path}/sumiu.odt'), isNull);
    });

    test('as palavras: as marcas no meio não partem a palavra', () {
      expect(odfWordCount('<text:p>pa<text:span>la</text:span>vra um</text:p><text:p>dois</text:p>'), 3);
      expect(odfWordCount('<text:p>a<text:tab/>b<text:s/>c<text:line-break/>d</text:p>'), 4);
      expect(odfWordCount('<text:p>&amp; e</text:p>'), 2);
    });
  });

  group('o corte do manuscrito', () {
    final xml = File('test/fixtures/livro-teste.fodt').readAsStringSync();

    test('os níveis e o sugerido', () {
      final m = FodtManuscript.parse(xml);
      expect(m.headingLevels, [1, 2]);
      expect(m.suggestedLevel, 1);
    });

    test('no nível 1: três capítulos, a dedicatória antes do primeiro título à parte', () {
      final m = FodtManuscript.parse(xml);
      final c = m.chapters(1);
      expect(c.map((d) => d.title), [null, 'Capítulo 1: A poeira', 'Capítulo 2: O poço', 'Capítulo 3: A cidade']);
      expect(c.first.words, greaterThan(3));
      expect(c[1].words, greaterThan(100));
      expect(c.every((d) => d.part == null), isTrue);
    });

    test('no nível 2: os títulos de nível 1 viram partes', () {
      final c = FodtManuscript.parse(xml).chapters(2);
      expect(c.where((d) => d.title != null).map((d) => (d.part, d.title)), [
        ('Capítulo 1: A poeira', 'Parte 1.1'),
        ('Capítulo 2: O poço', 'Parte 2.1'),
        ('Capítulo 3: A cidade', 'Parte 3.1'),
      ]);
    });

    test('cada capítulo leva o cabeçalho inteiro e só os blocos dele', () {
      final m = FodtManuscript.parse(xml);
      final c = m.chapters(1);
      final second = m.chapterXml(c[2]);
      expect(second, contains('<office:styles'));
      expect(second, contains('<office:automatic-styles'));
      expect(second, contains('Capítulo 2: O poço'));
      expect(second, isNot(contains('Capítulo 1: A poeira')));
      expect(second, contains('</office:document>'));
      expect(second, isNot(contains('meta:document-statistic')));
    });

    test('o marcador que atravessa: o começo vira ponto, o fim sozinho sai', () {
      final m = FodtManuscript.parse(xml);
      final c = m.chapters(1);
      final first = m.chapterXml(c[1]), second = m.chapterXml(c[2]);
      expect(first, contains('<text:bookmark text:name="atravessa"/>'));
      expect(first, isNot(contains('bookmark-start')));
      expect(second, isNot(contains('bookmark-end')));
    });

    test('sem office:text, não é um texto', () {
      expect(() => FodtManuscript.parse('<office:document/>'), throwsFormatException);
    });
  });

  group('o livro.json', () {
    test('ida e volta, com partes, status, rótulo e sinopse', () {
      final book = Book(title: 'Dustland', author: 'F.', nodes: [
        BookNode(id: 'a', kind: BookNodeKind.chapter, title: 'Abertura', file: 'capitulos/001-abertura.odt', words: 10),
        BookNode(id: 'p', kind: BookNodeKind.part, title: 'Parte I', children: [
          BookNode(
            id: 'b',
            kind: BookNodeKind.chapter,
            title: 'O poço',
            file: 'capitulos/002-o-poco.odt',
            status: ChapterStatus.revision,
            label: 2,
            synopsis: 'Eles descem.',
          ),
        ]),
      ]);
      writeBook(tmp.path, book);
      expect(File('${tmp.path}/.livro.json.tmp').existsSync(), isFalse, reason: 'grava ao lado e renomeia');
      final back = readBook(tmp.path);
      expect(back.title, 'Dustland');
      expect(back.author, 'F.');
      expect(back.chapters.map((c) => c.id), ['a', 'b']);
      final b = back.find('b')!.$1;
      expect((b.status, b.label, b.synopsis), (ChapterStatus.revision, 2, 'Eles descem.'));
      expect(back.parentOf('b')!.title, 'Parte I');
      expect(back.words, 10);
    });

    test('um JSON que não é livro', () {
      File('${tmp.path}/livro.json').writeAsStringSync(jsonEncode({'outra': 1}));
      expect(() => readBook(tmp.path), throwsFormatException);
    });

    test('os nomes: a pasta, o slug e o próximo número', () {
      expect(bookFolderName('Dustland: a poeira'), 'Dustland a poeira.psitobook');
      expect(slugOf('Capítulo 2: O Poço!'), 'capitulo-2-o-poco');
      createBookDir(tmp.path);
      File('${tmp.path}/capitulos/007-x.odt').writeAsStringSync('');
      expect(newChapterFile(tmp.path, 'A cidade'), 'capitulos/008-a-cidade.odt');
      expect(newChapterFile(tmp.path, 'B', taken: {'capitulos/010-y.odt'}), 'capitulos/011-b.odt');
      expect(() => createBookDir(tmp.path), returnsNormally, reason: 'sem livro.json ainda');
      writeBook(tmp.path, Book(title: 'x'));
      expect(() => createBookDir(tmp.path), throwsA(isA<FileSystemException>()));
    });

    test('as palavras dos capítulos fechados, num isolate', () async {
      final counts = await countChapterWords(['test/fixtures/capitulo-curto.odt', '${tmp.path}/sumiu.odt']);
      expect(counts.keys, ['test/fixtures/capitulo-curto.odt']);
      expect(counts.values.single.$1, greaterThan(100));
    });
  });

  group('o controlador', () {
    late FakeQuillKit kit;
    late BookController books;

    setUp(() {
      kit = FakeQuillKit();
      books = BookController(kit);
    });
    tearDown(() => books.dispose());

    test('novo livro: a pasta, o capítulo vazio pelo motor e o livro.json', () async {
      final dir = '${tmp.path}/Dustland.psitobook';
      await books.create(dir, 'Dustland', firstChapter: 'Capítulo 1');
      expect(kit.conversions.single, ('', '$dir/capitulos/001-capitulo-1.odt', 'odt'));
      expect(File('$dir/livro.json').existsSync(), isTrue);
      expect(books.book!.chapters.single.title, 'Capítulo 1');
      expect(() => books.create(dir, 'Outro', firstChapter: 'x'), throwsA(isA<BookException>()));
    });

    test('criar, mover, Alt+setas, renomear e apagar para a lixeira', () async {
      final dir = '${tmp.path}/L.psitobook';
      await books.create(dir, 'L', firstChapter: 'Um');
      final um = books.book!.chapters.single;
      final dois = await books.addChapter('Dois', afterId: um.id);
      final parte = books.addPart('Parte', afterId: dois.id);
      final tres = await books.addChapter('Três', partId: parte.id);
      List<String> order() => [
            for (final n in books.book!.nodes) ...[n.title, for (final c in n.children) '  ${c.title}'],
          ];
      expect(order(), ['Um', 'Dois', 'Parte', '  Três']);

      books.nudge(dois.id, up: false);
      expect(order(), ['Um', 'Parte', '  Dois', '  Três'], reason: 'descer sobre uma parte entra nela');
      books.nudge(dois.id, up: true);
      expect(order(), ['Um', 'Dois', 'Parte', '  Três'], reason: 'subir na ponta sai dela');
      books.nudge(um.id, up: false);
      expect(order(), ['Dois', 'Um', 'Parte', '  Três']);
      books.move(tres.id, index: 0);
      expect(order(), ['Três', 'Dois', 'Um', 'Parte']);
      books.move(parte.id, partId: parte.id, index: 0);
      expect(order(), ['Três', 'Dois', 'Um', 'Parte'], reason: 'uma parte não entra em parte');

      books.rename(um.id, '  Um, de novo ');
      expect(books.book!.find(um.id)!.$1.title, 'Um, de novo');
      books.rename(um.id, '   ');
      expect(books.book!.find(um.id)!.$1.title, 'Um, de novo', reason: 'nome vazio não vale');

      final file = um.file!;
      books.remove(um.id);
      expect(File('$dir/$file').existsSync(), isFalse);
      expect(File('$dir/lixeira/${file.split('/').last}').existsSync(), isTrue, reason: 'nunca apaga de vez');
      expect(readBook(dir).chapters.map((c) => c.title), ['Três', 'Dois'], reason: 'cada mudança grava');
    });

    test('apagar uma parte deixa os capítulos dela no lugar', () async {
      await books.create('${tmp.path}/P.psitobook', 'P', firstChapter: 'Um');
      final parte = books.addPart('Parte');
      await books.addChapter('Dois', partId: parte.id);
      books.remove(parte.id);
      expect(books.book!.nodes.map((n) => n.title), ['Um', 'Dois']);
    });

    test('salvar um capítulo reconta as palavras dele', () async {
      final dir = '${tmp.path}/S.psitobook';
      kit.onConvert = (src, dst, fmt) => File('test/fixtures/capitulo-curto.odt').copySync(dst);
      await books.create(dir, 'S', firstChapter: 'Um');
      final um = books.book!.chapters.single;
      expect(um.words, 0);
      kit.emit(DocumentSaved('$dir/${um.file}'));
      await pumpUntil(() => um.words > 0);
      expect(um.words, greaterThan(100));
      expect(readBook(dir).chapters.single.words, um.words);
    });

    test('abrir um livro que não existe ou que não é livro', () async {
      expect(() => books.open('${tmp.path}/nada'), throwsA(isA<BookException>()));
      File('${tmp.path}/livro.json').writeAsStringSync('{"x":1}');
      expect(
        () => books.open(tmp.path),
        throwsA(isA<BookException>().having((e) => e.error, 'error', BookError.invalid)),
      );
    });
  });

  group('o importador', () {
    test('lê o manuscrito pela cópia do motor e cria o livro, com os capítulos pelo motor', () async {
      final kit = FakeQuillKit();
      // O falso "salva" o DOCX em ODT plano copiando o FODT da fixture, e os
      // capítulos em ODT copiando o ODT curto.
      kit.onConvert = (src, dst, fmt) => File(fmt == 'fodt' ? 'test/fixtures/livro-teste.fodt' : src).copySync(dst);
      final importer = DocxImporter(kit);
      final m = await importer.read('/livros/dustland.docx');
      final leftovers = Directory(DocumentController.copyDir)
          .listSync()
          .where((f) => f.path.contains('${DocumentController.copyPrefixOfThisProcess}livro-'));
      expect(leftovers, isEmpty, reason: 'a cópia do manuscrito é apagada na hora');

      final drafts = m.chapters(2);
      final done = <int>[];
      final dir = '${tmp.path}/Dustland.psitobook';
      final book = await importer.create(
        dir: dir,
        title: 'Dustland',
        m: m,
        drafts: drafts,
        untitled: 'Abertura',
        progress: done.add,
      );
      expect(done.last, drafts.length);
      expect(book.nodes.map((n) => n.title), ['Abertura', 'Capítulo 1: A poeira', 'Capítulo 2: O poço', 'Capítulo 3: A cidade']);
      expect(book.nodes.skip(1).every((n) => n.isPart && n.children.length == 1), isTrue);
      final first = book.find(book.nodes[1].children.single.id)!.$1;
      expect(File('$dir/${first.file}').readAsStringSync(), contains('Capítulo 1: A poeira'),
          reason: 'a parte e a introdução dela ficam no começo do primeiro capítulo');
      expect(readBook(dir).chapters.length, drafts.length);
      expect(Directory(DocumentController.copyDir).listSync().where((f) => f.path.contains('livro-capitulo')), isEmpty);
    });

    test('o motor não lê o manuscrito', () async {
      final kit = FakeQuillKit()..failConversions = true;
      expect(
        () => DocxImporter(kit).read('/x.docx'),
        throwsA(isA<ImportException>().having((e) => e.error, 'error', ImportError.unreadable)),
      );
    });
  });
}

Future<void> pumpUntil(bool Function() ok) async {
  for (var i = 0; i < 200 && !ok(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
