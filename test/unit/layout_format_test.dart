// A Página Inicial, o Layout e o Inserir (Fase 4, Etapa 7, D-092): o que a
// cópia diz da página (os números de linha, a cor, a marca d'água) e as
// macros novas.
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/document/document_controller.dart';
import 'package:psito_quill/src/document/style_patch.dart';
import 'package:psito_quill/src/kit/lok/quill_macros.dart';

void main() {
  // Como o LibreOffice 24.2 grava (a sonda).
  const page = '<office:automatic-styles><style:page-layout style:name="pm1">'
      '<style:page-layout-properties fo:page-width="21.001cm" fo:background-color="#fff0e0" draw:fill="solid"/>'
      '</style:page-layout><style:page-layout style:name="pm2"><style:page-layout-properties fo:background-color="#ff0000"/>'
      '</style:page-layout></office:automatic-styles>'
      '<office:master-styles><style:master-page style:name="First_20_Page" style:page-layout-name="pm2"/>'
      '<style:master-page style:name="Standard" style:page-layout-name="pm1"><style:header><text:p text:style-name="Header">'
      '<draw:custom-shape text:anchor-type="char" draw:name="PowerPlusWaterMarkObject1" draw:style-name="gr1">'
      '<text:p>RASCUNHO</text:p><draw:enhanced-geometry/></draw:custom-shape></text:p></style:header></style:master-page>'
      '</office:master-styles>';

  test('a cópia: a cor do estilo Standard e a marca d\'água', () {
    final p = parsePageSetup(page);
    expect(p.pageColor, 0xFFF0E0, reason: 'a do Standard, não a da primeira página');
    expect(p.watermark, 'RASCUNHO');
    expect(p.header, isTrue, reason: 'a marca d\'água vai no cabeçalho');
    final none = parsePageSetup(page.replaceAll('#fff0e0', 'transparent').replaceAll(RegExp(r'<draw:custom-shape[\s\S]*?</draw:custom-shape>'), ''));
    expect(none.pageColor, isNull);
    expect(none.watermark, isNull);
  });

  test('a cópia: os números de linha', () {
    const off = '<text:linenumbering-configuration text:style-name="Line_20_numbering" text:number-lines="false" text:increment="5"/>';
    const on = '<text:linenumbering-configuration text:style-name="Line_20_numbering" text:increment="5"/>';
    expect(parsePageSetup(off).lineNumbers, isFalse);
    expect(parsePageSetup(on).lineNumbers, isTrue);
    expect(parsePageSetup('<office:document/>').lineNumbers, isFalse);
  });

  test('os modelos de lista e os comandos do motor', () {
    expect([for (final l in MultilevelList.values) l.outline], [7, 1, 2, 6, 8]);
    expect(TextCase.upper.command, '.uno:ChangeCaseToUpper');
    expect(Arrange.back.command, '.uno:SendToBack');
  });

  test('o módulo Basic tem as macros do Layout e do Inserir', () {
    final xml = quillMacroModuleXml();
    for (final sub in ['Sub Linhas', 'Sub CorPagina', 'Sub Caixa']) {
      expect(xml, contains(sub));
    }
    expect(quillMacro('CorPagina', [-1]), 'macro:///PsitoQuill.Referencias.CorPagina("-1")');
  });
}
