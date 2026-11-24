// O compilar (Fase 4, Etapa 1, D-086): o livro inteiro num PDF, num EPUB,
// num DOCX ou num ODT.
//
// 1. Cada capítulo escolhido sai em ODT plano (FODT) pelo motor, um de cada
//    vez, num documento oculto: o da tela pela cópia do Localizar (vale o que
//    está no motor), uma aba de fundo com alterações pela cópia de
//    recuperação, os outros pelo arquivo.
// 2. Um isolate junta as cópias num FODT só (`fodt_join.dart`).
// 3. O motor abre o livro juntado oculto, atualiza o sumário, grava no
//    formato pedido e fecha. É a única hora em que o livro inteiro entra no
//    motor; depois, a memória volta ao sistema (`trimMemory`).
//
// As cópias ficam nas temporárias do Quill e saem no fim, dê certo ou não.
import 'dart:io';
import 'dart:isolate';

import '../document/document_controller.dart';
import '../kit/quill_kit.dart';
import 'book.dart';
import 'docx_import.dart' show KitConverter;
import 'fodt_join.dart';

/// Os formatos do livro compilado.
enum CompileFormat {
  pdf('pdf', 'application/pdf'),
  epub('epub', 'application/epub+zip'),
  docx('docx', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'),
  odt('odt', 'application/vnd.oasis.opendocument.text');

  const CompileFormat(this.extension, this.mime);
  final String extension, mime;

  /// As opções do filtro: o PDF leva os títulos como marcadores.
  String get filterOptions => switch (this) {
        pdf => '{"ExportBookmarks":{"type":"boolean","value":"true"}}',
        _ => '',
      };
}

/// O que a janela Compilar escolheu.
class CompileSettings {
  const CompileSettings({
    this.excluded = const {},
    this.titlePage = true,
    this.title = '',
    this.subtitle = '',
    this.author = '',
    this.toc = true,
    this.tocTitle = 'Sumário',
    this.pageBreaks = true,
    this.partTitles = true,
    this.chapterTitles = true,
    this.scenes = SceneBreakMode.keep,
    this.format = CompileFormat.pdf,
  });

  /// Os capítulos que ficam de fora (os ids). Guardar os de fora, e não os
  /// de dentro, faz um capítulo novo entrar sem ninguém marcar.
  final Set<String> excluded;
  final bool titlePage;
  final String title, subtitle, author;
  final bool toc;
  final String tocTitle;
  final bool pageBreaks;

  /// O título de cada parte numa página própria.
  final bool partTitles;
  final bool chapterTitles;
  final SceneBreakMode scenes;
  final CompileFormat format;

  JoinOptions get join => JoinOptions(
        titlePage: titlePage,
        title: title,
        subtitle: subtitle,
        author: author,
        toc: toc,
        tocTitle: tocTitle,
        pageBreaks: pageBreaks,
        chapterTitles: chapterTitles,
        scenes: scenes,
      );
}

/// Em que passo o compilar está.
enum CompileStage { chapters, joining, writing }

/// O andamento: o passo e, nos capítulos, quantos já saíram de quantos.
typedef CompileProgress = void Function(CompileStage stage, int done, int total);

/// Como o compilar terminou.
enum CompileOutcome { done, cancelled, noChapters, chapterFailed, writeFailed }

/// O resultado: como terminou e, numa falha de capítulo, qual.
class CompileResult {
  const CompileResult(this.outcome, {this.chapter});
  final CompileOutcome outcome;
  final String? chapter;
  bool get ok => outcome == CompileOutcome.done;
}

/// De onde sai cada capítulo: o arquivo (ODT) e se ele já é um FODT.
typedef CompileSource = ({String path, bool flat});

/// Os capítulos de [book] que entram, na ordem, com as partes.
List<(BookNode? part, BookNode chapter)> compiledChapters(Book book, CompileSettings s) {
  final out = <(BookNode?, BookNode)>[];
  for (final n in book.nodes) {
    if (n.isPart) {
      for (final c in n.children) {
        if (!s.excluded.contains(c.id)) out.add((n, c));
      }
    } else if (!s.excluded.contains(n.id)) {
      out.add((null, n));
    }
  }
  return out;
}

/// Um compilar em andamento; [cancel] para no próximo passo.
class CompileJob {
  CompileJob(this.kit) : _convert = KitConverter(kit);
  final QuillKit kit;
  final KitConverter _convert;

  bool _cancelled = false;
  void cancel() => _cancelled = true;
  bool get cancelled => _cancelled;

  static int _serial = 0;
  static String _tmp(String what, String ext) =>
      '${DocumentController.copyDir}/${DocumentController.copyPrefixOfThisProcess}compilar-$what-${_serial++}.$ext';

  /// Compila [book] em [target]. [sourceOf] diz de onde sai cada capítulo
  /// (null: o capítulo não tem arquivo, e fica de fora).
  Future<CompileResult> run(
    Book book,
    CompileSettings s,
    String target, {
    required Future<CompileSource?> Function(BookNode chapter) sourceOf,
    CompileProgress? onProgress,
  }) async {
    final chosen = compiledChapters(book, s);
    if (chosen.isEmpty) return const CompileResult(CompileOutcome.noChapters);
    final temps = <String>[];
    try {
      final items = <JoinItem>[];
      BookNode? lastPart;
      for (var i = 0; i < chosen.length; i++) {
        if (_cancelled) return const CompileResult(CompileOutcome.cancelled);
        onProgress?.call(CompileStage.chapters, i, chosen.length);
        final (part, chapter) = chosen[i];
        if (part != null && part != lastPart && s.partTitles) items.add(JoinPart(part.title));
        lastPart = part;
        final source = await sourceOf(chapter);
        if (source == null) continue;
        var fodt = source.path;
        if (!source.flat) {
          fodt = _tmp('capitulo', 'fodt');
          temps.add(fodt);
          if (!await _convert.convert(source.path, fodt, 'fodt')) {
            return CompileResult(CompileOutcome.chapterFailed, chapter: chapter.title);
          }
        }
        items.add(JoinChapter(fodt, chapter.title));
      }
      if (!items.any((i) => i is JoinChapter)) return const CompileResult(CompileOutcome.noChapters);
      if (_cancelled) return const CompileResult(CompileOutcome.cancelled);

      onProgress?.call(CompileStage.joining, chosen.length, chosen.length);
      final joined = _tmp('livro', 'fodt');
      temps.add(joined);
      final options = s.join;
      try {
        await Isolate.run(() => joinFodt(items, options, joined));
      } on FormatException {
        return const CompileResult(CompileOutcome.noChapters);
      } on FileSystemException {
        return const CompileResult(CompileOutcome.writeFailed);
      }
      if (_cancelled) return const CompileResult(CompileOutcome.cancelled);

      onProgress?.call(CompileStage.writing, chosen.length, chosen.length);
      final ok = await _convert.convert(joined, target, s.format.extension,
          options: s.format.filterOptions, updateIndexes: s.toc, timeout: const Duration(minutes: 10));
      return CompileResult(ok ? CompileOutcome.done : CompileOutcome.writeFailed);
    } finally {
      for (final t in temps) {
        try {
          File(t).deleteSync();
        } on FileSystemException {
          // Já saiu.
        }
      }
      // O livro inteiro passou pelo motor: a memória volta ao sistema.
      kit.trimMemory();
    }
  }
}
