// As Preferências e os modelos (Fase 4, Etapa 8, D-093): os atalhos
// escolhidos por cima do jogo (o registro, o conflito, o que fica guardado),
// as preferências novas no arquivo, as regras da ortografia no perfil do
// motor, e a lista e o nome dos modelos.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/commands/command_registry.dart';
import 'package:psito_quill/src/document/templates.dart';
import 'package:psito_quill/src/kit/lok/lo_profile.dart';
import 'package:psito_quill/src/settings/settings.dart';
import 'package:psito_quill/src/ui/organisms/shortcut_dialog.dart';
import 'package:psito_quill/src/ui/tokens/themes/themes.dart';

CommandRegistry _registry(List<String> ran) {
  final r = CommandRegistry();
  Command c(String id, SingleActivator? a) => Command(
        id: id,
        label: id,
        icon: const IconData(0),
        run: () => ran.add(id),
        shortcuts: a == null ? const {} : {ShortcutScheme.wordPt: a, ShortcutScheme.wordEn: a},
      );
  r
    ..register(c('negrito', const SingleActivator(LogicalKeyboardKey.keyN, control: true)))
    ..register(c('italico', const SingleActivator(LogicalKeyboardKey.keyI, control: true)))
    ..register(c('sem', null));
  return r;
}

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('quill-etapa8-'));
  tearDown(() => tmp.deleteSync(recursive: true));

  test('o atalho guardado volta igual', () {
    const a = SingleActivator(LogicalKeyboardKey.f5, control: true, shift: true);
    final back = decodeActivator(encodeActivator(a))!;
    expect(sameActivator(a, back), isTrue);
    expect(activatorLabel(back), 'Ctrl+Shift+F5');
    expect(encodeActivator(null), '');
    expect(decodeActivator(''), isNull);
    expect(decodeActivator('lixo'), isNull);
  });

  test('o escolhido vale por cima do jogo, e tirar desliga', () {
    final ran = <String>[];
    final r = _registry(ran);
    const ctrlJ = SingleActivator(LogicalKeyboardKey.keyJ, control: true);
    r.overrides = {'italico': ctrlJ, 'negrito': null};
    expect(r.shortcutOf('italico'), ctrlJ);
    expect(r.shortcutOf('negrito'), isNull);
    expect(r.defaultShortcutOf('negrito')!.trigger, LogicalKeyboardKey.keyN);
    expect(r.commandWithShortcut(ctrlJ)?.id, 'italico');
    expect(r.commandWithShortcut(ctrlJ, except: 'italico'), isNull);
    expect(r.shortcutLabelOf('italico'), 'Ctrl+J');
    expect(r.tooltipOf('negrito'), 'negrito');
  });

  test('atribuir o atalho de outro tira dele; o igual ao jogo não fica guardado', () {
    final r = _registry([]);
    const ctrlN = SingleActivator(LogicalKeyboardKey.keyN, control: true);
    var custom = applyShortcutChoice(r, const {}, 'italico', const AssignShortcut(ctrlN, takenFrom: 'negrito'));
    expect(custom, {'italico': encodeActivator(ctrlN), 'negrito': ''});
    r.overrides = {for (final e in custom.entries) e.key: decodeActivator(e.value)};
    expect(r.commandWithShortcut(ctrlN)?.id, 'italico');

    // Voltar o negrito ao jogo tira o Ctrl+N do itálico.
    custom = applyShortcutChoice(r, custom, 'negrito', const ResetShortcut());
    expect(custom, {'italico': ''});

    // O mesmo do jogo não fica guardado; tirar um sem atalho no jogo, também não.
    expect(applyShortcutChoice(r, const {}, 'negrito', const AssignShortcut(ctrlN)), isEmpty);
    expect(applyShortcutChoice(r, const {}, 'sem', const RemoveShortcut()), isEmpty);
  });

  test('uma letra sozinha não serve de atalho', () {
    expect(usableShortcut(const SingleActivator(LogicalKeyboardKey.keyA)), isFalse);
    expect(usableShortcut(const SingleActivator(LogicalKeyboardKey.keyA, shift: true)), isFalse);
    expect(usableShortcut(const SingleActivator(LogicalKeyboardKey.keyA, alt: true)), isTrue);
    expect(usableShortcut(const SingleActivator(LogicalKeyboardKey.f7)), isTrue);
  });

  test('as preferências novas no arquivo', () {
    final f = File('${tmp.path}/preferencias.json');
    Settings(f)
      ..spellIgnoreUpper = true
      ..spellIgnoreDigits = true
      ..quickAccess = ['arquivo.salvar', 'formatar.negrito']
      ..customShortcuts = {'formatar.negrito': '1,0,0,106'};
    final back = Settings(f);
    expect(back.spellIgnoreUpper, isTrue);
    expect(back.spellIgnoreDigits, isTrue);
    expect(back.quickAccess, ['arquivo.salvar', 'formatar.negrito']);
    expect(back.customShortcuts, {'formatar.negrito': '1,0,0,106'});
    expect(Settings(null).quickAccess, Settings.defaultQuickAccess);
  });

  test('as regras da ortografia no perfil, sem repetir', () {
    final p = LoProfile(Directory('${tmp.path}/perfil'));
    p.ensureSettings(paperSchemes(builtInThemes), spellUpperCase: false, spellWithDigits: true);
    final file = File('${tmp.path}/perfil/user/registrymodifications.xcu');
    String rule(String name) => RegExp('oor:name="$name" oor:op="fuse"><value>(\\w+)').allMatches(file.readAsStringSync()).map((m) => m[1]).join(',');
    expect(rule('IsSpellUpperCase'), 'false');
    expect(rule('IsSpellWithDigits'), 'true');
    // O LibreOffice regrava sem os comentários, com o valor da sessão.
    file.writeAsStringSync(file.readAsStringSync().replaceAll(RegExp(r'<!-- /?psito-quill: esquemas -->\n'), ''));
    p.ensureSettings(paperSchemes(builtInThemes));
    expect(rule('IsSpellUpperCase'), 'true');
    expect(rule('IsSpellWithDigits'), 'true');
  });

  test('os modelos: o do livro primeiro, depois os da pasta pelo nome', () {
    final book = Directory('${tmp.path}/Livro.psitobook')..createSync();
    final dir = Directory('${tmp.path}/modelos')..createSync();
    File(bookTemplatePath(book.path)).writeAsStringSync('');
    for (final n in ['b.ott', 'A.ott', 'nota.txt']) {
      File('${dir.path}/$n').writeAsStringSync('');
    }
    final list = listTemplates(bookDir: book.path, dir: dir);
    expect([for (final e in list) e.name], ['estilos.ott', 'A', 'b']);
    expect(list.first.ofBook, isTrue);
    expect(listTemplates(dir: Directory('${tmp.path}/nao-existe')), isEmpty);
    expect(templateFileName(' Manuscrito / 2026 '), 'Manuscrito  2026.ott');
    expect(templateFileName('..'), isNull);
    expect(templateFileName('  '), isNull);
  });
}
