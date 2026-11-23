import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/ui/organisms/click_counter.dart';

void main() {
  final t0 = DateTime(2026, 11, 22, 10);
  Duration ms(int n) => Duration(milliseconds: n);

  test('cliques seguidos no mesmo lugar contam 1, 2, 3 e recomeçam', () {
    final c = ClickCounter();
    expect([for (var i = 0; i < 4; i++) c.down(t0.add(ms(200 * i)), Offset.zero)], [1, 2, 3, 1]);
  });

  test('quem clica devagar (até 500 ms) ainda faz clique duplo', () {
    final c = ClickCounter()..down(t0, Offset.zero);
    expect(c.down(t0.add(ms(480)), Offset.zero), 2);
    expect(c.down(t0.add(ms(480 + 501)), Offset.zero), 1);
  });

  test('o mouse andou: recomeça', () {
    final c = ClickCounter()..down(t0, Offset.zero);
    expect(c.down(t0.add(ms(100)), const Offset(10, 0)), 1);
    expect(c.down(t0.add(ms(200)), const Offset(13, 4)), 2, reason: 'dentro da folga de 6 px');
  });

  test('para o LibreOffice: triplo é 4 (parágrafo), Ctrl+clique é 3 (frase)', () {
    expect(lokClickCount(1, control: false), 1);
    expect(lokClickCount(2, control: false), 2);
    expect(lokClickCount(3, control: false), 4);
    expect(lokClickCount(1, control: true), 3);
  });
}
