import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/ui/tokens/themes/themes.dart';

double _luminance(Color c) => c.computeLuminance();
double contrast(Color a, Color b) {
  final la = _luminance(a), lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  for (final t in builtInThemes) {
    group('tema ${t.id}', () {
      test('texto da interface legível (WCAG AA, 4,5:1)', () {
        expect(contrast(t.colors.onFrame, t.colors.frame), greaterThanOrEqualTo(4.5));
        expect(contrast(t.colors.onFrame, t.colors.frameRaised), greaterThanOrEqualTo(4.5));
        expect(contrast(t.colors.onFrameMuted, t.colors.frame), greaterThanOrEqualTo(4.5));
        expect(contrast(t.colors.onAccent, t.colors.accent), greaterThanOrEqualTo(4.5));
      });

      test('tinta no papel com contraste de leitura longa (7:1)', () {
        expect(contrast(t.colors.paperInk, t.colors.paper), greaterThanOrEqualTo(7));
      });

      test('o cursor aparece no papel', () {
        expect(contrast(t.colors.cursor, t.colors.paper), greaterThanOrEqualTo(3));
      });

      test('o ThemeData leva os tokens junto', () {
        expect(t.toThemeData().extension<Object>(), isNull); // extensão é por tipo
        expect(t.toThemeData().extensions.values, contains(t));
      });
    });
  }

  test('cada tema tem o seu esquema de papel no LibreOffice', () {
    final names = builtInThemes.map((t) => t.paperScheme).toSet();
    expect(names.length, builtInThemes.length);
    final schemes = paperSchemes(builtInThemes);
    expect(schemes.map((s) => s.paper), everyElement(lessThanOrEqualTo(0xFFFFFF)));
  });

  test('nenhuma cor literal fora dos arquivos de tema', () {
    // Atomic design com tokens: widgets só leem QuillTokens.
    final literal = RegExp(r'Color\(0x|Colors\.[a-z]|Color\.fromARGB|Color\.fromRGBO');
    final offenders = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart') || f.path.contains('/tokens/themes/') || f.path.contains('/l10n/gen/')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (literal.hasMatch(lines[i])) offenders.add('${f.path}:${i + 1}');
      }
    }
    expect(offenders, isEmpty);
  });
}
