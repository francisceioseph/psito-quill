// O estado do documento aberto, montado a partir dos eventos do motor.
//
// Observer: a UI escuta este ChangeNotifier, e ele escuta o QuillKit. Nada
// aqui é adivinhado: o negrito ativo, o cursor, o "modificado", o desfazer
// e a página vêm do motor.
import 'dart:async';
import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter/foundation.dart';

import '../kit/lok/lok_payloads.dart';
import '../kit/quill_kit.dart';
import 'text_clipboard.dart';

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

class OpenFailedMessage extends DocMessage {
  const OpenFailedMessage(this.path, this.detail);
  final String path, detail;
}

class PluginMessage extends DocMessage {
  const PluginMessage(this.text);
  final String text;
}

/// Os limites do zoom.
const double minZoom = 0.5, maxZoom = 3.0;

class DocumentController extends ChangeNotifier {
  DocumentController(this.kit, {TextClipboard? clipboard}) : clipboard = clipboard ?? const SystemTextClipboard() {
    _sub = kit.events.listen(_onEvent);
  }

  final QuillKit kit;
  final TextClipboard clipboard;
  late final StreamSubscription<KitEvent> _sub;

  KitStatus kitStatus = KitStatus.starting;
  String engineVersion = '';
  DocStatus docStatus = DocStatus.none;

  /// O arquivo do documento. null: um documento novo, ainda sem arquivo.
  String? path;
  String? _openingPath;

  /// Aberto só para leitura porque outro está com o arquivo ([lockOwner]).
  bool readOnly = false;
  String? lockOwner;

  /// Tamanho do documento em twips.
  Size documentSize = Size.zero;
  Rect cursor = Rect.zero;
  bool cursorVisible = false;
  List<Rect> selection = const [];
  final Map<String, String> commandStates = {};
  DocMessage? message;

  /// As fontes instaladas (do motor), em ordem.
  List<String> fonts = const [];

  /// O zoom da página (1 = 100 %).
  double zoom = 1.0;

  /// A escala atual (pixels físicos por lógico × zoom) × 1000.
  int scaleMilli = 1000;
  final Map<int, TilePlacement> _tiles = {};

  /// Os ladrilhos da escala atual, para desenhar.
  Iterable<TilePlacement> get tiles => _tiles.values.where((t) => t.key.scaleMilli == scaleMilli);

  /// Os da escala anterior (antes do último zoom), que a página desenha
  /// esticados por baixo até os novos chegarem. Saem quando a vaga é reusada.
  Iterable<TilePlacement> get staleTiles =>
      _previousScale == null ? const [] : _tiles.values.where((t) => t.key.scaleMilli == _previousScale);
  int? _previousScale;

  bool isOn(String command) => commandStates[command] == 'true';
  bool _enabled(String command) => commandStates[command] == 'enabled';

  bool get isOpen => docStatus == DocStatus.open;
  bool get canEdit => isOpen && !readOnly;
  bool get modified => isOn('.uno:ModifiedStatus');
  bool get canUndo => canEdit && _enabled('.uno:Undo');
  bool get canRedo => canEdit && _enabled('.uno:Redo');
  bool get hasSelection => selection.isNotEmpty;

  /// Página do cursor e total.
  (int, int)? get page => parsePageStatus(commandStates['.uno:StatePageNumber']);
  ({int words, int characters, bool selection})? get wordCount =>
      parseWordCount(commandStates['.uno:StateWordCount']);

  /// O estilo de parágrafo do cursor, com o nome que o motor mostra.
  String? get paragraphStyle => commandStates['.uno:StyleApply'];
  String? get fontName => commandStates['.uno:CharFontName'];
  double? get fontSize => double.tryParse(commandStates['.uno:FontHeight'] ?? '');

  void start() => kit.start();

