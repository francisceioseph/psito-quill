// Os sons da máquina de escrever (D-095): só no zen com a máquina de
// escrever e a preferência; a tecla, o espaço, o retorno e o sino perto da
// margem; e o plugin desliga (e solta os sons) fora do zen.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/app.dart';
import 'package:psito_quill/src/document/typewriter_sound.dart';
import 'package:psito_quill/src/kit/quill_kit.dart';

import '../support/harness.dart';

void main() {
  late Harness h;
  Harness? current;

  Future<void> pumpApp(WidgetTester tester, {bool sound = true}) async {
    await tester.binding.setSurfaceSize(const Size(1500, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.localesTestValue = [const Locale('pt', 'BR')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    h = current = Harness();
    h.settings
      ..zenTypewriter = true
      ..typewriterSound = sound;
    await tester.pumpWidget(QuillApp(workspace: h.workspace, settings: h.settings, window: h.window, showMemory: false));
    h.doc.open('/livro/cap.odt');
    await tester.pump();
    await tester.pump();
  }

  Future<void> zen(WidgetTester tester) async {
    await tester.sendKeyEvent(LogicalKeyboardKey.f11);
    await tester.pump();
    await tester.pump();
  }

  /// O texto chega pelo IME (o DocumentView é o cliente dele).
  Future<void> type(WidgetTester tester, String text) async {
    tester.testTextInput.updateEditingValue(TextEditingValue(text: text));
    await tester.pump();
  }

  tearDown(() {
    current?.dispose();
    current = null;
  });

  testWidgets('fora do zen, nada; no zen, a tecla, o espaço, o Backspace e o retorno', (tester) async {
    await pumpApp(tester);
    await type(tester, 'a');
    expect(h.kit.soundEnabled, isFalse, reason: 'fora do zen, o plugin nem liga');
    expect(h.kit.sounds, isEmpty);

    await zen(tester);
    expect(h.kit.soundEnabled, isTrue);
    expect(h.kit.soundVolume, 0.6);
    await type(tester, 'a');
    await type(tester, ' ');
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(h.kit.sounds, [
      TypewriterSound.key,
      TypewriterSound.space,
      TypewriterSound.backspace,
      TypewriterSound.carriageReturn,
    ]);

    // Sair do zen desliga o plugin (e solta os sons).
    await tester.pump(const Duration(seconds: 3));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(h.kit.soundEnabled, isFalse);
  });

  testWidgets('o sino toca perto da margem, uma vez na linha', (tester) async {
    await pumpApp(tester);
    await zen(tester);
    final right = textRightTwips(h.doc.ruler)!;
    int bells() => h.kit.sounds.where((s) => s == TypewriterSound.bell).length;
    // O kit falso põe o cursor em 1440 + 120 twips por caractere, como o
    // motor manda depois de cada tecla.
    await type(tester, 'a');
    await tester.pump();
    expect(bells(), 0);
    final upTo = ((right - MarginBell.warningTwips - 1440) / 120).ceil();
    await type(tester, 'a' * (upTo - 1));
    await tester.pump();
    expect(h.doc.cursor.left, greaterThanOrEqualTo(right - MarginBell.warningTwips));
    expect(bells(), 1);
    await type(tester, 'b');
    await tester.pump();
    expect(bells(), 1, reason: 'uma vez na linha');
    // Mover o cursor sem digitar não toca.
    h.kit.emit(CursorMoved(Rect.fromLTWH(right - 300, 1800, 1, 280)));
    await tester.pump();
    expect(bells(), 1);
  });

  testWidgets('sem a preferência, o zen fica mudo; o botão Som da barrinha liga', (tester) async {
    await pumpApp(tester, sound: false);
    await zen(tester);
    await type(tester, 'a');
    expect(h.kit.soundEnabled, isFalse);
    expect(h.kit.sounds, isEmpty);
    await tester.tap(find.text('Som'));
    await tester.pump();
    expect(h.settings.typewriterSound, isTrue);
    expect(h.kit.soundEnabled, isTrue);
    await type(tester, 'b');
    expect(h.kit.sounds, [TypewriterSound.key]);
    // Sem a máquina de escrever, o som desliga.
    await tester.tap(find.text('Máquina de escrever'));
    await tester.pump();
    expect(h.kit.soundEnabled, isFalse);
  });
}
