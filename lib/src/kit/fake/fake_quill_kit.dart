// Um motor de mentira para os testes: responde na hora, sem LibreOffice.
//
// Guarda o que recebeu (teclas, comandos, salvamentos) para os testes
// conferirem, e simula o essencial: abrir, ladrilhos da área visível, cursor
// andando com o texto, negrito e salvar.
import 'dart:async';
import 'dart:ui' show Rect, Size;

import '../quill_kit.dart';

class FakeQuillKit implements QuillKit {
  FakeQuillKit({this.documentSize = const Size(12474, 16838 * 3), this.failStart = false});

  /// Três páginas A4 em twips, por padrão.
  final Size documentSize;
  final bool failStart;

  final _events = StreamController<KitEvent>.broadcast(sync: true);
  final keys = <(KeyEventType, int, int)>[];
  final mice = <(MouseEventType, int, int)>[];
  final unoCommands = <String>[];
  final saved = <(String, String)>[];
  final luaRuns = <String>[];
  final viewports = <(int, Rect)>[];
  String? openedPath;
  var text = StringBuffer();
  bool bold = false;
  bool disposed = false;
  final _placed = <TileKey, int>{};
  int _nextSlot = 0;

  @override
  Stream<KitEvent> get events => _events.stream;

  @override
  int get tileSize => 256;

  @override
  void start() =>
      _events.add(failStart ? const KitFailed('sem LibreOffice') : const KitReady('{"ProductVersion":"falso"}'));

  @override
  void dispose() {
    disposed = true;
    _events.close();
  }

  @override
  int textureId(int slot) => -1;

  @override
  void open(String path) {
    openedPath = path;
    text = StringBuffer();
    _placed.clear();
    _events.add(DocumentOpened(documentSize));
    _events.add(const CursorVisibility(true));
    _emitCursor();
  }

  @override
  void close() {
    openedPath = null;
    _events.add(const DocumentClosed());
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
        _events.add(TilePlaced(slot, key));
      }
    }
  }

  @override
  void repaintAll() {}

  @override
  void postKey(KeyEventType type, {int charCode = 0, int keyCode = 0}) {
    keys.add((type, charCode, keyCode));
    if (type == KeyEventType.input && charCode >= 0x20) {
      text.writeCharCode(charCode);
      _emitCursor();
    }
  }

  void _emitCursor() =>
      _events.add(CursorMoved(Rect.fromLTWH(1440 + text.length * 120.0, 1440, 20, 280)));

  @override
  void postMouse(MouseEventType type, int x, int y, {int count = 1, int buttons = 1, int modifier = 0}) =>
      mice.add((type, x, y));

  @override
  void uno(String command, [String argsJson = '']) {
    unoCommands.add(command);
    if (command == '.uno:Bold') {
      bold = !bold;
      _events.add(CommandStateChanged('.uno:Bold', '$bold'));
    }
  }

  @override
  void saveAs(String path, String format) {
    saved.add((path, format));
    _events.add(DocumentSaved(path));
  }

  @override
  void runLua(String source, String name, {int memoryLimit = 16 << 20, int instructionLimit = 10000000}) {
    luaRuns.add(name);
    final m = RegExp(r'psito\.log\("([^"]*)"\)').firstMatch(source);
    if (m != null) _events.add(PluginLog(m.group(1)!));
    _events.add(const PluginFinished(ok: true));
  }

  @override
  int get residentBytes => 100 << 20;

  @override
  KeyLatencyStats keyLatency() => const KeyLatencyStats(0, Duration.zero, Duration.zero, Duration.zero);

  @override
  void resetKeyLatency() {}

  @override
  double debugTilesLuma() => -1;
}
