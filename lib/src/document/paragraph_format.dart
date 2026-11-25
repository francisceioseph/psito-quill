// O parágrafo avançado (Fase 4, Etapa 6, D-091): as bordas, as tabulações e
// "não adicionar intervalo entre parágrafos do mesmo estilo". Na 24.2, a
// janela do motor trava o LOK; vão por macros (`quill_macros.dart`), com os
// números que o Quill gera.
//
// O motor só diz os lados com borda (o estado `.uno:BorderOuter`) e as
// tabulações (a régua, o callback 35); a largura, a cor e o intervalo não.
// Por isso a janela só manda o que a pessoa mudou nela.
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../kit/lok/quill_macros.dart';
import '../kit/quill_kit.dart';

/// Os lados de uma borda: 1 em cima, 2 embaixo, 4 à esquerda, 8 à direita
/// (como a macro `Bordas` lê).
abstract final class BorderSides {
  static const top = 1, bottom = 2, left = 4, right = 8;
  static const box = top | bottom | left | right;
}

/// As escolhas de borda da janela.
enum BorderPreset {
  none(0),
  box(BorderSides.box),
  top(BorderSides.top),
  bottom(BorderSides.bottom),
  topBottom(BorderSides.top | BorderSides.bottom),
  left(BorderSides.left);

  const BorderPreset(this.sides);
  final int sides;

  /// A escolha com estes lados; null se nenhuma tem exatamente esses.
  static BorderPreset? of(int sides) => values.where((p) => p.sides == sides).firstOrNull;
}

/// A largura da linha, em 1/100 mm (0,5 pt, 1,5 pt e 3 pt).
enum BorderWeight {
  thin(18),
  medium(53),
  thick(106);

  const BorderWeight(this.mm100);
  final int mm100;
}

@immutable
class BorderSpec {
  const BorderSpec({required this.sides, this.weight = BorderWeight.thin, this.color = 0x000000, this.distanceMm100 = 100});

  /// A soma dos [BorderSides].
  final int sides;
  final BorderWeight weight;

  /// RGB.
  final int color;

  /// A distância entre a borda e o texto.
  final int distanceMm100;

  @override
  bool operator ==(Object other) =>
      other is BorderSpec &&
      other.sides == sides &&
      other.weight == weight &&
      other.color == color &&
      other.distanceMm100 == distanceMm100;

  @override
  int get hashCode => Object.hash(sides, weight, color, distanceMm100);
}

/// Os lados com borda, pelo estado `.uno:BorderOuter` do motor
/// (`{"top": "true", "bottom": "false", ...}`). null: o motor não disse.
int? borderSidesFromState(String? state) {
  if (state == null || !state.startsWith('{')) return null;
  try {
    final m = jsonDecode(state);
    if (m is! Map) return null;
    bool on(String k) => m[k] == 'true' || m[k] == true;
    return (on('top') ? BorderSides.top : 0) |
        (on('bottom') ? BorderSides.bottom : 0) |
        (on('left') ? BorderSides.left : 0) |
        (on('right') ? BorderSides.right : 0);
  } on FormatException {
    return null;
  }
}

/// O alinhamento de uma tabulação, com o número do `TabAlign` da API.
enum TabAlign {
  left(0),
  center(1),
  right(2),
  decimal(3);

  const TabAlign(this.api);
  final int api;

  /// Pelo estilo da régua do motor (o `SvxTabAdjust`: 0 esquerda, 1 direita,
  /// 2 decimal, 3 centro; o 4 são as automáticas). null: uma automática.
  static TabAlign? fromRuler(int style) => switch (style) {
        0 => left,
        1 => right,
        2 => decimal,
        3 => center,
        _ => null,
      };
}

/// O que preenche o espaço antes da tabulação.
enum TabLeader {
  none(32),
  dots(46),
  dashes(45),
  line(95);

  const TabLeader(this.char);

  /// O código do caractere (o espaço é nenhum).
  final int char;
}

@immutable
class TabStopSpec {
  const TabStopSpec({required this.positionMm100, this.align = TabAlign.left, this.leader = TabLeader.none});

  /// Desde o recuo esquerdo do parágrafo, em 1/100 mm.
  final int positionMm100;
  final TabAlign align;
  final TabLeader leader;

  @override
  bool operator ==(Object other) =>
      other is TabStopSpec && other.positionMm100 == positionMm100 && other.align == align && other.leader == leader;

  @override
  int get hashCode => Object.hash(positionMm100, align, leader);
}

/// As tabulações do parágrafo do cursor, pela régua (sem as automáticas). A
/// régua não diz o preenchimento: elas vêm sem.
List<TabStopSpec> tabsFromRuler(RulerInfo? ruler) => [
      for (final t in ruler?.tabs ?? const <({int position, int style})>[])
        if (TabAlign.fromRuler(t.style) case final a?) TabStopSpec(positionMm100: t.position, align: a),
    ];

/// O argumento da macro `Tabulacoes`: "n_posição_alinhamento_preenchimento_...",
/// em ordem de posição. "0" volta às do estilo.
MacroName tabsMacroArg(List<TabStopSpec> tabs) {
  final sorted = [...tabs]..sort((a, b) => a.positionMm100.compareTo(b.positionMm100));
  return MacroName([
    sorted.length,
    for (final t in sorted) ...[t.positionMm100.clamp(0, 999999), t.align.api, t.leader.char],
  ].join('_'));
}

/// O que a janela do parágrafo devolve: só o que mudou (null fica como está).
@immutable
class ParagraphChanges {
  const ParagraphChanges({this.background, this.clearBackground = false, this.noSpaceSameStyle, this.borders, this.tabs});

  /// A cor de fundo nova (RGB); com [clearBackground], sem cor.
  final int? background;
  final bool clearBackground;
  final bool? noSpaceSameStyle;
  final BorderSpec? borders;
  final List<TabStopSpec>? tabs;

  bool get isEmpty => background == null && !clearBackground && noSpaceSameStyle == null && borders == null && tabs == null;
}

/// As propriedades do documento (as Informações): o `office:meta` da cópia.
@immutable
class DocProperties {
  const DocProperties({this.title = '', this.subject = '', this.author = '', this.keywords = const [], this.comment = ''});

  final String title, subject;

  /// O autor do documento (o `meta:initial-creator`), não quem salvou por
  /// último.
  final String author;
  final List<String> keywords;
  final String comment;

  static const empty = DocProperties();

  @override
  bool operator ==(Object other) =>
      other is DocProperties &&
      other.title == title &&
      other.subject == subject &&
      other.author == author &&
      listEquals(other.keywords, keywords) &&
      other.comment == comment;

  @override
  int get hashCode => Object.hash(title, subject, author, Object.hashAll(keywords), comment);
}

/// As etiquetas como a pessoa escreve: separadas por vírgula.
List<String> parseKeywords(String text) =>
    [for (final k in text.split(',')) if (k.trim().isNotEmpty) k.trim().replaceAll('\n', ' ')];

/// A chamada da macro `Propriedades`. Os textos vão em hexadecimal; as
/// etiquetas, separadas por quebras de linha.
String propertiesMacro(DocProperties p) => quillMacro('Propriedades', [
      MacroText(p.title),
      MacroText(p.subject),
      MacroText(p.author),
      MacroText(p.keywords.join('\n')),
      MacroText(p.comment),
    ]);
