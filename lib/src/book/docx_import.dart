// O importador de manuscritos (D-071): um DOCX (ou ODT) vira um livro.
//
// 1. O motor abre o manuscrito sem mostrar e salva uma cópia em ODT plano
//    nas cópias temporárias (`$XDG_RUNTIME_DIR`), sem tocar nas abas.
// 2. O Dart, num isolate, corta o corpo nos títulos ([FodtManuscript]).
// 3. A interface mostra os capítulos achados, e quem importa escolhe o
//    nível dos títulos.
// 4. Cada capítulo vira um ODT plano temporário, que o motor salva em ODT na
//    pasta `capitulos/` do livro. As cópias são apagadas na hora.
import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import '../document/document_controller.dart';
import '../document/fodt.dart';
import '../kit/quill_kit.dart';
import 'book.dart';
import 'book_io.dart';
import 'fodt_split.dart';

/// Pede conversões ao motor e espera cada resposta pelo número.
class KitConverter {
  KitConverter(this.kit);
  final QuillKit kit;

  static int _next = 1;

  /// true se o motor salvou [target].
  Future<bool> convert(String source, String target, String format) async {
    final id = _next++;
    final done = kit.events
        .firstWhere((e) => e is FileConverted && e.id == id)
        .timeout(const Duration(seconds: 120), onTimeout: () => FileConverted(id, ok: false, error: 'tempo'));
    kit.convert(id, source, target, format);
    return (await done as FileConverted).ok;
  }
}

/// Por que a importação parou.
enum ImportError { unreadable, emptyManuscript, bookExists, writeFailed }

class ImportException implements Exception {
  const ImportException(this.error);
  final ImportError error;
  @override
  String toString() => 'ImportException($error)';
}

class DocxImporter {
  DocxImporter(QuillKit kit) : _convert = KitConverter(kit);
  final KitConverter _convert;

  static int _serial = 0;
  static String _tmp(String what) =>
      '${DocumentController.copyDir}/${DocumentController.copyPrefixOfThisProcess}livro-$what-${_serial++}.fodt';

  /// Lê o manuscrito em [path]. Lança [ImportException].
  Future<FodtManuscript> read(String path) async {
    final copy = _tmp('manuscrito');
    try {
      if (!await _convert.convert(path, copy, 'fodt')) throw const ImportException(ImportError.unreadable);
      final m = await Isolate.run(() => FodtManuscript.parse(File(copy).readAsStringSync()));
      if (m.chapters(m.suggestedLevel).isEmpty) throw const ImportException(ImportError.emptyManuscript);
      return m;
    } on FormatException {
      throw const ImportException(ImportError.unreadable);
    } on FileSystemException {
      throw const ImportException(ImportError.unreadable);
    } finally {
      _delete(copy);
    }
  }

  /// Cria o livro [title] em [dir] com os capítulos [drafts] do manuscrito
  /// [m]. [untitled] nomeia o que vem antes do primeiro título. [progress]
  /// recebe quantos capítulos já foram (de [drafts.length]). Lança
  /// [ImportException]; no meio de uma falha, o que já foi feito fica na
  /// pasta, sem o `livro.json`.
  Future<Book> create({
    required String dir,
    required String title,
    required FodtManuscript m,
    required List<ChapterDraft> drafts,
    required String untitled,
    void Function(int done)? progress,
  }) async {
    try {
      createBookDir(dir);
    } on FileSystemException {
      throw const ImportException(ImportError.bookExists);
    }
    final book = Book(title: title);
    final taken = <String>{};
    BookNode? part;
    for (var i = 0; i < drafts.length; i++) {
      final d = drafts[i];
      final name = d.title?.isNotEmpty == true ? d.title! : untitled;
      final file = newChapterFile(dir, name, taken: taken);
      taken.add(file);
      final tmp = _tmp('capitulo');
      var scenes = const <String>[];
      try {
        final xml = m.chapterXml(d);
        scenes = [for (final s in odfScenes(xml)) s.label];
        File(tmp).writeAsStringSync(xml);
        if (!await _convert.convert(tmp, '$dir/$file', 'odt')) throw const ImportException(ImportError.writeFailed);
      } on FileSystemException {
        throw const ImportException(ImportError.writeFailed);
      } finally {
        _delete(tmp);
      }
      final stamp = File('$dir/$file').statSync().modified.millisecondsSinceEpoch;
      final chapter = BookNode(
        id: newNodeId(book),
        kind: BookNodeKind.chapter,
        title: name,
        file: file,
        words: d.words,
        wordsStamp: stamp,
        scenes: scenes,
      );
      if (d.part != null && d.part != part?.title) {
        part = BookNode(id: newNodeId(book), kind: BookNodeKind.part, title: d.part!);
        book.nodes.add(part);
      } else if (d.part == null) {
        part = null;
      }
      (part?.children ?? book.nodes).add(chapter);
      progress?.call(i + 1);
    }
    writeBook(dir, book);
    return book;
  }

  static void _delete(String path) {
    try {
      File(path).deleteSync();
    } on FileSystemException {
      // Já saiu (ou nunca foi escrita).
    }
  }
}
