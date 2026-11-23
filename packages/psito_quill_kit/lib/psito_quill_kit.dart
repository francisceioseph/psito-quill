/// O lado Dart do plugin nativo: uma casca fina sobre a API C.
///
/// Não interpreta nada: devolve os eventos crus (tipo e texto). Quem dá
/// sentido a eles é o `LokQuillKit` do app, que implementa a porta
/// `QuillKit`.
library;

import 'dart:async';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'src/quill_kit_bindings.g.dart';

export 'src/quill_kit_bindings.g.dart'
    show
        PqkEvent,
        LibreOfficeKitCallbackType,
        LibreOfficeKitExtTextInputType,
        LibreOfficeKitKeyEventType,
        LibreOfficeKitMouseEventType;

/// Um evento do kit: os do LOK (tipo < 10000) e os do plugin ([PqkEvent]).
typedef _EventFn = Void Function(Int32 type, Pointer<Char> payload);

class RawKitEvent {
  const RawKitEvent(this.type, this.payload);
  final int type;
  final String payload;

  @override
  String toString() => 'RawKitEvent($type, $payload)';
}

/// Latência tecla → ladrilho pronto, medida no nativo.
class KeyLatency {
  const KeyLatency(this.samples, this.p50, this.p95, this.max);
  final int samples;
  final Duration p50, p95, max;
}

class NativeQuillKit {
  NativeQuillKit._(this._b);

  /// A biblioteca do plugin já está carregada pelo runner; abrir pelo nome
  /// devolve a mesma.
  factory NativeQuillKit.open() =>
      NativeQuillKit._(QuillKitBindings(DynamicLibrary.open('libpsito_quill_kit_plugin.so')));

  final QuillKitBindings _b;

  NativeCallable<_EventFn>? _callback;
  final _events = StreamController<RawKitEvent>.broadcast(sync: true);

  Stream<RawKitEvent> get events => _events.stream;

  /// Liga o motor. O fim chega como [PqkEvent.PQK_EVENT_READY] ou
  /// [PqkEvent.PQK_EVENT_INIT_FAILED].
  void init({required String installPath, required String profileUrl, required int tileSlots}) {
    if (_callback != null) return;
    // listener: o nativo chama de qualquer thread; o Dart recebe na dele.
    final cb = NativeCallable<_EventFn>.listener(_onEvent);
    _callback = cb;
    using((arena) {
      _b.pqk_init(installPath.toNativeUtf8(allocator: arena).cast(),
          profileUrl.toNativeUtf8(allocator: arena).cast(), tileSlots, cb.nativeFunction);
    });
  }

  void _onEvent(int type, Pointer<Char> payload) {
    final text = payload == nullptr ? '' : payload.cast<Utf8>().toDartString();
    _b.pqk_free_string(payload);
    _events.add(RawKitEvent(type, text));
  }

  void shutdown() {
    _b.pqk_shutdown();
    _callback?.close();
    _callback = null;
  }

  int get tileSlots => _b.pqk_tile_slots();
  int get tileSize => _b.pqk_tile_size();
  int textureId(int slot) => _b.pqk_tile_texture_id(slot);

  void open(String path) => _withString(path, _b.pqk_open);
  void close() => _b.pqk_close();

  void setViewport(int scaleMilli, int x, int y, int w, int h) =>
      _b.pqk_set_viewport(scaleMilli, x, y, w, h);

  void repaintAll() => _b.pqk_repaint_all();

  void postKey(int type, int charCode, int keyCode) => _b.pqk_post_key(type, charCode, keyCode);

  void postMouse(int type, int x, int y, int count, int buttons, int modifier) =>
      _b.pqk_post_mouse(type, x, y, count, buttons, modifier);

  void uno(String command, [String args = '']) => using((arena) {
        _b.pqk_uno(command.toNativeUtf8(allocator: arena).cast(),
            args.toNativeUtf8(allocator: arena).cast());
      });

  void saveAs(String path, String format, [String options = '']) => using((arena) {
        _b.pqk_save_as(path.toNativeUtf8(allocator: arena).cast(),
            format.toNativeUtf8(allocator: arena).cast(),
            options.toNativeUtf8(allocator: arena).cast());
      });

  void commandValues(String command) => _withString(command, _b.pqk_command_values);

  void luaRun(String source, String chunkName, {required int memoryLimit, required int instructionLimit}) =>
      using((arena) {
        _b.pqk_lua_run(source.toNativeUtf8(allocator: arena).cast(),
            chunkName.toNativeUtf8(allocator: arena).cast(), memoryLimit, instructionLimit);
      });

  /// Entrada composta: [type] é um [LibreOfficeKitExtTextInputType].
  void extTextInput(int type, String text) => using((arena) {
        _b.pqk_ext_text_input(type, text.toNativeUtf8(allocator: arena).cast());
      });

  /// Responde com [PqkEvent.PQK_EVENT_TEXT_SELECTION].
  void textSelection(String mime) => _withString(mime, _b.pqk_text_selection);

  void paste(String mime, String data) => using((arena) {
        _b.pqk_paste(mime.toNativeUtf8(allocator: arena).cast(), data.toNativeUtf8(allocator: arena).cast());
      });

  void trimMemory(int target) => _b.pqk_trim_memory(target);

  void setWindowTitle(String title) => _withString(title, _b.pqk_set_window_title);

  int get residentBytes => _b.pqk_resident_bytes();

  KeyLatency keyLatency() => using((arena) {
        final p50 = arena<Int64>(), p95 = arena<Int64>(), max = arena<Int64>();
        final n = _b.pqk_key_latency(p50, p95, max);
        return KeyLatency(n, Duration(microseconds: p50.value),
            Duration(microseconds: p95.value), Duration(microseconds: max.value));
      });

  void resetKeyLatency() => _b.pqk_reset_key_latency();

  /// Luminância média dos ladrilhos em uso (0–255), ou -1.
  double debugTilesLuma() => _b.pqk_debug_tiles_luma();

  void _withString(String s, void Function(Pointer<Char>) fn) =>
      using((arena) => fn(s.toNativeUtf8(allocator: arena).cast()));
}
