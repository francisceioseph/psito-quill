import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/commands/command_registry.dart';

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
}
