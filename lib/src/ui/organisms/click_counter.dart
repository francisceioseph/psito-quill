// Cliques seguidos → o que o LibreOffice seleciona.
//
// Medido na 24.2: no Writer, 2 cliques selecionam a palavra, 3 a frase e 4 o
// parágrafo. No Word, o clique triplo seleciona o parágrafo, e o Ctrl+clique
// a frase. O Quill segue o Word (D-028).
import 'dart:ui' show Offset;

class ClickCounter {
  ClickCounter({this.interval = const Duration(milliseconds: 500), this.slop = 6});

  /// Tempo máximo entre um clique e o próximo da mesma série. O padrão do
  /// GTK é 400 ms; 500 perdoa quem clica devagar.
  final Duration interval;

  /// Quanto o mouse pode andar entre os cliques da série, em pixels.
  final double slop;

  DateTime _last = DateTime(0);
  Offset _lastPos = Offset.zero;
  int _clicks = 0;

  /// Registra um botão apertado e devolve quantos cliques seguidos já são
  /// (1, 2 ou 3; o quarto recomeça).
  int down(DateTime now, Offset position) {
    final sameSeries = now.difference(_last) <= interval && (position - _lastPos).distance <= slop;
    _clicks = sameSeries ? (_clicks % 3) + 1 : 1;
    _last = now;
    _lastPos = position;
    return _clicks;
  }

  int get clicks => _clicks;
}

/// A contagem que vai para o LibreOffice: o triplo vira 4 (parágrafo), e o
/// Ctrl+clique vira 3 (frase).
int lokClickCount(int clicks, {required bool control}) {
  if (clicks == 1 && control) return 3;
  return clicks == 3 ? 4 : clicks;
}
