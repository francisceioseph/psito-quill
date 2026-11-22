// O estado do documento aberto, montado a partir dos eventos do motor.
//
// Observer: a UI escuta este ChangeNotifier, e ele escuta o QuillKit. Nada
// aqui é adivinhado: o negrito ativo, o cursor e o tamanho vêm do motor.
import 'dart:async';
import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter/foundation.dart';

import '../kit/quill_kit.dart';

enum KitStatus { starting, ready, failed }

enum DocStatus { none, opening, open, failed }

/// Onde a vaga de ladrilho aparece.
class TilePlacement {
  const TilePlacement(this.slot, this.key, this.textureId);
  final int slot;
  final TileKey key;
  final int textureId;
}

/// Mensagens para a barra de status (o texto final vem da l10n).
sealed class DocMessage {
  const DocMessage();
}

class SavedMessage extends DocMessage {
  const SavedMessage(this.path);
  final String path;
}

class ErrorMessage extends DocMessage {
  const ErrorMessage(this.detail);
  final String detail;
}

class PluginMessage extends DocMessage {
  const PluginMessage(this.text);
  final String text;
}

class DocumentController extends ChangeNotifier {
  DocumentController(this.kit) {
    _sub = kit.events.listen(_onEvent);
  }

  final QuillKit kit;
  late final StreamSubscription<KitEvent> _sub;

  KitStatus kitStatus = KitStatus.starting;
  String engineVersion = '';
  DocStatus docStatus = DocStatus.none;
  String? path;

  /// Tamanho do documento em twips.
  Size documentSize = Size.zero;
  Rect cursor = Rect.zero;
  bool cursorVisible = false;
  List<Rect> selection = const [];
  final Map<String, String> commandStates = {};
  bool modified = false;
  DocMessage? message;

  /// A escala atual (pixels físicos por lógico × zoom) × 1000.
  int scaleMilli = 1000;
  final Map<int, TilePlacement> _tiles = {};

  /// Os ladrilhos da escala atual, para desenhar.
  Iterable<TilePlacement> get tiles => _tiles.values.where((t) => t.key.scaleMilli == scaleMilli);

  bool isOn(String command) => commandStates[command] == 'true';

  void start() => kit.start();

  void open(String path) {
    this.path = path.isEmpty ? null : path;
    docStatus = DocStatus.opening;
    _tiles.clear();
    selection = const [];
    commandStates.clear();
    modified = false;
    notifyListeners();
    kit.open(path);
  }

  /// Fecha o documento no motor e espera a confirmação. O LibreOffice deixa
  /// uma trava (.~lock) ao lado do arquivo enquanto está aberto; sair sem
  /// fechar deixa a trava, e a próxima abertura pode vir só para leitura.
  Future<void> close({Duration timeout = const Duration(seconds: 3)}) async {
    if (docStatus == DocStatus.none) return;
    final closed = kit.events.firstWhere((e) => e is DocumentClosed);
    kit.close();
    await closed.timeout(timeout, onTimeout: () => const DocumentClosed());
  }

  /// A área visível mudou (rolagem, tamanho da janela, escala).
  void setViewport(Rect visibleTwips, int scaleMilli) {
    if (scaleMilli != this.scaleMilli) {
      this.scaleMilli = scaleMilli;
      notifyListeners();
    }
    if (docStatus == DocStatus.open) kit.setViewport(scaleMilli, visibleTwips);
  }

  void postKey(int charCode, int keyCode) {
    kit.postKey(KeyEventType.input, charCode: charCode, keyCode: keyCode);
    kit.postKey(KeyEventType.up, charCode: charCode, keyCode: keyCode);
    modified = true;
  }

  void postMouse(MouseEventType type, Offset twips, {int count = 1, int buttons = 1, int modifier = 0}) =>
      kit.postMouse(type, twips.dx.round(), twips.dy.round(), count: count, buttons: buttons, modifier: modifier);

  void uno(String command, [String args = '']) {
    kit.uno(command, args);
    modified = true;
  }

  /// Salva por cima, no formato do próprio arquivo.
  bool save() {
    final p = path;
    if (p == null) return false;
    final dot = p.lastIndexOf('.');
    kit.saveAs(p, dot < 0 ? 'odt' : p.substring(dot + 1).toLowerCase());
    return true;
  }

  /// Troca o esquema de cor do papel ("PsitoQuillEscuro", por exemplo).
  void setPaperScheme(String name) {
    kit.uno('.uno:ChangeTheme', '{"NewTheme":{"type":"string","value":"$name"}}');
    kit.repaintAll();
  }

  void _onEvent(KitEvent e) {
    switch (e) {
      case KitReady(:final version):
        kitStatus = KitStatus.ready;
        engineVersion = version;
      case KitFailed(:final message):
        kitStatus = KitStatus.failed;
        this.message = ErrorMessage(message);
      case DocumentOpened(:final size):
        docStatus = DocStatus.open;
        documentSize = size;
      case DocumentOpenFailed(:final message):
        docStatus = DocStatus.failed;
        this.message = ErrorMessage(message);
      case DocumentClosed():
        docStatus = DocStatus.none;
        _tiles.clear();
        path = null;
      case DocumentSizeChanged(:final size):
        documentSize = size;
      case TilePlaced(:final slot, :final key):
        _tiles[slot] = TilePlacement(slot, key, kit.textureId(slot));
      case CursorMoved(:final rect):
        cursor = rect;
      case CursorVisibility(:final visible):
        cursorVisible = visible;
      case SelectionChanged(:final rects):
        selection = rects;
      case CommandStateChanged(:final command, :final value):
        if (commandStates[command] == value) return;
        commandStates[command] = value;
      case DocumentSaved(:final path):
        modified = false;
        message = SavedMessage(path);
      case SaveFailed(:final message):
        this.message = ErrorMessage(message);
      case PluginLog(:final text):
        message = PluginMessage(text);
      case PluginFinished(:final ok, :final error):
        if (!ok) message = ErrorMessage(error);
      case OtherKitEvent():
        return;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
