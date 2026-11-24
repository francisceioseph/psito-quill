// O adaptador da porta QuillKit para o LibreOfficeKit (pelo plugin nativo).
import 'dart:async';
import 'dart:convert';
import 'dart:io' show File;
import 'dart:ui' show Rect, Size;

import 'package:psito_quill_kit/psito_quill_kit.dart';

import '../quill_kit.dart';
import 'lo_profile.dart';
import 'lok_payloads.dart';

/// Quantas vagas de ladrilho cobrem uma tela de [physical] pixels: as
/// colunas da tela (com uma a mais, pelo corte) e as linhas, com uma fileira
/// de margem acima e abaixo. A memória dos ladrilhos é fixa: 256 KB por vaga.
int tileSlotsFor(Size physical, {int tileSize = 256, int min = 48, int max = 256}) {
  if (physical.isEmpty) return 128;
  final cols = (physical.width / tileSize).ceil() + 1;
  final rows = (physical.height / tileSize).ceil() + 3;
  return (cols * rows).clamp(min, max);
}

/// Onde está o `program/` do LibreOffice do sistema: `/usr/lib` no Debian e
/// no Ubuntu, `/usr/lib64` no Fedora. Sem nenhum, fica o primeiro (o motor
/// falha ao abrir, como antes).
String libreOfficeProgramDir({bool Function(String path) exists = _exists}) {
  const candidates = ['/usr/lib/libreoffice/program', '/usr/lib64/libreoffice/program'];
  return candidates.firstWhere((p) => exists('$p/libmergedlo.so') || exists('$p/libsofficeapp.so'),
      orElse: () => candidates.first);
}

bool _exists(String path) => File(path).existsSync();

class LokQuillKit implements QuillKit {
  LokQuillKit({
    required this.profile,
    String? installPath,
    this.tileSlots = 128,
    NativeQuillKit? native,
  }) : installPath = installPath ?? libreOfficeProgramDir(),
       _native = native ?? NativeQuillKit.open();

  final LoProfile profile;
  final String installPath;

  /// Vagas × 256 KB de ladrilhos, fixos (veja [tileSlotsFor]).
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
      final event = _copyOrSave(translate(e.type, e.payload));
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
  void activate(int id) => _native.activate(id);

  @override
  void closeDocument(int id) => _native.closeDocument(id);

  @override
  void setViewport(int scaleMilli, Rect v) =>
      _native.setViewport(scaleMilli, v.left.round(), v.top.round(), v.width.round(), v.height.round());

  @override
  void repaintAll() => _native.repaintAll();

  @override
  void setPaperInvert(PaperInvert? invert) =>
      _native.setPaperInvert(invert != null, invert?.paper ?? 0, invert?.ink ?? 0, invert?.source ?? 0);

  @override
  void setAccessibility(bool on) => _native.setAccessibility(on);

  @override
  void preloadSpelling(String path) => _native.preloadSpelling(path);

  @override
  void convert(int id, String source, String target, String format) => _native.convert(id, source, target, format);

  @override
  void printPdf(String pdfPath, String title) => _native.printPdf(pdfPath, title);

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
  void saveAs(String path, String format) {
    _saves.add(null);
    _native.saveAs(path, format, 'TakeOwnership');
  }

  @override
  List<int> fontClasses(List<String> families) => _native.fontClasses(families);

  @override
  void exportCopy(String path, String format) {
    _saves.add(path);
    _native.saveAs(path, format, '');
  }

  /// Os salvamentos em andamento, na ordem (a fila do kit é uma só): null é
  /// um salvamento de verdade; um caminho, uma cópia. O núcleo responde aos
  /// dois com o mesmo evento.
  final _saves = <String?>[];

  /// O fim de uma cópia vira [CopyExported], e não um salvamento.
  KitEvent? _copyOrSave(KitEvent? e) {
    if (e is! DocumentSaved && e is! SaveFailed) return e;
    final copy = _saves.isEmpty ? null : _saves.removeAt(0);
    if (copy == null) return e;
    return CopyExported(copy, ok: e is DocumentSaved);
  }

  @override
  void extTextInput(String text, {required bool commit}) {
    _native.extTextInput(LibreOfficeKitExtTextInputType.LOK_EXT_TEXTINPUT, text);
    if (commit) _native.extTextInput(LibreOfficeKitExtTextInputType.LOK_EXT_TEXTINPUT_END, '');
  }

  @override
  void setGraphicSelection(GraphicDrag type, int x, int y) => _native.setGraphicSelection(
      type == GraphicDrag.start
          ? LibreOfficeKitSetGraphicSelectionType.LOK_SETGRAPHICSELECTION_START
          : LibreOfficeKitSetGraphicSelectionType.LOK_SETGRAPHICSELECTION_END,
      x,
      y);

  @override
  void requestCommandValues(String command) => _native.commandValues(command);

  @override
  void requestTextSelection() => _native.textSelection(plainText);

  @override
  void pasteText(String text) => _native.paste(plainText, text);

  // Acima de 1000, o LibreOffice limpa os caches da VCL e chama o
  // malloc_trim. Acima de 2000 ele também despeja o estado (depuração): não.
  @override
  void trimMemory() => _native.trimMemory(2000);

