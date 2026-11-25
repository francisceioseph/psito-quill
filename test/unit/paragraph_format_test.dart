// O parágrafo avançado e as propriedades do documento (Fase 4, Etapa 6,
// D-091): os estados do motor, os argumentos das macros e a leitura da cópia.
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/document/fodt.dart';
import 'package:psito_quill/src/document/paragraph_format.dart';
import 'package:psito_quill/src/kit/lok/quill_macros.dart';
import 'package:psito_quill/src/kit/quill_kit.dart';

void main() {
  test('os lados com borda, pelo estado .uno:BorderOuter', () {
    expect(borderSidesFromState('{"top": "true", "bottom": "false", "left": "false", "right": "false"}'), BorderSides.top);
    expect(borderSidesFromState('{"top": "true", "bottom": "true", "left": "true", "right": "true"}'), BorderSides.box);
    expect(borderSidesFromState(null), isNull);
    expect(borderSidesFromState('disabled'), isNull);
    expect(BorderPreset.of(BorderSides.top | BorderSides.bottom), BorderPreset.topBottom);
    expect(BorderPreset.of(BorderSides.right), isNull);
  });

  test('as tabulações da régua, sem as automáticas', () {
    const ruler = RulerInfo(pageWidth: 21000, leftMargin: 2000, textWidth: 17000, tabs: [
      (position: 3000, style: 0),
      (position: 7999, style: 1),
      (position: 9000, style: 3),
      (position: 10005, style: 4),
    ]);
    expect(tabsFromRuler(ruler), const [
      TabStopSpec(positionMm100: 3000),
      TabStopSpec(positionMm100: 7999, align: TabAlign.right),
      TabStopSpec(positionMm100: 9000, align: TabAlign.center),
    ]);
    expect(tabsFromRuler(null), isEmpty);
  });

  test('o argumento das tabulações: em ordem, e "0" volta às do estilo', () {
    expect(
      tabsMacroArg(const [
        TabStopSpec(positionMm100: 8000, align: TabAlign.right, leader: TabLeader.dots),
        TabStopSpec(positionMm100: 3000),
      ]).name,
      '2_3000_0_32_8000_2_46',
    );
    expect(tabsMacroArg(const []).name, '0');
    expect(quillMacro('Tabulacoes', [tabsMacroArg(const [])]), 'macro:///PsitoQuill.Referencias.Tabulacoes("0")');
  });

  test('a janela não muda nada sem mudanças', () {
    expect(const ParagraphChanges().isEmpty, isTrue);
    expect(const ParagraphChanges(clearBackground: true).isEmpty, isFalse);
    expect(const ParagraphChanges(tabs: []).isEmpty, isFalse);
  });

  test('as etiquetas e a macro das propriedades, com os textos em hexadecimal', () {
    expect(parseKeywords(' livro, ficção ,, deserto '), ['livro', 'ficção', 'deserto']);
    final m = propertiesMacro(const DocProperties(title: 'Dustland "1"', keywords: ['a', 'b']));
    expect(m, startsWith('macro:///PsitoQuill.Referencias.Propriedades("${basicHex('Dustland "1"')}","",""'));
    expect(m, contains('"${basicHex('a\nb')}"'));
    expect(m, isNot(contains('Dustland')));
  });

  test('a cópia: as propriedades, as contagens e o intervalo do estilo', () {
    const xml = '<office:document><office:meta><dc:title>O rio &amp; o mar</dc:title><dc:subject>Assunto</dc:subject>'
        '<meta:initial-creator>Fulana</meta:initial-creator><dc:creator>Outra</dc:creator>'
        '<dc:description>Um comentário</dc:description><meta:keyword>um</meta:keyword><meta:keyword>dois</meta:keyword>'
        '<meta:document-statistic meta:paragraph-count="2" meta:word-count="2" meta:character-count="7" '
        'meta:non-whitespace-character-count="6"/></office:meta>'
        '<office:styles>'
        '<style:style style:name="Standard" style:family="paragraph"><style:paragraph-properties style:contextual-spacing="true"/></style:style>'
        '<style:style style:name="Text_20_body" style:display-name="Text body" style:family="paragraph" style:parent-style-name="Standard"/>'
        '<style:style style:name="Heading" style:family="paragraph" style:parent-style-name="Standard">'
        '<style:paragraph-properties style:contextual-spacing="false"/></style:style>'
        '</office:styles><office:body><office:text/></office:body></office:document>';
    final snap = parseFodt(xml);
    expect(
      snap.properties,
      const DocProperties(title: 'O rio & o mar', subject: 'Assunto', author: 'Fulana', keywords: ['um', 'dois'], comment: 'Um comentário'),
    );
    expect(snap.paragraphs, 2);
    expect(snap.charactersNoSpaces, 6);
    expect(snap.characters, 7);
    expect(snap.styles['Text body']?.noSpaceSameStyle, isTrue);
    expect(snap.styles['Heading']?.noSpaceSameStyle, isFalse);
    expect(parseFodt('<office:document/>').properties, DocProperties.empty);
  });

  test('o módulo Basic tem as macros do parágrafo', () {
    final xml = quillMacroModuleXml();
    for (final sub in ['Sub Intervalo', 'Sub Bordas', 'Sub Tabulacoes', 'Sub Propriedades', 'Function Trecho']) {
      expect(xml, contains(sub));
    }
    // As bordas pelos nomes sem "Para" (os com ele não fazem nada na 24.2).
    expect(xml, contains('c.TopBorder = b'));
    expect(xml, isNot(contains('ParaTopBorder')));
  });
}
