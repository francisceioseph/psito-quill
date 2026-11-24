// O estado do documento aberto, montado a partir dos eventos do motor.
//
// Observer: a UI escuta este ChangeNotifier, e ele escuta o QuillKit. Nada
// aqui é adivinhado: o negrito ativo, o cursor, o "modificado", o desfazer
// e a página vêm do motor.
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter/foundation.dart';

import '../book/docx_import.dart' show KitConverter;
import '../kit/lok/lo_styles.dart';
import '../kit/lok/lok_payloads.dart';
import '../kit/quill_kit.dart';
import 'doc_tab.dart';
import 'fodt.dart';
import 'outline.dart';
import 'recovery.dart';
import 'search.dart';
import 'style_patch.dart';
import 'text_clipboard.dart';

export 'doc_tab.dart' show DocStatus, DocTab;
export '../kit/quill_kit.dart' show DocLink, PrintOutcome, Printed;
export '../kit/lok/lok_payloads.dart' show DocLanguage;

part 'page_format.dart';
part 'scene_ops.dart';

/// O que trava a tela (D-066).
enum BusyKind { opening, saving, working }

enum KitStatus { starting, ready, failed }

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

/// Um aviso já traduzido pela página (exportado, impresso, D-076).
class NoticeMessage extends DocMessage {
  const NoticeMessage(this.text);
  final String text;
}

/// Os limites do zoom.
/// Com várias páginas lado a lado, cabe ver o capítulo inteiro (D-047).
const double minZoom = 0.2, maxZoom = 3.0;

/// Onde a busca está: quantas achou, se não achou, e o que foi trocado.
@immutable
class SearchStatus {
  const SearchStatus({this.query, this.count, this.notFound = false, this.replaced});
  final SearchQuery? query;

  /// Ocorrências (da busca de todas), ou null se não contou.
  final int? count;
  final bool notFound;

  /// Quantas o "substituir todas" trocou.
  final int? replaced;
}

/// Um menu de contexto do motor, pronto para mostrar onde foi o clique.
class PendingContextMenu {
  const PendingContextMenu(this.twips, this.items);
  final Offset twips;
  final List<EngineMenuItem> items;
}

/// Um tamanho de página, em centésimos de milímetro (retrato).
@immutable
class PageSize {
  const PageSize(this.id, this.width, this.height);
  final String id;
  final int width, height;
}

/// Os tamanhos da faixa Layout. O 6×9 pol. e o 5,5×8,5 pol. são os do livro
/// impresso sob demanda.
const pageSizes = [
  PageSize('a4', 21000, 29700),
  PageSize('a5', 14800, 21000),
  PageSize('carta', 21590, 27940),
  PageSize('livro6x9', 15240, 22860),
  PageSize('livro55x85', 13970, 21590),
];

/// Margens da página (cm): esquerda, direita, em cima, embaixo.
typedef PageMargins = ({double left, double right, double top, double bottom});

