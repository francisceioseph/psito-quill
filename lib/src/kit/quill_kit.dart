// A porta do motor (Ports & Adapters).
//
// A UI e o estado só conhecem esta interface. O `LokQuillKit` liga ao
// LibreOfficeKit por FFI; o `FakeQuillKit` roda nos testes, sem o LibreOffice.
import 'dart:ui' show Rect, Size;

import 'package:flutter/foundation.dart' show immutable, listEquals;

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

/// Arrastar a alça de uma imagem: o ponto de partida e o de chegada.
enum GraphicDrag { start, end }

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

/// Um documento foi aberto e é o ativo (os outros continuam abertos, D-054).
class DocumentOpened extends KitEvent {
  const DocumentOpened(this.size, {this.id = 1});

  /// Tamanho em twips.
  final Size size;

  /// O número do documento no motor, para [QuillKit.activate].
  final int id;
}

/// O motor trocou o documento ativo ([QuillKit.activate]). Daqui em diante,
/// os eventos são dele.
class DocumentActivated extends KitEvent {
  const DocumentActivated(this.id, this.size);
  final int id;
  final Size size;
}

class DocumentOpenFailed extends KitEvent {
  const DocumentOpenFailed(this.message);
  final String message;
}

/// O documento foi fechado no motor (e a trava .~lock, apagada).
class DocumentClosed extends KitEvent {
  const DocumentClosed([this.id = 0]);

  /// O número do documento fechado (0: nenhum estava aberto).
  final int id;
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

/// A régua do parágrafo do cursor (o callback 35, D-046), em centésimos de
/// milímetro: onde começa o texto na página, a largura dele, o recuo e as
/// tabulações. O recuo da primeira linha e o da direita não vêm aqui (vêm
/// do estado `.uno:LeftRightParaMargin`).
@immutable
class RulerInfo {
  const RulerInfo({
    required this.pageWidth,
    required this.leftMargin,
    required this.textWidth,
    this.indent = 0,
    this.tabs = const [],
    this.pageOffset,
  });

  final int pageWidth;

  /// Onde começa a página do cursor, da borda esquerda do documento
  /// (`pageOffset`, em centésimos de mm). Com uma página por linha, é o vão
  /// entre as páginas (501); no modo Livro ou Várias, a coluna da página.
  final int? pageOffset;

  /// A margem esquerda da página (`leftOffset`).
  final int leftMargin;

  /// A largura da área do texto, da margem esquerda (`margin2`).
  final int textWidth;

  /// O recuo esquerdo do parágrafo (`margin1`).
  final int indent;

  /// As tabulações, da margem esquerda: a posição e o tipo do LibreOffice.
  final List<({int position, int style})> tabs;

  int get rightMargin => pageWidth - leftMargin - textWidth;

  @override
  bool operator ==(Object other) =>
      other is RulerInfo &&
      other.pageWidth == pageWidth &&
      other.leftMargin == leftMargin &&
      other.textWidth == textWidth &&
      other.indent == indent &&
      other.pageOffset == pageOffset &&
      listEquals(other.tabs, tabs);

  @override
  int get hashCode => Object.hash(pageWidth, leftMargin, textWidth, indent, pageOffset, tabs.length);
}

class RulerUpdated extends KitEvent {
  const RulerUpdated(this.ruler);
  final RulerInfo ruler;
}

/// A cópia de [QuillKit.exportCopy] foi gravada (ou não, com [ok] falso).
/// Não é um salvamento: o documento não muda.
class CopyExported extends KitEvent {
  const CopyExported(this.path, {this.ok = true});
  final String path;
  final bool ok;
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

/// A seleção como texto simples (resposta de [QuillKit.requestTextSelection]).
class TextSelectionContent extends KitEvent {
  const TextSelectionContent(this.text);
  final String text;
}

/// Resposta de [QuillKit.requestCommandValues]: o JSON do motor.
class CommandValues extends KitEvent {
  const CommandValues(this.command, this.json);
  final String command, json;
}

/// Resultado de uma busca: os retângulos de cada ocorrência (twips). Na
/// busca de uma só, a ocorrência fica selecionada; na de todas, [all].
class SearchResult extends KitEvent {
  const SearchResult(this.matches, {this.all = false});
  final List<List<Rect>> matches;
  final bool all;
  int get count => matches.length;
}

class SearchNotFound extends KitEvent {
  const SearchNotFound(this.text);
  final String text;
}

/// Um item do menu de contexto do motor (clique direito).
class EngineMenuItem {
  const EngineMenuItem({this.text = '', this.command = '', this.enabled = true, this.children = const []});
  const EngineMenuItem.separator() : this();

