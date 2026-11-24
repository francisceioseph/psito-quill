// As cenas (Fase 3, Etapa 5, D-079): o separador, a leitura das cenas na
// cópia e no content.xml, o estilo, o importador que converte e o corte do
// capítulo no cursor.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/book/book.dart';
import 'package:psito_quill/src/book/chapter_cut.dart';
import 'package:psito_quill/src/book/fodt_split.dart';
import 'package:psito_quill/src/document/fodt.dart';
import 'package:psito_quill/src/document/style_patch.dart';

/// Um ODT plano mínimo, com [styles] em `office:styles`, [auto] nos
/// automáticos e [body] no texto.
String fodt(String body, {String styles = '', String auto = ''}) => '<?xml version="1.0" encoding="UTF-8"?>'
    '<office:document><office:styles><style:style style:name="Standard" style:family="paragraph"/>$styles'
    '</office:styles><office:automatic-styles>$auto</office:automatic-styles>'
    '<office:body><office:text>$body</office:text></office:body></office:document>';

const cena = '<style:style style:name="Cena" style:display-name="Cena" style:family="paragraph" '
    'style:parent-style-name="Standard"/>';

void main() {
  group('o separador', () {
    test('asteriscos, cerquilhas e o asterismo, com espaços', () {
      for (final t in ['* * *', '***', '#', ' # # ', '⁂', '*']) {
        expect(isSceneSeparatorText(t), isTrue, reason: t);
      }
      for (final t in ['', '   ', '* a *', '—', '***!', 'Cena 1', '* * * * * * * * * *']) {
        expect(isSceneSeparatorText(t), isFalse, reason: t);
      }
    });
  });

  group('as cenas na cópia', () {
    test('sem nenhum separador no estilo, nenhuma cena', () {
      expect(odfScenes(fodt('<text:p>Um.</text:p><text:p>* * *</text:p><text:p>Dois.</text:p>')), isEmpty);
    });

    test('a primeira antes do separador, e uma por separador, com o começo do texto', () {
      final xml = fodt(
        '<text:h text:outline-level="1">Capítulo</text:h><text:p>Era uma vez.</text:p>'
        '<text:p text:style-name="Cena">* * *</text:p><text:p/><text:p>A segunda <text:span>cena</text:span>.</text:p>'
        '<text:p text:style-name="P1">* * *</text:p><text:p>A terceira.</text:p>',
        styles: cena,
        // Um automático filho do Cena (a formatação direta) também é separador.
        auto: '<style:style style:name="P1" style:family="paragraph" style:parent-style-name="Cena"/>',
      );
      final scenes = odfScenes(xml);
      expect([for (final s in scenes) s.label], ['Era uma vez.', 'A segunda cena.', 'A terceira.']);
      expect(scenes[0].searchKey, isNull);
      expect(scenes[1].searchKey, '* * *');
      expect(scenes[1].occurrence, 0);
      // O segundo "* * *": o primeiro vem antes dele.
      expect(scenes[2].occurrence, 1);
    });

    test('no content.xml de um ODT, o "Cena" não vem declarado (está no styles.xml) e conta assim mesmo', () {
      final scenes = odfScenes(fodt('<text:p>Um.</text:p><text:p text:style-name="Cena">* * *</text:p><text:p>Dois.</text:p>'));
      expect([for (final s in scenes) s.label], ['Um.', 'Dois.']);
    });

    test('a ocorrência conta o texto dos parágrafos antes, e um separador vazio não conta', () {
      final xml = fodt(
        '<text:p>Ele escreveu # no muro.</text:p><text:p text:style-name="Cena"/>'
        '<text:p text:style-name="Cena">#</text:p><text:p>Depois.</text:p>',
        styles: cena,
      );
      final scenes = odfScenes(xml);
      expect(scenes, hasLength(2));
      expect(scenes[1].searchKey, '#');
      expect(scenes[1].occurrence, 1);
    });

    test('um capítulo que começa no separador não tem a cena vazia antes', () {
      final scenes = odfScenes(fodt('<text:p text:style-name="Cena">***</text:p><text:p>Só.</text:p>', styles: cena));
      expect(scenes, hasLength(1));
      expect(scenes.single.label, 'Só.');
    });

    test('o rótulo é cortado', () {
      final long = List.filled(40, 'palavra').join(' ');
      final scenes = odfScenes(fodt('<text:p text:style-name="Cena">*</text:p><text:p>$long</text:p>', styles: cena));
      expect(scenes.single.label.length, lessThanOrEqualTo(sceneLabelLength + 1));
      expect(scenes.single.label, endsWith('…'));
    });

    test('a cópia do capítulo de teste tem separadores soltos, ainda não cenas', () {
      final xml = File('test/fixtures/capitulo-30p.fodt').readAsStringSync();
      expect(parseFodt(xml).scenes, isEmpty);
      expect(odfLooseSeparators(xml), greaterThan(0));
    });
  });

  group('o estilo Cena', () {
    test('entra uma vez em office:styles, centrado e preso ao seguinte', () {
      final once = addSceneStyle(fodt('<text:p/>'));
      expect(addSceneStyle(once), once);
      expect(RegExp('style:name="Cena"').allMatches(once), hasLength(1));
      expect(once, contains('fo:text-align="center"'));
      expect(once, contains('fo:keep-with-next="always"'));
      expect(parseFodt(once).styles.keys, contains(sceneStyleName));
    });
  });

  group('o importador converte', () {
    test('os "* * *" do manuscrito viram o estilo Cena, e cada capítulo tem as cenas', () {
      final xml = File('test/fixtures/capitulo-30p.fodt').readAsStringSync();
      final loose = odfLooseSeparators(xml);
      final m = FodtManuscript.parse(xml);
      expect(m.sceneSeparators, loose);
      final drafts = m.chapters(m.suggestedLevel);
      var scenes = 0;
      for (final d in drafts) {
        final chapter = m.chapterXml(d);
        expect(odfLooseSeparators(chapter), 0);
        scenes += odfScenes(chapter).where((s) => s.searchKey != null).length;
        expect(parseFodt(chapter).styles.keys, contains(sceneStyleName));
      }
      expect(scenes, loose);
    });

    test('sem separador, o cabeçalho fica como estava', () {
      final xml = fodt('<text:h text:outline-level="1">Um</text:h><text:p>a</text:p>'
          '<text:h text:outline-level="1">Dois</text:h><text:p>b</text:p>');
      final m = FodtManuscript.parse(xml);
      expect(m.sceneSeparators, 0);
      expect(m.chapterXml(m.chapters(1).first), isNot(contains('style:name="Cena"')));
    });
  });

  group('as cenas no livro.json', () {
    test('vão e voltam, e um capítulo sem cenas não grava a chave', () {
      final n = BookNode(id: 'a', kind: BookNodeKind.chapter, title: 'A', scenes: ['Era', 'Depois']);
      expect(BookNode.fromJson(n.toJson()).scenes, ['Era', 'Depois']);
      expect(BookNode(id: 'b', kind: BookNodeKind.chapter, title: 'B').toJson().containsKey('cenas'), isFalse);
    });
  });

  group('o corte no cursor', () {
    const mark = '<text:bookmark text:name="corte"/>';

    test('no meio de um parágrafo: os elementos em volta são reabertos, o texto antes sai', () {
      final xml = fodt('<text:sequence-decls><text:sequence-decl text:name="Figura"/></text:sequence-decls>'
          '<text:h text:outline-level="1">Um</text:h>'
          '<text:p text:style-name="P1">Antes <text:span text:style-name="T1">ne${mark}grito</text:span> e o resto.</text:p>'
          '<text:p>Fim.</text:p>');
      final c = cutAtBookmark(xml, 'corte')!;
      final body = c.xml.substring(c.xml.indexOf('<office:text>'));
      expect(body, startsWith('<office:text><text:sequence-decls>'));
      expect(body, contains('<text:p text:style-name="P1"><text:span text:style-name="T1">grito</text:span> e o resto.</text:p>'));
      expect(body, isNot(contains('Antes')));
      expect(body, isNot(contains('Um')));
      expect(body, isNot(contains('corte')));
      expect(c.atParagraphStart, isFalse);
      expect(c.wordsBefore, 3);
      expect(c.wordsAfter, 5);
      expect(c.title, isNull);
    });

    test('no começo de um parágrafo depois de outro: o vazio que sobra junta', () {
      final c = cutAtBookmark(fodt('<text:p>Um.</text:p><text:p>${mark}Dois.</text:p>'), 'corte')!;
      expect(c.atParagraphStart, isTrue);
      expect(c.previousIsText, isTrue);
    });

    test('no começo de um título: ele dá o nome do capítulo novo', () {
      final c = cutAtBookmark(
        fodt('<text:p>Um.</text:p><text:h text:outline-level="1">${mark}O poço</text:h><text:p>Água.</text:p>'),
        'corte',
      )!;
      expect(c.title, 'O poço');
      expect(c.atParagraphStart, isTrue);
    });

    test('depois de uma tabela, o parágrafo vazio não junta', () {
      final c = cutAtBookmark(
        fodt('<table:table><table:table-row><table:table-cell><text:p>x</text:p></table:table-cell></table:table-row>'
            '</table:table><text:p>${mark}Dois.</text:p>'),
        'corte',
      )!;
      expect(c.atParagraphStart, isTrue);
      expect(c.previousIsText, isFalse);
    });

    test('uma nota antes do marcador é conteúdo, e sai com o texto', () {
      final c = cutAtBookmark(
        fodt('<text:p>Um<text:note text:id="n1"><text:note-body><text:p>A nota.</text:p></text:note-body></text:note>'
            '${mark}dois.</text:p>'),
        'corte',
      )!;
      expect(c.atParagraphStart, isFalse);
      expect(c.xml, isNot(contains('A nota.')));
      expect(c.xml, contains('<text:p>dois.</text:p>'));
    });

    test('numa lista: a lista e o item são reabertos, os itens antes saem', () {
      final c = cutAtBookmark(
        fodt('<text:list text:style-name="L1"><text:list-item><text:p>um</text:p></text:list-item>'
            '<text:list-item><text:p>${mark}dois</text:p></text:list-item></text:list><text:p>Fim.</text:p>'),
        'corte',
      )!;
      final body = c.xml.substring(c.xml.indexOf('<office:text>'));
      expect(body, startsWith('<office:text><text:list text:style-name="L1"><text:list-item><text:p>dois</text:p>'));
      expect(body, isNot(contains('>um<')));
      // Num bloco de dentro, não junta: o parágrafo não é do primeiro nível.
      expect(c.atParagraphStart, isFalse);
    });

    test('com o texto selecionado (um intervalo), corta no começo, e o fim do intervalo sai', () {
      final c = cutAtBookmark(
        fodt('<text:p>Um.</text:p><text:p><text:bookmark-start text:name="corte"/>Do<text:bookmark-end text:name="corte"/>is.</text:p>'),
        'corte',
      )!;
      expect(c.atParagraphStart, isTrue);
      expect(c.xml, contains('<text:p>Dois.</text:p>'));
      expect(c.xml, isNot(contains('corte')));
    });

    test('no separador de uma cena: o capítulo novo começa na cena, sem o separador', () {
      final c = cutAtBookmark(
        fodt('<text:p>Um.</text:p><text:p text:style-name="Cena">$mark* * *</text:p><text:p>A cena.</text:p>', styles: cena),
        'corte',
      )!;
      final body = c.xml.substring(c.xml.indexOf('<office:text>'));
      expect(body, startsWith('<office:text><text:p>A cena.</text:p>'));
      expect(c.wordsAfter, 2);
    });

    test('sem o marcador, nada', () {
      expect(cutAtBookmark(fodt('<text:p>Um.</text:p>'), 'corte'), isNull);
    });

    test('o capítulo de teste cortado no meio continua um ODT plano que se lê', () {
      final xml = File('test/fixtures/capitulo-30p.fodt').readAsStringSync();
      final at = xml.indexOf('<text:p', xml.length ~/ 2);
      final open = xml.indexOf('>', at) + 1;
      final marked = '${xml.substring(0, open)}$mark${xml.substring(open)}';
      final c = cutAtBookmark(marked, 'corte')!;
      expect(c.atParagraphStart, isTrue);
      expect(c.wordsBefore, greaterThan(1000));
      expect(c.wordsAfter, greaterThan(1000));
      expect(parseFodt(c.xml).styles.keys, contains('Heading 2'));
      expect(c.wordsBefore + c.wordsAfter, odfWordCount(xml.substring(xml.indexOf('<office:text'))));
    });
  });
}
