// O papel escuro (D-074): a conta do Dart (os cartões de estilo) é a mesma
// do nativo (paper_invert_test.cc).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/kit/quill_kit.dart';
import 'package:psito_quill/src/ui/tokens/themes/themes.dart';

void main() {
  const inv = PaperInvert(paper: 0x1E1F22, ink: 0xE6E6E6, source: 0xFFFFFF);

  test('o branco vira o papel, o preto a tinta, o cinza-escuro um claro', () {
    expect(inv.apply(0xFFFFFF), 0x1E1F22);
    expect(inv.apply(0x000000), 0xE6E6E6);
    expect((inv.apply(0x333333) >> 16) & 255, greaterThan(0xB0));
  });

  test('o vermelho continua vermelho, mais claro', () {
    final c = inv.apply(0xC00000);
    final r = (c >> 16) & 255, g = (c >> 8) & 255;
    expect(r, greaterThan(0xC0));
    expect(r, greaterThan(g + 80));
  });

  test('os temas escuros pedem o papel claro irmão e invertem; os claros não', () {
    for (final t in builtInThemes) {
      final p = enginePaper(t);
      if (t.brightness == Brightness.light) {
        expect((p.scheme, p.invert), (t.paperScheme, null), reason: t.id);
      } else {
        expect(p.invert, isNotNull, reason: t.id);
        expect(p.invert!.paper, t.colors.paper.toARGB32() & 0xFFFFFF);
        final light = builtInThemes.firstWhere((l) => l.paperScheme == p.scheme);
        expect(light.brightness, Brightness.light);
      }
    }
  });
}
