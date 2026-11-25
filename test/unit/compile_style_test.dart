// Os modelos de compilação (Fase 4, Etapa 2, D-087): os estilos de saída no
// livro juntado, o `compilar.json` e os modelos prontos.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/book/compile.dart';
import 'package:psito_quill/src/book/compile_models.dart';
import 'package:psito_quill/src/book/compile_style.dart';
import 'package:psito_quill/src/book/fodt_join.dart';
import 'package:psito_quill/src/book/fodt_split.dart';

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('quill-modelos-'));
  tearDown(() => tmp.deleteSync(recursive: true));

  List<String> chapters() {
    final m = FodtManuscript.parse(File('test/fixtures/livro-teste.fodt').readAsStringSync());
    final drafts = m.chapters(1);
    return [
      for (var i = 0; i < drafts.length; i++)
        (File('${tmp.path}/c$i.fodt')..writeAsStringSync(m.chapterXml(drafts[i]))).path,
    ];
  }

  String join(CompileSettings s) {
    final out = '${tmp.path}/livro.fodt';
    joinFodt([const JoinPart('Parte'), for (final f in chapters()) JoinChapter(f, 'Capítulo')], s.join, out);
    return File(out).readAsStringSync();
  }

  String styleOf(String xml, String name) =>
      RegExp('<style:style style:name="$name"[\\s\\S]*?</style:style>').firstMatch(xml)![0]!;

  group('a página', () {
    const layout = '<style:page-layout style:name="pm1"><style:page-layout-properties fo:page-width="21.001cm" '
        'fo:page-height="29.7cm" fo:margin-top="2cm" fo:margin-left="2cm"/></style:page-layout>';

    test('o 6×9 espelhado, com o espaço do cabeçalho', () {
      final out = styleLayout(layout, const OutputStyle(page: PageChoice.sixByNine, headers: HeaderMode.book));
      expect(out, contains('fo:page-width="15.24cm"'));
      expect(out, contains('fo:page-height="22.86cm"'));
      expect(out, contains('fo:margin-left="2.20cm"'));
      expect(out, contains('fo:margin-right="1.60cm"'));
      expect(out, contains('style:page-usage="mirrored"'));
      expect(out, contains('<style:header-style><style:header-footer-properties'));
      expect('fo:page-width='.allMatches(out).length, 1);
    });

    test('manter não toca; sem cabeçalho, o espaço sai', () {
      expect(styleLayout(layout, const OutputStyle()), layout);
      final none = styleLayout('${layout.replaceFirst('</style:page-layout>', '')}<style:header-style><style:header-footer-properties fo:min-height="1cm"/></style:header-style></style:page-layout>',
          const OutputStyle(headers: HeaderMode.none));
      expect(none, contains('<style:header-style/>'));
    });

    test('a abertura: só nas ímpares, sem cabeçalho', () {
      final out = openingLayoutOf(styleLayout(layout, const OutputStyle(headers: HeaderMode.book)));
      expect(out, contains('style:name="$openingLayout"'));
      expect(out, contains('style:page-usage="right"'));
      expect(out, contains('<style:header-style/>'));
    });
  });

  group('os cabeçalhos', () {
    const masters = '<office:master-styles><style:master-page style:name="Standard" style:page-layout-name="pm1">'
        '<style:header><text:p>DUSTLAND · 2025</text:p></style:header><style:footer><text:p>pé</text:p></style:footer>'
        '</style:master-page></office:master-styles>';

    test('o manuscrito troca o cabeçalho do capítulo', () {
      final out = styleMasters(masters, const OutputStyle(headers: HeaderMode.manuscript), title: 'Dustland', author: 'Francisco Souza');
      expect(out, isNot(contains('DUSTLAND · 2025')));
      expect(out, contains('Souza / DUSTLAND / <text:page-number'));
      expect(out, contains('<style:footer>'));
    });

    test('o livro alterna o título do livro e o do capítulo', () {
      final out = styleMasters(masters, const OutputStyle(headers: HeaderMode.book), title: 'Dustland', author: '');
      expect(out, contains('<style:header><text:p text:style-name="QuillCabecalhoImpar"><text:chapter'));
      expect(out, contains('<style:header-left><text:p text:style-name="QuillCabecalhoPar">'));
      expect(out, contains('Dustland</text:p></style:header-left>'));
    });

    test('a abertura na ímpar: o rodapé do corpo, sem cabeçalho, e depois o corpo', () {
      final out = styleMasters(masters, const OutputStyle(rightPage: true), title: '', author: '');
      final opening = RegExp('<style:master-page style:name="$openingMaster"[\\s\\S]*?</style:master-page>').firstMatch(out)![0]!;
      expect(opening, contains('style:next-style-name="Standard"'));
      expect(opening, contains('style:page-layout-name="$openingLayout"'));
      expect(opening, contains('<style:footer>'));
      expect(opening, isNot(contains('<style:header')));
    });

    test('o sobrenome', () {
      expect(surnameOf('  Francisco  de Souza '), 'Souza');
      expect(surnameOf(''), '');
    });
  });

  group('o corpo', () {
    test('o padrão ganha a fonte, o espaço e o recuo; os automáticos do corpo perdem os seus; os títulos não', () {
      const s = OutputStyle(font: 'Times New Roman', fontSize: 12, spacing: LineSpacing.double, indent: IndentChoice.on);
      final std = styleNamed('<style:style style:name="Standard" style:family="paragraph"><style:text-properties '
          'style:font-name="Liberation Serif" fo:font-family="\'Liberation Serif\'"/></style:style>', s);
      expect(std, contains('style:font-name="Times New Roman"'));
      expect(std, isNot(contains('fo:font-family')));
      expect(std, contains('fo:line-height="200%"'));
      expect(std, contains('fo:text-indent="1.27cm"'));
      expect(std.indexOf('paragraph-properties'), lessThan(std.indexOf('text-properties')));

      final auto = styleAuto('<style:style style:name="P3" style:family="paragraph" style:parent-style-name="Standard">'
          '<style:paragraph-properties fo:line-height="115%" fo:text-indent="0.5cm" fo:text-align="justify"/>'
          '<style:text-properties fo:font-size="11pt" fo:font-style="italic"/></style:style>', s);
      expect(auto, isNot(contains('fo:line-height')));
      expect(auto, isNot(contains('fo:text-indent')));
      expect(auto, isNot(contains('fo:font-size')));
      expect(auto, contains('fo:text-align="justify"'));
      expect(auto, contains('fo:font-style="italic"'));

      final heading = styleAuto('<style:style style:name="P9" style:family="paragraph" style:parent-style-name="Heading_20_1">'
          '<style:text-properties fo:font-size="18pt"/></style:style>', s);
      expect(heading, contains('fo:font-size="18pt"'));
      expect(heading, contains('fo:text-indent="0cm"'));
    });

    test('sem nada do corpo, os estilos ficam como estão', () {
      const el = '<style:style style:name="P3" style:family="paragraph"><style:paragraph-properties fo:line-height="115%"/></style:style>';
      expect(styleAuto(el, const OutputStyle(page: PageChoice.a4)), el);
      expect(styleNamed(el, const OutputStyle(headers: HeaderMode.none)), el);
    });

    test('o tamanho da imagem: PNG e JPEG', () {
      final png = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 13, 0x49, 0x48, 0x44, 0x52, 0, 0, 2, 88, 0, 0, 3, 132, 8, 2];
      expect(imageSize(png), (600, 900));
      final jpeg = [0xFF, 0xD8, 0xFF, 0xE0, 0, 4, 0, 0, 0xFF, 0xC0, 0, 17, 8, 0, 200, 1, 44, 3, 0, 0];
      expect(imageSize(jpeg), (300, 200));
      expect(imageSize([1, 2, 3]), isNull);
    });
  });

  group('no livro juntado', () {
    test('o Manuscrito: a fonte declarada, o cabeçalho, o "#" e sem sumário', () {
      final xml = join(BuiltInModel.manuscript.settings.copyWith(title: 'Dustland', author: 'Francisco Souza'));
      expect(xml, contains('<style:font-face style:name="Times New Roman"'));
      expect(xml, contains('Souza / DUSTLAND / '));
      expect(xml, contains('style:name="QuillCabecalhoManuscrito"'));
      expect(xml, isNot(contains('<text:table-of-content ')));
      expect(styleOf(xml, 'Standard'), contains('fo:line-height="200%"'));
    });

    test('o 6×9: as partes e os capítulos começam no estilo de página da abertura', () {
      final xml = join(BuiltInModel.sixByNine.settings.copyWith(title: 'Dustland'));
      expect(styleOf(xml, 'QuillParteQuebra'), contains('style:master-page-name="$openingMaster"'));
      expect(styleOf(xml, 'QuillParteQuebra'), isNot(contains('fo:break-before')));
      expect(xml, contains('<style:master-page style:name="$openingMaster"'));
      expect(xml, contains('<style:page-layout style:name="$openingLayout"'));
      // Cada capítulo (menos o primeiro, que vem depois da parte) abre na ímpar.
      final breaks = RegExp(r'<style:style style:name="QuillQuebra\d+"[^>]*>').allMatches(xml).map((m) => m[0]!).toList();
      expect(breaks, isNotEmpty);
      expect(breaks.every((b) => b.contains('style:master-page-name="$openingMaster"')), isTrue);
      expect(BuiltInModel.sixByNine.settings.filterOptions, contains('"IsSkipEmptyPages"'));
    });

    test('o E-book: a capa embutida e o sumário sem páginas', () {
      final cover = File('${tmp.path}/capa.png')
        ..writeAsBytesSync([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 13, 0x49, 0x48, 0x44, 0x52, 0, 0, 0, 60, 0, 0, 0, 90, 8, 2]);
      final xml = join(BuiltInModel.ebook.settings.copyWith(title: 'Dustland', cover: cover.path));
      final body = xml.substring(xml.indexOf('<office:text'));
      expect(body.indexOf('<draw:frame draw:name="QuillCapa"'), lessThan(body.indexOf('QuillRostoTitulo')));
      expect(body, contains('svg:width="12.00cm" svg:height="18.00cm"'));
      expect(body, contains('<office:binary-data>${base64.encode(cover.readAsBytesSync())}</office:binary-data>'));
      expect(body, isNot(contains('<text:index-entry-page-number/>')));
    });
  });

  group('o compilar.json', () {
    test('grava e lê os modelos, o último e as escolhas', () {
      final store = CompileStore()
        ..save('Revista', BuiltInModel.manuscript.settings.copyWith(tocTitle: 'Índice'))
        ..choices = const CompileSettings(excluded: {'b', 'a'}, title: 'Dustland', cover: '/capa.png',
            style: OutputStyle(page: PageChoice.a5, font: 'Courier New', fontSize: 11));
      store.write(tmp.path);
      final j = jsonDecode(File('${tmp.path}/$compileFileName').readAsStringSync()) as Map;
      expect(j['versao'], 1);
      expect(j['ultimo'], 'Revista');
      // O modelo não leva o que é do livro.
      expect((j['modelos'] as List).single, isNot(contains('deFora')));
      expect((j['modelos'] as List).single, isNot(contains('titulo')));

      final back = CompileStore.read(tmp.path);
      expect(back.last, 'Revista');
      expect(back.named('Revista')!.settings.sameModel(store.named('Revista')!.settings), isTrue);
      expect(back.named('Revista')!.settings.tocTitle, 'Índice');
      expect(back.choices!.excluded, {'a', 'b'});
      expect(back.choices!.cover, '/capa.png');
      expect(back.choices!.style, const OutputStyle(page: PageChoice.a5, font: 'Courier New', fontSize: 11));
      expect(back.settingsOf(BuiltInModel.ebook.id)!.format, CompileFormat.epub);
    });

    test('renomear e apagar; um arquivo estragado é um livro sem modelos', () {
      final store = CompileStore()..save('Um', const CompileSettings());
      store.rename('Um', 'Dois');
      expect(store.last, 'Dois');
      expect(store.named('Um'), isNull);
      store.delete('Dois');
      expect(store.models, isEmpty);
      expect(store.last, isNull);

      File('${tmp.path}/$compileFileName').writeAsStringSync('{não é json');
      expect(CompileStore.read(tmp.path).models, isEmpty);
      expect(CompileStore.read('${tmp.path}/nada').models, isEmpty);
    });

    test('aplicar um modelo mantém o que é do livro', () {
      const mine = CompileSettings(excluded: {'x'}, title: 'Dustland', author: 'Fulano', cover: '/c.png');
      final s = mine.withModel(BuiltInModel.sixByNine.settings);
      expect(s.excluded, {'x'});
      expect(s.title, 'Dustland');
      expect(s.cover, '/c.png');
      expect(s.style.page, PageChoice.sixByNine);
      expect(s.sameModel(BuiltInModel.sixByNine.settings), isTrue);
      expect(s.sameModel(BuiltInModel.ebook.settings), isFalse);
    });
  });
}
