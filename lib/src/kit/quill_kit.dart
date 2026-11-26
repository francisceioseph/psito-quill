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

/// A resposta a [QuillKit.convert] de número [id].
/// A impressão terminou (D-076): enviada, cancelada na janela, ou com erro.
enum PrintOutcome { sent, cancelled, failed }

class Printed extends KitEvent {
  const Printed(this.outcome, {this.error = ''});
  final PrintOutcome outcome;

  /// "sem-pdf": a impressora não aceita PDF.
  final String error;
}

class FileConverted extends KitEvent {
  const FileConverted(this.id, {required this.ok, this.error = ''});
  final int id;
  final bool ok;
  final String error;
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
  const CursorMoved(this.rect, {this.link});
  final Rect rect;

  /// O link em que o cursor está (D-076); null fora de um link.
  final DocLink? link;
}

/// Um link do documento: o texto e o endereço.
class DocLink {
  const DocLink(this.text, this.url);
  final String text, url;

  @override
  bool operator ==(Object other) => other is DocLink && other.text == text && other.url == url;
  @override
  int get hashCode => Object.hash(text, url);
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

/// O motor começou um trabalho com progresso (callback 9, D-066). Na 24.2,
/// só abrir um documento grande manda ("Carregando: "); salvar não manda.
class ProgressStarted extends KitEvent {
  const ProgressStarted(this.label);
  final String label;
}

/// O progresso, de 0 a 100 (callback 10).
class ProgressValue extends KitEvent {
  const ProgressValue(this.percent);
  final int percent;
}

/// O trabalho terminou (callback 11). Chega também sem o começo, ao abrir um
/// documento pequeno.
class ProgressFinished extends KitEvent {
  const ProgressFinished();
}

/// O parágrafo do cursor mudou (callback 62): o texto e onde está o cursor
/// nele (em caracteres).
class A11yParagraph extends KitEvent {
  const A11yParagraph(this.text, this.caret);
  final String text;
  final int caret;
}

/// O cursor andou dentro do mesmo parágrafo (callback 63).
class A11yCaret extends KitEvent {
  const A11yCaret(this.caret);
  final int caret;
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

/// Um comentário do documento (D-088), como o motor manda no callback 32 e
/// no `.uno:ViewAnnotations`. [range] é o trecho comentado (um retângulo
/// por linha, em twips; vazio numa resposta), e [anchor], o ponto dele.
class DocComment {
  const DocComment({
    required this.id,
    this.parentId = '',
    this.author = '',
    this.text = '',
    this.resolved = false,
    this.date,
    this.anchor,
    this.range = const [],
  });

  final String id;

  /// O comentário respondido; vazio (o "0" do motor) num comentário novo.
  final String parentId;
  final String author, text;
  final bool resolved;
  final DateTime? date;
  final Rect? anchor;
  final List<Rect> range;

  bool get isReply => parentId.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is DocComment &&
      other.id == id &&
      other.parentId == parentId &&
      other.author == author &&
      other.text == text &&
      other.resolved == resolved &&
      other.date == date &&
      other.anchor == anchor &&
      _sameRects(other.range, range);
  @override
  int get hashCode => Object.hash(id, parentId, text, resolved, anchor);