  /// [path] vazio abre um documento novo. [lockOwner]: o arquivo está com
  /// outro, e abre só para leitura.
  void open(String path, {String? lockOwner}) {
    _openingPath = path.isEmpty ? null : path;
    docStatus = DocStatus.opening;
    readOnly = lockOwner != null;
    this.lockOwner = lockOwner;
    _tiles.clear();
    _previousScale = null;
    selection = const [];
    commandStates.clear();
    message = null;
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
      _previousScale = this.scaleMilli;
      this.scaleMilli = scaleMilli;
      notifyListeners();
    }
    if (isOpen) kit.setViewport(scaleMilli, visibleTwips);
  }

  void setZoom(double value) {
    final z = (value.clamp(minZoom, maxZoom) * 20).roundToDouble() / 20; // passos de 5 %
    if (z == zoom) return;
    zoom = z;
    notifyListeners();
  }

  void zoomIn() => setZoom(zoom + 0.1);
  void zoomOut() => setZoom(zoom - 0.1);

  // ------------------------------------------------------------ edição --

  void postKey(int charCode, int keyCode) {
    if (!isOpen) return;
    kit.postKey(KeyEventType.input, charCode: charCode, keyCode: keyCode);
    kit.postKey(KeyEventType.up, charCode: charCode, keyCode: keyCode);
  }

  /// Texto confirmado pelo teclado ou pelo IME.
  void insertText(String text) {
    if (canEdit && text.isNotEmpty) kit.extTextInput(text, commit: true);
  }

  /// Pré-edição do IME (o `´` antes do `a`): aparece no documento, mas a
  /// próxima chamada a substitui.
  void composeText(String text) {
    if (canEdit) kit.extTextInput(text, commit: false);
  }

  void postMouse(MouseEventType type, Offset twips, {int count = 1, int buttons = 1, int modifier = 0}) {
    if (isOpen) kit.postMouse(type, twips.dx.round(), twips.dy.round(), count: count, buttons: buttons, modifier: modifier);
  }

  /// Um comando do motor que muda o documento. No modo só leitura, nada.
  void uno(String command, [String args = '']) {
    if (canEdit) kit.uno(command, args);
  }

  void undo() => uno('.uno:Undo');
  void redo() => uno('.uno:Redo');
  void selectAll() {
    if (isOpen) kit.uno('.uno:SelectAll');
  }

  void applyParagraphStyle(String style) => uno('.uno:StyleApply',
      '{"Style":{"type":"string","value":${_json(style)}},"FamilyName":{"type":"string","value":"ParagraphStyles"}}');

  void setFontName(String name) =>
      uno('.uno:CharFontName', '{"CharFontName.FamilyName":{"type":"string","value":${_json(name)}}}');

  void setFontSize(double points) => uno('.uno:FontHeight', '{"FontHeight.Height":{"type":"float","value":$points}}');

  static String _json(String s) => '"${s.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';

  // ---------------------------------------------- copiar, recortar, colar --
  //
  // O motor tem a própria área de transferência (com a formatação). A do
  // sistema recebe o texto simples. Ao colar: se o sistema ainda tem o que
  // o Quill copiou, cola o do motor (com a formatação); se não, o texto que
  // veio de fora.

  String? _lastCopied;
  bool _awaitingCopy = false;

  void copy() {
    if (!isOpen || !hasSelection) return;
    kit.uno('.uno:Copy');
    _awaitingCopy = true;
    kit.requestTextSelection();
  }

  void cut() {
    if (!canEdit || !hasSelection) return;
    _awaitingCopy = true;
    kit.requestTextSelection(); // antes do recorte, na fila do motor
    kit.uno('.uno:Cut');
  }

  Future<void> paste() async {
    if (!canEdit) return;
    final text = await clipboard.read();
    if (text == null || text.isEmpty) return;
    if (text == _lastCopied) {
      kit.uno('.uno:Paste');
    } else {
      kit.pasteText(text);
    }
  }

  // ------------------------------------------------------------ salvar --

  /// Salva por cima, no formato do próprio arquivo. false se não há arquivo
  /// (documento novo) ou se está só para leitura: aí é "Salvar como".
  bool save() {
    final p = path;
    if (p == null || !isOpen || readOnly) return false;
    saveAs(p);
    return true;
  }

  /// Salva em [target] e passa a ser aquele arquivo.
  void saveAs(String target) {
    if (!isOpen) return;
    final dot = target.lastIndexOf('.');
    kit.saveAs(target, dot < 0 ? 'odt' : target.substring(dot + 1).toLowerCase());
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
        path = _openingPath;
        documentSize = size;
        // O LOK manda a posição do cursor ao abrir, mas o "cursor visível"
        // só depois da primeira tecla. O cursor começa visível; só some se o
        // motor disser (com uma imagem selecionada, por exemplo).
        cursorVisible = true;
        if (fonts.isEmpty) kit.requestCommandValues('.uno:CharFontName');
      case DocumentOpenFailed(:final message):
        docStatus = DocStatus.failed;
        this.message = OpenFailedMessage(_openingPath ?? '', message);
      case DocumentClosed():
        docStatus = DocStatus.none;
        cursorVisible = false;
        _tiles.clear();
        path = null;
        readOnly = false;
        lockOwner = null;
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
      case CommandValues(:final command, :final json):
        if (command != '.uno:CharFontName') return;
        fonts = parseFontList(json);
      case TextSelectionContent(:final text):
        if (!_awaitingCopy) return;
        _awaitingCopy = false;
        if (text.isEmpty) return;
        _lastCopied = text;
        unawaited(clipboard.write(text));
        return;
      case DocumentSaved(:final path):
        this.path = path;
        readOnly = false;
        lockOwner = null;
        commandStates['.uno:ModifiedStatus'] = 'false';
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
