// A busca no livro inteiro (Fase 3, Etapa 6, D-080).
//
// Os capítulos são lidos um a um num isolate: o `content.xml` de um capítulo
// fechado, ou a cópia do motor de um capítulo aberto com alterações (a do
// Localizar, para o da tela; a de recuperação, para uma aba de fundo). Quem
// busca é o Dart, com as opções do Localizar. O texto de cada capítulo é
// solto antes do próximo, e o que volta é só o trecho em volta de cada
// ocorrência, até um limite.
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

import '../document/fodt.dart';
import 'odt_zip.dart';

/// De onde ler um capítulo: um ODT (o arquivo do livro ou a cópia de
/// recuperação) ou um ODT plano (a cópia da busca do motor).
typedef ChapterSource = ({String id, String path, bool flat});

/// As ocorrências num capítulo.
@immutable
class ChapterHits {
  const ChapterHits({required this.id, required this.title, required this.hits, required this.total});

  /// O nó do capítulo no livro.
  final String id;
  final String title;

  /// As primeiras ocorrências (até o limite do capítulo) e quantas há nele.
  final List<TextHit> hits;
  final int total;
}

class BookSearchResult {
  const BookSearchResult(this.chapters, {this.badPattern = false, this.unread = 0});

  /// Só os capítulos com ocorrências, na ordem do livro.
  final List<ChapterHits> chapters;

  /// A expressão regular não vale.
  final bool badPattern;

  /// Os capítulos que não deu para ler (o arquivo sumiu, um zip quebrado).
  final int unread;

  int get total => chapters.fold(0, (s, c) => s + c.total);

  static const empty = BookSearchResult([]);
}

/// Quantas ocorrências de cada capítulo vêm com o trecho. As outras só
/// contam: quem quer ver todas abre o capítulo e usa "Neste capítulo".
const bookHitsPerChapter = 30;

/// Acha [q] nos capítulos [sources], num isolate. [titles] dá o nome de
/// cada um pelo id.
Future<BookSearchResult> searchChapters(
  List<ChapterSource> sources,
  SearchQuery q, {
  required Map<String, String> titles,
  int perChapter = bookHitsPerChapter,
}) async {
  if (sources.isEmpty) return BookSearchResult.empty;
  if (searchPattern(q) == null) {
    return (q.regex ? q.text : q.text.trim()).isEmpty ? BookSearchResult.empty : const BookSearchResult([], badPattern: true);
  }
  final found = await Isolate.run(() => searchSources(sources, q, perChapter: perChapter));
  return BookSearchResult(
    [
      for (final f in found.hits)
        ChapterHits(id: f.id, title: titles[f.id] ?? '', hits: f.result.hits, total: f.result.total),
    ],
    unread: found.unread,
  );
}

/// O trabalho do isolate (público para os testes): lê, busca e solta cada
/// capítulo, na ordem.
({List<({String id, TextSearchResult result})> hits, int unread}) searchSources(
  List<ChapterSource> sources,
  SearchQuery q, {
  int perChapter = bookHitsPerChapter,
}) {
  final hits = <({String id, TextSearchResult result})>[];
  var unread = 0;
  for (final s in sources) {
    String? xml;
    try {
      xml = s.flat ? File(s.path).readAsStringSync() : readOdtContent(s.path);
    } on FileSystemException {
      xml = null;
    }
    if (xml == null) {
      unread++;
      continue;
    }
    final r = searchOdfText(xml, q, limit: perChapter);
    if (r.total > 0) hits.add((id: s.id, result: r));
  }
  return (hits: hits, unread: unread);
}
