// Os sons da máquina de escrever (D-095): qual som cada texto e cada tecla
// fazem, e o sino que toca perto da margem direita, como numa máquina de
// verdade. Tocar é o plugin (`QuillKit.playTypewriterSound`); aqui é só a
// escolha, sem estado além do sino da linha.
import 'dart:ui' show Rect;

import '../kit/lok/vcl_keys.dart';
import '../kit/quill_kit.dart';

/// O som do texto confirmado (a tecla ou o IME). O espaço tem o seu; o
/// resto, a tecla. null: nada (o texto vazio do fim de uma composição).
TypewriterSound? soundForText(String text) {
  if (text.isEmpty) return null;
  return text.endsWith(' ') || text.endsWith(' ') ? TypewriterSound.space : TypewriterSound.key;
}

/// O som de uma tecla que vai ao motor pelo código do VCL: o Enter é o
/// retorno do carro, o Backspace e o Delete voltam o carro, o Tab é o
/// espaço. As setas e o resto não fazem som (não batem no papel).
TypewriterSound? soundForVclKey(int keyCode) => switch (keyCode & 0x0FFF) {
      VclKey.enter => TypewriterSound.carriageReturn,
      VclKey.backspace || VclKey.delete => TypewriterSound.backspace,
      VclKey.tab => TypewriterSound.space,
      _ => null,
    };

/// Os twips por centésimo de milímetro.
const double _twipsPerMm100 = 1440 / 2540;

/// O vão em volta das páginas (os 284 twips do motor), quando a régua não
/// diz onde a página começa.
const double _pageGapTwips = 284;

/// A borda direita da área do texto da página do cursor, em twips do
/// documento, pela régua do motor. null sem régua.
double? textRightTwips(RulerInfo? ruler) {
  if (ruler == null || ruler.textWidth <= 0) return null;
  final pageLeft = ruler.pageOffset == null ? _pageGapTwips : ruler.pageOffset! * _twipsPerMm100;
  return pageLeft + (ruler.leftMargin + ruler.textWidth) * _twipsPerMm100;
}

/// O sino perto da margem: numa máquina de escrever, ele toca uns oito
/// caracteres antes do fim da linha, para quem datilografa saber que é hora
/// de terminar a palavra. Aqui, quando o cursor passa a meia polegada da
/// margem direita digitando, uma vez por linha. Uma linha nova (o texto
/// quebrou, ou o Enter) arma o sino de novo.
class MarginBell {
  /// Meia polegada, em twips: uns oito caracteres numa fonte de 12 pt.
  static const warningTwips = 720.0;

  double? _lineTop;
  bool _rung = false;

  /// Depois de digitar, com o cursor em [cursor] (twips) e a margem em
  /// [right] (twips): true se o sino toca agora.
  bool afterTyping(Rect cursor, double right) {
    final top = _lineTop;
    if (top == null || (cursor.top - top).abs() > cursor.height / 2) {
      _lineTop = cursor.top;
      _rung = false;
    }
    if (_rung || cursor.left < right - warningTwips || cursor.left > right + warningTwips) return false;
    _rung = true;
    return true;
  }
}