class DocumentController extends ChangeNotifier {
  DocumentController(this.kit, {TextClipboard? clipboard, this.deferOpenWork = false})
      : clipboard = clipboard ?? const SystemTextClipboard() {
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

  /// A régua do parágrafo do cursor (o callback 35, D-046).
  RulerInfo? ruler;

  /// A classe de cada fonte da lista ([FontClass]), para os filtros.
  Map<String, int> fontClasses = const {};

  /// Os estilos do documento (nomes de programa do LibreOffice).
  List<String> paragraphStyles = const [];
  List<String> characterStyles = const [];

  /// A busca em curso, e os retângulos das ocorrências para realçar.
  SearchStatus search = const SearchStatus();
  List<Rect> searchHighlights = const [];

  /// O menu do clique direito, até a página mostrá-lo.
  PendingContextMenu? contextMenu;
  Offset? _contextAt;

  /// A imagem selecionada (twips), ou null.
  Rect? graphic;

  /// O cursor está numa tabela.
  bool inTable = false;

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
  /// Uma cópia recuperada (D-073) conta como modificada até ser salva: ela
  /// não é o arquivo de ninguém.
  bool get modified => isOn('.uno:ModifiedStatus') || recovered != null;
  bool get canUndo => canEdit && _enabled('.uno:Undo');
  bool get canRedo => canEdit && _enabled('.uno:Redo');
  bool get hasSelection => selection.isNotEmpty;

  /// Página do cursor e total.
  (int, int)? get page => parsePageStatus(commandStates['.uno:StatePageNumber']);
  /// As palavras do motor. Na 24.2, ao abrir, ele às vezes não manda a
  /// contagem até a primeira edição (D-054); até lá vale a da cópia
  /// temporária, que o LibreOffice conta ao gravá-la.
  ({int words, int characters, bool selection})? get wordCount =>
      parseWordCount(commandStates['.uno:StateWordCount']) ??
      switch ((snapshot.words, snapshot.characters)) {
        (final w?, final c?) => (words: w, characters: c, selection: false),
        _ => null,
      };

  /// O estilo de parágrafo do cursor, com o nome que o motor mostra.
  String? get paragraphStyle => commandStates['.uno:StyleApply'];

  /// O mesmo estilo, pelo nome de programa ("Heading 1").
  String? get paragraphStyleId => switch (paragraphStyle) {
    null || '' => null,
    final s => styleIdFromState(s),
  };

  /// Os estilos criados pelo autor (os que não vêm de fábrica).
  List<String> get customParagraphStyles => [
    for (final s in paragraphStyles)
      if (!loBuiltinParagraphStyles.contains(s)) s,
  ];

  /// Recuos do parágrafo, em cm: "left", "right", "firstline".
  Map<String, double> get paragraphIndents => parseMeasures(commandStates['.uno:LeftRightParaMargin']);

  /// Espaço antes e depois do parágrafo, em cm: "upper", "lower".
  Map<String, double> get paragraphSpacing => parseMeasures(commandStates['.uno:ULSpacing']);

  /// O entrelinhas pelos botões: 100, 150 ou 200 (%); null se é outro.
  int? get lineSpacing => isOn('.uno:SpacePara1')
      ? 100
      : isOn('.uno:SpacePara15')
      ? 150
      : isOn('.uno:SpacePara2')
      ? 200
      : null;

  /// A cor da fonte e o realce, em RGB; null é a automática (ou nenhum).
  int? get fontColor => _color('.uno:Color');
  int? get highlightColor => _color('.uno:CharBackColor');
  int? _color(String command) {
    final v = int.tryParse(commandStates[command] ?? '');
    return v == null || v < 0 ? null : v;
  }

  bool get landscape => commandStates['.uno:Orientation'] == 'IsLandscape';

  /// O tamanho da imagem selecionada, em cm.
  Size? get graphicSizeCm => switch (parseObjectSize(commandStates['.uno:Size'])) {
    final s? when graphic != null => Size(s.width / 1000, s.height / 1000),
    _ => null,
  };
  String? get fontName => commandStates['.uno:CharFontName'];
  double? get fontSize => double.tryParse(commandStates['.uno:FontHeight'] ?? '');

  void start() => kit.start();

  // ------------------------------------------------------ as abas (D-054) --

  /// As abas abertas, na ordem da fileira.
  final List<DocTab> tabs = [];
  DocTab? _current;

  /// A aba da tela (null: nenhum documento).
  DocTab? get currentTab => _current;

  /// Sobe quando a aba da tela muda (a vista devolve a rolagem dela).
  int tabRevision = 0;

  /// Quantas abas ficam carregadas no motor. Passou disso, a salva usada há
  /// mais tempo é fechada no motor e reabre ao voltar.
  static const maxLoadedTabs = 8;

  int _tabSerial = 0, _useClock = 0;

  /// O motor ainda não confirmou o documento da tela (abrindo ou trocando):
  /// os eventos de documento que chegam até lá são do anterior, e saem.
  bool _switching = false;

  /// As abas esperando o DocumentOpened, na ordem dos pedidos.
  final _pendingOpens = <DocTab>[];

  /// Os documentos que o limite mandou fechar (a aba fica).
  final _unloading = <int>{};

  /// Um documento novo, vazio, que dá lugar ao que está abrindo.
  DocTab? _replaceWhenOpened;

  /// De onde se veio ao abrir: se falhar, volta para ela.
  DocTab? _cameFrom;

  /// A rolagem da página, que a vista escreve (sem avisar ninguém).
  Offset scrollPosition = Offset.zero;

  String? tabPath(DocTab t) => t == _current ? (path ?? _openingPath) : (t.path ?? t.openingPath);
  bool tabModified(DocTab t) => t == _current ? modified : t.modified;

  bool get _pristine => isOpen && path == null && !modified && !_switching;

  void _stash(DocTab t) {
    t
      ..status = docStatus
      ..path = path
      ..openingPath = _openingPath
      ..readOnly = readOnly
      ..lockOwner = lockOwner
      ..documentSize = documentSize
      ..cursor = cursor
      ..cursorVisible = cursorVisible
      ..selection = selection
      ..commandStates = Map.of(commandStates)
      ..ruler = ruler
      ..paragraphStyles = paragraphStyles
      ..characterStyles = characterStyles
      ..graphic = graphic
      ..inTable = inTable
      ..zoom = zoom
      ..viewColumns = viewColumns
      ..bookMode = bookMode
      ..snapshot = snapshot
      ..editedSinceCopy = _editedSinceCopy || _exporting != null
      ..recoveryDirty = _recoveryDirty
      ..recovered = recovered
      ..scroll = scrollPosition;
  }

  void _restore(DocTab t) {
    docStatus = t.status;
    path = t.path;
    _openingPath = t.openingPath;
    readOnly = t.readOnly;
    lockOwner = t.lockOwner;
    documentSize = t.documentSize;
    cursor = t.cursor;
    cursorVisible = t.cursorVisible;
    selection = t.selection;
    commandStates
      ..clear()
      ..addAll(t.commandStates);
    ruler = t.ruler;
    paragraphStyles = t.paragraphStyles;
    characterStyles = t.characterStyles;
    graphic = t.graphic;
    inTable = t.inTable;
    zoom = t.zoom;
    viewColumns = t.viewColumns;
    bookMode = t.bookMode;
    snapshot = t.snapshot;
    _editedSinceCopy = t.editedSinceCopy;
    _recoveryDirty = t.recoveryDirty;
    recovered = t.recovered;
    scrollPosition = t.scroll;
    t.commandStates = const {};
  }

  /// O que é da tela e não do documento: sai ao trocar de aba.
  void _clearTransient() {
    _tiles.clear();
    _previousScale = null;
    message = null;
    search = const SearchStatus();
    searchHighlights = const [];
    contextMenu = null;
    _contextAt = null;
    _countingForReplace = false;
    _pendingGraphicHeight = null;
    // A cópia em andamento era do outro documento: quando chegar, sai.
    _exporting = null;
    _exportAgain = false;
    _outlineTimer?.cancel();
    _autosaveTimer?.cancel();
    _autosaveTimer = null;
    endTextSearch();
  }

  DocTab _newTab() => DocTab(++_tabSerial)..lastUsed = ++_useClock;

  /// Leva [t] para a tela. Os eventos dela valem quando o motor confirmar.
  void activateTab(DocTab t) {
    // Durante uma troca pode trocar de novo (o motor faz na ordem); durante
    // uma abertura, não (o DocumentOpened é da aba que está abrindo).
    if (t == _current || !tabs.contains(t) || _pendingOpens.isNotEmpty) return;
    _flushRecovery();
    if (_current case final c?) _stash(c);
    _current = t;
    tabRevision++;
    t.lastUsed = ++_useClock;
    _clearTransient();
    _restore(t);
    if (_recoveryDirty) _scheduleAutosave();
    if (t.engineId case final id?) {
      _switching = true;
      kit.activate(id);
      if (_liveOutline && _editedSinceCopy) refreshSnapshot();
    } else {
      // O limite fechou este no motor: reabre, com o zoom e a rolagem.
      commandStates.clear();
      docStatus = DocStatus.opening;
      _switching = true;
      _pendingOpens.add(t);
      kit.open(_openingPath ?? path ?? '');
    }
    notifyListeners();
  }

  /// A próxima aba (ou a anterior, com [back]), dando a volta.
  void cycleTab({bool back = false}) {
    final c = _current;
    if (c == null || tabs.length < 2) return;
    final i = tabs.indexOf(c);
    activateTab(tabs[(i + (back ? -1 : 1)) % tabs.length]);
  }

  /// Fecha a aba no motor (sem perguntar: quem chama pergunta antes).
  Future<void> closeTab(DocTab t, {Duration timeout = const Duration(seconds: 3)}) async {
    if (!tabs.contains(t) || _pendingOpens.contains(t)) return;
    final id = t.engineId;
    if (id == null) {
      // Não está no motor (o limite, ou ainda abrindo e falhou).
      _removeTab(t);
      notifyListeners();
      return;
    }
    final closed = kit.events.firstWhere((e) => e is DocumentClosed && e.id == id);
    kit.closeDocument(id);
    await closed.timeout(timeout, onTimeout: () {
      _onEvent(DocumentClosed(id));
      return DocumentClosed(id);
    });
  }

  void _removeTab(DocTab t) {
    final i = tabs.indexOf(t);
    if (i < 0) return;
    tabs.removeAt(i);
    _forgetRecovery(t, t == _current ? recovered : t.recovered);
    if (t == _current) recovered = null;
    _pendingOpens.remove(t);
    if (t != _current) return;
    _current = null;
    tabRevision++;
    _switching = false;
    if (tabs.isEmpty) return;
    // A vizinha da direita, ou a da esquerda se era a última.
    final next = tabs[i.clamp(0, tabs.length - 1)];
    activateTab(next);
  }

  /// Fecha no motor as abas salvas usadas há mais tempo, além do limite.
  void _enforceLimit() {
    final loaded = [for (final t in tabs) if (t.engineId != null) t];
    if (loaded.length <= maxLoadedTabs) return;
    final candidates = [
      for (final t in loaded)
        if (t != _current && t.path != null && !t.modified && t.status == DocStatus.open) t,
    ]..sort((a, b) => a.lastUsed.compareTo(b.lastUsed));
    for (final t in candidates.take(loaded.length - maxLoadedTabs)) {
      final id = t.engineId!;
      _unloading.add(id);
      t.engineId = null;
      kit.closeDocument(id);
    }
  }

  /// Abre numa aba nova. [path] vazio abre um documento novo. [lockOwner]: o
  /// arquivo está com outro, e abre só para leitura. Um documento novo e
  /// vazio na tela dá lugar a este quando ele abrir.
  void open(String path, {String? lockOwner, RecoveryEntry? recovered}) {
    _flushRecovery();
    final previous = _current;
    _replaceWhenOpened = previous != null && _pristine ? previous : null;
    _cameFrom = previous;
    if (previous != null) _stash(previous);
    final t = _newTab();
    tabs.insert(previous == null ? tabs.length : tabs.indexOf(previous) + 1, t);
    _current = t;
    tabRevision++;
    _pendingOpens.add(t);
    _switching = true;
    _clearTransient();
    scrollPosition = Offset.zero;
    zoom = 1.0;
    viewColumns = 1;
    bookMode = false;
    ruler = null;
    snapshot = FodtSnapshot.empty;
    _editedSinceCopy = false;
    _recoveryDirty = false;
    this.recovered = recovered;
    t.recovered = recovered;
    this.path = null;
    documentSize = Size.zero;
    cursor = Rect.zero;
    _openingPath = path.isEmpty ? null : path;
    a11yParagraph = null;
    docStatus = DocStatus.opening;
    readOnly = lockOwner != null;
    this.lockOwner = lockOwner;
    selection = const [];
    commandStates.clear();
    graphic = null;
    inTable = false;
    notifyListeners();
    kit.open(path);
  }

  /// Fecha todos os documentos no motor e espera a confirmação. O
  /// LibreOffice deixa uma trava (.~lock) ao lado do arquivo enquanto está
  /// aberto; sair sem fechar deixa a trava, e a próxima abertura pode vir só
  /// para leitura.
  Future<void> close({Duration timeout = const Duration(seconds: 3)}) async {
    if (tabs.isEmpty) {
      if (docStatus == DocStatus.none) return;
      final closed = kit.events.firstWhere((e) => e is DocumentClosed);
      kit.close();
      await closed.timeout(timeout, onTimeout: () => const DocumentClosed());
      return;
    }
    // As de fora da tela primeiro: fechar a da tela traria outra para ela.
    for (final t in [for (final t in tabs) if (t != _current) t]) {
      await closeTab(t, timeout: timeout);
    }
    if (_current case final c?) await closeTab(c, timeout: timeout);
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
    if (!isOpen || busy != null) return;
    kit.postKey(KeyEventType.input, charCode: charCode, keyCode: keyCode);
    kit.postKey(KeyEventType.up, charCode: charCode, keyCode: keyCode);
    _edited();
  }

  /// Texto confirmado pelo teclado ou pelo IME.
  void insertText(String text) {
    if (canEdit && busy == null && text.isNotEmpty) {
      final rune = text.runes.length == 1 ? text.runes.first : -1;
      if (!_composing && graphic == null && rune >= 0x20 && rune != 0x7f && rune <= 0xFFFF) {
        // Um caractere digitado vai como tecla: o autocorrigir do motor (as
        // aspas curvas, o travessão) só age nas teclas, não no texto do IME
        // (sondado, D-076). Com uma imagem selecionada, não: o Writer
        // ignora a tecla, e o texto do IME tira a seleção e digita.
        kit.postKey(KeyEventType.input, charCode: rune);
        kit.postKey(KeyEventType.up, charCode: rune);
      } else {
        kit.extTextInput(text, commit: true);
      }
      _composing = false;
      _edited();
    }
  }

  /// O IME está compondo (o `´` esperando a letra): o texto confirmado
  /// fecha a composição pelo `extTextInput`.
  bool _composing = false;

  // --------------------------------------- a Estrutura ao vivo (D-047) --

  /// O painel Estrutura está aberto: a cópia se refaz numa pausa de 2 s na
  /// digitação. Fechado, não (ninguém paga por uma cópia que não vê).
  bool get liveOutline => _liveOutline;
  set liveOutline(bool v) {
    if (v == _liveOutline) return;
    _liveOutline = v;
    if (!v) {
      _outlineTimer?.cancel();
    } else if (_editedSinceCopy) {
      refreshSnapshot();
    }
  }

  bool _liveOutline = false;
  bool _editedSinceCopy = false;
  Timer? _outlineTimer;

  /// A pausa de digitação que refaz a Estrutura.
  static const outlinePause = Duration(seconds: 2);

  void _edited() {
    _editedSinceCopy = true;
    _markRecovery();
    if (!_liveOutline) return;
    _outlineTimer?.cancel();
    _outlineTimer = Timer(outlinePause, refreshSnapshot);
  }

  /// Leva o cursor ao título [e] da Estrutura. Sondado (D-047): a 24.2 não
  /// tem um comando de ir para o título; a busca do texto dele seleciona o
  /// título. Para não parar num parágrafo com o mesmo texto antes dele
  /// ("Cena 1" dentro de "Cena 10", um título repetido), vai ao começo do
  /// documento e procura uma vez a mais que as ocorrências antes do título
  /// (D-072). A vista rola até o cursor. A busca não acende o Localizar.
  void goToHeading(OutlineEntry e) {
    if (!isOpen || e.searchKey.isEmpty) return;
    _jumpToText(e.searchKey, e.occurrence);
  }

  /// Vai ao começo e procura [key] uma vez a mais que [occurrence].
  void _jumpToText(String key, int occurrence) {
    kit.uno('.uno:GoToStartOfDoc');
    final args = searchArgs(SearchQuery(key, matchCase: true), SearchCommand.next);
    for (var i = 0; i <= occurrence; i++) {
      _headingSearches++;
      kit.uno('.uno:ExecuteSearch', args);
    }
  }

  /// A cena a saltar quando o capítulo que está abrindo tiver a cópia.
  ({String path, int index})? _pendingScene;

  /// As respostas da busca do salto a um título, que não são do Localizar.
  int _headingSearches = 0;

  // ------------------------------------- a busca no texto (D-050) --

  /// A cópia da busca: feita na primeira busca no texto e apagada quando a
  /// busca fecha (`endTextSearch`). A busca é modal: o documento não muda
  /// enquanto ela está aberta, então uma cópia basta.
  String? _searchCopyPath;
  Completer<bool>? _searchCopyReady;

  /// A contagem de palavras e caracteres quando a cópia foi feita (D-062):
  /// muda com o texto, e não com a página (a `statusRevision` sobe também ao
  /// rolar ou ao saltar a uma ocorrência).
  String? _searchCopyCount;

  /// As ocorrências de [query] no documento, com a página e o contexto. A
  /// cópia é lida num isolate a cada busca: o texto do livro não fica na
  /// memória do app.
  ///
  /// Com [fresh], a cópia é refeita se o documento mudou desde ela: o painel
  /// Localizar fica aberto enquanto se escreve (a busca única é modal e não
  /// precisa).
  Future<TextSearchResult> searchText(String query, {int limit = 50, bool fresh = false}) async {
    if (!isOpen || query.trim().length < 2) return TextSearchResult.empty;
    final count = commandStates['.uno:StateWordCount'];
    if (fresh && _searchCopyReady != null && _searchCopyCount != count) endTextSearch();
    if (_searchCopyReady == null) {
      _searchCopyCount = count;
      final path = '$copyDir/$_copyPrefix$pid-${_copies++}.fodt';
      _searchCopyPath = path;
      _searchCopyReady = Completer<bool>();
      kit.exportCopy(path, 'fodt');
    }
    final ok = await _searchCopyReady!.future;
    final path = _searchCopyPath;
    if (!ok || path == null || _disposed) return TextSearchResult.empty;
    try {
      return await Isolate.run(() => searchFodtText(File(path).readAsStringSync(), query, limit: limit));
    } on Object {
      return TextSearchResult.empty;
    }
  }

  /// Fecha a busca: a cópia sai.
  void endTextSearch() {
    // Quem ainda espera a cópia velha recebe "sem resultado", em vez de
    // esperar para sempre.
    if (_searchCopyReady case final r? when !r.isCompleted) r.complete(false);
    if (_searchCopyPath case final p?) _deleteCopy(p);
    _searchCopyPath = null;
    _searchCopyReady = null;
  }

  /// Leva o cursor a uma ocorrência e a seleciona (só ela, pelo contexto).
  void goToHit(TextHit hit) {
    if (!isOpen) return;
    // O painel Localizar, se abrir depois, mostra a palavra, não a expressão.
    search = SearchStatus(query: SearchQuery(hit.match));
    kit.uno('.uno:ExecuteSearch', searchArgs(SearchQuery(hit.regex, regex: true), SearchCommand.next));
  }

  // ------------------------------------------ várias páginas (D-047) --

  /// Quantas páginas lado a lado, e se é o modo livro (a primeira sozinha, à
  /// direita; depois, as pares à esquerda).
  int viewColumns = 1;
  bool bookMode = false;

  /// Manda o `.uno:ViewLayout` só se mudou.
  void setViewLayout({required int columns, bool book = false}) {
    if (!isOpen || (columns == viewColumns && book == bookMode)) return;
    viewColumns = columns;
    bookMode = book;
    kit.uno(
      '.uno:ViewLayout',
      '{"ViewLayout.Columns":{"type":"short","value":$columns},"ViewLayout.BookMode":{"type":"boolean","value":$book}}',
    );
    notifyListeners();
  }

  /// A pré-edição foi cancelada (o `´` e depois Esc): o motor tira o `´` e
  /// sai do modo de entrada composta. Sem isso, o `´` ficava no texto.
  void cancelComposition() {
    _composing = false;
    if (canEdit) kit.extTextInput('', commit: true);
  }

  /// Pré-edição do IME (o `´` antes do `a`): aparece no documento, mas a
  /// próxima chamada a substitui.
  void composeText(String text) {
    if (!canEdit) return;
    _composing = text.isNotEmpty;
    kit.extTextInput(text, commit: false);
  }

  void postMouse(MouseEventType type, Offset twips, {int count = 1, int buttons = 1, int modifier = 0}) {
    if (isOpen) {
      kit.postMouse(type, twips.dx.round(), twips.dy.round(), count: count, buttons: buttons, modifier: modifier);
    }
  }

  /// Um comando do motor que muda o documento. No modo só leitura, nada.
  void uno(String command, [String args = '']) {
    if (!canEdit) return;
    kit.uno(command, args);
    _markRecovery();
  }

  void undo() => uno('.uno:Undo');

  /// Manter o parágrafo na mesma página que o seguinte (D-061, sondado na
  /// 24.2: o `ParaKeepTogether` vira o `fo:keep-with-next`). O motor não diz
  /// o estado, e sem o valor o comando não alterna.
  void setKeepWithNext(bool keep) =>
      uno('.uno:ParaKeepTogether', '{"ParaKeepTogether":{"type":"boolean","value":$keep}}');

  /// Não dividir as linhas do parágrafo entre duas páginas (o `ParaSplit`
  /// falso vira o `fo:keep-together`).
  void setKeepLinesTogether(bool keep) =>
      uno('.uno:ParaSplit', '{"ParaSplit":{"type":"boolean","value":${!keep}}}');
  void redo() => uno('.uno:Redo');
  void selectAll() {
    if (isOpen) kit.uno('.uno:SelectAll');
  }

  void applyParagraphStyle(String style) => uno(
    '.uno:StyleApply',
    '{"Style":{"type":"string","value":${_json(style)}},"FamilyName":{"type":"string","value":"ParagraphStyles"}}',
  );

  void setFontName(String name) =>
      uno('.uno:CharFontName', '{"CharFontName.FamilyName":{"type":"string","value":${_json(name)}}}');

  void setFontSize(double points) => uno('.uno:FontHeight', '{"FontHeight.Height":{"type":"float","value":$points}}');

  static String _json(String s) => '"${s.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';

  void applyCharacterStyle(String style) => uno(
    '.uno:StyleApply',
    '{"Style":{"type":"string","value":${_json(style)}},"FamilyName":{"type":"string","value":"CharacterStyles"}}',
  );

  /// Cria um estilo de parágrafo com a formatação do parágrafo do cursor, e
  /// já o aplica. O motor responde "success: false", mas cria (D-030).
  void newStyleFromSelection(String name) {
    uno(
      '.uno:StyleNewByExample',
      '{"Param":{"type":"string","value":${_json(name)}},"Family":{"type":"short","value":2}}',
    );
    refreshStyles();
    refreshSnapshot();
  }

  /// Muda o estilo [name] para ficar como o parágrafo do cursor.
  void updateStyleFromSelection(String name) {
    uno(
      '.uno:StyleUpdateByExample',
      '{"StyleName":{"type":"string","value":${_json(name)}},"Family":{"type":"short","value":2}}',
    );
    refreshSnapshot();
  }

  // ------------------------- a página, as notas e os links (D-075, D-076) --

  /// As cópias que alguém espera (`exportTo`): o caminho e o aviso.
  final _copyWaiters = <String, Completer<bool>>{};

  /// Uma mudança de estilos pela cópia em andamento (uma por vez).
  bool _patching = false;

  /// O link em que o cursor está (o callback 1 traz, D-076).
  DocLink? link;

  /// Um Ctrl+clique esperando o cursor (`expectLinkClick`).
  bool _linkClick = false;
  Timer? _linkClickTimer;
  void Function()? _linkOtherwise;

  /// O Ctrl+clique parou num link: a página pergunta se abre.
  void Function(DocLink link)? onLinkClicked;

  // ------------------------------- o salvamento automático (D-073) --

  /// Onde ficam as cópias de recuperação; null: nenhuma (os testes que não
  /// pedem, o `--bench`).
  RecoveryStore? recovery;

  /// A preferência (ligada por padrão). Desligar apaga as cópias da sessão.
  bool get autosave => _autosave;
  set autosave(bool v) {
    if (v == _autosave) return;
    _autosave = v;
    if (v) {
      if (_recoveryDirty) _scheduleAutosave();
    } else {
      _autosaveTimer?.cancel();
      _autosaveTimer = null;
      recovery?.deleteSession();
    }
  }

  bool _autosave = true;

  /// De quanto em quanto tempo, com alterações, e a pausa da digitação que
  /// a cópia espera (ela ocupa a fila do motor: ~0,3 s num capítulo de 30
  /// páginas, ~0,65 s num documento de 300).
  static Duration autosaveEvery = const Duration(seconds: 60);
  static Duration autosavePause = const Duration(seconds: 2);

  /// O nome que a cópia guarda ("Dustland — A poeira"): o Workspace põe,
  /// porque sabe do livro. null: o nome do arquivo.
  String? Function(String? path)? recoveryTitle;

  /// A cópia recuperada que esta aba abriu (até ser salva ou fechada).
  RecoveryEntry? recovered;

  /// Mudou desde a última cópia de recuperação.
  bool _recoveryDirty = false;
  DateTime _lastEdit = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _autosaveTimer;

  /// As cópias que o motor está gravando: o caminho e de que aba.
  final _recoveryWrites = <String, ({DocTab tab, String id, String? original, String? title})>{};

  void _markRecovery() {
    _recoveryDirty = true;
    _lastEdit = DateTime.now();
    _scheduleAutosave();
  }

  void _scheduleAutosave([Duration? after]) {
    if (!_autosave || recovery == null) return;
    if (after == null && _autosaveTimer != null) return;
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(after ?? autosaveEvery, _autosaveTick);
  }

  void _autosaveTick() {
    _autosaveTimer = null;
    if (_disposed || !_recoveryDirty) return;
    // Abrindo, salvando ou trocando de aba: tenta depois da pausa.
    if (busy != null || _switching || !isOpen) return _scheduleAutosave(autosavePause);
    final quiet = DateTime.now().difference(_lastEdit);
    if (quiet < autosavePause) return _scheduleAutosave(autosavePause - quiet);
    _writeRecovery();
  }

  /// Sair da aba da tela (outra aba, ou abrir uma nova) é uma pausa: a cópia
  /// sai agora, antes da troca na fila do motor.
  void _flushRecovery() {
    _autosaveTimer?.cancel();
    _autosaveTimer = null;
    if (_recoveryDirty && !_switching && isOpen && busy == null) _writeRecovery();
  }

  void _writeRecovery() {
    final store = recovery, tab = _current;
    if (store == null || tab == null || !_autosave || readOnly) return;
    _recoveryDirty = false;
    final id = store.idFor(tab.serial);
    if (!isOn('.uno:ModifiedStatus')) {
      // Desfez tudo: o arquivo já é o documento.
      store.delete(id);
      return;
    }
    if (!store.ensureDir()) return;
    final at = store.writingPath(id);
    if (_recoveryWrites.containsKey(at)) {
      // A anterior ainda está na fila do motor: esta vai depois dela.
      _recoveryDirty = true;
      return _scheduleAutosave(autosavePause);
    }
    // Uma gravação desta aba ainda na fila: a nova a substitui.
    _recoveryWrites[at] = (tab: tab, id: id, original: path ?? recovered?.original, title: recoveryTitle?.call(path) ?? recovered?.title);
    kit.exportCopy(at, 'odt');
  }

  void _recoveryWritten(({DocTab tab, String id, String? original, String? title}) w, {required bool ok}) {
    final store = recovery;
    if (store == null) return;
    if (!ok || !tabs.contains(w.tab)) {
      // Falhou, ou a aba fechou no meio (fechar já apagou a cópia).
      store.dropWriting(w.id);
      return;
    }
    store.commit(w.id, original: w.original, title: w.title);
    // A cópia nova tem tudo: a recuperada que a aba abriu sai (no Linux, o
    // motor continua lendo o arquivo aberto mesmo apagado).
    final adopted = w.tab == _current ? recovered : w.tab.recovered;
    if (adopted != null && adopted.id != w.id) store.delete(adopted.id);
  }

  /// A aba salvou ou fechou: as cópias dela (e a recuperada que ela abriu)
  /// não servem mais.
  void _forgetRecovery(DocTab t, RecoveryEntry? adopted) {
    final store = recovery;
    if (store == null) return;
    store.delete(store.idFor(t.serial));
    if (adopted != null) store.delete(adopted.id);
  }

  // --------------------------------------------------- a cópia (D-044) --

  /// O que se sabe do documento pela última cópia temporária: as
  /// propriedades dos estilos, as fontes declaradas e os títulos.
  FodtSnapshot snapshot = FodtSnapshot.empty;

  /// A cópia em andamento (o caminho), e se outra foi pedida no meio.
  String? _exporting;
  bool _exportAgain = false;
  int _copies = 0;

  /// Onde vão as cópias: o `$XDG_RUNTIME_DIR` fica na memória e é só do
  /// usuário; sem ele, a pasta temporária.
  static String get copyDir => copyDirOverride ?? Platform.environment['XDG_RUNTIME_DIR'] ?? Directory.systemTemp.path;

  /// Os testes põem as cópias numa pasta deles (test/flutter_test_config.dart).
  @visibleForTesting
  static String? copyDirOverride;

  /// O começo do nome das cópias deste processo.
  static String get copyPrefixOfThisProcess => '$_copyPrefix$pid-';
  static const _copyPrefix = 'psito-quill-copia-';

  /// Pede uma cópia nova. Ao abrir, ao salvar e ao mudar um estilo; nunca a
  /// cada tecla (a cópia grava o documento inteiro na fila do motor).
  void refreshSnapshot() {
    if (!isOpen) return;
    _editedSinceCopy = false;
    if (_exporting != null) {
      _exportAgain = true;
      return;
    }
    final path = '$copyDir/$_copyPrefix$pid-${_copies++}.fodt';
    _exporting = path;
    kit.exportCopy(path, 'fodt');
  }

  Future<void> _readCopy(String path) async {
    final tab = _current;
    FodtSnapshot? snap;
    try {
      snap = await Isolate.run(() => parseFodt(File(path).readAsStringSync()));
    } on Object {
      snap = null;
    } finally {
      _deleteCopy(path);
    }
    if (_disposed || snap == null || !isOpen) return;
    if (tab != _current) {
      // Trocou de aba no meio: a cópia é da outra.
      tab?.snapshot = snap;
      return;
    }
    snapshot = snap;
    _takePendingScene();
    notifyListeners();
  }

  /// A cópia tem o texto do livro: sai assim que é lida (com a trava que o
  /// LibreOffice deixa ao lado).
  static void _deleteCopy(String path) {
    final f = File(path);
    for (final victim in [f, File('${f.parent.path}/.~lock.${f.uri.pathSegments.last}#')]) {
      try {
        if (victim.existsSync()) victim.deleteSync();
      } on FileSystemException {
        // Já foi.
      }
    }
  }

  /// Cópias de uma sessão que caiu antes de apagar (o perfil só aceita um
  /// Quill por vez, então nenhuma é de outro processo vivo).
  static void cleanStaleCopies() {
    try {
      for (final f in Directory(copyDir).listSync().whereType<File>()) {
        if (f.uri.pathSegments.last.startsWith(_copyPrefix)) _deleteCopy(f.path);
      }
    } on FileSystemException {
      // Sem acesso à pasta: nada a limpar.
    }
  }

  void refreshStyles() {
    if (isOpen) kit.requestCommandValues('.uno:StyleApply');
  }

  // --------------------------------------------- caractere e parágrafo --

  /// [rgb] null volta à cor automática.
  void setFontColor(int? rgb) => uno('.uno:Color', '{"Color.Color":{"type":"long","value":${rgb ?? -1}}}');

  /// [rgb] null tira o realce.
  void setHighlight(int? rgb) =>
      uno('.uno:CharBackColor', '{"CharBackColor.Color":{"type":"long","value":${rgb ?? -1}}}');

  /// Recuos em cm. Os nomes "LRSpace.*" são os que o 24.2 aceita (D-032).
  void setIndents({double? left, double? right, double? firstLine}) {
    final args = {
      if (left != null) 'LRSpace.LeftMargin': _mm100(left),
      if (right != null) 'LRSpace.RightMargin': _mm100(right),
      if (firstLine != null) 'LRSpace.FirstLineIndent': _mm100(firstLine),
    };
    if (args.isEmpty) return;
    uno(
      '.uno:LeftRightParaMargin',
      '{${args.entries.map((e) => '"${e.key}":{"type":"long","value":${e.value}}').join(',')}}',
    );
  }

  /// Entrelinhas proporcional, em %.
  void setLineSpacing(int percent) => uno(
    '.uno:LineSpacing',
    '{"LineSpacing.Mode":{"type":"short","value":0},"LineSpacing.Height":{"type":"short","value":$percent}}',
  );

  /// Mais (ou menos) espaço antes e depois do parágrafo, em passos do motor.
  /// O `.uno:ULSpacing` com valores não funciona no 24.2 (D-032).
  void changeParagraphSpacing({required bool increase}) =>
      uno(increase ? '.uno:ParaspaceIncrease' : '.uno:ParaspaceDecrease');

  static int _mm100(double cm) => (cm * 1000).round();

  // ------------------------------------------------------------ página --

  void setPageSize(PageSize size) {
    final (w, h) = landscape ? (size.height, size.width) : (size.width, size.height);
    uno(
      '.uno:AttributePageSize',
      '{"AttributePageSize.Width":{"type":"long","value":$w},"AttributePageSize.Height":{"type":"long","value":$h}}',
    );
    // A régua vertical lê as margens da cópia (D-046).
    refreshSnapshot();
  }

  /// Na 24.2, o `.uno:AttributePage` só muda a marca da orientação, e a
  /// página continua do mesmo jeito. Como no painel lateral do LibreOffice,
  /// o Quill troca a largura e a altura antes (D-036).
  void setLandscape(bool value) {
    if (pageSizeMm100 case (final w, final h)) {
      final (long, short) = w > h ? (w, h) : (h, w);
      final (nw, nh) = value ? (long, short) : (short, long);
      uno(
        '.uno:AttributePageSize',
        '{"AttributePageSize.Width":{"type":"long","value":$nw},"AttributePageSize.Height":{"type":"long","value":$nh}}',
      );
    }
    uno('.uno:AttributePage', '{"AttributePage.Landscape":{"type":"boolean","value":$value}}');
    // A régua vertical lê as margens da cópia (D-046).
    refreshSnapshot();
  }

  /// O tamanho da página, em 1/100 mm. O motor não diz, e o Quill tira do
  /// tamanho do documento: no LOK, o Writer põe [_pageGap] twips em volta e
  /// entre as páginas (medido na 24.2). Vale para documentos com um tamanho
  /// de página só. Com páginas lado a lado, a pilha é de fileiras, e a
  /// largura vem da régua do motor.
  (int, int)? get pageSizeMm100 {
    if (documentSize.isEmpty) return null;
    final pages = page?.$2 ?? 1;
    final rows = bookMode ? pages ~/ 2 + 1 : (pages + viewColumns - 1) ~/ viewColumns;
    int mm100(double twips) => (twips * 2540 / 1440).round();
    final w = viewColumns > 1 ? ruler?.pageWidth : mm100(documentSize.width - 2 * _pageGap);
    final h = (documentSize.height - _pageGap) / rows - _pageGap;
    if (w == null || w <= 0 || h <= 0) return null;
    return (w, mm100(h));
  }

  static const _pageGap = 284;

  void setPageMargins(PageMargins m) {
    uno(
      '.uno:PageLRMargin',
      '{"PageLRMargin.Left":{"type":"long","value":${_mm100(m.left)}},"PageLRMargin.Right":{"type":"long","value":${_mm100(m.right)}}}',
    );
    uno(
      '.uno:PageULMargin',
      '{"PageULMargin.Upper":{"type":"long","value":${_mm100(m.top)}},"PageULMargin.Lower":{"type":"long","value":${_mm100(m.bottom)}}}',
    );
    // A régua vertical lê as margens da cópia (D-046).
    refreshSnapshot();
  }

  // ---------------------------------------------- imagens e tabelas --

  void insertImage(String path) =>
      uno('.uno:InsertGraphic', '{"FileName":{"type":"string","value":${_json(Uri.file(path).toString())}}}');

  /// Arrasta a imagem selecionada de [from] para [to] (twips): pela alça,
  /// redimensiona; pelo meio, move.
  void dragGraphic(Offset from, Offset to) {
    if (!canEdit || graphic == null) return;
    kit.setGraphicSelection(GraphicDrag.start, from.dx.round(), from.dy.round());
    kit.setGraphicSelection(GraphicDrag.end, to.dx.round(), to.dy.round());
  }

  /// Muda o tamanho da imagem selecionada, em cm (a aba Imagem, D-043).
  ///
  /// A 24.2 não aceita o `.uno:Size` com valores; o tamanho vai pelas alças,
  /// como o mouse. A alça do canto sempre mantém a proporção (manda a
  /// largura); sem a proporção, vai a alça da direita e, quando o novo
  /// retângulo chega, a de baixo.
  void setGraphicSizeCm({double? width, double? height, required bool keepRatio}) {
    final r = graphic;
    if (!canEdit || r == null || r.isEmpty) return;
    double twips(double cm) => cm * 1440 / 2.54;
    if (keepRatio) {
      final w = width != null ? twips(width) : twips(height!) * r.width / r.height;
      dragGraphic(r.bottomRight, Offset(r.left + w, r.top + w * r.height / r.width));
      return;
    }
    if (width != null) {
      // Antes da alça: a resposta do motor pode chegar logo.
      _pendingGraphicHeight = height == null ? null : twips(height);
      dragGraphic(r.centerRight, Offset(r.left + twips(width), r.center.dy));
    } else if (height != null) {
      dragGraphic(r.bottomCenter, Offset(r.center.dx, r.top + twips(height)));
    }
  }

  /// A altura que falta, sem a proporção: vai quando o motor manda o
  /// retângulo depois da largura.
  double? _pendingGraphicHeight;

  void insertTable(int rows, int columns) =>
      uno('.uno:InsertTable', '{"Rows":{"type":"long","value":$rows},"Columns":{"type":"long","value":$columns}}');

  // ------------------------------------------------- localizar e trocar --

  void find(SearchQuery q, {bool backward = false}) => _search(q, SearchCommand.next, backward: backward);

  /// Acha todas: conta e seleciona.
  void findAll(SearchQuery q) => _search(q, SearchCommand.all);

  /// Troca a ocorrência selecionada e vai para a próxima.
  void replace(SearchQuery q, String replacement) {
    if (canEdit) _search(q, SearchCommand.replace, replacement: replacement);
  }

  /// Troca todas. O motor não diz quantas: o Quill conta antes (D-031).
  void replaceAll(SearchQuery q, String replacement) {
    if (!canEdit || q.isEmpty) return;
    _countingForReplace = true;
    search = SearchStatus(query: q);
    kit.uno('.uno:ExecuteSearch', searchArgs(q, SearchCommand.all));
    kit.uno('.uno:ExecuteSearch', searchArgs(q, SearchCommand.replaceAll, replacement: replacement));
  }

  bool _countingForReplace = false;

  void _search(SearchQuery q, SearchCommand c, {String replacement = '', bool backward = false}) {
    if (!isOpen || q.isEmpty) return;
    // Uma resposta perdida do salto a um título não engole a do Localizar.
    _headingSearches = 0;
    search = SearchStatus(query: q);
    kit.uno('.uno:ExecuteSearch', searchArgs(q, c, replacement: replacement, backward: backward));
  }

  void clearSearch() {
    search = const SearchStatus();
    searchHighlights = const [];
    notifyListeners();
  }

  // ------------------------------------------------ menu de contexto --

  /// Clique direito em [twips]: o motor responde com o menu dele
  /// (sugestões de ortografia, se a palavra estiver errada).
  void requestContextMenu(Offset twips) {
    if (!isOpen) return;
    _contextAt = twips;
    final (x, y) = (twips.dx.round(), twips.dy.round());
    kit.postMouse(MouseEventType.down, x, y, buttons: 4);
    kit.postMouse(MouseEventType.up, x, y, buttons: 4);
  }

  void clearContextMenu() {
    if (contextMenu == null) return;
    contextMenu = null;
    notifyListeners();
  }

  /// Um item do menu do motor (".uno:SpellCheckApplySuggestion?...").
  void runEngineCommand(String command) {
    if (command.isEmpty) return;
    if (canEdit || command == '.uno:Copy') kit.uno(command);
  }

  /// Os idiomas com ortografia instalada (pedidos uma vez, ao abrir).
  List<DocLanguage> languages = const [];

  /// O idioma onde está o cursor (ou o da seleção).
  DocLanguage? get language => parseLanguage(commandStates['.uno:LanguageStatus']);

  /// Muda o idioma da seleção ou, sem seleção, do parágrafo (D-063): [name]
  /// é o nome que o motor deu na lista; null tira a verificação; [reset]
  /// volta ao idioma do estilo.
  void setLanguage(String? name, {bool reset = false}) {
    if (!canEdit) return;
    final where = hasSelection ? 'Current_' : 'Paragraph_';
    final what = reset ? 'RESET_LANGUAGES' : name ?? 'LANGUAGE_NONE';
    kit.uno('.uno:LanguageStatus', jsonEncode({'Language': {'type': 'string', 'value': '$where$what'}}));
    _edited();
  }

  /// Liga e desliga a ortografia automática (os sublinhados vermelhos).
  void toggleSpellOnline() {
    if (isOpen) kit.uno('.uno:SpellOnline');
  }

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

  // ------------------------------- o trabalho depois de abrir (D-068) --

  /// O que o Quill pede ao motor ao abrir (a cópia da Estrutura e dos
  /// estilos, as listas de fontes, de estilos e de idiomas) espera o primeiro
  /// ladrilho: tudo roda na thread do motor, e a cópia de um capítulo
  /// atrasava a primeira tela. Sem ladrilho (sem a vista), vai depois de 1 s.
  ///
  /// Ligado no app (`main.dart`); nos testes, o trabalho vai na hora, como
  /// antes, salvo nos que conferem o adiamento.
  final bool deferOpenWork;
  Timer? _openWork;
  static const openWorkFallback = Duration(seconds: 1);

  void _deferOpenWork() {
    if (!deferOpenWork) {
      _runOpenWork();
      return;
    }
    _openWork?.cancel();
    _openWork = Timer(openWorkFallback, _runOpenWork);
  }

  void _runOpenWork() {
    _openWork?.cancel();
    _openWork = null;
    if (!isOpen || _disposed) return;
    if (fonts.isEmpty) kit.requestCommandValues('.uno:CharFontName');
    if (languages.isEmpty) kit.requestCommandValues('.uno:LanguageStatus');
    kit.requestCommandValues('.uno:StyleApply');
    refreshSnapshot();
  }

  // ------------------------------------------- ocupado (Etapa 8, D-066) --

  /// Salvando: de pedir até o motor responder (salvo ou falhou).
  bool _saving = false;

  /// Se o motor nunca responder, a tela não fica travada para sempre.
  Timer? _savingGuard;
  static const savingTimeout = Duration(seconds: 90);

  /// O que trava a tela: abrir o documento da tela, ou salvar. null: nada.
  BusyKind? get busy => docStatus == DocStatus.opening
      ? BusyKind.opening
      : _saving
      ? BusyKind.saving
      : _working
      ? BusyKind.working
      : null;

  /// Um trabalho de várias etapas no motor (dividir ou juntar capítulos,
  /// D-079): a tela trava como ao salvar, para uma tecla no meio não cair
  /// entre a cópia e o corte.
  bool _working = false;
  Future<T> whileWorking<T>(Future<T> Function() work) async {
    _working = true;
    notifyListeners();
    try {
      return await work();
    } finally {
      _working = false;
      if (!_disposed) notifyListeners();
    }
  }

  /// O progresso que o motor mandou (0 a 100); null: sem número.
  int? progress;

  /// Um trabalho do motor com progresso que não é abrir nem salvar: só
  /// aparece no rodapé, sem travar nada.
  String? backgroundTask;

  void _endSaving() {
    _saving = false;
    _savingGuard?.cancel();
    _savingGuard = null;
  }

  /// Só a vista lê (o parágrafo para o leitor de tela): não refaz nada pesado.
  void _notifyView() {
    _viewOnly = true;
    super.notifyListeners();
    _viewOnly = false;
  }

  // ------------------------------ o documento no leitor de tela (D-067) --

  /// Ligado pela preferência ou com o leitor de tela ativo. Vale para cada
  /// documento aberto (o motor guarda por vista).
  bool _accessibility = false;
  bool get accessibility => _accessibility;

  /// O texto do parágrafo do cursor e onde o cursor está nele, como o motor
  /// diz; null com a acessibilidade desligada.
  String? a11yParagraph;
  int a11yCaret = 0;

  void setAccessibility(bool on) {
    if (on == _accessibility) return;
    _accessibility = on;
    if (!on) {
      a11yParagraph = null;
      a11yCaret = 0;
    }
    if (isOpen) kit.setAccessibility(on);
    _notifyView();
  }

  /// Carrega o dicionário de português enquanto a tela inicial está aberta
  /// (D-069): o motor abre um documento oculto com uma frase, e a ortografia
  /// automática faz o resto. Sem isso, o primeiro capítulo espera ~800 ms
  /// pelo dicionário. O arquivo é uma cópia como as outras (o motor apaga; se
  /// sobrar, a limpeza das cópias leva).
  void preloadSpelling() {
    if (isOpen) return;
    final path = '$copyDir/$_copyPrefix$pid-ortografia.fodt';
    try {
      File(path).writeAsStringSync(_spellingSample);
    } on FileSystemException {
      return;
    }
    kit.preloadSpelling(path);
  }

  static const _spellingSample = '<?xml version="1.0" encoding="UTF-8"?>'
      '<office:document xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" '
      'xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0" '
      'xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0" '
      'xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0" '
      'office:version="1.3" office:mimetype="application/vnd.oasis.opendocument.text">'
      '<office:styles><style:default-style style:family="paragraph">'
      '<style:text-properties fo:language="pt" fo:country="BR"/></style:default-style></office:styles>'
      '<office:body><office:text><text:p>O livro começa aqui.</text:p></office:text></office:body>'
      '</office:document>';

  /// Só a barra de status lê o progresso: não refaz a faixa nem o painel.
  void _notifyStatus() {
    statusRevision++;
    _viewOnly = true;
    super.notifyListeners();
    _viewOnly = false;
  }

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
    _saving = true;
    _savingGuard?.cancel();
    _savingGuard = Timer(savingTimeout, () {
      if (!_saving || _disposed) return;
      _endSaving();
      notifyListeners();
    });
    notifyListeners();
    kit.saveAs(target, dot < 0 ? 'odt' : target.substring(dot + 1).toLowerCase());
  }

