import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/document/fodt.dart';
import 'package:psito_quill/src/document/format_origin.dart';

void main() {
  const body = StyleProps(fontName: 'Literata', sizePt: 12, align: 'justify', firstLineCm: 0.6);

  Map<FormatAspect, bool> at({String font = 'Literata', double size = 12, bool bold = false, bool italic = false, int? color, String align = 'justify', double first = 0.6}) =>
      formatOrigins(style: body, fontName: font, fontSize: size, bold: bold, italic: italic, color: color, alignment: align, firstLineCm: first);

  test('tudo como o estilo: nada direto', () {
    expect(at().values, everyElement(isFalse));
  });

  test('o itálico e a cor no texto são diretos; o resto, do estilo', () {
    final o = at(italic: true, color: 0xC9211E);
    expect(o[FormatAspect.italic], isTrue);
    expect(o[FormatAspect.color], isTrue);
    expect(o[FormatAspect.font], isFalse);
    expect(o[FormatAspect.alignment], isFalse);
  });

  test('tamanho, fonte, alinhamento e recuo diferentes', () {
    final o = at(font: 'Liberation Serif', size: 14, align: 'center', first: 0);
    expect([o[FormatAspect.font], o[FormatAspect.size], o[FormatAspect.alignment], o[FormatAspect.firstLine]], everyElement(isTrue));
  });

  test('sem a cópia, não se sabe nada', () {
    expect(formatOrigins(style: null, fontName: 'x', fontSize: 1, bold: true, italic: true, color: 1, alignment: 'start', firstLineCm: 1), isEmpty);
  });
}
