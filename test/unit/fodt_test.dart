// A leitura do ODT plano (D-044), com a cópia de verdade que o LibreOffice
// 24.2 gravou do capítulo de teste (test/fixtures/capitulo-30p.fodt).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/document/fodt.dart';
import 'package:psito_quill/src/document/outline.dart';

void main() {
  final snap = parseFodt(File('test/fixtures/capitulo-30p.fodt').readAsStringSync());

  test('os estilos com nome, pelo nome do LibreOffice', () {
    expect(snap.styles.keys, containsAll(['Standard', 'Heading', 'Heading 1', 'Heading 2', 'Text body']));
  });

  test('o título herda do pai e tem tamanho, peso e fonte', () {
    final h1 = snap.styles['Heading 1']!;
    expect(h1.parent, 'Heading');
    expect(h1.bold, isTrue);
    expect(h1.sizePt, isNotNull);
    expect(h1.sizePt!, greaterThan(snap.styles['Text body']!.sizePt ?? 12));
    expect(h1.fontName, isNotNull);
  });

  test('as fontes declaradas e os títulos com o nível', () {
    expect(snap.fonts, isNotEmpty);
    expect(snap.outline, isNotEmpty);
    expect(snap.outline.map((e) => e.level), everyElement(inInclusiveRange(1, 10)));
    expect(snap.outline.first.text, isNot(contains('<')));
  });

  test('as margens do estilo de página Standard', () {
    final m = snap.pageMargins!;
    expect([m.top, m.bottom, m.left, m.right], [closeTo(1, 0.001), closeTo(1, 0.001), closeTo(2, 0.001), closeTo(1, 0.001)]);
  });

  test('a página de cada título, pelas quebras que o LibreOffice escreve', () {
    final pages = snap.outline.map((e) => e.page).toList();
    expect(pages.first, greaterThanOrEqualTo(1));
    expect(pages.last, greaterThan(20), reason: 'o capítulo tem 30 páginas');
    for (var i = 1; i < pages.length; i++) {
      expect(pages[i], greaterThanOrEqualTo(pages[i - 1]));
    }
    final s = parseFodt('<office:body><text:h text:outline-level="1">A</text:h><text:p>x<text:soft-page-break/>y</text:p>'
        '<text:soft-page-break/><text:h text:outline-level="2">B</text:h></office:body>');
    expect(s.outline.map((e) => (e.text, e.page)), [('A', 1), ('B', 3)]);
    expect(currentHeading(s.outline, 2), 0);
    expect(currentHeading(s.outline, 3), 1);
    expect(currentHeading(const [], 3), isNull);
  });

  test('as palavras e os caracteres vêm do meta:document-statistic', () {
    expect(snap.words, 21069);
    expect(snap.characters, 117539);
    expect(parseFodt('<office:body/>').words, isNull);
  });

  test('o que vem por porcentagem é relativo ao pai', () {
    final s = parseFodt('''
<office:document><office:font-face-decls><style:font-face style:name="Serifa" svg:font-family="&apos;Liberation Serif&apos;"/></office:font-face-decls>
<office:styles>
<style:default-style style:family="paragraph"><style:text-properties fo:font-size="12pt"/></style:default-style>
<style:style style:name="Base" style:family="paragraph"><style:text-properties style:font-name="Serifa" fo:font-size="10pt"/></style:style>
<style:style style:name="Grande" style:family="paragraph" style:parent-style-name="Base"><style:text-properties fo:font-size="150%" fo:font-style="italic" fo:color="#c9211e"/><style:paragraph-properties fo:text-align="center" fo:margin-left="1cm" fo:text-indent="0.5cm"/></style:style>
<style:style style:name="Cita_e7__e3_o" style:family="paragraph"/>
</office:styles>
<office:body><text:h text:outline-level="2">Um <text:span>título</text:span><text:s/>&amp; mais</text:h></office:body></office:document>''');
    final g = s.styles['Grande']!;
    expect(g.sizePt, 15);
    expect(g.italic, isTrue);
    expect(g.fontName, 'Liberation Serif');
    expect(g.color, 0xC9211E);
    expect(g.align, 'center');
    expect(g.indentLeftCm, closeTo(1, 0.001));
    expect(g.firstLineCm, closeTo(0.5, 0.001));
    expect(s.styles['Base']!.sizePt, 10);
    expect(s.styles.keys, contains('Citação'));
    expect(s.outline.single.text, 'Um título & mais');
    expect(s.outline.single.level, 2);
  });

  test('um arquivo estranho não quebra', () {
    expect(parseFodt('nada').styles, isEmpty);
    expect(decodeStyleName('Text_20_body'), 'Text body');
  });
}
