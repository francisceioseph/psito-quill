// O compilar (Fase 4, Etapa 1, D-086): juntar os capítulos num FODT só.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/book/fodt_join.dart';
import 'package:psito_quill/src/book/fodt_split.dart';

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('quill-compilar-'));
  tearDown(() => tmp.deleteSync(recursive: true));

  /// Os capítulos do livro de teste, cortados como o importador corta (os
  /// mesmos nomes de automáticos em todos, como na vida real).
  List<String> chapters() {
    final m = FodtManuscript.parse(File('test/fixtures/livro-teste.fodt').readAsStringSync());
    final drafts = m.chapters(1);
    return [
      for (var i = 0; i < drafts.length; i++)
        (File('${tmp.path}/c$i.fodt')..writeAsStringSync(m.chapterXml(drafts[i]))).path,
    ];
  }

  Set<String> autoNames(String xml) {
    final autos = xml.substring(xml.indexOf('<office:automatic-styles>'), xml.indexOf('</office:automatic-styles>'));
    return {for (final m in RegExp(r'<style:[a-z-]+ style:name="([^"]*)"').allMatches(autos)) m[1]!};
  }

  String bodyOf(String xml) => xml.substring(xml.indexOf('<office:text'), xml.indexOf('</office:text>'));

  test('junta os capítulos com a folha de rosto, o sumário e a parte', () {
    final files = chapters();
    expect(files.length, greaterThan(2));
    final out = '${tmp.path}/livro.fodt';
    joinFodt([
      const JoinPart('Primeira parte'),
      for (final f in files) JoinChapter(f, 'Capítulo'),
    ], const JoinOptions(title: 'Dustland', subtitle: 'Um teste', author: 'Fulano', scenes: SceneBreakMode.stars), out);
    final xml = File(out).readAsStringSync();
    if (Platform.environment['QUILL_JOIN_OUT'] case final copy?) File(out).copySync(copy);

    expect(xml, startsWith('<?xml'));
    expect(xml.trimRight(), endsWith('</office:document>'));
    expect(File('$out.corpo').existsSync(), isFalse);
    expect(xml, contains('<dc:title>Dustland</dc:title>'));
    expect(xml, contains('<dc:creator>Fulano</dc:creator>'));
    final body = bodyOf(xml);
    // A ordem: o rosto, o sumário, a parte, os capítulos.
    final rosto = body.indexOf('QuillRostoTitulo">Dustland<');
    final toc = body.indexOf('<text:table-of-content ');
    final parte = body.indexOf('>Primeira parte</text:h>');
    final cap = body.indexOf('A poeira');
    expect([rosto, toc, parte, cap].every((i) => i >= 0), isTrue);
    expect(rosto < toc && toc < parte && parte < cap, isTrue);
    expect(body, contains('QuillParteQuebra'));
    // Os títulos de nível 2 dos capítulos entram no sumário.
    expect(body, contains('text:outline-level="2">'));

    // Cada nome de automático aparece uma vez, e o corpo só usa os que existem.
    final names = autoNames(xml);
    final declared = RegExp(r'<style:[a-z-]+ style:name="').allMatches(
        xml.substring(xml.indexOf('<office:automatic-styles>'), xml.indexOf('</office:automatic-styles>')));
    expect(declared.length, names.length, reason: 'automáticos repetidos');
    expect(names.any((n) => n.startsWith('q1_')), isTrue);
    final named = {
      for (final m in RegExp(r' style:name="([^"]*)"')
          .allMatches(xml.substring(xml.indexOf('<office:styles>'), xml.indexOf('</office:styles>'))))
        m[1]!,
    };
    const pool = {'Title', 'Subtitle', 'Standard', 'Heading_20_1', 'Contents_20_Heading', 'Contents_20_1', 'Contents_20_2', 'Index_20_Link'};
    for (final m in RegExp(r'\stext:style-name="([^"]*)"').allMatches(body)) {
      final n = m[1]!;
      expect(names.contains(n) || named.contains(n) || pool.contains(n), isTrue, reason: 'estilo sem declaração: $n');
    }
    // Os ids das notas não colidem.
    final ids = [for (final m in RegExp(r'<text:note text:id="([^"]*)"').allMatches(body)) m[1]!];
    expect(ids.toSet().length, ids.length);
  });

  test('o capítulo sem título ganha o título, e as quebras saem quando pedido', () {
    final empty = File('${tmp.path}/vazio.fodt')
      ..writeAsStringSync(File('test/fixtures/livro-teste.fodt')
          .readAsStringSync()
          .replaceFirstMapped(RegExp(r'(<office:text\b[^>]*>)[\s\S]*(</office:text>)'),
              (m) => '${m[1]}<text:p text:style-name="Standard">Só texto.</text:p>${m[2]}'));
    final out = '${tmp.path}/livro.fodt';
    joinFodt([JoinChapter(empty.path, 'O <primeiro>'), JoinChapter(empty.path, 'O segundo')],
        const JoinOptions(titlePage: false, toc: false), out);
    final body = bodyOf(File(out).readAsStringSync());
    expect(body, contains('<text:h text:style-name="QuillCapitulo" text:outline-level="1">O &lt;primeiro&gt;</text:h>'));
    expect(body, contains('<text:h text:style-name="QuillCapituloQuebra" text:outline-level="1">O segundo</text:h>'));

    joinFodt([JoinChapter(empty.path, 'Um'), JoinChapter(empty.path, 'Dois')],
        const JoinOptions(titlePage: false, toc: false, pageBreaks: false, chapterTitles: false), out);
    final plain = bodyOf(File(out).readAsStringSync());
    expect(plain, isNot(contains('Quebra')));
    expect(plain, isNot(contains('<text:h')));
  });

  test('a quebra no primeiro parágrafo copia o automático dele', () {
    final xml = File('test/fixtures/livro-teste.fodt').readAsStringSync();
    final file = File('${tmp.path}/c.fodt')..writeAsStringSync(xml);
    final out = '${tmp.path}/livro.fodt';
    joinFodt([JoinChapter(file.path, 'A'), JoinChapter(file.path, 'B')],
        const JoinOptions(titlePage: false, toc: false, chapterTitles: false), out);
    final joined = File(out).readAsStringSync();
    // O segundo começa numa página nova, por um automático novo com a quebra.
    expect(RegExp(r'<style:style style:name="QuillQuebra1"[^>]*>[\s\S]*?fo:break-before="page"').hasMatch(joined), isTrue);
    expect(bodyOf(joined), contains('text:style-name="QuillQuebra1"'));
  });

  test('o separador de cena vira o texto escolhido', () {
    final xml = File('test/fixtures/livro-teste.fodt').readAsStringSync().replaceFirstMapped(
        RegExp(r'(<office:text\b[^>]*>)'),
        (m) => '${m[1]}<text:h text:style-name="P3" text:outline-level="1">T</text:h><text:p text:style-name="Cena">⁂</text:p><text:p text:style-name="Cena"/>');
    final file = File('${tmp.path}/c.fodt')..writeAsStringSync(xml);
    final out = '${tmp.path}/livro.fodt';
    joinFodt([JoinChapter(file.path, 'T')], const JoinOptions(titlePage: false, toc: false, scenes: SceneBreakMode.hash), out);
    final body = bodyOf(File(out).readAsStringSync());
    expect(body, contains('<text:p text:style-name="Cena">#</text:p><text:p text:style-name="Cena">#</text:p>'));
    expect(body, isNot(contains('⁂')));
  });

  test('sem nenhum capítulo, FormatException', () {
    expect(() => joinFodt(const [JoinPart('P')], const JoinOptions(), '${tmp.path}/x.fodt'), throwsFormatException);
  });
}
