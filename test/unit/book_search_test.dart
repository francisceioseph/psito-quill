// A busca no livro (Fase 3, Etapa 6, D-080): as opções do Localizar no
// texto do ODT e a leitura dos capítulos, um a um.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/book/book_search.dart';
import 'package:psito_quill/src/document/fodt.dart';

void main() {
  const xml = '<office:document><office:body><office:text>'
      '<text:p>Ação e acao; a Ação da poeira.</text:p>'
      '<text:soft-page-break/>'
      '<text:p>Poeirada não é poeira. Ano 2016, ano 2017.</text:p>'
      '</office:text></office:body></office:document>';

  group('as opções', () {
    test('sem nada: ignora maiúsculas, acha dentro de palavras', () {
      final r = searchOdfText(xml, const SearchQuery('poeira'));
      expect(r.total, 3);
      expect(r.hits.map((h) => h.page), [1, 2, 2]);
    });

    test('maiúsculas: só a forma exata, com acento', () {
      expect(searchOdfText(xml, const SearchQuery('Ação', matchCase: true)).total, 2);
      expect(searchOdfText(xml, const SearchQuery('ação', matchCase: true)).total, 0);
      expect(searchOdfText(xml, const SearchQuery('ação')).total, 2, reason: 'acao sem acento é outra palavra');
    });

    test('palavra inteira: as letras acentuadas contam como letra', () {
      // "Poeirada" não conta; o \b do Dart pararia no "ç" de "Ação".
      expect(searchOdfText(xml, const SearchQuery('poeira', wholeWord: true)).total, 2);
      expect(searchOdfText(xml, const SearchQuery('Aç', wholeWord: true)).total, 0);
    });

    test('expressão regular, e a que não vale', () {
      final r = searchOdfText(xml, const SearchQuery(r'ano \d+', regex: true));
      expect(r.hits.map((h) => h.match), ['Ano 2016', 'ano 2017']);
      final bad = searchOdfText(xml, const SearchQuery('(ano', regex: true));
      expect(bad.badPattern, isTrue);
      expect(bad.total, 0);
      // Casar o vazio não é ocorrência.
      expect(searchOdfText(xml, const SearchQuery('x*', regex: true)).total, 0);
    });

    test('a busca única continua igual', () {
      expect(searchFodtText(xml, ' poeira ').total, 3, reason: 'o texto solto é aparado');
    });
  });

  group('os capítulos', () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('pq-busca-livro'));
    tearDown(() => tmp.deleteSync(recursive: true));

    test('lê o ODT, o ODT plano e conta o que não deu para ler', () {
      final odt = File('test/fixtures/capitulo-curto.odt').copySync('${tmp.path}/001.odt');
      final flat = File('${tmp.path}/copia.fodt')..writeAsStringSync(xml);
      final found = searchSources(
        [
          (id: 'a', path: odt.path, flat: false),
          (id: 'b', path: flat.path, flat: true),
          (id: 'c', path: '${tmp.path}/sumiu.odt', flat: false),
          (id: 'd', path: '${tmp.path}/copia.fodt', flat: false), // não é zip
        ],
        const SearchQuery('poeira'),
        perChapter: 4,
      );
      expect(found.hits.map((h) => h.id), ['a', 'b']);
      expect(found.unread, 2);
      final a = found.hits.first.result;
      expect(a.hits, hasLength(4), reason: 'o limite por capítulo');
      expect(a.total, greaterThan(4), reason: 'mas o total conta todas');
    });

    test('o resultado leva o nome e soma o total', () async {
      final flat = File('${tmp.path}/copia.fodt')..writeAsStringSync(xml);
      final r = await searchChapters(
        [(id: 'b', path: flat.path, flat: true)],
        const SearchQuery('poeira'),
        titles: {'b': 'A poeira'},
      );
      expect(r.chapters.single.title, 'A poeira');
      expect(r.total, 3);
      expect((await searchChapters([(id: 'b', path: flat.path, flat: true)], const SearchQuery('[', regex: true), titles: const {})).badPattern, isTrue);
    });
  });
}
