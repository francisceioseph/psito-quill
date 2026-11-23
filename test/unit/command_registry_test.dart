import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/l10n/gen/app_localizations.dart';
import 'package:psito_quill/src/commands/command_registry.dart';
import 'package:psito_quill/src/commands/commands_document.dart';

import '../support/harness.dart';

void main() {
  Command cmd(String id, VoidCallback run, {bool Function()? canRun}) => Command(
        id: id,
        label: id,
        icon: Icons.circle,
        run: run,
        canRun: canRun,
        shortcuts: const {
          ShortcutScheme.wordPt: SingleActivator(LogicalKeyboardKey.keyN, control: true),
          ShortcutScheme.wordEn: SingleActivator(LogicalKeyboardKey.keyB, control: true),
        },
      );

  test('um id só por comando', () {
    final r = CommandRegistry()..register(cmd('a', () {}));
    expect(() => r.register(cmd('a', () {})), throwsArgumentError);
  });

  test('run respeita o canRun', () {
    var ran = 0;
    var allowed = false;
    final r = CommandRegistry()..register(cmd('a', () => ran++, canRun: () => allowed));
    expect(r.run('a'), isFalse);
    allowed = true;
    expect(r.run('a'), isTrue);
    expect(ran, 1);
    expect(r.run('nao-existe'), isFalse);
  });

  test('o atalho segue o jogo escolhido', () {
    final r = CommandRegistry()..register(cmd('negrito', () {}));
    expect(r.shortcutOf('negrito')!.trigger, LogicalKeyboardKey.keyN);
    r.scheme = ShortcutScheme.wordEn;
    expect(r.shortcutOf('negrito')!.trigger, LogicalKeyboardKey.keyB);
  });

  testWidgets('match encontra o comando pela tecla', (tester) async {
    final r = CommandRegistry()..register(cmd('negrito', () {}));
    final keyboard = HardwareKeyboard.instance;
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    const n = KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyN, logicalKey: LogicalKeyboardKey.keyN, timeStamp: Duration.zero);
    expect(r.match(n, keyboard)?.id, 'negrito');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(r.match(n, keyboard), isNull);
  });

  test('trocar o jogo avisa a faixa (as dicas mudam)', () {
    final r = CommandRegistry()..register(cmd('negrito', () {}));
    var n = 0;
    r.addListener(() => n++);
    expect(r.shortcutLabelOf('negrito'), 'Ctrl+N');
    r.scheme = ShortcutScheme.wordEn;
    expect(n, 1);
    expect(r.shortcutLabelOf('negrito'), 'Ctrl+B');
    expect(r.tooltipOf('negrito'), 'negrito (Ctrl+B)');
    r.dispose();
  });

  group('os comandos do editor', () {
    late Harness h;
    late CommandRegistry r;
    setUp(() {
      h = Harness();
      r = CommandRegistry();
      registerEditorCommands(r, doc: h.doc, workspace: h.workspace, l10n: lookupAppLocalizations(const Locale('pt')));
    });
    tearDown(() {
      r.dispose();
      h.dispose();
    });

    for (final scheme in ShortcutScheme.values) {
      test('nenhum atalho repetido no jogo ${scheme.name}', () {
        final seen = <String, String>{};
        for (final c in r.all) {
          final a = c.shortcuts[scheme];
          if (a == null) continue;
          final key = '${a.control}${a.alt}${a.shift}${a.trigger.keyId}';
          expect(seen[key], isNull, reason: '${c.id} e ${seen[key]} têm o mesmo atalho');
          seen[key] = c.id;
        }
      });
    }

    test('os atalhos do Word em português', () {
      String? s(String id) {
        r.scheme = ShortcutScheme.wordPt;
        return r.shortcutLabelOf(id);
      }

      expect(s(CommandIds.bold), 'Ctrl+N');
      expect(s(CommandIds.italic), 'Ctrl+I');
      expect(s(CommandIds.underline), 'Ctrl+S');
      expect(s(CommandIds.save), 'Ctrl+B');
      expect(s(CommandIds.open), 'Ctrl+A');
      expect(s(CommandIds.newDocument), 'Ctrl+O');
      expect(s(CommandIds.selectAll), 'Ctrl+T');
      expect(s(CommandIds.redo), 'Ctrl+R');
      expect(s(CommandIds.saveAs), 'F12');
      expect(s(CommandIds.heading1), 'Ctrl+Alt+1');
    });

    test('sem documento, os comandos de edição ficam desligados', () {
      expect(r[CommandIds.bold]!.enabled, isFalse);
      expect(r[CommandIds.paste]!.enabled, isFalse);
      expect(r[CommandIds.newDocument]!.enabled, isTrue, reason: 'o motor está ligado');
    });

    test('Título 1 aplica o estilo pelo nome do LibreOffice', () {
      h.doc.open('/a.odt');
      r.run(CommandIds.heading1);
      expect(h.kit.unoCommands.last, '.uno:StyleApply');
      expect(h.kit.unoArgs.last, contains('"Heading 1"'));
    });
  });
}
