// Um motor de mentira para os testes: responde na hora, sem LibreOffice.
//
// Guarda o que recebeu (teclas, comandos, salvamentos) para os testes
// conferirem, e simula o essencial com um texto de uma linha só: digitar,
// pré-edição do IME, desfazer, seleção, copiar e colar, negrito, o estado
// "modificado", ladrilhos da área visível e salvar. Da Fase 2: localizar e
// substituir no texto, o menu de contexto com sugestões de ortografia,
// estilos, imagens e tabelas (só os eventos).
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Offset, Rect, Size;

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

  // Os documentos abertos (D-054): o ativo vive nos campos de cima (text,
  // openedPath...); os outros, guardados aqui.
  final _docs = <int, _FakeDoc>{};
  int _nextId = 1;

  /// O número do documento ativo (0: nenhum).
  int activeId = 0;

  /// Os números dos documentos abertos.
  Iterable<int> get openIds => _docs.keys;

  void _stash() {
    if (activeId == 0) return;
    _docs[activeId] = _FakeDoc(openedPath, text, bold, [..._undo], [..._redo]);
  }

  void _load(_FakeDoc d) {
    openedPath = d.path;
    text = d.text;
    bold = d.bold;
    preedit = '';
    _undo
      ..clear()
      ..addAll(d.undo);
    _redo
      ..clear()
      ..addAll(d.redo);
    _placed.clear();
  }

  @override
  void activate(int id) {
    final d = _docs[id];
    if (d == null) return;
    _stash();
    activeId = id;
    _load(d);
    _emit(DocumentActivated(id, documentSize));
  }

  @override
  void closeDocument(int id) {
    if (!_docs.containsKey(id)) return;
    if (id == activeId) {
      close();
      return;
    }
    _docs.remove(id);
    _emit(DocumentClosed(id));
  }

  @override
  void open(String path) {
    opened.add(path);
    if (openFails) {
      _emit(const DocumentOpenFailed('arquivo estragado'));
      return;
    }
    _stash();
    final id = _nextId++;
    activeId = id;
    _load(_FakeDoc(path, '', false, const [], const []));
    _docs[id] = _FakeDoc(path, '', false, const [], const []);
    // Como o LOK: ao abrir, manda onde está o cursor, mas não manda o
    // "cursor visível" (esse só chega depois da primeira tecla).
    _emit(DocumentOpened(documentSize, id: id));
    // A régua de uma A4 com 2 cm à esquerda e 1 cm à direita (o capítulo).
    _emit(const RulerUpdated(RulerInfo(pageWidth: 21001, leftMargin: 2000, textWidth: 18000)));
    _state('.uno:ModifiedStatus', 'false');
    _state('.uno:Undo', 'disabled');
    _state('.uno:Redo', 'disabled');
    _state('.uno:StatePageNumber', 'Página 1 de 3');
    _state('.uno:StateWordCount', '0 palavras, 0 caracteres');
    _state('.uno:LanguageStatus', 'Português (Brasil);pt-BR');
    _state('.uno:StyleApply', 'Estilo de parágrafo padrão');
    _emitCursor();
  }

  @override
  void close() {
    final id = activeId;
    _docs.remove(id);
    activeId = 0;
    openedPath = null;
    _emit(DocumentClosed(id));
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

  /// Os pedidos de papel invertido (D-074), em ordem.
  final paperInverts = <PaperInvert?>[];

  @override
  void setPaperInvert(PaperInvert? invert) => paperInverts.add(invert);

  /// Os pedidos de acessibilidade (ligar e desligar).
  final accessibility = <bool>[];

  @override
  void setAccessibility(bool on) => accessibility.add(on);

  /// O autor do próximo documento aberto ([setAuthor]).
  String author = '';

  @override
  void setAuthor(String name) => author = name;

  /// Os comentários do documento (D-088), mudados pelos comandos `.uno:`.
  final comments = <DocComment>[];
  int _commentId = 0;

  void _comment(String command, Map<String, dynamic> args) {
    String arg(String k) => '${(args[k] as Map?)?['value'] ?? ''}';
    DocComment? byId(String id) => comments.where((c) => c.id == id).firstOrNull;
    void put(CommentAction a, DocComment c) {
      final i = comments.indexWhere((o) => o.id == c.id);
      if (a == CommentAction.remove) {
        if (i >= 0) comments.removeAt(i);
      } else if (i >= 0) {
        comments[i] = c;
      } else {
        comments.add(c);
      }
      _emit(CommentChanged(a, c));
    }

    switch (command) {
      case '.uno:InsertAnnotation':
        final y = 1418.0 + 276 * comments.where((c) => !c.isReply).length;
        put(
            CommentAction.add,
            DocComment(
              id: '${++_commentId}',
              author: author,
              text: arg('Text'),
              date: DateTime(2026, 11, 25, 9),
              anchor: Rect.fromLTWH(5610, y, 1, 276),
              range: [Rect.fromLTWH(5123, y, 487, 275)],
            ));
      case '.uno:ReplyComment':
        final parent = byId(arg('Id'));
        if (parent == null) return;
        put(
            CommentAction.add,
            DocComment(
                id: '${++_commentId}',
                parentId: parent.id,
                author: author,
                text: arg('Text'),
                date: DateTime(2026, 11, 25, 10),
                anchor: parent.anchor));
      case '.uno:ResolveComment':
        final c = byId(arg('Id'));
        if (c == null) return;
        put(
            CommentAction.resolve,
            DocComment(
                id: c.id,
                parentId: c.parentId,
                author: c.author,
                text: c.text,
                resolved: !c.resolved,
                date: c.date,
                anchor: c.anchor,
                range: c.range));
      case '.uno:EditAnnotation':
        final c = byId(arg('Id'));
        if (c == null) return;
        put(
            CommentAction.modify,
            DocComment(
                id: c.id,
                parentId: c.parentId,
                author: c.author,
                text: arg('Text'),
                resolved: c.resolved,
                date: c.date,
                anchor: c.anchor,
                range: c.range));
      case '.uno:DeleteComment':
        if (byId(arg('Id')) == null) return;
        put(CommentAction.remove, DocComment(id: arg('Id')));
    }
  }

  static const commentCommands = {
    '.uno:InsertAnnotation',
    '.uno:ReplyComment',
    '.uno:ResolveComment',
    '.uno:EditAnnotation',
    '.uno:DeleteComment',
  };

  /// Os arquivos pedidos ao [preloadSpelling].
  final preloads = <String>[];

  @override
  void preloadSpelling(String path) => preloads.add(path);

  /// As conversões pedidas (de onde, para onde, o formato).
  final conversions = <(String, String, String)>[];

  /// Como o falso converte: o padrão copia o arquivo (ou grava vazio, para
  /// um documento novo). Os testes do livro trocam por um que grava ODTs.
  void Function(String source, String target, String format)? onConvert;

  /// Quantas conversões pediram para atualizar os índices.
  int indexUpdates = 0;

  /// Falha as próximas conversões.
  bool failConversions = false;

  /// As impressões pedidas (o PDF e o título); [printOutcome] é a resposta.
  final prints = <(String, String)>[];
  PrintOutcome printOutcome = PrintOutcome.sent;

  @override
  void printPdf(String pdfPath, String title) {
    prints.add((pdfPath, title));
    _emit(Printed(printOutcome));
  }

  @override
  void convert(int id, String source, String target, String format, {String options = '', bool updateIndexes = false}) {
    conversions.add((source, target, format));
    if (updateIndexes) indexUpdates++;
    if (failConversions) {
      _emit(FileConverted(id, ok: false, error: 'falhou'));
      return;
    }
    final handler = onConvert;
    if (handler != null) {
      handler(source, target, format);
    } else if (source.isEmpty) {
      File(target).writeAsBytesSync(const []);
    } else {
      File(source).copySync(target);
    }
    _emit(FileConverted(id, ok: true));
  }

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
      if (text.isEmpty) {
        _emitCursor(); // a pré-edição some, e o texto fica como estava
        return;
      }
      _edit(this.text + text);
    } else {
      preedit = text;
      _emitCursor();
    }
  }

  /// Os idiomas com ortografia que o falso diz ter.
  List<String> languages = const ['Inglês (EUA);en-US', 'Português (Brasil);pt-BR'];

  /// As fontes que o falso diz ter.
  List<String> fonts = const ['Liberation Sans', 'Liberation Serif', 'Noto Serif'];

  /// Os `getCommandValues` pedidos, em ordem.
  final requestedValues = <String>[];

  @override
  void requestCommandValues(String command) {
    requestedValues.add(command);
    if (command == '.uno:AcceptTrackedChanges') {
      _emit(CommandValues(
          command,
          jsonEncode({
            'redlines': [
              for (final c in changes)
                {
                  'index': c.index,
                  'author': c.author,
                  'type': switch (c.kind) {
                    TrackedChangeKind.insert => 'Insert',
                    TrackedChangeKind.delete => 'Delete',
                    TrackedChangeKind.format => 'Format',
                    TrackedChangeKind.other => 'Other',
                  },
                  'comment': c.comment,
                  'description': c.description,
                  'dateTime': c.date?.toIso8601String() ?? '',
                  'textRange': c.range.map(_rect).join('; '),
                }
            ]
          })));
      return;
    }
    if (command == '.uno:ViewAnnotations') {
      _emit(CommandValues(
          command,
          jsonEncode({
            'comments': [
              for (final c in comments)
                {
                  'id': int.parse(c.id),
                  'parentId': c.parentId.isEmpty ? 0 : int.parse(c.parentId),
                  'author': c.author,
                  'text': c.text,
                  'resolved': '${c.resolved}',
                  'dateTime': c.date?.toIso8601String() ?? '',
                  'anchorPos': _rect(c.anchor),
                  'textRange': c.range.map(_rect).join('; '),
                }
            ]
          })));
      return;
    }
    if (command == '.uno:StyleApply') {
      _emit(CommandValues(
          command,
          jsonEncode({
            'commandName': command,
            'commandValues': {'ParagraphStyles': paragraphStyles, 'CharacterStyles': characterStyles},
          })));
      return;
    }
    if (command == '.uno:LanguageStatus') {
      _emit(CommandValues(command, jsonEncode({'commandName': command, 'commandValues': languages})));
      return;
    }
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
    final before = text;
    _undo.add(text);
    _redo.clear();
    text = next;
    _afterEdit();
    if (tracking && next != before) {
      final grew = next.length > before.length;
      _trackChange(TrackedChange(
        index: ++_changeIndex,
        kind: grew ? TrackedChangeKind.insert : TrackedChangeKind.delete,
        author: author,
        description: grew ? 'Inserir “${next.substring(before.length)}”' : 'Excluir',
        date: DateTime(2026, 11, 25, 11),
        range: [Rect.fromLTWH(1440 + before.length * 120.0, 1440, 400, 280)],
      ));
    }
  }

  // ------------------------------------- as alterações (D-089) --

  /// O controle de alterações ligado (`.uno:TrackChanges`) e as alterações,
  /// na ordem do motor.
  bool tracking = false;
  bool showChanges = true;
  final changes = <TrackedChange>[];
  int _changeIndex = 0;

  void _trackChange(TrackedChange c) {
    changes.add(c);
    _changesChanged();
  }

  void _changesChanged() {
    final any = changes.isEmpty ? 'disabled' : 'enabled';
    _state('.uno:AcceptAllTrackedChanges', any);
    _state('.uno:RejectAllTrackedChanges', any);
    _emit(const TrackedChangesChanged());
  }

  void _changeCommand(String command, String argsJson) {
    int? index() {
      if (argsJson.isEmpty) return null;
      final v = (jsonDecode(argsJson) as Map).values.first;
      return (v as Map)['value'] as int?;
    }

    switch (command) {
      case '.uno:TrackChanges':
        tracking = !tracking;
        _state(command, '$tracking');
      case '.uno:ShowTrackedChanges':
        showChanges = !showChanges;
        _state(command, '$showChanges');
      case '.uno:AcceptTrackedChange' || '.uno:RejectTrackedChange':
        final i = index();
        changes.removeWhere((c) => c.index == i);
        _changesChanged();
      case '.uno:AcceptAllTrackedChanges' || '.uno:RejectAllTrackedChanges':
        changes.clear();
        _changesChanged();
    }
  }

  static const changeCommands = {
    '.uno:TrackChanges',
    '.uno:ShowTrackedChanges',
    '.uno:AcceptTrackedChange',
    '.uno:RejectTrackedChange',
    '.uno:AcceptAllTrackedChanges',
    '.uno:RejectAllTrackedChanges',
  };

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
  void postMouse(MouseEventType type, int x, int y, {int count = 1, int buttons = 1, int modifier = 0}) {
    mice.add((type, x, y, count));
    if (type == MouseEventType.up && buttons == 4) _contextMenu();
  }

  // ------------------------------------------------------- Fase 2 --

  /// Os estilos que o falso diz ter.
  List<String> paragraphStyles = ['Standard', 'Text body', 'Heading 1', 'Heading 2', 'Quotations'];
  List<String> characterStyles = ['Emphasis', 'Strong Emphasis'];

  /// As palavras erradas e as sugestões: o clique direito oferece as da
  /// primeira que estiver no texto.
  Map<String, List<String>> misspelled = {};
  final graphicDrags = <(GraphicDrag, int, int)>[];
  Offset? _dragFrom;

  /// A imagem selecionada (twips), ou null.
  Rect? graphic;
  bool inTable = false;

  Rect _charRect(int index, int length) => Rect.fromLTWH(1440 + index * 120.0, 1440, length * 120.0, 280);

  void _contextMenu() {
    final items = <EngineMenuItem>[];
    for (final MapEntry(key: word, value: suggestions) in misspelled.entries) {
      if (!text.contains(word)) continue;
      items
        ..addAll([
          for (final s in suggestions)
            EngineMenuItem(text: s, command: '.uno:SpellCheckApplySuggestion?ApplyRule:string=Spelling_$s'),
        ])
        ..add(const EngineMenuItem.separator())
        ..add(const EngineMenuItem(text: 'Ignorar', command: '.uno:SpellCheckIgnore?Type:string=Spelling'));
      break;
    }
    items.addAll(const [
      EngineMenuItem(text: 'Cortar', command: '.uno:Cut', enabled: false),
      EngineMenuItem(text: 'Copiar', command: '.uno:Copy', enabled: false),
      EngineMenuItem(text: 'Colar', command: '.uno:Paste'),
    ]);
    _emit(ContextMenuReady(items));
  }

  void _search(Map<String, dynamic> args) {
    String str(String k) => '${(args['SearchItem.$k'] as Map?)?['value'] ?? ''}';
    final what = str('SearchString');
    final command = int.tryParse(str('Command')) ?? 0;
    final regex = str('AlgorithmType2') == '2';
    final matchCase = str('TransliterateFlags') == '0';
    final pattern = RegExp(regex ? what : RegExp.escape(what), caseSensitive: matchCase);
    final matches = pattern.allMatches(text).toList();
    if (matches.isEmpty) {
      _emit(SearchNotFound(what));
      return;
    }
    switch (command) {
      case 1:
        _emit(SearchResult([for (final m in matches) [_charRect(m.start, m.end - m.start)]], all: true));
      case 2 || 3:
        final replace = str('ReplaceString');
        _edit(command == 3 ? text.replaceAll(pattern, replace) : text.replaceFirst(pattern, replace));
      default:
        final m = matches.first;
        final r = _charRect(m.start, m.end - m.start);
        _emit(SelectionChanged([r]));
        _emit(SearchResult([
          [r]
        ]));
    }
  }

  @override
  void setGraphicSelection(GraphicDrag type, int x, int y) {
    graphicDrags.add((type, x, y));
    final g = graphic;
    if (type == GraphicDrag.start) _dragFrom = Offset(x.toDouble(), y.toDouble());
    if (type == GraphicDrag.end && g != null) {
      // Como o motor (sondado no D-043): a alça da direita muda só a
      // largura, a de baixo só a altura, e a do canto as duas.
      final from = _dragFrom ?? g.bottomRight;
      final right = (from.dx - g.right).abs() < 30, bottom = (from.dy - g.bottom).abs() < 30;
      graphic = Rect.fromLTRB(g.left, g.top, right ? x.toDouble() : g.right, bottom ? y.toDouble() : g.bottom);
      _dragFrom = null;
      _emit(GraphicSelected(graphic));
    }
  }

  @override
  void uno(String command, [String argsJson = '']) {
    unoCommands.add(command);
    unoArgs.add(argsJson);
    if (changeCommands.contains(command)) {
      _changeCommand(command, argsJson);
      return;
    }
    if (commentCommands.contains(command)) {
      _comment(command, argsJson.isEmpty ? const {} : jsonDecode(argsJson) as Map<String, dynamic>);
      return;
    }
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
      case '.uno:ExecuteSearch':
        _search(jsonDecode(argsJson) as Map<String, dynamic>);
      case '.uno:InsertGraphic':
        graphic = const Rect.fromLTWH(1440, 2000, 2880, 2880);
        _emit(GraphicSelected(graphic));
        _state('.uno:Size', '5080 x 5080');
        _edit(text);
      case '.uno:InsertTable':
        inTable = true;
        _emit(const TableSelected(true));
        _state('.uno:StateTableCell', 'Tabela1:A1');
        _edit(text);
      case '.uno:StyleApply':
        final style = '${((jsonDecode(argsJson) as Map)['Style'] as Map?)?['value'] ?? ''}';
        _state('.uno:StyleApply', style);
      case '.uno:InsertBookmark':
        bookmark = '${((jsonDecode(argsJson) as Map)['Bookmark'] as Map?)?['value'] ?? ''}';
      case '.uno:DeleteBookmark':
        bookmark = null;
      case '.uno:LoadStyles' when loadStylesAdds != null:
        paragraphStyles = [...paragraphStyles, loadStylesAdds!];
      case '.uno:StyleNewByExample':
        final name = '${((jsonDecode(argsJson) as Map)['Param'] as Map?)?['value'] ?? ''}';
        paragraphStyles = [...paragraphStyles, name];
        _state('.uno:StyleApply', name);
      case final c when c.startsWith('.uno:SpellCheckApplySuggestion'):
        final word = c.substring(c.indexOf('Spelling_') + 'Spelling_'.length);
        for (final wrong in misspelled.keys) {
          if (text.contains(wrong)) {
            _edit(text.replaceFirst(wrong, word));
            break;
          }
        }
    }
  }

  /// Segura a resposta do salvar até o [finishSave] (o "ocupado", D-066).
  bool holdSaves = false;
  String? _heldSave;

  @override
  void saveAs(String path, String format) {
    saved.add((path, format));
    if (holdSaves) {
      _heldSave = path;
      return;
    }
    _emit(DocumentSaved(path));
    _state('.uno:ModifiedStatus', 'false');
  }

  void finishSave() {
    final p = _heldSave;
    if (p == null) return;
    _heldSave = null;
    _emit(DocumentSaved(p));
    _state('.uno:ModifiedStatus', 'false');
  }

  /// As cópias pedidas (o caminho e o formato).
  final copies = <(String, String)>[];

  /// Os títulos que a cópia leva (os testes da Estrutura preenchem).
  List<(int, String)> headings = const [];

  /// Os parágrafos de texto da cópia (a busca no texto, D-050).
  List<String> bodyParagraphs = const [];

  /// O marcador do cursor (D-079): o `.uno:InsertBookmark` o põe, e a cópia
  /// o grava no começo do parágrafo [bookmarkParagraph] de [bodyParagraphs].
  String? bookmark;
  int bookmarkParagraph = 0;

  /// Para os testes: XML cru no fim do corpo da cópia (as legendas, D-090).
  String extraBodyXml = '';

  /// Para os testes: XML cru no `office:meta` da cópia (o título, D-091).
  String extraMetaXml = '';

  /// O estilo que o `.uno:LoadStyles` traz (o "Cena"), para a cópia seguinte.
  String? loadStylesAdds;

  /// Não responde às cópias (para testar a fila de pedidos).
  bool holdCopies = false;
  final heldCopies = <String>[];

  @override
  List<int> fontClasses(List<String> families) => [
        for (final f in families)
          f.contains('Mono')
              ? FontClass.mono
              : f.contains('Serif')
                  ? FontClass.serif
                  : FontClass.sans,
      ];

  @override
  void exportCopy(String path, String format) {
    copies.add((path, format));
    if (holdCopies) {
      heldCopies.add(path);
      return;
    }
    finishCopy(path);
  }

  /// Grava um ODT plano com os estilos e os títulos do falso, e avisa.
  void finishCopy(String path) {
    String esc(String v) => v.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('"', '&quot;');
    final styles = StringBuffer();
    for (final name in paragraphStyles) {
      final heading = RegExp(r'^Heading (\d)$').firstMatch(name);
      final size = heading == null ? 12 : 20 - 2 * int.parse(heading[1]!);
      final italic = name == 'Quotations' ? ' fo:font-style="italic"' : '';
      final weight = heading != null ? ' fo:font-weight="bold"' : '';
      styles.write('<style:style style:name="${esc(name.replaceAll(' ', '_20_'))}" style:display-name="${esc(name)}" '
          'style:family="paragraph"><style:text-properties style:font-name="Liberation Serif" fo:font-size="${size}pt"$weight$italic/></style:style>');
    }
    final body = [
      for (final (level, text) in headings) '<text:h text:outline-level="$level">${esc(text)}</text:h>',
      for (final (i, text) in bodyParagraphs.indexed)
        '<text:p text:style-name="Text_20_body">'
            '${bookmark != null && i == bookmarkParagraph ? '<text:bookmark text:name="${esc(bookmark!)}"/>' : ''}'
            '${esc(text)}</text:p>',
      extraBodyXml,
    ].join();
    // As estatísticas, como o LibreOffice grava (as palavras do texto falso).
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final paragraphs = headings.length + bodyParagraphs.length;
    final noSpaces = text.replaceAll(RegExp(r'\s'), '').length;
    File(path).writeAsStringSync('<office:document><office:meta>$extraMetaXml'
        '<meta:document-statistic meta:word-count="$words" meta:character-count="${text.length}" '
        'meta:paragraph-count="$paragraphs" meta:non-whitespace-character-count="$noSpaces"/></office:meta>'
        '<office:font-face-decls>'
        '<style:font-face style:name="Liberation Serif" svg:font-family="&apos;Liberation Serif&apos;"/></office:font-face-decls>'
        '<office:styles>$styles</office:styles><office:body><office:text>$body</office:text></office:body></office:document>');
    _emit(CopyExported(path));
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

  static String _rect(Rect? r) =>
      r == null ? '' : '${r.left.round()}, ${r.top.round()}, ${r.width.round()}, ${r.height.round()}';

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

class _FakeDoc {
  _FakeDoc(this.path, this.text, this.bold, this.undo, this.redo);
  final String? path;
  final String text;
  final bool bold;
  final List<String> undo, redo;
}
