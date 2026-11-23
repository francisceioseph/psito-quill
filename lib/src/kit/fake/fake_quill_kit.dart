// Um motor de mentira para os testes: responde na hora, sem LibreOffice.
//
// Guarda o que recebeu (teclas, comandos, salvamentos) para os testes
// conferirem, e simula o essencial com um texto de uma linha só: digitar,
// pré-edição do IME, desfazer, seleção, copiar e colar, negrito, o estado
// "modificado", ladrilhos da área visível e salvar.
import 'dart:async';
import 'dart:ui' show Rect, Size;

import '../quill_kit.dart';

class FakeQuillKit implements QuillKit {
  FakeQuillKit({this.documentSize = const Size(12474, 16838 * 3), this.failStart = false, this.openFails = false});

  /// Três páginas A4 em twips, por padrão.
  final Size documentSize;
  final bool failStart;
  bool openFails;

  final _events = StreamController<KitEvent>.broadcast(sync: true);
  final keys = <(KeyEventType, int, int)>[];
  final mice = <(MouseEventType, int, int, int)>[];
  final unoCommands = <String>[];
  final unoArgs = <String>[];
  final saved = <(String, String)>[];
  final luaRuns = <String>[];
  final viewports = <(int, Rect)>[];
  final opened = <String>[];
  final pasted = <String>[];
  int trims = 0;
  String? openedPath;

  /// O texto do documento, e a pré-edição do IME (ainda fora dele).
  String text = '';
  String preedit = '';

  /// O que [requestTextSelection] responde (os testes escolhem).
  String selectedText = '';
  bool bold = false;
  bool disposed = false;
  final _undo = <String>[];
  final _redo = <String>[];
  final _placed = <TileKey, int>{};
  int _nextSlot = 0;

  @override
  Stream<KitEvent> get events => _events.stream;

  // O stream é síncrono (os testes veem o efeito na hora). Um ouvinte que
  // chama o kit de dentro de um evento enfileira a resposta, como no motor
  // de verdade, em vez de disparar no meio do outro.
  final _pending = <KitEvent>[];
  bool _firing = false;

  void _emit(KitEvent e) {
    if (_events.isClosed) return;
    _pending.add(e);
    if (_firing) return;
    _firing = true;
    try {
      while (_pending.isNotEmpty) {
        _events.add(_pending.removeAt(0));
      }
    } finally {
      _firing = false;
    }
  }

  @override
  int get tileSize => 256;

  @override
  void start() =>
      _emit(failStart ? const KitFailed('sem LibreOffice') : const KitReady('{"ProductVersion":"falso"}'));

  @override
  void dispose() {
    disposed = true;
    _events.close();
  }

  @override
  int textureId(int slot) => -1;

  @override
  void open(String path) {
    opened.add(path);
    if (openFails) {
      _emit(const DocumentOpenFailed('arquivo estragado'));
      return;
    }
    openedPath = path;
    text = '';
    preedit = '';
    _undo.clear();
    _redo.clear();
    _placed.clear();
    // Como o LOK: ao abrir, manda onde está o cursor, mas não manda o
    // "cursor visível" (esse só chega depois da primeira tecla).
    _emit(DocumentOpened(documentSize));
    _state('.uno:ModifiedStatus', 'false');
    _state('.uno:Undo', 'disabled');
    _state('.uno:Redo', 'disabled');
    _state('.uno:StatePageNumber', 'Página 1 de 3');
    _state('.uno:StateWordCount', '0 palavras, 0 caracteres');
    _state('.uno:StyleApply', 'Estilo de parágrafo padrão');
    _emitCursor();
  }

  @override
  void close() {
    openedPath = null;
    _emit(const DocumentClosed());
  }

  @override
  void setViewport(int scaleMilli, Rect visible) {
    viewports.add((scaleMilli, visible));
    final side = 256 * twipsPerPixel * 1000 / scaleMilli;
    final c0 = (visible.left / side).floor().clamp(0, 1 << 20);
    final r0 = (visible.top / side).floor().clamp(0, 1 << 20);
    final c1 = ((visible.right - 1) / side).floor();
    final r1 = ((visible.bottom - 1) / side).floor();
    for (var r = r0; r <= r1; r++) {
      for (var c = c0; c <= c1; c++) {
        final key = TileKey(c, r, scaleMilli);
        if (_placed.containsKey(key)) continue;
        final slot = _nextSlot++;
        _placed[key] = slot;
        _emit(TilePlaced(slot, key));
      }
    }
  }

