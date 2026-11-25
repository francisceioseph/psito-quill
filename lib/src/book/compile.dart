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
import 'compile_style.dart';
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
    this.figures = false,
    this.figuresTitle = 'Índice de figuras',
    this.index = false,
    this.indexTitle = 'Índice remissivo',
    this.pageBreaks = true,
    this.partTitles = true,
    this.chapterTitles = true,
    this.scenes = SceneBreakMode.keep,
    this.format = CompileFormat.pdf,
    this.style = const OutputStyle(),
    this.cover = '',
  });

  /// Os capítulos que ficam de fora (os ids). Guardar os de fora, e não os
  /// de dentro, faz um capítulo novo entrar sem ninguém marcar.
  final Set<String> excluded;
  final bool titlePage;
  final String title, subtitle, author;
  final bool toc;
  final String tocTitle;

  /// O índice de figuras depois do sumário e o índice remissivo no fim
  /// (D-090), das legendas e das entradas marcadas nos capítulos.
  final bool figures, index;
  final String figuresTitle, indexTitle;
  final bool pageBreaks;

  /// O título de cada parte numa página própria.
  final bool partTitles;
  final bool chapterTitles;
  final SceneBreakMode scenes;
  final CompileFormat format;

  /// A página, o corpo e os cabeçalhos do modelo (D-087).
  final OutputStyle style;

  /// A imagem da capa ('' sem capa).
  final String cover;

  /// As opções do filtro: o PDF leva os títulos como marcadores e, com os
  /// capítulos na página ímpar, as páginas em branco (que ele pula).
  String get filterOptions => switch (format) {
        CompileFormat.pdf => '{"ExportBookmarks":{"type":"boolean","value":"true"}'
            '${style.rightPage ? ',"IsSkipEmptyPages":{"type":"boolean","value":"false"}' : ''}}',
        _ => '',
      };

  CompileSettings copyWith({
    Set<String>? excluded,
    bool? titlePage,
    String? title,
    String? subtitle,
    String? author,
    bool? toc,
    String? tocTitle,
    bool? figures,
    String? figuresTitle,
    bool? index,
    String? indexTitle,
    bool? pageBreaks,
    bool? partTitles,
    bool? chapterTitles,
    SceneBreakMode? scenes,
    CompileFormat? format,
    OutputStyle? style,
    String? cover,
  }) =>
      CompileSettings(
        excluded: excluded ?? this.excluded,
        titlePage: titlePage ?? this.titlePage,
        title: title ?? this.title,
        subtitle: subtitle ?? this.subtitle,
        author: author ?? this.author,
        toc: toc ?? this.toc,
        tocTitle: tocTitle ?? this.tocTitle,
        figures: figures ?? this.figures,
        figuresTitle: figuresTitle ?? this.figuresTitle,
        index: index ?? this.index,
        indexTitle: indexTitle ?? this.indexTitle,
        pageBreaks: pageBreaks ?? this.pageBreaks,
        partTitles: partTitles ?? this.partTitles,
        chapterTitles: chapterTitles ?? this.chapterTitles,
        scenes: scenes ?? this.scenes,
        format: format ?? this.format,
        style: style ?? this.style,
        cover: cover ?? this.cover,
      );

  /// As escolhas que um modelo guarda: sem o que é do livro (os capítulos,
  /// o título, o subtítulo, o autor e a capa).
  Map<String, Object?> modelJson() => {
        'folhaDeRosto': titlePage,
        'sumario': toc,
        'tituloDoSumario': tocTitle,
        'figuras': figures,
        'tituloDasFiguras': figuresTitle,
        'indiceRemissivo': index,
        'tituloDoIndice': indexTitle,
        'quebras': pageBreaks,
        'partes': partTitles,
        'titulos': chapterTitles,
        'cenas': scenes.name,
        'formato': format.name,
        'estilo': style.toJson(),
      };

  /// Tudo, para o "último usado".
  Map<String, Object?> toJson() => {
        ...modelJson(),
        'deFora': [...excluded]..sort(),
        if (title.isNotEmpty) 'titulo': title,
        if (subtitle.isNotEmpty) 'subtitulo': subtitle,
        if (author.isNotEmpty) 'autor': author,
        if (cover.isNotEmpty) 'capa': cover,
      };

  static CompileSettings fromJson(Object? j) {
    if (j is! Map) return const CompileSettings();
    bool flag(String k, bool d) => j[k] is bool ? j[k] as bool : d;
    String text(String k, String d) => j[k] is String ? j[k] as String : d;
    final out = j['deFora'];
    return CompileSettings(
      excluded: {if (out is List) ...out.whereType<String>()},
      titlePage: flag('folhaDeRosto', true),
      title: text('titulo', ''),
      subtitle: text('subtitulo', ''),
      author: text('autor', ''),
      toc: flag('sumario', true),
      tocTitle: text('tituloDoSumario', 'Sumário'),
      figures: flag('figuras', false),
      figuresTitle: text('tituloDasFiguras', 'Índice de figuras'),
      index: flag('indiceRemissivo', false),
      indexTitle: text('tituloDoIndice', 'Índice remissivo'),
      pageBreaks: flag('quebras', true),
      partTitles: flag('partes', true),
      chapterTitles: flag('titulos', true),
      scenes: SceneBreakMode.values.where((v) => v.name == j['cenas']).firstOrNull ?? SceneBreakMode.keep,
      format: CompileFormat.values.where((v) => v.name == j['formato']).firstOrNull ?? CompileFormat.pdf,
      style: OutputStyle.fromJson(j['estilo']),
      cover: text('capa', ''),
    );
  }

  /// As escolhas do modelo [m] por cima destas, mantendo o que é do livro.
  CompileSettings withModel(CompileSettings m) => m.copyWith(
        excluded: excluded,
        title: title,
        subtitle: subtitle,
        author: author,
        cover: cover,
      );

  /// As mesmas escolhas de modelo que [other].
  bool sameModel(CompileSettings other) => _deepEq(modelJson(), other.modelJson());

  JoinOptions get join => JoinOptions(
        titlePage: titlePage,
        title: title,
        subtitle: subtitle,
        author: author,
        toc: toc,
        tocTitle: tocTitle,
        figures: figures,
        figuresTitle: figuresTitle,
        // O EPUB não tem páginas: um índice remissivo sem elas não serve.
        index: index && format != CompileFormat.epub,
        indexTitle: indexTitle,
        pageBreaks: pageBreaks,
        chapterTitles: chapterTitles,
        scenes: scenes,
        style: style,
        cover: cover.isEmpty ? null : cover,
        tocPageNumbers: format != CompileFormat.epub,
      );
}

bool _deepEq(Object? a, Object? b) {
  if (a is Map && b is Map) {
    return a.length == b.length && a.keys.every((k) => b.containsKey(k) && _deepEq(a[k], b[k]));
  }
  return a == b;
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
      // Uma capa que saiu do lugar não derruba o compilar: o livro sai sem.
      final options = (s.cover.isEmpty || File(s.cover).existsSync() ? s : s.copyWith(cover: '')).join;
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
          options: s.filterOptions, updateIndexes: s.toc || s.figures || s.index, timeout: const Duration(minutes: 10));
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