  /// Troca o esquema de cor do papel ("PsitoQuillClaro", por exemplo). Com
  /// [invert], o Quill inverte a luminosidade dos ladrilhos (o papel escuro,
  /// D-074).
  void setPaperScheme(String name, {PaperInvert? invert}) {
    kit.setPaperInvert(invert);
    kit.uno('.uno:ChangeTheme', '{"NewTheme":{"type":"string","value":"$name"}}');
    kit.repaintAll();
  }

  /// Os eventos que são de um documento (e não do motor, nem de uma cópia).
  static bool _ofDocument(KitEvent e) =>
      e is TilePlaced ||
      e is CursorMoved ||
      e is CursorVisibility ||
      e is SelectionChanged ||
      e is CommandStateChanged ||
      e is DocumentSizeChanged ||
      e is SearchResult ||
      e is SearchNotFound ||
      e is ContextMenuReady ||
      e is RulerUpdated ||
      e is GraphicSelected ||
      e is TableSelected ||
      (e is CommandValues && e.command == '.uno:StyleApply');

  void _onEvent(KitEvent e) {
    // Até o motor confirmar o documento da tela, o que chega é do anterior.
    if (_switching && _ofDocument(e)) return;
    switch (e) {
      case KitReady(:final version):
        kitStatus = KitStatus.ready;
        engineVersion = version;
      case KitFailed(:final message):
        kitStatus = KitStatus.failed;
        this.message = ErrorMessage(message);
      case DocumentOpened(:final size, :final id):
        progress = null;
        final tab = _pendingOpens.isEmpty ? _current : _pendingOpens.removeAt(0);
        tab?.engineId = id;
        if (tab != null && tab != _current) {
          // Abriu, mas outra aba já está na tela (dois pedidos seguidos).
          tab
            ..status = DocStatus.open
            ..path = tab.recovered == null ? tab.openingPath : null
            ..documentSize = size;
          if (tab.recovered != null) tab.openingPath = null;
          return;
        }
        _switching = false;
        if (_replaceWhenOpened case final old?) {
          _replaceWhenOpened = null;
          unawaited(closeTab(old));
        }
        _cameFrom = null;
        _enforceLimit();
        docStatus = DocStatus.open;
        // A cópia recuperada abre como um documento novo, sem arquivo.
        path = recovered == null ? _openingPath : null;
        if (recovered != null) _openingPath = null;
        documentSize = size;
        // O LOK manda a posição do cursor ao abrir, mas o "cursor visível"
        // só depois da primeira tecla. O cursor começa visível; só some se o
        // motor disser (com uma imagem selecionada, por exemplo).
        cursorVisible = true;
        if (_accessibility) kit.setAccessibility(true);
        snapshot = FodtSnapshot.empty;
        _deferOpenWork();
      case DocumentOpenFailed(:final message):
        progress = null;
        final tab = _pendingOpens.isEmpty ? _current : _pendingOpens.removeAt(0);
        final failed = OpenFailedMessage((tab == _current ? _openingPath : tab?.openingPath) ?? '', message);
        _replaceWhenOpened = null;
        final back = _cameFrom;
        _cameFrom = null;
        if (tab != null && tab == _current && back != null && tabs.contains(back)) {
          // Volta para a aba de onde se veio; o motor nem saiu dela.
          tabs.remove(tab);
          _current = back;
          tabRevision++;
          _switching = false;
          _restore(back);
          this.message = failed;
        } else if (tab != null && tab != _current) {
          tabs.remove(tab);
          return;
        } else {
          if (tab != null) tabs.remove(tab);
          _current = null;
          _switching = false;
          docStatus = DocStatus.failed;
          this.message = failed;
        }
      case DocumentActivated(:final id, :final size):
        if (_current?.engineId != id) return;
        _switching = false;
        a11yParagraph = null;
        if (_accessibility) kit.setAccessibility(true);
        documentSize = size;
      case DocumentClosed(:final id):
        if (_unloading.remove(id)) return;
        final tab = [for (final t in tabs) if (t.engineId == id) t].firstOrNull;
        if (tab != null && tab != _current) {
          tabs.remove(tab);
          _forgetRecovery(tab, tab.recovered);
          break;
        }
        docStatus = DocStatus.none;
        snapshot = FodtSnapshot.empty;
        viewColumns = 1;
        bookMode = false;
        ruler = null;
        _exportAgain = false;
        cursorVisible = false;
        _tiles.clear();
        path = null;
        readOnly = false;
        lockOwner = null;
        graphic = null;
        inTable = false;
        contextMenu = null;
        commandStates.clear();
        if (tab != null) _removeTab(tab);
      case DocumentSizeChanged(:final size):
        documentSize = size;
      case TilePlaced(:final slot, :final key):
        _tiles[slot] = TilePlacement(slot, key, kit.textureId(slot));
        if (_openWork != null) _runOpenWork();
      case CursorMoved(:final rect, link: final l):
        cursor = rect;
        if (l != link) {
          link = l;
          // O menu de contexto e a faixa mostram "Abrir o link" pelo estado.
          stateRevision++;
        }
        if (_linkClick) _settleLinkClick(l);
      case CursorVisibility(:final visible):
        cursorVisible = visible;
      case SelectionChanged(:final rects):
        selection = rects;
      case CommandStateChanged(:final command, :final value):
        if (commandStates[command] == value) return;
        commandStates[command] = value;
        if (command == '.uno:ModifiedStatus' && value == 'true') _markRecovery();
        if (statusOnlyStates.contains(command)) {
          // A página e as palavras mudam ao rolar e a cada tecla, e só a barra
          // de status e a Estrutura as leem: não refazem a faixa nem o painel.
          statusRevision++;
          _viewOnly = true;
          super.notifyListeners();
          _viewOnly = false;
          return;
        }
      case CommandValues(command: '.uno:StyleApply', :final json):
        final lists = parseStyleLists(json);
        paragraphStyles = lists.paragraph;
        characterStyles = lists.character;
      case CommandValues(command: '.uno:LanguageStatus', :final json):
        languages = parseLanguageList(json);
      case CommandValues(:final command, :final json):
        if (command != '.uno:CharFontName') return;
        fonts = parseFontList(json);
        // Os filtros da lista de fontes (D-045): uma chamada ao fontconfig
        // para a lista toda, quando ela chega.
        final classes = kit.fontClasses(fonts);
        fontClasses = {for (var i = 0; i < fonts.length; i++) fonts[i]: classes[i]};
      case SearchResult() || SearchNotFound() when _headingSearches > 0:
        _headingSearches--;
        return;
      case SearchResult(:final matches, :final all):
        searchHighlights = [for (final m in matches) ...m];
        if (_countingForReplace) {
          _countingForReplace = false;
          search = SearchStatus(query: search.query, replaced: matches.length);
          searchHighlights = const [];
        } else {
          search = SearchStatus(query: search.query, count: all ? matches.length : search.count);
        }
      case SearchNotFound():
        _countingForReplace = false;
        searchHighlights = const [];
        search = SearchStatus(query: search.query, notFound: true, count: 0);
      case ContextMenuReady(:final items):
        final at = _contextAt;
        if (at == null) return;
        _contextAt = null;
        contextMenu = PendingContextMenu(at, items);
      case RulerUpdated(:final ruler):
        if (ruler == this.ruler) return;
        this.ruler = ruler;
      case GraphicSelected(:final rect):
        graphic = rect;
        if (_pendingGraphicHeight case final h? when rect != null && !rect.isEmpty) {
          _pendingGraphicHeight = null;
          dragGraphic(rect.bottomCenter, Offset(rect.center.dx, rect.top + h));
        }
      case TableSelected(inTable: final t):
        if (t == inTable) return;
        inTable = t;
      case TextSelectionContent(:final text):
        if (!_awaitingCopy) return;
        _awaitingCopy = false;
        if (text.isEmpty) return;
        _lastCopied = text;
        unawaited(clipboard.write(text));
        return;
      case DocumentSaved(:final path):
        _endSaving();
        this.path = path;
        readOnly = false;
        lockOwner = null;
        commandStates['.uno:ModifiedStatus'] = 'false';
        if (_current case final t?) _forgetRecovery(t, recovered);
        recovered = null;
        _recoveryDirty = false;
        _autosaveTimer?.cancel();
        _autosaveTimer = null;
        message = SavedMessage(path);
        refreshSnapshot();
      case CopyExported(:final path, :final ok):
        if (_copyWaiters.remove(path) case final c?) {
          c.complete(ok);
          return;
        }
        if (_recoveryWrites.remove(path) case final w?) {
          _recoveryWritten(w, ok: ok);
          return;
        }
        if (path == _searchCopyPath) {
          if (!ok) _searchCopyPath = null;
          _searchCopyReady?.complete(ok);
          return;
        }
        if (path != _exporting) {
          // Uma cópia que ninguém espera mais (o documento fechou): sai.
          _deleteCopy(path);
          return;
        }
        _exporting = null;
        if (ok) {
          unawaited(_readCopy(path));
        } else {
          _deleteCopy(path);
        }
        if (_exportAgain) {
          _exportAgain = false;
          refreshSnapshot();
        }
        return;
      case SaveFailed(:final message):
        _endSaving();
        this.message = ErrorMessage(message);
      case PluginLog(:final text):
        message = PluginMessage(text);
      case PluginFinished(:final ok, :final error):
        if (!ok) message = ErrorMessage(error);
      case A11yParagraph(:final text, :final caret):
        a11yParagraph = text;
        a11yCaret = caret;
        _notifyView();
        return;
      case A11yCaret(:final caret):
        a11yCaret = caret;
        _notifyView();
        return;
      case ProgressStarted(:final label):
        progress = 0;
        backgroundTask = busy == null ? label : null;
        _notifyStatus();
        return;
      case ProgressValue(:final percent):
        progress = percent;
        _notifyStatus();
        return;
      case ProgressFinished():
        if (progress == null && backgroundTask == null) return;
        progress = null;
        backgroundTask = null;
        _notifyStatus();
        return;
      case OtherKitEvent():
        return;
      // As conversões são do livro (D-071) e da mudança de estilos (D-075);
      // a impressão, de quem a pediu (D-076).
      case FileConverted():
        return;
      case Printed():
        return;
    }
    // Ladrilhos, cursor e seleção mudam só a vista (D-037).
    _viewOnly = e is TilePlaced || e is CursorMoved || e is CursorVisibility || e is SelectionChanged;
    notifyListeners();
    _viewOnly = false;
  }

  /// Sobe a cada mudança que não é só da vista (os estados, a imagem, a
  /// tabela, o arquivo). Os painéis pesados se refazem só quando ela muda.
  int stateRevision = 0;
  bool _viewOnly = false;

  /// Os estados que só a barra de status e a Estrutura leem.
  static const statusOnlyStates = {'.uno:StatePageNumber', '.uno:StateWordCount'};

  /// Sobe quando um dos [statusOnlyStates] muda (e com a [stateRevision]).
  int statusRevision = 0;

  @override
  void notifyListeners() {
    if (!_viewOnly) {
      stateRevision++;
      statusRevision++;
    }
    super.notifyListeners();
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _outlineTimer?.cancel();
    _savingGuard?.cancel();
    _openWork?.cancel();
    _autosaveTimer?.cancel();
    _linkClickTimer?.cancel();
    for (final c in _copyWaiters.values) {
      if (!c.isCompleted) c.complete(false);
    }
    if (_exporting case final p?) _deleteCopy(p);
    endTextSearch();
    _sub.cancel();
    super.dispose();
  }
}
