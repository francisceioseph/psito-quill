// As referências (Fase 4, Etapa 5, D-090): os marcadores e as legendas que a
// cópia do documento (o FODT da Estrutura) tem, e o que a referência cruzada
// manda ao motor.
//
// O sumário, as tabelas de figuras, o índice remissivo, a legenda e a
// referência a um título vão pelas macros do perfil (`quill_macros.dart`):
// na 24.2, o motor só os faz por janelas, que travam o LOK. O marcador e a
// referência a um marcador ou a uma legenda são comandos `.uno:`.
import 'package:flutter/foundation.dart';

import '../kit/lok/quill_macros.dart';

/// O tipo de uma legenda: a sequência do LibreOffice que a numera.
enum CaptionKind {
  figure('Figure', 'Figura'),
  table('Table', 'Tabela');

  const CaptionKind(this.sequence, this.engineName);

  /// O nome no arquivo e na API (o `text:name` da sequência, a categoria da
  /// tabela de figuras).
  final String sequence;

  /// O nome que a interface do motor mostra, que o `.uno:InsertField` pede
  /// para entrar na sequência que já existe. O motor abre tudo em pt-BR
  /// (`Language=pt-BR`, no `LokEngine`).
  final String engineName;
}

/// O nome que o `.uno:InsertField` pede para a sequência [sequence] do
/// arquivo: os cinco que o LibreOffice traz têm o nome traduzido na
/// interface (pt-BR); os outros, o mesmo.
String engineSequenceName(String sequence) => switch (sequence) {
      'Figure' => 'Figura',
      'Table' => 'Tabela',
      'Illustration' => 'Ilustração',
      'Text' => 'Texto',
      'Drawing' => 'Desenho',
      _ => sequence,
    };

/// Uma legenda (um parágrafo com um campo de sequência) na cópia.
@immutable
class CaptionEntry {
  const CaptionEntry({required this.sequence, required this.number, required this.text});

  /// O nome da sequência no arquivo ("Figure", "Table").
  final String sequence;

  /// O número interno do campo (o do `text:ref-name="refFigure0"`), que a
  /// referência pede; não é o número que aparece.
  final int number;

  /// O parágrafo inteiro ("Figura 1: Mapa de Dustland").
  final String text;

  @override
  bool operator ==(Object other) =>
      other is CaptionEntry && other.sequence == sequence && other.number == number && other.text == text;

  @override
  int get hashCode => Object.hash(sequence, number, text);
}

/// O que a referência cruzada mostra no texto.
enum RefFormat {
  /// O texto do título ou do marcador; da legenda, "Figura 1".
  text,

  /// O número da página.
  page,

  /// "acima" ou "abaixo".
  aboveBelow,
}

/// O `ReferenceFieldPart` da API (o `Format` do `.uno:InsertField`): PAGE 0,
/// TEXT 2, UP_DOWN 3 e CATEGORY_AND_NUMBER 5.
int refPart(RefFormat f, {bool caption = false}) => switch (f) {
      RefFormat.text => caption ? 5 : 2,
      RefFormat.page => 0,
      RefFormat.aboveBelow => 3,
    };

/// O `.uno:InsertField` da referência a um marcador (o `SubType` 2) ou a uma
/// legenda (1, com o número interno). O tipo 13 é o `GetRef` da 24.2.
String bookmarkRefArgs(String name, RefFormat f) => _refArgs(2, name, '', refPart(f));

String captionRefArgs(CaptionEntry c, RefFormat f) =>
    _refArgs(1, engineSequenceName(c.sequence), '${c.number}', refPart(f, caption: true));

String _refArgs(int subType, String name, String content, int format) => '{"Type":{"type":"short","value":13},'
    '"SubType":{"type":"short","value":$subType},'
    '"Name":{"type":"string","value":${_json(name)}},'
    '"Content":{"type":"string","value":${_json(content)}},'
    '"Format":{"type":"long","value":$format}}';

String _json(String s) {
  final b = StringBuffer('"');
  for (final c in s.runes) {
    switch (c) {
      case 0x22:
        b.write(r'\"');
      case 0x5c:
        b.write(r'\\');
      case < 0x20:
        b.write('\\u${c.toRadixString(16).padLeft(4, '0')}');
      default:
        b.writeCharCode(c);
    }
  }
  b.write('"');
  return b.toString();
}

/// O `.uno:InsertBookmark` com o nome.
String bookmarkArgs(String name) => '{"Bookmark":{"type":"string","value":${_json(name)}}}';

