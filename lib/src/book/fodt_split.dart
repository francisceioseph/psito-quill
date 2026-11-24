// O corte de um manuscrito em capítulos (o importador de DOCX, D-071).
//
// O motor salva o DOCX numa cópia em ODT plano (um XML só). Aqui, o corpo
// (`office:text`) é lido como uma lista de blocos de primeiro nível (os
// parágrafos, os títulos, as listas, as tabelas), e o corte cai antes dos
// títulos do nível escolhido. Cada capítulo leva o cabeçalho inteiro do
// manuscrito (as fontes, os estilos, os automáticos, as páginas), para abrir
// igual. O motor salva cada pedaço em ODT.
//
// Sondado na 24.2 (D-071): as notas de rodapé, as imagens embutidas, as
// listas e as tabelas sobrevivem ao corte. Um marcador que atravessa dois
// capítulos é jogado fora pelo motor (o começo fica num, o fim no outro):
// o começo vira um marcador de ponto, e o fim sozinho sai.
import 'package:flutter/foundation.dart';

import '../document/fodt.dart';

/// Um capítulo achado no manuscrito: os blocos [start] a [end] (exclusivo).
@immutable
class ChapterDraft {
  const ChapterDraft({required this.title, required this.words, required this.start, required this.end, this.part});

  /// O texto do título que abre o capítulo; null para o que vem antes do
  /// primeiro título (a dedicatória, a epígrafe), que a interface nomeia.
  final String? title;

  /// A parte (um título de nível acima) em que o capítulo começa; null fora
  /// de partes.
  final String? part;
  final int words;
  final int start, end;
}

/// O manuscrito lido: o que vem antes do corpo, os blocos e o que vem depois.
class FodtManuscript {
  FodtManuscript._(this._head, this._prelude, this._blocks, this._tail, this._levels);

  final String _head, _prelude, _tail;
  final List<String> _blocks;

  /// O nível de título (`text:outline-level`) de cada bloco; null fora dos
  /// títulos.
  final List<int?> _levels;

  /// Os níveis de título que aparecem, em ordem.
  List<int> get headingLevels => (_levels.whereType<int>().toSet().toList()..sort());

  /// O nível que vira capítulo, sem escolha: o mais alto que dá mais de um
  /// capítulo (um livro com "Parte I" em nível 1 e os capítulos em nível 2
  /// corta no 2 se só houver uma parte).
  int get suggestedLevel {
    for (final l in headingLevels) {
      if (_levels.where((x) => x == l).length > 1) return l;
    }
    return headingLevels.isEmpty ? 1 : headingLevels.first;
  }

  static final _bodyOpen = RegExp(r'<office:text\b[^>]*>');
  static final _token = RegExp(r'<(/?)([A-Za-z0-9:_.-]+)\b[^>]*?(/?)>|<!--[\s\S]*?-->|<\?[\s\S]*?\?>|[^<]+');
  static final _outline = RegExp(r'^<text:h\b[^>]*\btext:outline-level="(\d+)"');
  static final _headInner = RegExp(r'^<text:h\b[^>]*>([\s\S]*)</text:h>$');

  /// Lê a cópia em ODT plano. Lança [FormatException] se não é um texto.
  static FodtManuscript parse(String xml) {
    final open = _bodyOpen.firstMatch(xml);
    final close = xml.lastIndexOf('</office:text>');
    if (open == null || close < open.end) throw const FormatException('sem office:text');
    final body = xml.substring(open.end, close);
    final blocks = <String>[];
    final prelude = StringBuffer();
    var depth = 0;
    var start = 0;
    for (final m in _token.allMatches(body)) {
      final name = m[2];
      if (name == null) {
        // Texto solto ou comentário no primeiro nível: só espaço, na prática.
        continue;
      }
      if (m[1] == '/') {
        depth--;
        if (depth == 0) _add(body.substring(start, m.end), blocks, prelude);
      } else if (m[3] == '/') {
        if (depth == 0) _add(m[0]!, blocks, prelude);
      } else {
        if (depth == 0) start = m.start;
        depth++;
      }
    }
    final levels = [
      for (final b in blocks)
        switch (_outline.firstMatch(b)) {
          final m? => int.parse(m[1]!),
          null => null,
        },
    ];
    return FodtManuscript._(xml.substring(0, open.end), prelude.toString(), blocks, xml.substring(close), levels);
  }

