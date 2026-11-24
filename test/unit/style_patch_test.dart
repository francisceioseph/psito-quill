// As mudanças de estilos pela cópia (D-075): o XML que vai ao LoadStyles.
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/document/style_patch.dart';

const _page = '''
<office:document>
<office:styles>
<style:default-style style:family="paragraph"><style:paragraph-properties/><style:text-properties fo:language="pt"/></style:default-style>
<style:style style:name="Standard" style:family="paragraph"/>
<style:style style:name="Cita_c3_a7_c3_a3_o" style:display-name="Citação" style:family="paragraph"><style:text-properties fo:hyphenate="false"/></style:style>
<style:style style:name="Heading_20_1" style:display-name="Heading 1" style:family="paragraph" style:default-outline-level="1"><style:text-properties fo:hyphenate="false"/></style:style>
</office:styles>
<office:automatic-styles>
<style:page-layout style:name="pm1"><style:header-style><style:header-footer-properties fo:min-height="0.5cm"/></style:header-style><style:footer-style/></style:page-layout>
</office:automatic-styles>
<office:master-styles>
<style:master-page style:name="Standard" style:page-layout-name="pm1"><style:header><text:p text:style-name="Header">Dustland</text:p></style:header></style:master-page>
</office:master-styles>
<office:body><office:text><text:p>Muito texto aqui.</text:p><text:p>Mais.</text:p></office:text></office:body>
</office:document>''';

void main() {
  test('parsePageSetup: cabeçalho, sem rodapé, sem hifenização', () {
    expect(parsePageSetup(_page), const PageSetup(header: true));
  });

  test('stylesOnly tira o texto e guarda o resto', () {
    final s = stylesOnly(_page);
    expect(s, isNot(contains('Muito texto')));
    expect(s, contains('<office:text><text:p/></office:text>'));
    expect(s, contains('<style:master-page'));
  });

  test('tirar o cabeçalho tira o bloco e o espaço dele', () {
    final s = xmlRemoveHeaderFooter(_page, footer: false);
    expect(s, isNot(contains('Dustland')));
    expect(s, contains('<style:header-style/>'));
    expect(s, contains('<style:footer-style/>'));
    expect(parsePageSetup(s).header, isFalse);
  });

  test('a primeira página diferente liga e desliga', () {
    final on = xmlFirstDifferent(_page, true);
    expect(parsePageSetup(on).firstDifferent, isTrue);
    expect(on, contains('<style:header-first>'));
    // Sem rodapé, nada de rodapé da primeira página.
    expect(on, isNot(contains('footer-first')));
    // Ligar de novo não duplica.
    expect('<style:header-first>'.allMatches(xmlFirstDifferent(on, true)).length, 1);
    expect(parsePageSetup(xmlFirstDifferent(on, false)).firstDifferent, isFalse);
  });

  test('as pares diferentes começam iguais às ímpares', () {
    final on = xmlLeftDifferent(_page, true);
    expect(parsePageSetup(on).leftDifferent, isTrue);
    expect(on, contains('<style:header-left><text:p text:style-name="Header">Dustland</text:p></style:header-left>'));
    expect(parsePageSetup(xmlLeftDifferent(on, false)).leftDifferent, isFalse);
  });

  test('a hifenização do documento: o padrão e os estilos, menos os títulos', () {
    final on = xmlDocumentHyphenation(_page, true);
    expect(parsePageSetup(on).hyphenation, isTrue);
    expect(on, contains('style:display-name="Citação" style:family="paragraph"><style:text-properties fo:hyphenate="true"/>'));
    expect(on, contains('style:default-outline-level="1"><style:text-properties fo:hyphenate="false"/>'));
    expect(parsePageSetup(xmlDocumentHyphenation(on, false)).hyphenation, isFalse);
  });

  test('a hifenização entra num estilo padrão sem propriedades de texto', () {
    const bare = '<style:default-style style:family="paragraph"/>';
    final on = xmlDocumentHyphenation(bare, true);
    expect(on, '<style:default-style style:family="paragraph"><style:text-properties fo:hyphenate="true"/></style:default-style>');
  });

  test('encodeStyleName guarda as letras com acento, como o LibreOffice', () {
    expect(encodeStyleName('Text body'), 'Text_20_body');
    expect(encodeStyleName('Citação'), 'Citação');
  });

  test('paragraphStyleXmlName acha pelo nome de exibição', () {
    expect(paragraphStyleXmlName(_page, 'Citação'), 'Cita_c3_a7_c3_a3_o');
    expect(paragraphStyleXmlName(_page, 'Heading 1'), 'Heading_20_1');
    expect(paragraphStyleXmlName(_page, 'Standard'), 'Standard');
    expect(paragraphStyleXmlName(_page, 'Sem ele'), 'Sem_20_ele');
  });

  test('a capitular: um estilo filho, que troca o de antes', () {
    final (xml, name) = addDropCapStyle(_page, base: 'Citação', label: 'Citação', lines: 3);
    expect(name, 'Citação · capitular 3');
    expect(xml, contains('style:parent-style-name="Cita_c3_a7_c3_a3_o"'));
    expect(xml, contains('<style:drop-cap style:lines="3"'));
    final (again, _) = addDropCapStyle(xml, base: 'Citação', label: 'Citação', lines: 3);
    expect('style:lines="3"'.allMatches(again).length, 1);
    expect(dropCapBase(name), 'Citação');
    expect(dropCapBase('Citação'), isNull);
    expect(dropCapBase(null), isNull);
  });
}
