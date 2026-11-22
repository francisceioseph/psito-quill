import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/kit/lok/vcl_keys.dart';

KeyDownEvent _down(LogicalKeyboardKey key, PhysicalKeyboardKey physical, {String? character}) =>
    KeyDownEvent(physicalKey: physical, logicalKey: key, character: character, timeStamp: Duration.zero);

VclKeyStroke? _map(KeyEvent e, {bool shift = false, bool control = false, bool alt = false}) =>
    vclKeyFor(e, shift: shift, control: control, alt: alt);

void main() {
  test('letra vira o caractere, já com acento e maiúscula do layout', () {
    expect(_map(_down(LogicalKeyboardKey.keyA, PhysicalKeyboardKey.keyA, character: 'a')), const VclKeyStroke(0x61, 0));
    expect(_map(_down(LogicalKeyboardKey.keyA, PhysicalKeyboardKey.keyA, character: 'A'), shift: true),
        const VclKeyStroke(0x41, 0));
    expect(_map(_down(LogicalKeyboardKey.semicolon, PhysicalKeyboardKey.semicolon, character: 'ç')),
        const VclKeyStroke(0xE7, 0));
  });

  test('espaço leva o código da tecla junto', () {
    expect(_map(_down(LogicalKeyboardKey.space, PhysicalKeyboardKey.space, character: ' ')),
        const VclKeyStroke(0x20, VclKey.space));
  });

  test('teclas especiais têm o código do VCL', () {
    expect(_map(_down(LogicalKeyboardKey.enter, PhysicalKeyboardKey.enter)), const VclKeyStroke(13, VclKey.enter));
    expect(_map(_down(LogicalKeyboardKey.backspace, PhysicalKeyboardKey.backspace)),
        const VclKeyStroke(8, VclKey.backspace));
    expect(_map(_down(LogicalKeyboardKey.arrowLeft, PhysicalKeyboardKey.arrowLeft), shift: true),
        const VclKeyStroke(0, VclKey.left | VclKey.shift));
    expect(_map(_down(LogicalKeyboardKey.f5, PhysicalKeyboardKey.f5)), const VclKeyStroke(0, VclKey.f1 + 4));
  });

  test('com Ctrl vai o código da letra, sem caractere', () {
    expect(_map(_down(LogicalKeyboardKey.keyZ, PhysicalKeyboardKey.keyZ, character: 'z'), control: true),
        const VclKeyStroke(0, (VclKey.a + 25) | VclKey.mod1));
    expect(_map(_down(LogicalKeyboardKey.digit1, PhysicalKeyboardKey.digit1, character: '1'), control: true, alt: true),
        const VclKeyStroke(0, (VclKey.num0 + 1) | VclKey.mod1 | VclKey.mod2));
  });

  test('modificador sozinho não vai para o motor', () {
    expect(_map(_down(LogicalKeyboardKey.shiftLeft, PhysicalKeyboardKey.shiftLeft), shift: true), isNull);
  });
}