  /// As declarações (sequências, variáveis) vão para todo capítulo; as
  /// quebras de página moles, para nenhum (o motor refaz).
  static void _add(String block, List<String> blocks, StringBuffer prelude) {
    if (block.startsWith('<text:soft-page-break')) return;
    if (block.startsWith('<text:sequence-decls') ||
        block.startsWith('<text:variable-decls') ||
        block.startsWith('<text:user-field-decls') ||
        block.startsWith('<text:dde-connection-decls')) {
      prelude.write(block);
      return;
    }
    blocks.add(block);
  }

  String _title(int i) => switch (_headInner.firstMatch(_blocks[i])) {
        final m? => odfHeadingText(m[1]!),
        null => '',
      };

  /// Os capítulos, cortados nos títulos de nível [level]. Os títulos de
  /// nível acima viram partes: o título da parte e o que vem depois dele
  /// ficam no começo do primeiro capítulo dela. O que vem antes do primeiro
  /// título vira um capítulo sem título, se tiver palavras.
  List<ChapterDraft> chapters(int level) {
    final drafts = <ChapterDraft>[];
    String? part;
    var start = 0;
    String? title;
    String? draftPart;
    var hasChapterHeading = false;
    var hasAnyHeading = false;

    void flush(int end) {
      if (end <= start) return;
      final words = odfWordCount(_blocks.sublist(start, end).join());
      final isFront = !hasAnyHeading;
      if (!isFront || words > 0) {
        drafts.add(ChapterDraft(title: title, words: words, start: start, end: end, part: draftPart));
      }
      start = end;
    }

    for (var i = 0; i < _blocks.length; i++) {
      final l = _levels[i];
      if (l == null || l > level) continue;
      if (l < level) {
        // Uma parte: começa um pedaço novo, que o próximo capítulo continua.
        flush(i);
        part = _title(i);
        title = part;
        draftPart = part;
        hasChapterHeading = false;
        hasAnyHeading = true;
        continue;
      }
      // Um capítulo: depois de um título de parte sem capítulo, continua o
      // mesmo pedaço; senão, começa outro.
      if (hasChapterHeading || !hasAnyHeading) {
        flush(i);
        draftPart = part;
      }
      title = _title(i);
      hasChapterHeading = true;
      hasAnyHeading = true;
    }
    flush(_blocks.length);
    return drafts;
  }

  static final _meta = RegExp(r'<meta:document-statistic\b[^>]*/>');

  /// O ODT plano de um capítulo: o cabeçalho do manuscrito, as declarações e
  /// os blocos dele, com os marcadores que atravessam o corte consertados.
  String chapterXml(ChapterDraft d) {
    final body = _fixRanges(_blocks.sublist(d.start, d.end).join());
    return '${_head.replaceAll(_meta, '')}$_prelude$body$_tail';
  }

  static final _rangeMark = RegExp(
      r'<(text:bookmark|text:reference-mark|text:toc-mark|text:alphabetical-index-mark|text:user-index-mark)-(start|end)\b([^>]*?)/>');
  static final _nameAttr = RegExp(r'text:(?:name|id)="([^"]*)"');
  static final _annotation = RegExp(r'<office:annotation-end\b[^>]*office:name="([^"]*)"[^>]*/>');
  static final _annotationName = RegExp(r'<office:annotation\b[^>]*office:name="([^"]*)"');

  /// Um começo sem o fim (o fim ficou no próximo capítulo): o marcador vira
  /// de ponto, e as outras marcas de intervalo saem. Um fim sem o começo
  /// sai. Os comentários que atravessam ficam no começo, sem o fim.
  static String _fixRanges(String body) {
    final starts = <String>{}, ends = <String>{};
    for (final m in _rangeMark.allMatches(body)) {
      final name = '${m[1]}:${_nameAttr.firstMatch(m[3]!)?[1]}';
      (m[2] == 'start' ? starts : ends).add(name);
    }
    var out = body.replaceAllMapped(_rangeMark, (m) {
      final name = '${m[1]}:${_nameAttr.firstMatch(m[3]!)?[1]}';
      final paired = m[2] == 'start' ? ends.contains(name) : starts.contains(name);
      if (paired) return m[0]!;
      if (m[2] == 'start' && m[1] == 'text:bookmark') return '<text:bookmark${m[3]}/>';
      return '';
    });
    final opened = {for (final m in _annotationName.allMatches(out)) m[1]!};
    out = out.replaceAllMapped(_annotation, (m) => opened.contains(m[1]) ? m[0]! : '');
    return out;
  }
}