  /// O rótulo do LibreOffice, sem o "~" do atalho.
  final String text;

  /// ".uno:SpellCheckApplySuggestion?ApplyRule:string=Spelling_erro".
  final String command;
  final bool enabled;
  final List<EngineMenuItem> children;

  bool get isSeparator => text.isEmpty && command.isEmpty;
}

/// O motor respondeu ao clique direito com o menu dele.
class ContextMenuReady extends KitEvent {
  const ContextMenuReady(this.items);
  final List<EngineMenuItem> items;
}

/// Uma imagem (ou outro objeto) selecionada, em twips; null quando nenhuma.
class GraphicSelected extends KitEvent {
  const GraphicSelected(this.rect);
  final Rect? rect;
}

/// O cursor entrou (ou saiu) de uma tabela.
class TableSelected extends KitEvent {
  const TableSelected(this.inTable);
  final bool inTable;
}

/// O resto, cru: o que o app ainda não usa.
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

  /// Abre mais um documento e o ativa, sem fechar os outros (D-054). [path]
  /// vazio abre um documento novo. Responde com [DocumentOpened] (com o
  /// número) ou [DocumentOpenFailed].
  void open(String path);

  /// Troca o documento ativo; todas as outras chamadas vão a ele. Responde
  /// com [DocumentActivated].
  void activate(int id);

  /// Fecha o ativo ([close]) ou um pelo número. Responde com [DocumentClosed].
  void close();
  void closeDocument(int id);

  /// Área visível em twips e a escala × 1000.
  void setViewport(int scaleMilli, Rect visibleTwips);
  void repaintAll();

  void postKey(KeyEventType type, {int charCode = 0, int keyCode = 0});
  void postMouse(MouseEventType type, int x, int y, {int count = 1, int buttons = 1, int modifier = 0});
  void uno(String command, [String argsJson = '']);
  /// Salva em [path]. O documento passa a ser aquele arquivo (os próximos
  /// salvamentos vão para lá), mesmo num formato diferente.
  void saveAs(String path, String format);

  /// As classes de cada fonte do sistema, para os filtros da lista de
  /// fontes: a soma de [FontClass.mono], [FontClass.serif], [FontClass.sans];
  /// 0 se não está instalada. Síncrona e barata (o fontconfig, não o motor).
  List<int> fontClasses(List<String> families);

  /// Grava uma cópia em [path] sem mudar o documento: o caminho e o
  /// "modificado" continuam os mesmos (D-044). Responde com [CopyExported].
  void exportCopy(String path, String format);

  /// Entrada composta (IME). Sem [commit], é a pré-edição, que a próxima
  /// chamada substitui. Com [commit], o texto entra no documento.
  void extTextInput(String text, {required bool commit});

  /// Arrasta a imagem selecionada (pela alça, para redimensionar; pelo
  /// meio, para mover), em twips: [GraphicDrag.start] onde começa e
  /// [GraphicDrag.end] onde termina.
  void setGraphicSelection(GraphicDrag type, int x, int y);

  /// Pede os valores possíveis de um comando (as fontes de
  /// `.uno:CharFontName`, por exemplo); a resposta é um [CommandValues].
  void requestCommandValues(String command);

  /// Pede a seleção como texto; a resposta é um [TextSelectionContent].
  void requestTextSelection();

  /// Cola texto simples no cursor.
  void pasteText(String text);

  /// Devolve ao sistema a memória de caches do motor (ao ficar ocioso).
  void trimMemory();

  /// Roda um plugin Lua na caixa de areia.
  void runLua(String source, String name, {int memoryLimit = 16 << 20, int instructionLimit = 10000000});

  int get residentBytes;
  KeyLatencyStats keyLatency();
  void resetKeyLatency();

  /// Luminância média (0–255) dos ladrilhos em uso, ou -1. Só para medir.
  double debugTilesLuma();
}

/// As classes de fonte de [QuillKit.fontClasses].
abstract final class FontClass {
  static const mono = 1, serif = 2, sans = 4;
}