/// A macro da referência ao título número [index] da Estrutura (o texto
/// confere, D-090). [mark] é o nome do marcador novo, se o título ainda não
/// tem um.
String headingRefMacro(int index, String text, String mark, RefFormat f) =>
    quillMacro('RefTitulo', [index, MacroText(text), MacroName(mark), refPart(f)]);

/// Um nome novo para o marcador de referência de um título: os do
/// LibreOffice começam por `__RefHeading__`, que a 24.2 esconde da lista e
/// trata como de título. Único entre os capítulos, que o compilar junta.
String newHeadingMark(DateTime now, int counter) =>
    '__RefHeading__quill_${now.microsecondsSinceEpoch.toRadixString(36)}_$counter';

/// O que não pode num nome de marcador (o LibreOffice recusa na janela dele).
final _badBookmarkChars = RegExp(r'[/\\@:*?";,.#|]');

/// null: o nome serve. Senão, o motivo (para a janela mostrar).
BookmarkNameProblem? bookmarkNameProblem(String name, Iterable<String> existing) {
  final n = name.trim();
  if (n.isEmpty) return BookmarkNameProblem.empty;
  if (n.startsWith('_') || _badBookmarkChars.hasMatch(n)) return BookmarkNameProblem.characters;
  if (existing.contains(n)) return BookmarkNameProblem.exists;
  return null;
}

enum BookmarkNameProblem { empty, characters, exists }

// --------------------------------------------------------- a cópia --

final _bookmark = RegExp(r'<text:bookmark(?:-start)?\s[^>]*?text:name="([^"]*)"');
final _paragraph = RegExp(r'<text:(p|h)(\s[^>]*)?>([\s\S]*?)</text:\1>');
final _sequence = RegExp(r'<text:sequence\s([^>]*?)(?:/>|>([\s\S]*?)</text:sequence>)');
final _attr = RegExp(r'([\w:-]+)="([^"]*)"');
final _tag = RegExp(r'<[^>]+>');
final _spaces = RegExp(r'<text:s(\s+text:c="(\d+)")?\s*/>');
final _breakLike = RegExp(r'<text:(tab|line-break)\s*/>');
final _note = RegExp(r'<text:note\b[\s\S]*?</text:note>');

String _unescape(String s) => s
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAll('&amp;', '&');

String _text(String inner) => _unescape(inner
        .replaceAllMapped(_spaces, (m) => ' ' * int.parse(m[2] ?? '1'))
        .replaceAll(_breakLike, ' ')
        .replaceAll(_tag, ''))
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Os marcadores da pessoa no corpo [body], na ordem do texto: sem os
/// escondidos (os que começam por `_`: os de título, o `_GoBack` do Word).
List<String> odfBookmarks(String body) {
  final out = <String>{};
  for (final m in _bookmark.allMatches(body)) {
    final name = _unescape(m[1]!);
    if (!name.startsWith('_')) out.add(name);
  }
  return out.toList();
}

/// As legendas do corpo [body]: os parágrafos com um campo de sequência. O
/// número que aparece vem do campo; sem ele (a cópia gravada antes de o
/// motor calcular), a conta pela ordem.
List<CaptionEntry> odfCaptions(String body) {
  final out = <CaptionEntry>[];
  final counts = <String, int>{};
  for (final p in _paragraph.allMatches(body.replaceAll(_note, ''))) {
    final inner = p[3]!;
    if (!inner.contains('<text:sequence ')) continue;
    // A referência vai ao primeiro campo do parágrafo; os outros só contam.
    CaptionEntry? first;
    final shown = inner.replaceAllMapped(_sequence, (m) {
      final a = {for (final x in _attr.allMatches(m[1]!)) x[1]!: x[2]!};
      final name = _unescape(a['text:name'] ?? '');
      final n = counts[name] = (counts[name] ?? 0) + 1;
      final value = _text(m[2] ?? '');
      final ref = RegExp('^ref${RegExp.escape(a['text:name'] ?? '')}(\\d+)\$').firstMatch(a['text:ref-name'] ?? '');
      if (first == null && ref != null && name.isNotEmpty) {
        first = CaptionEntry(sequence: name, number: int.parse(ref[1]!), text: '');
      }
      return value.isEmpty ? '$n' : value;
    });
    final f = first;
    if (f != null) out.add(CaptionEntry(sequence: f.sequence, number: f.number, text: _text(shown)));
  }
  return out;
}
