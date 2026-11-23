// A busca no texto da cópia (D-050): a página, o contexto no parágrafo e a
// expressão que seleciona só a ocorrência no motor.
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/document/fodt.dart';

void main() {
  const xml = '<office:document><office:body><office:text>'
      '<text:h text:outline-level="1">A estrada</text:h>'
      '<text:p>Ele disse a estrada<text:s/>velha acabou.</text:p>'
      '<text:soft-page-break/>'
      '<text:p>Na Estrada &amp; no posto (2016).</text:p>'
      '<text:p/>'
      '</office:text></office:body></office:document>';

  test('acha sem diferenciar maiúsculas, com a página e o contexto', () {
    final r = searchFodtText(xml, 'estrada');
    expect(r.total, 3);
    expect(r.hits.map((h) => h.page), [1, 1, 2]);
    expect(r.hits[1].before, 'Ele disse a ');
    expect(r.hits[1].after, ' velha acabou.', reason: 'o <text:s/> vira espaço');
    expect(r.hits[2].match, 'Estrada', reason: 'o achado vem como está no texto');
    expect(r.hits[2].after, ' & no posto (2016).');
  });

  test('o limite corta a lista mas não o total', () {
    final r = searchFodtText(xml, 'estrada', limit: 1);
    expect(r.hits, hasLength(1));
    expect(r.total, 3);
    expect(searchFodtText(xml, '  ').total, 0);
  });

  test('a expressão: lookbehind e lookahead, com os especiais escapados', () {
    const h = TextHit(page: 2, before: 'Na ', match: 'Estrada', after: ' & no posto (2016).');
    expect(h.regex, r'(?<=Na )Estrada(?= & no posto \(2016\)\.)');
    expect(const TextHit(page: 1, before: '', match: 'a.b', after: '').regex, r'a\.b');
  });
}
