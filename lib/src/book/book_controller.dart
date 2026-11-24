// O livro aberto (D-071). Facade, como o Workspace: o fichário e os comandos
// chamam estes métodos, e cada mudança grava o `livro.json` na hora (de
// forma atômica; ele é pequeno).
//
// Só um livro por vez. Os capítulos abrem como abas (D-054) pelo Workspace;
// o livro não guarda o texto de nenhum deles.
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../kit/quill_kit.dart';
import 'book.dart';
import 'book_io.dart';
import 'docx_import.dart';

/// Por que o livro não abriu.
enum BookError { missing, invalid, newerFormat, exists, writeFailed }

class BookException implements Exception {
  const BookException(this.error);
  final BookError error;
  @override
  String toString() => 'BookException($error)';
}

class BookController extends ChangeNotifier {
  BookController(this.kit) : _convert = KitConverter(kit);

  final QuillKit kit;
  final KitConverter _convert;
  StreamSubscription<KitEvent>? _sub;

  Book? _book;
  String? _dir;

  Book? get book => _book;

  /// A pasta do livro aberto.
  String? get dir => _dir;
  bool get isOpen => _book != null;

  /// Sobe a cada mudança do livro: a chave de memoização do fichário (D-037).
  int revision = 0;

  /// O caminho absoluto do capítulo [node].
  String? pathOf(BookNode node) => node.file == null || _dir == null ? null : '$_dir/${node.file}';

  /// O capítulo cujo arquivo é [path]; null fora do livro.
  BookNode? chapterAt(String? path) {
    if (path == null || _book == null) return null;
    for (final c in _book!.chapters) {
      if (pathOf(c) == path) return c;
    }
    return null;
  }

  /// Abre o livro em [path] (a pasta ou o `livro.json`). Lança [BookException].
  Future<Book> open(String path) async {
    final dir = bookDirOf(path);
    final Book book;
    try {
      final raw = File('$dir/$bookFileName');
      if (!raw.existsSync()) throw const BookException(BookError.missing);
      book = readBook(dir);
    } on FileSystemException {
      throw const BookException(BookError.missing);
    } on FormatException {
      throw const BookException(BookError.invalid);
    } on TypeError {
      throw const BookException(BookError.invalid);
    }
    _attach(dir, book);
    unawaited(refreshWords());
    return book;
  }

  /// Usa [book], já gravado em [dir] (o importador).
  void adopt(String dir, Book book) => _attach(dir, book);

  void _attach(String dir, Book book) {
    _book = book;
    _dir = dir;
    _sub ??= kit.events.listen(_onKit);
    _changed(save: false);
  }

  void close() {
    _book = null;
    _dir = null;
    _changed(save: false);
  }

  /// Um livro novo, [title], na pasta [dir], com um capítulo vazio
  /// [firstChapter]. Lança [BookException].
  Future<Book> create(String dir, String title, {required String firstChapter}) async {
    try {
      createBookDir(dir);
    } on FileSystemException {
      throw const BookException(BookError.exists);
    }
    final book = Book(title: title);
    final file = newChapterFile(dir, firstChapter);
    if (!await _convert.convert('', '$dir/$file', 'odt')) throw const BookException(BookError.writeFailed);
    book.nodes.add(BookNode(id: newNodeId(book), kind: BookNodeKind.chapter, title: firstChapter, file: file));
    writeBook(dir, book);
    _attach(dir, book);
    return book;
  }

  void _onKit(KitEvent e) {
    // Salvar um capítulo do livro reconta as palavras dele.
    if (e is DocumentSaved && chapterAt(e.path) != null) unawaited(refreshWords());
  }

  /// Reconta as palavras dos capítulos cujo arquivo mudou desde a última
  /// contagem (num isolate), e grava o livro se algo mudou.
  Future<void> refreshWords() async {
    final book = _book;
    if (book == null) return;
    final stale = <String, BookNode>{};
    for (final c in book.chapters) {
      final p = pathOf(c);
      if (p == null) continue;
      final f = File(p);
      if (!f.existsSync()) continue;
      if (f.lastModifiedSync().millisecondsSinceEpoch != c.wordsStamp) stale[p] = c;
    }
    if (stale.isEmpty) return;
    final counts = await countChapterWords(stale.keys.toList());
    if (_disposed || _book != book) return;
    for (final MapEntry(:key, :value) in counts.entries) {
      stale[key]!
        ..words = value.words
        ..wordsStamp = value.stamp
        ..scenes = value.scenes;
    }
    _changed();
  }

  /// Um capítulo novo e vazio [title], depois de [afterId] (na mesma parte),
  /// ou no fim de [partId], ou no fim do livro. Devolve o capítulo.
  Future<BookNode> addChapter(String title, {String? afterId, String? partId}) =>
      addChapterFrom('', title, afterId: afterId, partId: partId);

