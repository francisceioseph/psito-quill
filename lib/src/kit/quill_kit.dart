// A porta do motor (Ports & Adapters).
//
// A UI e o estado só conhecem esta interface. O `LokQuillKit` liga ao
// LibreOfficeKit por FFI; o `FakeQuillKit` roda nos testes, sem o LibreOffice.
import 'dart:ui' show Rect, Size;

/// Twips: 1/1440 polegada. A 96 dpi e zoom 1, 1 px lógico = 15 twips.
const double twipsPerPixel = 15;

/// Ladrilho na grade do motor, numa escala (pixels físicos por lógico × zoom).
class TileKey {
  const TileKey(this.col, this.row, this.scaleMilli);
  final int col, row, scaleMilli;

  @override
  bool operator ==(Object other) =>
      other is TileKey && other.col == col && other.row == row && other.scaleMilli == scaleMilli;

  @override
  int get hashCode => Object.hash(col, row, scaleMilli);

  @override
  String toString() => 'TileKey($col, $row, ${scaleMilli / 1000}x)';
}

/// Teclas e mouse no vocabulário do LOK (os números do LibreOfficeKitEnums.h).
enum KeyEventType { input, up }

enum MouseEventType { down, up, move }

// ------------------------------------------------------------ eventos --

sealed class KitEvent {
  const KitEvent();
}

class KitReady extends KitEvent {
  const KitReady(this.version);
  final String version;
}

class KitFailed extends KitEvent {
  const KitFailed(this.message);
  final String message;
}

class DocumentOpened extends KitEvent {
  const DocumentOpened(this.size);

  /// Tamanho em twips.
  final Size size;
}

class DocumentOpenFailed extends KitEvent {
  const DocumentOpenFailed(this.message);
  final String message;
}

/// O documento foi fechado no motor (e a trava .~lock, apagada).
class DocumentClosed extends KitEvent {
  const DocumentClosed();
}

class DocumentSizeChanged extends KitEvent {
  const DocumentSizeChanged(this.size);
  final Size size;
}

/// A vaga [slot] passou a mostrar o ladrilho [key].
class TilePlaced extends KitEvent {
  const TilePlaced(this.slot, this.key);
  final int slot;
  final TileKey key;
}

/// Cursor de texto, em twips. [Rect.zero] quando não há.
class CursorMoved extends KitEvent {
  const CursorMoved(this.rect);
  final Rect rect;
}

class CursorVisibility extends KitEvent {
  const CursorVisibility(this.visible);
  final bool visible;
}

/// Retângulos da seleção em twips (vazio: sem seleção).
class SelectionChanged extends KitEvent {
  const SelectionChanged(this.rects);
  final List<Rect> rects;
}

/// Estado de um comando: `.uno:Bold` = `true`, `.uno:PageStatus` = ...
class CommandStateChanged extends KitEvent {
  const CommandStateChanged(this.command, this.value);
  final String command, value;
}

class DocumentSaved extends KitEvent {
  const DocumentSaved(this.path);
  final String path;
}

class SaveFailed extends KitEvent {
  const SaveFailed(this.message);
  final String message;
}

class PluginLog extends KitEvent {
  const PluginLog(this.text);
  final String text;
}

class PluginFinished extends KitEvent {
  const PluginFinished({required this.ok, this.error = ''});
  final bool ok;
  final String error;
}

/// O resto, cru: o que a Fase 0 ainda não usa.
class OtherKitEvent extends KitEvent {
  const OtherKitEvent(this.type, this.payload);
  final int type;
  final String payload;
}

// -------------------------------------------------------------- medidas --

class KeyLatencyStats {
  const KeyLatencyStats(this.samples, this.p50, this.p95, this.max);
  final int samples;
  final Duration p50, p95, max;
}

// ---------------------------------------------------------------- porta --

abstract interface class QuillKit {
  Stream<KitEvent> get events;

  /// Lado do ladrilho em pixels físicos.
  int get tileSize;

  /// Liga o motor. Responde com [KitReady] ou [KitFailed] em [events].
  void start();
  void dispose();

  /// Id da textura do Flutter da vaga, ou -1 (kit sem texturas).
  int textureId(int slot);

  /// [path] vazio abre um documento novo.
  void open(String path);
  void close();

  /// Área visível em twips e a escala × 1000.
  void setViewport(int scaleMilli, Rect visibleTwips);
  void repaintAll();

  void postKey(KeyEventType type, {int charCode = 0, int keyCode = 0});
  void postMouse(MouseEventType type, int x, int y, {int count = 1, int buttons = 1, int modifier = 0});
  void uno(String command, [String argsJson = '']);
  void saveAs(String path, String format);

  /// Roda um plugin Lua na caixa de areia.
  void runLua(String source, String name, {int memoryLimit = 16 << 20, int instructionLimit = 10000000});

  int get residentBytes;
  KeyLatencyStats keyLatency();
  void resetKeyLatency();

  /// Luminância média (0–255) dos ladrilhos em uso, ou -1. Só para medir.
  double debugTilesLuma();
}
