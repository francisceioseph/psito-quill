// Uma aba de documento (D-054): o que o DocumentController guarda de um
// documento enquanto outro está na tela.
//
// Memento: o controlador copia os campos dele para cá ao trocar de aba e de
// volta ao voltar. A aba da tela não usa estes campos: os de verdade estão no
// controlador (DocumentController.tabPath e tabModified leem os dois).
import 'dart:ui' show Offset, Rect, Size;

import '../kit/quill_kit.dart';
import 'fodt.dart';

/// O estado de um documento, na ordem em que o controlador o lê.
enum DocStatus { none, opening, open, failed }

class DocTab {
  DocTab(this.serial);

  /// Único na sessão: a chave do widget da aba.
  final int serial;

  /// O número do documento no motor; null enquanto abre ou depois que o
  /// limite o fechou (a aba guarda só o caminho, o zoom e a rolagem).
  int? engineId;

  /// Quando foi a aba da tela pela última vez (para o limite).
  int lastUsed = 0;

  DocStatus status = DocStatus.opening;
  String? path, openingPath, lockOwner;
  bool readOnly = false;
  Size documentSize = Size.zero;
  Rect cursor = Rect.zero;
  bool cursorVisible = false;
  List<Rect> selection = const [];
  Map<String, String> commandStates = const {};
  RulerInfo? ruler;
  List<String> paragraphStyles = const [], characterStyles = const [];
  Rect? graphic;
  bool inTable = false;
  double zoom = 1.0;
  int viewColumns = 1;
  bool bookMode = false;
  FodtSnapshot snapshot = FodtSnapshot.empty;
  bool editedSinceCopy = false;

  /// A rolagem da página (pixels lógicos), que a vista devolve ao voltar.
  Offset scroll = Offset.zero;

  bool get modified => commandStates['.uno:ModifiedStatus'] == 'true';
}
