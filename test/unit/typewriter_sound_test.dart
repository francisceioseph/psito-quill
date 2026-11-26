// Os sons da máquina de escrever (D-095): o som de cada texto e de cada
// tecla, a margem pela régua, o sino uma vez por linha e as preferências.
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/document/typewriter_sound.dart';
import 'package:psito_quill/src/kit/lok/vcl_keys.dart';
import 'package:psito_quill/src/kit/quill_kit.dart';
import 'package:psito_quill/src/settings/settings.dart';

void main() {
  test('o texto: o espaço tem o seu som, o resto é a tecla', () {
    expect(soundForText('a'), TypewriterSound.key);
    expect(soundForText('á'), TypewriterSound.key);
    expect(soundForText(' '), TypewriterSound.space);
    expect(soundForText(' '), TypewriterSound.space);
    expect(soundForText(''), isNull);
  });

  test('as teclas do motor: o Enter é o retorno, o Backspace volta, as setas calam', () {
    expect(soundForVclKey(VclKey.enter), TypewriterSound.carriageReturn);
    // Com o Shift (a quebra de linha), também.
    expect(soundForVclKey(VclKey.enter | 0x1000), TypewriterSound.carriageReturn);
    expect(soundForVclKey(VclKey.backspace), TypewriterSound.backspace);
    expect(soundForVclKey(VclKey.delete), TypewriterSound.backspace);
    expect(soundForVclKey(VclKey.tab), TypewriterSound.space);
    expect(soundForVclKey(VclKey.pageDown), isNull);
  });

  test('a margem direita sai da régua, em twips do documento', () {
    expect(textRightTwips(null), isNull);
    // O vão de 284 twips, mais a margem e o texto (20.000 centésimos de mm).
    final right = textRightTwips(const RulerInfo(pageWidth: 21001, leftMargin: 2000, textWidth: 18000))!;
    expect(right, closeTo(284 + 20000 * 1440 / 2540, 0.5));
    // No modo Várias páginas, a página do cursor começa no pageOffset.
    final second = textRightTwips(const RulerInfo(pageWidth: 21001, leftMargin: 2000, textWidth: 18000, pageOffset: 21502))!;
    expect(second, closeTo((21502 + 20000) * 1440 / 2540, 0.5));
  });

  test('o sino toca uma vez perto da margem, e de novo só na linha seguinte', () {
    final bell = MarginBell();
    const right = 11000.0;
    Rect at(double x, double top) => Rect.fromLTWH(x, top, 1, 280);
    expect(bell.afterTyping(at(5000, 1000), right), isFalse, reason: 'longe da margem');
    expect(bell.afterTyping(at(right - 700, 1000), right), isTrue, reason: 'a meia polegada');
    expect(bell.afterTyping(at(right - 500, 1000), right), isFalse, reason: 'já tocou nesta linha');
    // A linha seguinte (a palavra quebrou): arma de novo.
    expect(bell.afterTyping(at(1500, 1300), right), isFalse);
    expect(bell.afterTyping(at(right - 100, 1300), right), isTrue);
    // Um cursor longe demais (outra coluna, outra página) não toca.
    expect(MarginBell().afterTyping(at(right + 5000, 1000), right), isFalse);
  });

  test('as preferências dos sons: desligados por padrão, e o volume entre 0 e 1', () {
    final dir = Directory.systemTemp.createTempSync('quill-som-');
    addTearDown(() => dir.deleteSync(recursive: true));
    final f = File('${dir.path}/preferencias.json');
    expect(Settings(f).typewriterSound, isFalse);
    Settings(f)
      ..typewriterSound = true
      ..typewriterVolume = 3;
    final back = Settings(f);
    expect(back.typewriterSound, isTrue);
    expect(back.typewriterVolume, 1);
  });
}