  static bool _sameRects(List<Rect> a, List<Rect> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

enum CommentAction { add, modify, resolve, remove }

/// Um comentário mudou (o callback 32, D-088). No [CommentAction.remove],
/// só o [DocComment.id] vem preenchido.
class CommentChanged extends KitEvent {
  const CommentChanged(this.action, this.comment);
  final CommentAction action;
  final DocComment comment;
}

enum TrackedChangeKind { insert, delete, format, other }

/// Uma alteração do controle de alterações (D-089), como a lista do
/// `getCommandValues(".uno:AcceptTrackedChanges")` traz. [index] é o número
/// que aceitar e rejeitar uma pedem.
class TrackedChange {
  const TrackedChange({
    required this.index,
    this.kind = TrackedChangeKind.other,
    this.author = '',
    this.description = '',
    this.comment = '',
    this.date,
    this.range = const [],
  });

  final int index;
  final TrackedChangeKind kind;
  final String author;

  /// "Inserir “Ele miava.”", no idioma do motor.
  final String description;
  final String comment;
  final DateTime? date;
  final List<Rect> range;
}

/// A tabela das alterações mudou (os callbacks 30 e 31, D-089). O Quill pede
/// a lista de novo, se precisar dela.
class TrackedChangesChanged extends KitEvent {
  const TrackedChangesChanged();
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

  /// O papel escuro (D-074): os ladrilhos pintados depois vêm com a
  /// luminosidade invertida e o tom mantido; null desliga. Chame o
  /// [repaintAll] em seguida.
  void setPaperInvert(PaperInvert? invert);

  /// Os callbacks de acessibilidade do documento ativo (D-067): o parágrafo
  /// do cursor ([A11yParagraph]) e a posição do cursor nele ([A11yCaret]).
  /// Custam trabalho a cada tecla: só para quem usa leitor de tela.
  void setAccessibility(bool on);

  /// O nome de quem escreve os comentários (D-088). Vale para os documentos
  /// abertos depois: a 24.2 não troca o de um documento aberto.
  void setAuthor(String name);

  /// Os sons da máquina de escrever (D-095): ligar sintetiza os sons no
  /// plugin (uns 200 KB) e desligar os solta. O volume vai de 0 a 1. Sem
  /// PulseAudio, o som fica mudo, sem erro.
  void setTypewriterSound({required bool enabled, required double volume});

  /// Toca um som da máquina de escrever. Volta logo; desligado, não faz nada.
  void playTypewriterSound(TypewriterSound sound);

  /// Abre o documento em [path] (pequeno, com texto em português) sem
  /// mostrar, para a ortografia carregar o dicionário enquanto a tela inicial
  /// está aberta (D-069). Só vale sem documento aberto; o motor apaga o
  /// arquivo, e o documento oculto fecha quando outro abre.
  void preloadSpelling(String path);

  /// Abre [source] sem mostrar ('' para um documento novo), salva em
  /// [target] no [format] ("odt", "fodt", "pdf", "epub", "docx") e fecha, sem tocar nas abas (o
  /// livro, D-071). Responde com [FileConverted] e o mesmo [id].
  ///
  /// [options] são as do filtro (um JSON do LibreOffice, "" sem opções); com
  /// [updateIndexes], o motor atualiza os sumários e os índices antes de
  /// gravar (o compilar, D-086).
  void convert(int id, String source, String target, String format, {String options = '', bool updateIndexes = false});

  /// A janela de impressão do sistema para o PDF [pdfPath], que é apagado
  /// no fim. Responde com [Printed] (D-076).
  void printPdf(String pdfPath, String title);

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

/// O papel escuro desenhado pelo Quill (D-074), em 0xRRGGBB: o [source] (o
/// papel claro que o motor pinta) vira o [paper], e o preto vira o [ink].
class PaperInvert {
  const PaperInvert({required this.paper, required this.ink, required this.source});
  final int paper, ink, source;

  /// A cor [rgb] como o motor a mostra no papel escuro: a mesma conta do
  /// `LokEngine::invertPixels` (os cartões de estilo da faixa usam).
  int apply(int rgb) {
    int ch(int v, int shift) => (v >> shift) & 255;
    final top = (77 * ch(source, 16) + 150 * ch(source, 8) + 29 * ch(source, 0)) >> 8;
    final r = ch(rgb, 16), g = ch(rgb, 8), b = ch(rgb, 0);
    final y = (77 * r + 150 * g + 29 * b) >> 8;
    final t = top < 1 || y >= top ? 255 : y * 255 ~/ top;
    var out = 0;
    for (final (shift, v) in [(16, r), (8, g), (0, b)]) {
      final k = ch(ink, shift), p = ch(paper, shift);
      final n = k + (p - k) * t ~/ 255;
      out |= (n + v - y).clamp(0, 255) << shift;
    }
    return out;
  }

  @override
  bool operator ==(Object other) =>
      other is PaperInvert && other.paper == paper && other.ink == ink && other.source == source;
  @override
  int get hashCode => Object.hash(paper, ink, source);
}

/// Os sons da máquina de escrever (D-095), na ordem do `PQK_SOUND_*`.
enum TypewriterSound { key, space, backspace, carriageReturn, bell }
