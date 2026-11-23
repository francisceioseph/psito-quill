// A régua (Fase 2B, Etapa 4, D-046): o callback 35 da 24.2, a geometria e os
// recuos depois de arrastar.
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/kit/lok/lok_payloads.dart';
import 'package:psito_quill/src/kit/quill_kit.dart';
import 'package:psito_quill/src/ui/organisms/document_view.dart' show DocViewport;
import 'package:psito_quill/src/ui/organisms/ruler.dart';

void main() {
  test('o callback 35 de verdade (as tabulações com a chave repetida)', () {
    const payload = '{ "margin1": 0, "margin2": 18000, "leftOffset": 2000, "pageOffset": 501, "pageWidth": 21001, '
        '"tabs": { "": { "position": 2000, "style": 4}, "": { "position": 4001, "style": 4}}, "unit": " cm"}';
    final r = parseRuler(payload)!;
    expect(r.pageWidth, 21001);
    expect(r.leftMargin, 2000);
    expect(r.textWidth, 18000);
    expect(r.rightMargin, 1001);
    expect(r.tabs.map((t) => t.position), [2000, 4001]);
    expect(r.pageOffset, 501);
    expect(parseRuler('{}'), isNull);
  });

  const info = RulerInfo(pageWidth: 21000, leftMargin: 2000, textWidth: 18000);
  const data = RulerData(info: info, leftCm: 1, firstLineCm: 0.5, rightCm: 0);

  test('a geometria: o zero na margem esquerda', () {
    // 1 twip por pixel: 1 cm = 566,9 px.
    const view = DocViewport(left: 100, top: 0, pxPerTwip: 1, viewSize: Size(800, 600));
    const g = HRulerGeometry(view, data);
    // A página começa depois do vão de 284 twips em volta dela.
    expect(g.marginLeft, closeTo(100 + 284 + 2000 * 1440 / 2540, 0.01));
    expect(g.xOf(RulerMark.left) - g.marginLeft, closeTo(g.pxPerCm, 0.01));
    expect(g.xOf(RulerMark.firstLine) - g.marginLeft, closeTo(1.5 * g.pxPerCm, 0.01));
    expect(g.xOf(RulerMark.right), closeTo(g.marginRight, 0.01));
    expect(g.cmAt(g.marginLeft + 2 * g.pxPerCm), closeTo(2, 1e-9));
  });

  test('a régua começa onde o motor diz que a página começa (o pageOffset sondado na 24.2)', () {
    const view = DocViewport(left: 100, top: 0, pxPerTwip: 1, viewSize: Size(800, 600));
    const twips = 1440 / 2540;
    // Uma página por linha: o pageOffset é o vão (501 = 284 twips).
    const single = HRulerGeometry(
        view, RulerData(info: RulerInfo(pageWidth: 21000, leftMargin: 2000, textWidth: 18000, pageOffset: 501), leftCm: 0, firstLineCm: 0, rightCm: 0));
    expect(single.pageLeft, closeTo(100 + 284, 0.5));
    expect(single.pageRight, closeTo(single.pageLeft + 21000 * twips, 0.5));
    // Livro: a primeira página sozinha, na coluna da direita (21502).
    const book = HRulerGeometry(
        view, RulerData(info: RulerInfo(pageWidth: 21000, leftMargin: 2000, textWidth: 18000, pageOffset: 21502), leftCm: 0, firstLineCm: 0, rightCm: 0));
    expect(book.pageLeft, closeTo(100 + 21502 * twips, 0.5));
    expect(book.pageRight, closeTo(book.pageLeft + 21000 * twips, 0.5), reason: 'a faixa não pode se fechar');
    expect(book.marginLeft, closeTo(book.pageLeft + 2000 * twips, 0.5));
    // Sem o pageOffset, o vão de sempre.
    const none = HRulerGeometry(
        view, RulerData(info: RulerInfo(pageWidth: 21000, leftMargin: 2000, textWidth: 18000), leftCm: 0, firstLineCm: 0, rightCm: 0));
    expect(none.pageLeft, closeTo(100 + 284, 0.5));
  });

  test('as fileiras de páginas da régua vertical', () {
    expect(pageRows(5), 5);
    expect(pageRows(5, columns: 3), 2);
    expect(pageRows(1, columns: 2, book: true), 1);
    expect(pageRows(2, columns: 2, book: true), 2);
    expect(pageRows(3, columns: 2, book: true), 2);
    expect(pageRows(4, columns: 2, book: true), 3);
    expect(pageRows(0), 0);
  });

  test('arrastar o esquerdo leva a primeira linha junto, no mesmo lugar da página', () {
    final i = indentsAfterDrag(data, RulerMark.left, 2);
    expect(i.left, 2);
    expect(i.firstLine, -0.5, reason: 'antes em 1,5 cm; continua em 1,5 cm');
    expect(i.right, isNull);
    final f = indentsAfterDrag(data, RulerMark.firstLine, 1);
    expect(f.firstLine, 0);
    expect(f.left, isNull);
    expect(indentsAfterDrag(data, RulerMark.right, 1.2).right, 1.2);
  });

  test('gruda de milímetro em milímetro', () {
    expect(snapCm(1.234), closeTo(1.2, 1e-9));
    expect(snapCm(-0.06), closeTo(-0.1, 1e-9));
  });

  test('os números da régua são medidos uma vez só (o heap não cresce ao rolar)', () {
    final labels = RulerLabels();
    const ink = Color(0xFF000000);
    final a = labels.get('3', ink);
    expect(identical(labels.get('3', ink), a), isTrue);
    labels.get('4', ink);
    expect(labels.length, 2);
    labels.get('3', const Color(0xFFFFFFFF));
    expect(labels.length, 1, reason: 'trocar o tema refaz');
    labels.clear();
    expect(labels.length, 0);
  });
}
