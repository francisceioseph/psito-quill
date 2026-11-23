import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/kit/lok/lo_profile.dart';
import 'package:psito_quill/src/ui/tokens/themes/themes.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('quill-perfil-'));
  tearDown(() => dir.deleteSync(recursive: true));

  File registry() => File('${dir.path}/user/registrymodifications.xcu');

  test('cria o registro com os esquemas dos temas', () {
    LoProfile(dir).ensureSettings(paperSchemes(builtInThemes));
    final text = registry().readAsStringSync();
    expect(text, startsWith('<?xml'));
    expect(text, contains('oor:name="PsitoQuillClaro"'));
    expect(text, contains('oor:name="PsitoQuillEscuro"'));
    // O papel do tema Escuro.
    expect(text, contains('<value>${escuro.colors.paper.toARGB32() & 0xFFFFFF}</value>'));
    expect(text.trim(), endsWith('</oor:items>'));
  });

  test('não duplica ao chamar de novo e preserva o resto', () {
    final p = LoProfile(dir);
    p.ensureSettings(paperSchemes(builtInThemes));
    final file = registry();
    file.writeAsStringSync(file.readAsStringSync().replaceFirst(
        '</oor:items>', '<item oor:path="/org.openoffice.Office.Common/Misc"><prop oor:name="X"><value>1</value></prop></item>\n</oor:items>'));
    p.ensureSettings(paperSchemes(builtInThemes));
    final text = file.readAsStringSync();
    expect('PsitoQuillEscuro'.allMatches(text).length, 1);
    expect(text, contains('Office.Common/Misc'));
  });

  test('o LibreOffice regrava sem os comentários: os nós antigos saem pelo nome', () {
    final p = LoProfile(dir);
    p.ensureSettings(paperSchemes(builtInThemes));
    final file = registry();
    file.writeAsStringSync(file.readAsStringSync().replaceAll(RegExp(r'<!--[^>]*-->\n'), ''));
    p.ensureSettings(paperSchemes(builtInThemes));
    expect('PsitoQuillClaro'.allMatches(file.readAsStringSync()).length, 1);
  });

  test('a URL do perfil é file:// sem barra no fim', () {
    expect(LoProfile(Directory('/tmp/a b/perfil')).url, 'file:///tmp/a%20b/perfil');
  });
}