  /// Um capítulo novo [title] com o texto de [source] (um arquivo que o
  /// motor abre, como o resto de um capítulo dividido; vazio: um documento
  /// novo), no lugar de [addChapter].
  Future<BookNode> addChapterFrom(String source, String title, {String? afterId, String? partId}) async {
    final book = _book!, dir = _dir!;
    final file = newChapterFile(dir, title);
    if (!await _convert.convert(source, '$dir/$file', 'odt')) throw const BookException(BookError.writeFailed);
    final node = BookNode(id: newNodeId(book), kind: BookNodeKind.chapter, title: title, file: file);
    _insert(node, afterId: afterId, partId: partId);
    return node;
  }

  /// Uma parte nova [title], depois de [afterId] no primeiro nível.
  BookNode addPart(String title, {String? afterId}) {
    final node = BookNode(id: newNodeId(_book!), kind: BookNodeKind.part, title: title);
    final top = afterId == null ? null : _topLevelOf(afterId);
    _insert(node, afterId: top);
    return node;
  }

  String? _topLevelOf(String id) => _book!.parentOf(id)?.id ?? id;

  void _insert(BookNode node, {String? afterId, String? partId}) {
    final book = _book!;
    if (afterId != null) {
      final found = book.find(afterId);
      if (found != null && !(node.isPart && !identical(found.$2, book.nodes))) {
        final (after, list) = found;
        list.insert(list.indexOf(after) + 1, node);
        _changed();
        return;
      }
    }
    final part = partId == null ? null : book.find(partId)?.$1;
    (part != null && part.isPart && !node.isPart ? part.children : book.nodes).add(node);
    _changed();
  }

  void rename(String id, String title) {
    final n = _book?.find(id)?.$1;
    if (n == null || title.trim().isEmpty || n.title == title.trim()) return;
    n.title = title.trim();
    _changed();
  }

  void setStatus(String id, ChapterStatus status) {
    final n = _book?.find(id)?.$1;
    if (n == null || n.status == status) return;
    n.status = status;
    _changed();
  }

  void setLabel(String id, int? label) {
    final n = _book?.find(id)?.$1;
    if (n == null || n.label == label) return;
    n.label = label;
    _changed();
  }

  void setSynopsis(String id, String synopsis) {
    final n = _book?.find(id)?.$1;
    if (n == null || n.synopsis == synopsis) return;
    n.synopsis = synopsis;
    _changed();
  }

  /// Move [id] para a posição [index] de [partId] (null: o primeiro nível).
  /// Uma parte só vai para o primeiro nível.
  void move(String id, {String? partId, required int index}) {
    final book = _book;
    final found = book?.find(id);
    if (book == null || found == null) return;
    final (node, from) = found;
    final target = partId == null ? book.nodes : book.find(partId)?.$1.children;
    if (target == null || (node.isPart && partId != null) || node.id == partId) return;
    final old = from.indexOf(node);
    from.removeAt(old);
    var i = index;
    if (identical(from, target) && old < i) i--;
    target.insert(i.clamp(0, target.length), node);
    _changed();
  }

  /// Um passo para cima ou para baixo (Alt+setas, D-071). Na ponta de uma
  /// parte, o capítulo sai dela; ao passar por uma parte, entra nela.
  void nudge(String id, {required bool up}) {
    final book = _book;
    final found = book?.find(id);
    if (book == null || found == null) return;
    final (node, list) = found;
    final i = list.indexOf(node);
    final parent = book.parentOf(id);
    if (up) {
      if (i > 0) {
        final prev = list[i - 1];
        if (!node.isPart && prev.isPart) {
          move(id, partId: prev.id, index: prev.children.length);
        } else {
          move(id, partId: parent?.id, index: i - 1);
        }
      } else if (parent != null) {
        move(id, index: book.nodes.indexOf(parent));
      }
    } else {
      if (i < list.length - 1) {
        final next = list[i + 1];
        if (!node.isPart && next.isPart) {
          move(id, partId: next.id, index: 0);
        } else {
          move(id, partId: parent?.id, index: i + 2);
        }
      } else if (parent != null) {
        move(id, index: book.nodes.indexOf(parent) + 1);
      }
    }
  }

  /// Tira [id] do livro: o arquivo do capítulo vai para a `lixeira/`. Uma
  /// parte sai sozinha, e os capítulos dela ficam no lugar dela.
  void remove(String id) {
    final book = _book, dir = _dir;
    final found = book?.find(id);
    if (book == null || dir == null || found == null) return;
    final (node, list) = found;
    final i = list.indexOf(node);
    list.removeAt(i);
    if (node.isPart) {
      list.insertAll(i, node.children);
    } else if (node.file != null) {
      try {
        moveToTrash(dir, node.file!);
      } on FileSystemException {
        // O arquivo some do livro mesmo assim; ele fica onde estava.
      }
    }
    _changed();
  }

  void _changed({bool save = true}) {
    revision++;
    if (save && _book != null && _dir != null) {
      try {
        writeBook(_dir!, _book!);
      } on FileSystemException {
        // Sem gravar, o livro continua na memória; a próxima mudança tenta de novo.
      }
    }
    notifyListeners();
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    super.dispose();
  }
}
