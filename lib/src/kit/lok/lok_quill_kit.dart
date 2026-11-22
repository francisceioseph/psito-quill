// O adaptador da porta QuillKit para o LibreOfficeKit (pelo plugin nativo).
import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Rect;

import 'package:psito_quill_kit/psito_quill_kit.dart';

import '../quill_kit.dart';
import 'lo_profile.dart';
import 'lok_payloads.dart';

class LokQuillKit implements QuillKit {
  LokQuillKit({
    required this.profile,
    this.installPath = '/usr/lib/libreoffice/program',
    this.tileSlots = 128,
    NativeQuillKit? native,
  }) : _native = native ?? NativeQuillKit.open();

  final LoProfile profile;
  final String installPath;

  /// 128 vagas × 256 KB = 32 MB de ladrilhos, fixos.
  final int tileSlots;
  final NativeQuillKit _native;
  final _events = StreamController<KitEvent>.broadcast();
  StreamSubscription<RawKitEvent>? _sub;

  @override
  Stream<KitEvent> get events => _events.stream;

  @override
  int get tileSize => _native.tileSize;

  @override
  void start() {
    _sub ??= _native.events.listen((e) {
      final event = translate(e.type, e.payload);
      if (event != null) _events.add(event);
    });
    _native.init(installPath: installPath, profileUrl: profile.url, tileSlots: tileSlots);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _native.shutdown();
    _events.close();
  }

  @override
  int textureId(int slot) => _native.textureId(slot);

  @override
  void open(String path) => _native.open(path);

  @override
  void close() => _native.close();

  @override
  void setViewport(int scaleMilli, Rect v) =>
      _native.setViewport(scaleMilli, v.left.round(), v.top.round(), v.width.round(), v.height.round());

  @override
  void repaintAll() => _native.repaintAll();

  @override
  void postKey(KeyEventType type, {int charCode = 0, int keyCode = 0}) => _native.postKey(
      type == KeyEventType.input
          ? LibreOfficeKitKeyEventType.LOK_KEYEVENT_KEYINPUT
          : LibreOfficeKitKeyEventType.LOK_KEYEVENT_KEYUP,
      charCode,
      keyCode);

  @override
  void postMouse(MouseEventType type, int x, int y, {int count = 1, int buttons = 1, int modifier = 0}) =>
      _native.postMouse(
          switch (type) {
            MouseEventType.down => LibreOfficeKitMouseEventType.LOK_MOUSEEVENT_MOUSEBUTTONDOWN,
            MouseEventType.up => LibreOfficeKitMouseEventType.LOK_MOUSEEVENT_MOUSEBUTTONUP,
            MouseEventType.move => LibreOfficeKitMouseEventType.LOK_MOUSEEVENT_MOUSEMOVE,
          },
          x,
          y,
          count,
          buttons,
          modifier);

  @override
  void uno(String command, [String argsJson = '']) => _native.uno(command, argsJson);

  @override
  void saveAs(String path, String format) => _native.saveAs(path, format);

  @override
  void runLua(String source, String name, {int memoryLimit = 16 << 20, int instructionLimit = 10000000}) =>
      _native.luaRun(source, name, memoryLimit: memoryLimit, instructionLimit: instructionLimit);

  @override
  int get residentBytes => _native.residentBytes;

  @override
  KeyLatencyStats keyLatency() {
    final l = _native.keyLatency();
    return KeyLatencyStats(l.samples, l.p50, l.p95, l.max);
  }

  @override
  void resetKeyLatency() => _native.resetKeyLatency();

  @override
  double debugTilesLuma() => _native.debugTilesLuma();

  /// Evento cru → evento tipado. Público para os testes.
  static KitEvent? translate(int type, String payload) {
    switch (type) {
      case PqkEvent.PQK_EVENT_READY:
        return KitReady(payload);
      case PqkEvent.PQK_EVENT_INIT_FAILED:
        return KitFailed(payload);
      case PqkEvent.PQK_EVENT_OPENED:
        return DocumentOpened(parseOpened(payload));
      case PqkEvent.PQK_EVENT_OPEN_FAILED:
        return DocumentOpenFailed(payload);
      case PqkEvent.PQK_EVENT_TILE:
        return parseTilePlaced(payload);
      case PqkEvent.PQK_EVENT_CLOSED:
        return const DocumentClosed();
      case PqkEvent.PQK_EVENT_SAVED:
        return DocumentSaved(payload);
      case PqkEvent.PQK_EVENT_SAVE_FAILED:
        return SaveFailed(payload);
      case PqkEvent.PQK_EVENT_LUA_LOG:
        return PluginLog(payload);
      case PqkEvent.PQK_EVENT_LUA_DONE:
        final json = jsonDecode(payload) as Map<String, dynamic>;
        return PluginFinished(ok: json['ok'] == true, error: '${json['error'] ?? ''}');
      case LibreOfficeKitCallbackType.LOK_CALLBACK_INVALIDATE_VISIBLE_CURSOR:
        return CursorMoved(parseCursor(payload));
      case LibreOfficeKitCallbackType.LOK_CALLBACK_CURSOR_VISIBLE:
        return CursorVisibility(payload.trim() == 'true');
      case LibreOfficeKitCallbackType.LOK_CALLBACK_TEXT_SELECTION:
        return SelectionChanged(parseSelection(payload));
      case LibreOfficeKitCallbackType.LOK_CALLBACK_STATE_CHANGED:
        final s = parseCommandState(payload);
        return s == null ? OtherKitEvent(type, payload) : CommandStateChanged(s.$1, s.$2);
      case LibreOfficeKitCallbackType.LOK_CALLBACK_DOCUMENT_SIZE_CHANGED:
        final size = parseDocumentSize(payload);
        return size == null ? null : DocumentSizeChanged(size);
    }
    return OtherKitEvent(type, payload);
  }
}