  static const plainText = 'text/plain;charset=utf-8';

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
        return DocumentOpened(parseOpened(payload), id: parseDocumentId(payload));
      case PqkEvent.PQK_EVENT_ACTIVATED:
        return DocumentActivated(parseDocumentId(payload), parseOpened(payload));
      case PqkEvent.PQK_EVENT_CONVERTED:
        return parseConverted(payload);
      case PqkEvent.PQK_EVENT_PRINTED:
        return switch (payload) {
          'ok' => const Printed(PrintOutcome.sent),
          'cancelado' => const Printed(PrintOutcome.cancelled),
          _ => Printed(PrintOutcome.failed, error: payload.split('\n').skip(1).join('\n')),
        };
      case PqkEvent.PQK_EVENT_OPEN_FAILED:
        return DocumentOpenFailed(payload);
      case PqkEvent.PQK_EVENT_TILE:
        return parseTilePlaced(payload);
      case PqkEvent.PQK_EVENT_CLOSED:
        return DocumentClosed(int.tryParse(payload.trim()) ?? 0);
      case PqkEvent.PQK_EVENT_SAVED:
        return DocumentSaved(payload);
      case PqkEvent.PQK_EVENT_SAVE_FAILED:
        return SaveFailed(payload);
      case PqkEvent.PQK_EVENT_COMMAND_VALUES:
        final nl = payload.indexOf('\n');
        return nl < 0 ? OtherKitEvent(type, payload) : CommandValues(payload.substring(0, nl), payload.substring(nl + 1));
      case PqkEvent.PQK_EVENT_TEXT_SELECTION:
        final nl = payload.indexOf('\n');
        return TextSelectionContent(nl < 0 ? '' : payload.substring(nl + 1));
      case PqkEvent.PQK_EVENT_LUA_LOG:
        return PluginLog(payload);
      case PqkEvent.PQK_EVENT_LUA_DONE:
        final json = jsonDecode(payload) as Map<String, dynamic>;
        return PluginFinished(ok: json['ok'] == true, error: '${json['error'] ?? ''}');
      case LibreOfficeKitCallbackType.LOK_CALLBACK_INVALIDATE_VISIBLE_CURSOR:
        return CursorMoved(parseCursor(payload), link: parseCursorLink(payload));
      case LibreOfficeKitCallbackType.LOK_CALLBACK_CURSOR_VISIBLE:
        return CursorVisibility(payload.trim() == 'true');
      case LibreOfficeKitCallbackType.LOK_CALLBACK_TEXT_SELECTION:
        return SelectionChanged(parseSelection(payload));
      case LibreOfficeKitCallbackType.LOK_CALLBACK_STATE_CHANGED:
        final s = parseCommandState(payload);
        return s == null ? OtherKitEvent(type, payload) : CommandStateChanged(s.$1, s.$2);
      case LibreOfficeKitCallbackType.LOK_CALLBACK_SEARCH_RESULT_SELECTION:
        return parseSearchResult(payload);
      case LibreOfficeKitCallbackType.LOK_CALLBACK_STATUS_INDICATOR_START:
        return ProgressStarted(payload.trim());
      case LibreOfficeKitCallbackType.LOK_CALLBACK_STATUS_INDICATOR_SET_VALUE:
        return ProgressValue((int.tryParse(payload.trim()) ?? 0).clamp(0, 100));
      case LibreOfficeKitCallbackType.LOK_CALLBACK_STATUS_INDICATOR_FINISH:
        return const ProgressFinished();
      case LibreOfficeKitCallbackType.LOK_CALLBACK_A11Y_FOCUS_CHANGED:
        return parseA11yParagraph(payload) ?? OtherKitEvent(type, payload);
      case LibreOfficeKitCallbackType.LOK_CALLBACK_A11Y_CARET_CHANGED:
        return parseA11yCaret(payload) ?? OtherKitEvent(type, payload);
      case LibreOfficeKitCallbackType.LOK_CALLBACK_SEARCH_NOT_FOUND:
        return SearchNotFound(payload);
      case LibreOfficeKitCallbackType.LOK_CALLBACK_CONTEXT_MENU:
        return ContextMenuReady(parseContextMenu(payload));
      case LibreOfficeKitCallbackType.LOK_CALLBACK_RULER_UPDATE:
        return switch (parseRuler(payload)) {
          final r? => RulerUpdated(r),
          null => OtherKitEvent(type, payload),
        };
      case LibreOfficeKitCallbackType.LOK_CALLBACK_GRAPHIC_SELECTION:
        return GraphicSelected(parseGraphicSelection(payload));
      case LibreOfficeKitCallbackType.LOK_CALLBACK_TABLE_SELECTED:
        return TableSelected(parseTableSelected(payload));
      case LibreOfficeKitCallbackType.LOK_CALLBACK_DOCUMENT_SIZE_CHANGED:
        final size = parseDocumentSize(payload);
        return size == null ? null : DocumentSizeChanged(size);
    }
    return OtherKitEvent(type, payload);
  }
}
