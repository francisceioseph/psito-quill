// Os textos que o LibreOffice 24.2 manda nos recursos da Fase 2 (copiados
// das respostas reais, medidas com o lok_script).
import 'dart:convert';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/document/search.dart';
import 'package:psito_quill/src/kit/lok/lo_styles.dart';
import 'package:psito_quill/src/kit/lok/lok_payloads.dart';
import 'package:psito_quill/src/kit/lok/lok_quill_kit.dart';
import 'package:psito_quill/src/kit/quill_kit.dart';

void main() {
  test('resultado da busca: uma ocorrência e todas', () {
    final one = parseSearchResult(
        '{"searchString": "texto", "highlightAll": "false", "searchResultSelection": [{"part": "0", "rectangles": "4883, 1418, 480, 275"}]}')!;
    expect(one.count, 1);
    expect(one.all, isFalse);
    expect(one.matches.single.single, const Rect.fromLTWH(4883, 1418, 480, 275));
    final all = parseSearchResult('{"highlightAll": "true", "searchResultSelection": ['
        '{"part": "0", "rectangles": "1838, 1418, 480, 275"}, {"part": "0", "rectangles": "4883, 1418, 480, 275; 1, 2, 3, 4"}]}')!;
    expect(all.count, 2);
    expect(all.all, isTrue);
    expect(all.matches[1], hasLength(2));
    expect(parseSearchResult('lixo'), isNull);
  });

  test('menu de contexto: sem o ~, com separador e submenu', () {
    final items = parseContextMenu(jsonEncode({
      'menu': [
        {'text': 'erro', 'type': 'command', 'command': '.uno:SpellCheckApplySuggestion?ApplyRule:string=Spelling_erro', 'enabled': 'true'},
        {'type': 'separator'},
        {'text': '~Ignorar', 'type': 'command', 'command': '.uno:SpellCheckIgnore?Type:string=Spelling', 'enabled': 'true'},
        {'text': 'Cop~iar', 'type': 'command', 'command': '.uno:Copy', 'enabled': 'false'},
        {
          'text': 'Colar e~special',
          'type': 'menu',
          'command': '.uno:PasteSpecialMenu',
          'menu': [
            {'text': 'Texto não ~formatado', 'type': 'command', 'command': '.uno:PasteUnformatted', 'enabled': 'true'},
          ],
        },
      ],
    }));
    expect(items.map((i) => i.text), ['erro', '', 'Ignorar', 'Copiar', 'Colar especial']);
    expect(items[1].isSeparator, isTrue);
    expect(items[3].enabled, isFalse);
    expect(items[4].children.single.command, '.uno:PasteUnformatted');
    expect(parseContextMenu('{'), isEmpty);
  });

  test('imagem selecionada: retângulo com o JSON das alças, ou EMPTY', () {
    expect(parseGraphicSelection('3678, 2892, 5118, 5118, 0, {"id":"1","type":601}'),
        const Rect.fromLTWH(3678, 2892, 5118, 5118));
    expect(parseGraphicSelection('EMPTY'), isNull);
  });

  test('tabela: "{ }" é fora; com colunas, dentro', () {
    expect(parseTableSelected('{ }'), isFalse);
    expect(parseTableSelected('{ "columns": { "left": 0 }, "rows": {} }'), isTrue);
    expect(parseTableSelected(''), isFalse);
  });

  test('estilos por família', () {
    final s = parseStyleLists('{"commandName": ".uno:StyleApply", "commandValues": {'
        '"CharacterStyles": ["Emphasis"], "ParagraphStyles": ["Text body", "Cena"], "PageStyles": ["Standard"]}}');
    expect(s.paragraph, ['Text body', 'Cena']);
    expect(s.character, ['Emphasis']);
    expect(parseStyleLists('x').paragraph, isEmpty);
  });

  test('medidas em polegadas com vírgula viram centímetros', () {
    final m = parseMeasures('{"left":"0,5","right":"0,0","firstline":"0.25","unit":"inch"}');
    expect(m['left'], closeTo(1.27, 1e-9));
    expect(m['firstline'], closeTo(0.635, 1e-9));
    expect(m['right'], 0);
    expect(parseMeasures(null), isEmpty);
    expect(parseMeasures('{"upper":"1","unit":"cm"}')['upper'], 1);
  });

  test('estado composto segue como JSON; tamanho do objeto', () {
    final (name, value) = parseCommandState(
        '{"commandName": ".uno:ULSpacing", "state": {"upper": "0,1", "lower": "0,0", "unit": "inch"}}')!;
    expect(name, '.uno:ULSpacing');
    expect(parseMeasures(value)['upper'], closeTo(0.254, 1e-9));
    expect(parseObjectSize('9029 x 9029'), const Size(9029, 9029));
    expect(parseObjectSize(''), isNull);
  });

  test('o adaptador traduz os callbacks novos', () {
    expect(LokQuillKit.translate(12, 'nada'), isA<SearchNotFound>());
    expect((LokQuillKit.translate(6, 'EMPTY')! as GraphicSelected).rect, isNull);
    expect((LokQuillKit.translate(44, '{ }')! as TableSelected).inTable, isFalse);
    expect(LokQuillKit.translate(23, '{"menu": []}'), isA<ContextMenuReady>());
    expect(LokQuillKit.translate(15, '{"searchResultSelection": []}'), isA<SearchResult>());
  });

  test('o estado do estilo, em português, volta ao nome de programa', () {
    expect(styleIdFromState('Título 1'), 'Heading 1');
    expect(styleIdFromState('Estilo de parágrafo Padrão'), 'Standard');
    expect(styleIdFromState('Cena'), 'Cena');
    expect(loBuiltinParagraphStyles, contains('Text body'));
    expect(loBuiltinParagraphStyles, isNot(contains('Cena')));
  });

  test('os argumentos da busca', () {
    Map<String, dynamic> args(SearchQuery q, SearchCommand c) =>
        jsonDecode(searchArgs(q, c, replacement: 'X')) as Map<String, dynamic>;
    Object? v(Map<String, dynamic> a, String k) => (a['SearchItem.$k'] as Map)['value'];
    final plain = args(const SearchQuery('ação'), SearchCommand.next);
    expect(v(plain, 'SearchString'), 'ação');
    expect(v(plain, 'Command'), 0);
    expect(v(plain, 'AlgorithmType2'), 1);
    expect(v(plain, 'TransliterateFlags'), 256);
    final strict = args(const SearchQuery('a+', matchCase: true, wholeWord: true, regex: true), SearchCommand.replaceAll);
    expect(v(strict, 'Command'), 3);
    expect(v(strict, 'AlgorithmType2'), 2);
    expect(v(strict, 'TransliterateFlags'), 0);
    expect(v(strict, 'WordOnly'), true);
    expect(v(strict, 'ReplaceString'), 'X');
  });
}
