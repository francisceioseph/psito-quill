// Dividir o capítulo no cursor (Fase 3, Etapa 5, D-079).
//
// O motor põe um marcador no cursor e grava a cópia (FODT). Aqui sai o resto
// do capítulo, do marcador ao fim: o texto antes dele vai embora, e os
// elementos que o envolvem (o parágrafo, um negrito, uma lista) são reabertos
// no começo, para o XML continuar fechado. O motor salva o resto em ODT como
// o capítulo novo, e apaga do cursor ao fim no capítulo da tela.
import 'package:flutter/foundation.dart';

import '../document/fodt.dart';

@immutable
class ChapterCut {
  const ChapterCut({
    required this.xml,
    required this.atParagraphStart,
    required this.previousIsText,
    required this.wordsBefore,
    required this.wordsAfter,
    this.title,
  });

  /// O ODT plano do capítulo novo (do marcador ao fim).
  final String xml;

  /// O marcador está no começo de um parágrafo do primeiro nível: depois de
  /// apagar até o fim, sobra um parágrafo vazio no capítulo da tela.
  final bool atParagraphStart;

  /// O bloco antes desse parágrafo é texto (um parágrafo ou um título), e o
  /// Backspace junta o vazio a ele sem estragar nada (uma tabela, não).
  final bool previousIsText;
  final int wordsBefore, wordsAfter;

  /// O texto do título que abre o resto, se ele começa por um.
  final String? title;
}

const _decls = {'text:sequence-decls', 'text:variable-decls', 'text:user-field-decls', 'text:dde-connection-decls'};

/// Os elementos que contam como conteúdo dentro de um parágrafo (os
/// espaços, as tabulações, as imagens, as notas, os campos); os marcadores e
/// as quebras moles não.
bool _isContent(String name) =>
    !(name.startsWith('text:bookmark') ||
        name.startsWith('text:reference-mark') ||
        name.startsWith('text:toc-mark') ||
        name.startsWith('text:alphabetical-index-mark') ||
        name.startsWith('text:user-index-mark') ||
        name == 'text:soft-page-break' ||
        name == 'office:annotation-end' ||
        name == 'text:change-start' ||
        name == 'text:change-end');

final _token = RegExp(r'<(/?)([A-Za-z0-9:_.-]+)\b[^>]*?(/?)>|<!--[\s\S]*?-->|[^<]+');
final _bodyOpen = RegExp(r'<office:text\b[^>]*>');
final _leadingParagraph = RegExp(r'^<text:p\b[^>]*?text:style-name="([^"]*)"[^>]*>([\s\S]*?)</text:p>');
final _firstParagraph = RegExp(r'<text:(p|h)\b[^>]*>([\s\S]*?)</text:\1>');

/// O fim (depois da marca de fechamento) do elemento [name] aberto antes de
/// [from], contando os do mesmo nome dentro dele (um quadro num quadro).
/// -1 se não fecha.
int _closeOf(String xml, String name, int from) {
  final tags = RegExp('<(/?)${RegExp.escape(name)}\\b[^>]*?(/?)>');
  var depth = 1;
  for (final m in tags.allMatches(xml, from)) {
    if (m[2] == '/') continue;
    depth += m[1] == '/' ? -1 : 1;
    if (depth == 0) return m.end;
  }
  return -1;
}

/// O resto de [fodt] a partir do marcador [bookmark]; null se ele não está
/// no corpo.
ChapterCut? cutAtBookmark(String fodt, String bookmark) {
  final open = _bodyOpen.firstMatch(fodt);
  final close = fodt.lastIndexOf('</office:text>');
  if (open == null || close < open.end) return null;
  final body = fodt.substring(open.end, close);
  // Um marcador de ponto (sem seleção) ou o começo de um intervalo (com o
  // texto selecionado, como depois do salto a uma cena): o corte cai no
  // começo.
  final name = RegExp.escape(bookmark);
  final mark = RegExp('<text:bookmark(?:-start)?\\s+text:name="$name"\\s*/>').firstMatch(body);
  if (mark == null) return null;
  final markEnd = RegExp('<text:bookmark-end\\s+text:name="$name"\\s*/>');

  // Os elementos abertos no marcador: (a marca de abertura, o nome).
  final stack = <(String, String)>[];
  final decls = StringBuffer();
  var contentInParagraph = false;
  String? lastTopLevel;
  String? topLevelOfMark;
  var skipUntil = -1;
  for (final m in _token.allMatches(body.substring(0, mark.start))) {
    if (m.start < skipUntil) continue;
    final name = m[2];
    if (name == null) {
      // Texto (ou um comentário): dentro de um parágrafo, é conteúdo.
      if (m[0]!.startsWith('<!--')) continue;
      if (stack.any((e) => e.$2 == 'text:p' || e.$2 == 'text:h')) contentInParagraph = true;
      continue;
    }
    if (m[1] == '/') {
      if (stack.isNotEmpty) stack.removeLast();
      if (stack.isEmpty) lastTopLevel = name;
      continue;
    }
    if (m[3] == '/') {
      if (stack.isEmpty) {
        lastTopLevel = name == 'text:soft-page-break' ? lastTopLevel : name;
      } else if (_isContent(name)) {
        contentInParagraph = true;
      }
      continue;
    }
    if (stack.isEmpty && _decls.contains(name)) {
      // As declarações (as sequências das legendas, as variáveis) vão
      // inteiras para o capítulo novo.
      final end = _closeOf(body, name, m.end);
      if (end >= 0) {
        decls.write(body.substring(m.start, end));
        skipUntil = end;
      }
      continue;
    }
    if (name == 'text:p' || name == 'text:h') contentInParagraph = false;
    // Uma nota (ou um quadro) antes do marcador é conteúdo do parágrafo, e
    // tudo o que vem dentro dela sai junto.
    if (stack.isNotEmpty && (name == 'text:note' || name == 'draw:frame' || name == 'office:annotation')) {
      contentInParagraph = true;
      final end = _closeOf(body, name, m.end);
      if (end >= 0) skipUntil = end;
      continue;
    }
    if (stack.isEmpty) topLevelOfMark = name;
    stack.add((m[0]!, name));
  }
  // O marcador fora de qualquer bloco (não acontece com o LibreOffice).
  if (stack.isEmpty) topLevelOfMark = null;

  final before = body.substring(0, mark.start);
  var rest = '${stack.map((e) => e.$1).join()}${body.substring(mark.end).replaceFirst(markEnd, '')}';
  // O capítulo novo não começa por um separador de cena: ele sai.
  final lead = _leadingParagraph.firstMatch(rest);
  if (lead != null && sceneStyleNames(fodt).contains(lead[1]) && isSceneSeparatorText(odfHeadingText(lead[2]!))) {
    rest = rest.substring(lead.end);
  }
  final head = fodt.substring(0, open.end).replaceAll(RegExp(r'<meta:document-statistic\b[^>]*/>'), '');
  final first = _firstParagraph.firstMatch(rest);
  final title = first != null && first[1] == 'h' ? odfHeadingText(first[2]!) : null;
  final topIsParagraph = stack.length == 1 && (topLevelOfMark == 'text:p' || topLevelOfMark == 'text:h');
  return ChapterCut(
    xml: '$head$decls$rest${fodt.substring(close)}',
    atParagraphStart: topIsParagraph && !contentInParagraph,
    previousIsText: lastTopLevel == 'text:p' || lastTopLevel == 'text:h',
    wordsBefore: odfWordCount(before),
    wordsAfter: odfWordCount(rest),
    title: title == null || title.isEmpty ? null : title,
  );
}
