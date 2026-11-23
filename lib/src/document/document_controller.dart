// O estado do documento aberto, montado a partir dos eventos do motor.
//
// Observer: a UI escuta este ChangeNotifier, e ele escuta o QuillKit. Nada
// aqui é adivinhado: o negrito ativo, o cursor, o "modificado", o desfazer
// e a página vêm do motor.
import 'dart:async';
import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter/foundation.dart';

import '../kit/lok/lo_styles.dart';
import '../kit/lok/lok_payloads.dart';
import '../kit/quill_kit.dart';
import 'search.dart';
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
  bool get modified => isOn('.uno:ModifiedStatus');
  bool get canUndo => canEdit && _enabled('.uno:Undo');
  bool get canRedo => canEdit && _enabled('.uno:Redo');
  bool get hasSelection => selection.isNotEmpty;

  /// Página do cursor e total.
  (int, int)? get page => parsePageStatus(commandStates['.uno:StatePageNumber']);
  ({int words, int characters, bool selection})? get wordCount => parseWordCount(commandStates['.uno:StateWordCount']);

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
    search = const SearchStatus();
    searchHighlights = const [];
    contextMenu = null;
    graphic = null;
    inTable = false;
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

  /// A pré-edição foi cancelada (o `´` e depois Esc): o motor tira o `´` e
  /// sai do modo de entrada composta. Sem isso, o `´` ficava no texto.
  void cancelComposition() {
    if (canEdit) kit.extTextInput('', commit: true);
  }

  /// Pré-edição do IME (o `´` antes do `a`): aparece no documento, mas a
  /// próxima chamada a substitui.
  void composeText(String text) {
    if (canEdit) kit.extTextInput(text, commit: false);
  }

  void postMouse(MouseEventType type, Offset twips, {int count = 1, int buttons = 1, int modifier = 0}) {
    if (isOpen) {
      kit.postMouse(type, twips.dx.round(), twips.dy.round(), count: count, buttons: buttons, modifier: modifier);
    }
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
  }

  /// Muda o estilo [name] para ficar como o parágrafo do cursor.
  void updateStyleFromSelection(String name) => uno(
    '.uno:StyleUpdateByExample',
    '{"StyleName":{"type":"string","value":${_json(name)}},"Family":{"type":"short","value":2}}',
  );

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
  }

  /// O tamanho da página, em 1/100 mm. O motor não diz, e o Quill tira do
  /// tamanho do documento: no LOK, o Writer põe [_pageGap] twips em volta e
  /// entre as páginas (medido na 24.2). Vale para documentos com um tamanho
  /// de página só.
  (int, int)? get pageSizeMm100 {
    if (documentSize.isEmpty) return null;
    final pages = page?.$2 ?? 1;
    final w = documentSize.width - 2 * _pageGap;
    final h = (documentSize.height - _pageGap) / pages - _pageGap;
    if (w <= 0 || h <= 0) return null;
    int mm100(double twips) => (twips * 2540 / 1440).round();
    return (mm100(w), mm100(h));
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
        kit.requestCommandValues('.uno:StyleApply');
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
        graphic = null;
        inTable = false;
        contextMenu = null;
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
      case CommandValues(command: '.uno:StyleApply', :final json):
        final lists = parseStyleLists(json);
        paragraphStyles = lists.paragraph;
        characterStyles = lists.character;
      case CommandValues(:final command, :final json):
        if (command != '.uno:CharFontName') return;
        fonts = parseFontList(json);
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
      case GraphicSelected(:final rect):
        graphic = rect;
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
    // Ladrilhos, cursor e seleção mudam só a vista (D-037).
    _viewOnly = e is TilePlaced || e is CursorMoved || e is CursorVisibility || e is SelectionChanged;
    notifyListeners();
    _viewOnly = false;
  }

  /// Sobe a cada mudança que não é só da vista (os estados, a imagem, a
  /// tabela, o arquivo). Os painéis pesados se refazem só quando ela muda.
  int stateRevision = 0;
  bool _viewOnly = false;

  @override
  void notifyListeners() {
    if (!_viewOnly) stateRevision++;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
