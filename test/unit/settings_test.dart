import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/commands/command_registry.dart';
import 'package:psito_quill/src/settings/settings.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('quill-pref-'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('os padrões: tema Claro e atalhos do Word em português', () {
    final s = Settings(null);
    expect((s.theme, s.shortcuts), ('claro', ShortcutScheme.wordPt));
    s.dispose();
  });

  test('guarda e lê de volta', () {
    final f = File('${dir.path}/preferencias.json');
    Settings(f)
      ..theme = 'escuro'
      ..shortcuts = ShortcutScheme.wordEn
      ..dispose();
    final again = Settings(f);
    expect((again.theme, again.shortcuts), ('escuro', ShortcutScheme.wordEn));
    again.dispose();
  });

  test('arquivo estragado ou com valor desconhecido: os padrões', () {
    final f = File('${dir.path}/preferencias.json')..writeAsStringSync('{"atalhos":"emacs"}');
    final s = Settings(f);
    expect(s.shortcuts, ShortcutScheme.wordPt);
    f.writeAsStringSync('lixo');
    expect(Settings(f).theme, 'claro');
    s.dispose();
  });
}