  @override
  void repaintAll() {}

  @override
  void postKey(KeyEventType type, {int charCode = 0, int keyCode = 0}) {
    keys.add((type, charCode, keyCode));
    if (type != KeyEventType.input) return;
    if (charCode == 8 && text.isNotEmpty) {
      _edit(text.substring(0, text.length - 1));
    } else if (charCode >= 0x20) {
      _edit(text + String.fromCharCode(charCode));
    }
  }

  @override
  void extTextInput(String text, {required bool commit}) {
    if (commit) {
      preedit = '';
      _edit(this.text + text);
    } else {
      preedit = text;
      _emitCursor();
    }
  }

  /// As fontes que o falso diz ter.
  List<String> fonts = const ['Liberation Sans', 'Liberation Serif', 'Noto Serif'];

  @override
  void requestCommandValues(String command) {
    if (command != '.uno:CharFontName') return;
    final entries = fonts.map((f) => '"$f": ["12"]').join(',');
    _emit(CommandValues(command, '{"commandName":"$command","commandValues":{"":{$entries}}}'));
  }

  @override
  void requestTextSelection() => _emit(TextSelectionContent(selectedText));

  @override
  void pasteText(String text) {
    pasted.add(text);
    _edit(this.text + text);
  }

  @override
  void trimMemory() => trims++;

  void _edit(String next) {
    _undo.add(text);
    _redo.clear();
    text = next;
    _afterEdit();
  }

  void _afterEdit() {
    _state('.uno:ModifiedStatus', 'true');
    _state('.uno:Undo', _undo.isEmpty ? 'disabled' : 'enabled');
    _state('.uno:Redo', _redo.isEmpty ? 'disabled' : 'enabled');
    final words = text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
    _state('.uno:StateWordCount', '$words palavras, ${text.length} caracteres');
    _emitCursor();
  }

  void _state(String command, String value) => _emit(CommandStateChanged(command, value));

  void _emitCursor() =>
      _emit(CursorMoved(Rect.fromLTWH(1440 + (text.length + preedit.length) * 120.0, 1440, 20, 280)));

  @override
  void postMouse(MouseEventType type, int x, int y, {int count = 1, int buttons = 1, int modifier = 0}) =>
      mice.add((type, x, y, count));

  @override
  void uno(String command, [String argsJson = '']) {
    unoCommands.add(command);
    unoArgs.add(argsJson);
    switch (command) {
      case '.uno:Bold':
        bold = !bold;
        _state('.uno:Bold', '$bold');
      case '.uno:Undo' when _undo.isNotEmpty:
        _redo.add(text);
        text = _undo.removeLast();
        _afterEdit();
      case '.uno:Redo' when _redo.isNotEmpty:
        _undo.add(text);
        text = _redo.removeLast();
        _afterEdit();
      case '.uno:Cut':
        if (selectedText.isNotEmpty && text.endsWith(selectedText)) {
          _edit(text.substring(0, text.length - selectedText.length));
        }
      case '.uno:Paste':
        _edit(text + selectedText);
    }
  }

  @override
  void saveAs(String path, String format) {
    saved.add((path, format));
    _emit(DocumentSaved(path));
    _state('.uno:ModifiedStatus', 'false');
  }

  @override
  void runLua(String source, String name, {int memoryLimit = 16 << 20, int instructionLimit = 10000000}) {
    luaRuns.add(name);
    final m = RegExp(r'psito\.log\("([^"]*)"\)').firstMatch(source);
    if (m != null) _emit(PluginLog(m.group(1)!));
    _emit(const PluginFinished(ok: true));
  }

  /// Para os testes: um evento qualquer, como se viesse do motor.
  void emit(KitEvent e) => _emit(e);

  /// Para os testes: um estado qualquer, como se viesse do motor.
  void emitState(String command, String value) => _state(command, value);

  @override
  int get residentBytes => 100 << 20;

  @override
  KeyLatencyStats keyLatency() => const KeyLatencyStats(0, Duration.zero, Duration.zero, Duration.zero);

  @override
  void resetKeyLatency() {}

  @override
  double debugTilesLuma() => -1;
}
