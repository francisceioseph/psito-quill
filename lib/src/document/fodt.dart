// A leitura da cópia temporária em ODT plano (D-044): as propriedades dos
// estilos, as fontes declaradas e os títulos (a Estrutura da Etapa 5).
//
// Um leitor pequeno, por expressões regulares, só do que o Quill usa: o
// arquivo vem sempre do próprio LibreOffice, com o mesmo formato. Roda num
// isolate (`Isolate.run`), e o que volta é pouco: um mapa de estilos e uma
// lista de títulos. O texto do documento não fica guardado.
import 'package:flutter/foundation.dart';

import 'outline.dart';
import 'references.dart';
import 'search.dart';
import 'style_patch.dart';

export 'search.dart' show SearchQuery;
export 'style_patch.dart' show PageSetup;

/// O que a galeria e o "Revelar formatação" precisam de um estilo, já com o
/// que vem dos pais (`style:parent-style-name`) resolvido.
@immutable
class StyleProps {
  const StyleProps({
    this.family = 'paragraph',
    this.parent,
    this.fontName,
    this.sizePt,
    this.bold,
    this.italic,
    this.color,
    this.align,
    this.indentLeftCm,
    this.firstLineCm,
  });

  /// "paragraph" ou "text" (caractere).
  final String family;
  final String? parent;
  final String? fontName;
  final double? sizePt;
  final bool? bold, italic;

  /// 0xRRGGBB.
  final int? color;

  /// "start", "center", "end", "justify" (os valores do ODF).
  final String? align;
  final double? indentLeftCm, firstLineCm;

  /// Os valores deste por cima dos de [base] (o pai).
  StyleProps over(StyleProps base) => StyleProps(
        family: family,
        parent: parent,
        fontName: fontName ?? base.fontName,
        sizePt: sizePt ?? base.sizePt,
        bold: bold ?? base.bold,
        italic: italic ?? base.italic,
        color: color ?? base.color,
        align: align ?? base.align,
        indentLeftCm: indentLeftCm ?? base.indentLeftCm,
        firstLineCm: firstLineCm ?? base.firstLineCm,
      );

  @override
  bool operator ==(Object other) =>
      other is StyleProps &&
      other.family == family &&
      other.fontName == fontName &&
      other.sizePt == sizePt &&
      other.bold == bold &&
      other.italic == italic &&
      other.color == color &&
      other.align == align &&
      other.indentLeftCm == indentLeftCm &&
      other.firstLineCm == firstLineCm;

  @override
  int get hashCode => Object.hash(family, fontName, sizePt, bold, italic, color, align, indentLeftCm, firstLineCm);
}

/// O que sai de uma cópia.
/// As margens da página em cm (do estilo de página "Standard", o de quase
/// todo o livro): a régua vertical usa as de cima e de baixo (D-046).
typedef PageMarginsCm = ({double top, double bottom, double left, double right});

@immutable
class FodtSnapshot {
  const FodtSnapshot({
    this.styles = const {},
    this.fonts = const [],
    this.outline = const [],
    this.pageMargins,
    this.words,
    this.characters,
    this.page = const PageSetup(),
    this.scenes = const [],
    this.bookmarks = const [],
    this.captions = const [],
  });

  /// Os marcadores da pessoa e as legendas, para a referência cruzada (D-090).
  final List<String> bookmarks;
  final List<CaptionEntry> captions;

  /// As cenas do documento (D-079); vazia sem nenhum separador.
  final List<SceneEntry> scenes;

  /// O cabeçalho, o rodapé e a hifenização do documento (D-075).
  final PageSetup page;

  /// As palavras e os caracteres do `meta:document-statistic` da cópia (o
  /// LibreOffice conta ao gravar). null: a cópia não disse.
  final int? words, characters;

  /// null: a cópia não disse (ou ainda não chegou).
  final PageMarginsCm? pageMargins;

  /// Pelo nome do LibreOffice ("Heading 1", "Text body").
  final Map<String, StyleProps> styles;

  /// As fontes declaradas no documento (`style:font-face`), a seção "Neste
  /// documento" da lista de fontes.
  final List<String> fonts;
  final List<OutlineEntry> outline;

  static const empty = FodtSnapshot();
}

final _attr = RegExp(r'([\w:-]+)="([^"]*)"');
final _fontFace = RegExp(r'<style:font-face\s([^>]*?)/?>');
final _style = RegExp(r'<style:(style|default-style)\s([^>]*?)(/>|>([\s\S]*?)</style:\1>)');
final _textProps = RegExp(r'<style:text-properties\s([^>]*?)/?>');
final _paraProps = RegExp(r'<style:paragraph-properties\s([^>]*?)/?>');
final _bodyMarks = RegExp(r'(<text:soft-page-break\s*/>)|<text:h\s([^>]*)>([\s\S]*?)</text:h>');
final _tag = RegExp(r'<[^>]+>');
final _docStatistic = RegExp(r'<meta:document-statistic\s([^>]*?)/?>');

Map<String, String> _attrs(String s) => {for (final m in _attr.allMatches(s)) m[1]!: m[2]!};

/// "Heading_20_1" → "Heading 1" (o ODF escreve os caracteres especiais como
/// `_XX_`, em hexadecimal).
String decodeStyleName(String name) =>
    name.replaceAllMapped(RegExp(r'_([0-9a-fA-F]{2})_'), (m) => String.fromCharCode(int.parse(m[1]!, radix: 16)));

String _unescape(String s) => s
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAll('&amp;', '&');

/// "12pt" → 12; "0.5in" → 36; "130%" de 12 → 15,6.
double? _points(String? v, {double? base}) {
  if (v == null) return null;
  final m = RegExp(r'^(-?[\d.]+)(pt|cm|mm|in|%)$').firstMatch(v.trim());
  if (m == null) return null;
  final n = double.parse(m[1]!);
  return switch (m[2]) {
    'pt' => n,
    'cm' => n * 72 / 2.54,
    'mm' => n * 72 / 25.4,
    'in' => n * 72,
    '%' => base == null ? null : base * n / 100,
    _ => null,
  };
}

double? _cm(String? v) => switch (_points(v)) {
      final p? => p * 2.54 / 72,
      null => null,
    };

int? _color(String? v) => v != null && RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(v) ? int.parse(v.substring(1), radix: 16) : null;

/// Lê o ODT plano inteiro. Só as seções que interessam: os estilos de
/// `office:styles` (os com nome, que o autor escolhe) e os títulos do corpo.
FodtSnapshot parseFodt(String xml) {
  final statMatch = _docStatistic.firstMatch(xml);
  final statistic = statMatch == null ? const <String, String>{} : _attrs(statMatch[1]!);
  final fonts = <String, String>{};
  for (final m in _fontFace.allMatches(xml)) {
    final a = _attrs(m[1]!);
    final name = a['style:name'];
    if (name == null) continue;
    fonts[name] = (a['svg:font-family'] ?? name).replaceAll('&apos;', '').replaceAll("'", '').trim();
  }

  final start = xml.indexOf('<office:styles>');
  final end = xml.indexOf('</office:styles>');
  final stylesXml = start >= 0 && end > start ? xml.substring(start, end) : '';
  final raw = <String, StyleProps>{};
  final defaults = <String, StyleProps>{};
  // O tamanho em porcentagem depende do pai: resolvido depois.
  final percent = <String, double?>{};
  for (final m in _style.allMatches(stylesXml)) {
    final a = _attrs(m[2]!);
    final family = a['style:family'] ?? 'paragraph';
    final inner = m[4] ?? '';
    final t = _textProps.firstMatch(inner) == null ? const <String, String>{} : _attrs(_textProps.firstMatch(inner)![1]!);
    final p = _paraProps.firstMatch(inner) == null ? const <String, String>{} : _attrs(_paraProps.firstMatch(inner)![1]!);
    final fontKey = t['style:font-name'];
    final props = StyleProps(
      family: family,
      parent: a['style:parent-style-name'] == null ? null : decodeStyleName(a['style:parent-style-name']!),
      fontName: fontKey == null ? (t['fo:font-family']?.replaceAll("'", '')) : fonts[fontKey] ?? fontKey,
      // A porcentagem depende do pai: fica para a resolução, como texto.
      sizePt: _points(t['fo:font-size']),
      bold: switch (t['fo:font-weight']) {
        null => null,
        'bold' || '600' || '700' || '800' || '900' => true,
        _ => false,
      },
      italic: switch (t['fo:font-style']) {
        null => null,
        'italic' || 'oblique' => true,
        _ => false,
      },
      color: _color(t['fo:color']),
      align: switch (p['fo:text-align']) {
        'left' => 'start',
        'right' => 'end',
        final v => v,
      },
      indentLeftCm: _cm(p['fo:margin-left']),
      firstLineCm: _cm(p['fo:text-indent']),
    );
    if (m[1] == 'default-style') {
      defaults[family] = props;
      continue;
    }
    final name = a['style:display-name'] ?? decodeStyleName(a['style:name'] ?? '');
    if (name.isEmpty) continue;
    raw[name] = props;
    final pct = t['fo:font-size'];
    if (pct != null && pct.endsWith('%')) percent[name] = double.tryParse(pct.substring(0, pct.length - 1));
  }

  final resolved = <String, StyleProps>{};
  StyleProps resolve(String name, [int depth = 0]) {
    if (resolved[name] case final r?) return r;
    final own = raw[name]!;
    final parentName = own.parent;
    final base = parentName != null && raw.containsKey(parentName) && depth < 20
        ? resolve(parentName, depth + 1)
        : defaults[own.family] ?? const StyleProps();
    var r = own.over(base);
    if (percent[name] case final pct? when base.sizePt != null) {
      r = StyleProps(
        family: r.family,
        parent: r.parent,
        fontName: r.fontName,
        sizePt: base.sizePt! * pct / 100,
        bold: r.bold,
        italic: r.italic,
        color: r.color,
        align: r.align,
        indentLeftCm: r.indentLeftCm,
        firstLineCm: r.firstLineCm,
      );
    }
    return resolved[name] = r;
  }

  for (final name in raw.keys) {
    resolve(name);
  }

  final bodyStart = xml.indexOf('<office:body>');
  final body = bodyStart >= 0 ? xml.substring(bodyStart) : '';
  // Os títulos e as quebras de página, na ordem do texto: a página de cada
  // título é 1 + as quebras antes dele.
  final outline = <OutlineEntry>[];
  var page = 1;
  // O texto de cada parágrafo antes do título, para contar as ocorrências
  // da chave de busca dele (o salto, D-072). A busca do motor não atravessa
  // parágrafos, e cada ocorrência numa mesma linha conta.
  final paragraphs = [
    for (final p in _bodyParas.allMatches(body))
      if (p[1] == null) (end: p.end, text: _paragraphText(_noteRemoved(p[4] ?? ''))),
  ];
  var before = 0;
  for (final m in _bodyMarks.allMatches(body)) {
    if (m[1] != null) {
      page++;
      continue;
    }
    final inner = _noteRemoved(m[3]!);
    final text = _headingText(inner);
    if (text.isEmpty) continue;
    final key = headingSearchKey(inner);
    while (before < paragraphs.length && paragraphs[before].end <= m.start) {
      before++;
    }
    var occurrence = 0;
    if (key.isNotEmpty) {
      for (var i = 0; i < before; i++) {
        occurrence += _countOf(paragraphs[i].text, key);
      }
    }
    outline.add(OutlineEntry(
      level: int.tryParse(_attrs(m[2]!)['text:outline-level'] ?? '') ?? 1,
      text: text,
      page: page,
      searchKey: key.isEmpty ? text : key,
      occurrence: occurrence,
    ));
  }

  return FodtSnapshot(
    styles: resolved,
    fonts: fonts.values.toSet().toList()..sort(),
    outline: outline,
    pageMargins: _pageMargins(xml),
    words: int.tryParse(statistic['meta:word-count'] ?? ''),
    characters: int.tryParse(statistic['meta:character-count'] ?? ''),
    page: parsePageSetup(xml),
    scenes: odfScenes(xml),
    bookmarks: odfBookmarks(body),
    captions: odfCaptions(body),
  );
}

final _masterPage = RegExp(r'<style:master-page\s([^>]*?)/?>');
final _pageLayout = RegExp(r'<style:page-layout\s+style:name="([^"]*)"[^>]*>\s*<style:page-layout-properties\s([^>]*?)/?>');

/// As margens do estilo de página "Standard" (ou do primeiro, se não há).
PageMarginsCm? _pageMargins(String xml) {
  String? layout;
  for (final m in _masterPage.allMatches(xml)) {
    final a = _attrs(m[1]!);
    layout ??= a['style:page-layout-name'];
    if (a['style:name'] == 'Standard') {
      layout = a['style:page-layout-name'];
      break;
    }
  }
  for (final m in _pageLayout.allMatches(xml)) {
    if (layout != null && m[1] != layout) continue;
    final a = _attrs(m[2]!);
    final top = _cm(a['fo:margin-top']), bottom = _cm(a['fo:margin-bottom']);
    final left = _cm(a['fo:margin-left']), right = _cm(a['fo:margin-right']);
    if (top == null || bottom == null || left == null || right == null) return null;
    return (top: top, bottom: bottom, left: left, right: right);
  }
  return null;
}

final _note = RegExp(r'<text:note\b[\s\S]*?</text:note>');
String _noteRemoved(String inner) => inner.replaceAll(_note, '');

final _keyStop = RegExp(r'<text:(tab|line-break)\s*/>');

/// A chave de busca de um título (o miolo do `text:h`): o texto até a
/// primeira tabulação ou quebra de linha, com os espaços como estão.
String headingSearchKey(String inner) {
  final stop = _keyStop.firstMatch(inner);
  return _paragraphText(stop == null ? inner : inner.substring(0, stop.start)).trim();
}

int _countOf(String text, String key) {
  var n = 0;
  for (var i = text.indexOf(key); i >= 0; i = text.indexOf(key, i + key.length)) {
    n++;
  }
  return n;
}

String _headingText(String inner) {
  final spaced = inner
      .replaceAll(RegExp(r'<text:s\s*/>'), ' ')
      .replaceAll(RegExp(r'<text:s\s+text:c="(\d+)"\s*/>'), ' ')
      .replaceAll(RegExp(r'<text:(tab|line-break)\s*/>'), ' ');
  return _unescape(spaced.replaceAll(_tag, '')).replaceAll(RegExp(r'\s+'), ' ').trim();
}

// ------------------------------------------- a busca no texto (D-050) --

/// Uma ocorrência na cópia: a página (pelas quebras que o LibreOffice
/// escreve), o trecho antes, o achado e o trecho depois, todos do mesmo
/// parágrafo.
@immutable
class TextHit {
  const TextHit({required this.page, required this.before, required this.match, required this.after});
  final int page;
  final String before, match, after;

  /// A busca que seleciona só esta ocorrência no motor: o achado com o
  /// contexto em volta (lookbehind e lookahead do ICU, sondados no
  /// `lok_script`; dá a volta no fim do documento sozinha).
  String get regex {
    final b = escapeRegex(before), a = escapeRegex(after);
    return '${b.isEmpty ? '' : '(?<=$b)'}${escapeRegex(match)}${a.isEmpty ? '' : '(?=$a)'}';
  }
}

class TextSearchResult {
  const TextSearchResult(this.hits, this.total, {this.badPattern = false});

  /// As primeiras ocorrências (até o limite) e quantas há ao todo.
  final List<TextHit> hits;
  final int total;

  /// A expressão regular da pergunta não vale.
  final bool badPattern;

  static const empty = TextSearchResult([], 0);
  static const invalid = TextSearchResult([], 0, badPattern: true);
}

final _regexSpecial = RegExp(r'[\\^$.|?*+()\[\]{}]');
String escapeRegex(String s) => s.replaceAllMapped(_regexSpecial, (m) => '\\${m[0]}');

final _bodyParas = RegExp(r'(<text:soft-page-break\s*/>)|<text:(p|h)(\s[^>]*)?>([\s\S]*?)</text:\2>|<text:(p|h)(\s[^>]*)?/>');
final _softBreak = RegExp(r'<text:soft-page-break\s*/>');
final _spaces = RegExp(r'<text:s(\s+text:c="(\d+)")?\s*/>');
final _breakLike = RegExp(r'<text:(tab|line-break)\s*/>');

/// O texto de um parágrafo do ODT plano, sem as marcas.
String _paragraphText(String inner) => _unescape(inner
    .replaceAllMapped(_spaces, (m) => ' ' * int.parse(m[2] ?? '1'))
    .replaceAll(_breakLike, ' ')
    .replaceAll(_tag, ''));

/// Acha [query] no corpo da cópia, sem diferenciar maiúsculas (a busca
/// única, D-050). O contexto tem até [context] caracteres de cada lado,
/// cortado no parágrafo.
TextSearchResult searchFodtText(String xml, String query, {int limit = 50, int context = 28}) =>
    searchOdfText(xml, SearchQuery(query), limit: limit, context: context);

/// A expressão de [q] para o Dart: o texto escapado (ou a expressão, com
/// [SearchQuery.regex]), a palavra inteira pelas letras do Unicode (o `\b`
/// do Dart só conhece o ASCII) e as maiúsculas. null: a expressão não vale.
RegExp? searchPattern(SearchQuery q) {
  final text = q.regex ? q.text : q.text.trim();
  if (text.isEmpty) return null;
  var source = q.regex ? '(?:$text)' : escapeRegex(text);
  if (q.wholeWord) source = '(?<![\\p{L}\\p{N}_])$source(?![\\p{L}\\p{N}_])';
  try {
    return RegExp(source, caseSensitive: q.matchCase, unicode: true);
  } on FormatException {
    return null;
  }
}

/// Acha [q] no corpo de um ODT (a cópia plana ou o `content.xml` de um
/// capítulo fechado), com as opções do Localizar (Fase 3, Etapa 6). A
/// página sai das quebras que o LibreOffice escreve; o contexto tem até
/// [context] caracteres de cada lado, cortado no parágrafo. Uma expressão
/// que não vale dá [TextSearchResult.invalid].
TextSearchResult searchOdfText(String xml, SearchQuery q, {int limit = 50, int context = 28}) {
  if ((q.regex ? q.text : q.text.trim()).isEmpty) return TextSearchResult.empty;
  final pattern = searchPattern(q);
  if (pattern == null) return TextSearchResult.invalid;
  // Do começo do corpo, sem copiar o texto (o livro lê dezenas de capítulos).
  final bodyStart = xml.indexOf('<office:text');
  final hits = <TextHit>[];
  var total = 0;
  var page = 1;
  for (final m in _bodyParas.allMatches(xml, bodyStart < 0 ? 0 : bodyStart)) {
    if (m[1] != null) {
      page++;
      continue;
    }
    final inner = m[4];
    if (inner == null) continue;
    // Uma quebra no meio do parágrafo: o resto dele já está na página seguinte.
    final breaks = _softBreak.allMatches(inner).length;
    final text = _paragraphText(inner);
    for (final f in pattern.allMatches(text)) {
      // Uma expressão que casa o vazio (`x*`) não é uma ocorrência.
      if (f.end == f.start) continue;
      total++;
      if (hits.length >= limit) continue;
      final from = (f.start - context).clamp(0, text.length);
      final to = (f.end + context).clamp(0, text.length);
      hits.add(TextHit(
        page: page,
        before: text.substring(from, f.start),
        match: text.substring(f.start, f.end),
        after: text.substring(f.end, to),
      ));
    }
    page += breaks;
  }
  return TextSearchResult(hits, total);
}

// ------------------------------------------------- o texto, para o livro --
// O fichário conta as palavras dos capítulos fechados e o importador dá nome
// aos capítulos (Fase 3, D-071): os mesmos leitores, públicos.

/// O texto de um título (o miolo do `text:h`), com os espaços resolvidos.
String odfHeadingText(String inner) => _headingText(inner);

final _wordBreaks = RegExp(r'</text:(p|h)>|<text:(tab|line-break)\s*/>|<text:s(\s[^>]*)?/>');

/// As palavras de um trecho do corpo (ODT ou ODT plano). Os fins de
/// parágrafo, as tabulações e os espaços do ODF separam palavras; as outras
/// marcas (negrito, um link) não, para "pa<span>la</span>vra" ser uma só.
int odfWordCount(String bodyXml) {
  final text = _unescape(bodyXml.replaceAll(_wordBreaks, ' ').replaceAll(_tag, ''));
  var words = 0;
  var inWord = false;
  for (final c in text.runes) {
    final space = c == 0x20 || c == 0x0A || c == 0x0D || c == 0x09 || c == 0xA0;
    if (!space && !inWord) words++;
    inWord = !space;
  }
  return words;
}

// ------------------------------------------------ as cenas (D-079) --
// Um separador de cena é um parágrafo no estilo "Cena" (ou num automático
// filho dele, como o LibreOffice grava a formatação direta). Serve para a
// cópia (FODT) e para o `content.xml` de um capítulo fechado.

/// O nome do estilo de parágrafo do separador de cena, no documento.
const sceneStyleName = 'Cena';

/// O que o importador e o "Converter os separadores" reconhecem como
/// separador de cena: só asteriscos, cerquilhas ou o asterismo, com espaços
/// ("* * *", "***", "#", "⁂").
bool isSceneSeparatorText(String text) {
  final t = text.trim();
  return t.isNotEmpty && t.length <= 16 && RegExp(r'^[*#⁂](\s*[*#⁂])*$').hasMatch(t);
}

final _paragraphStyleDecl = RegExp(r'<style:style\s([^>]*?)/?>');

/// Os nomes (como o XML grava) dos estilos de parágrafo que são de cena: o
/// "Cena" e os automáticos filhos dele. O "Cena" conta mesmo sem estar
/// declarado: no `content.xml` de um ODT, os estilos com nome ficam no
/// `styles.xml`, e só os automáticos vêm junto.
Set<String> sceneStyleNames(String xml) => _sceneStyles(xml);

Set<String> _sceneStyles(String xml) {
  final out = <String>{sceneStyleName};
  for (final m in _paragraphStyleDecl.allMatches(xml)) {
    final a = _attrs(m[1]!);
    if (a['style:family'] != 'paragraph') continue;
    final name = a['style:name'];
    if (name == null) continue;
    final display = a['style:display-name'] ?? decodeStyleName(name);
    final parent = a['style:parent-style-name'];
    if (display == sceneStyleName || (parent != null && decodeStyleName(parent) == sceneStyleName)) out.add(name);
  }
  return out;
}

final _styleNameAttr = RegExp(r'text:style-name="([^"]*)"');

/// O tamanho máximo do rótulo de uma cena.
const sceneLabelLength = 80;

/// As cenas do corpo de [xml]. Sem nenhum separador, nenhuma. A cena antes
/// do primeiro separador entra se tiver texto.
List<SceneEntry> odfScenes(String xml) {
  // Sem o nome em lugar nenhum, não há cena: nada é lido (a cópia de um
  // documento sem cenas não paga nada, D-079).
  if (!xml.contains('"$sceneStyleName"')) return const [];
  final styles = _sceneStyles(xml);
  final bodyStart = xml.indexOf('<office:text');
  if (bodyStart < 0) return const [];
  final body = _noteRemoved(xml.substring(bodyStart));
  bool isSeparator(RegExpMatch m, String text) {
    if ((m[2] ?? m[5]) != 'p' || text.isEmpty) return false;
    final style = _styleNameAttr.firstMatch(m[3] ?? m[6] ?? '')?[1];
    // Um separador vazio não tem como ser achado pela busca: não conta.
    return style != null && styles.contains(style);
  }

  // Primeira passada: os textos dos separadores (as chaves da busca, poucas).
  final keys = <String>{};
  for (final m in _bodyParas.allMatches(body)) {
    if (m[1] != null) continue;
    final text = _paragraphText(m[4] ?? '').trim();
    if (isSeparator(m, text)) keys.add(text);
  }
  if (keys.isEmpty) return const [];

  // Segunda: as cenas, com as ocorrências de cada chave contadas no caminho,
  // sem guardar o texto dos parágrafos.
  final seen = {for (final k in keys) k: 0};
  final scenes = <SceneEntry>[];
  String? key;
  var occurrence = 0;
  var label = '';
  var started = false;
  void flush() {
    if (started || label.isNotEmpty) scenes.add(SceneEntry(label: label, searchKey: key, occurrence: occurrence));
  }

  for (final m in _bodyParas.allMatches(body)) {
    if (m[1] != null) continue;
    // Como está no parágrafo (a chave da busca) e com os espaços juntados
    // (o rótulo).
    final text = _paragraphText(m[4] ?? '').trim();
    if (isSeparator(m, text)) {
      flush();
      started = true;
      key = text;
      occurrence = seen[text]!;
      label = '';
    } else if (label.isEmpty && (m[2] ?? m[5]) == 'p' && text.isNotEmpty) {
      final t = text.replaceAll(RegExp(r'\s+'), ' ');
      label = t.length <= sceneLabelLength ? t : '${t.substring(0, sceneLabelLength).trimRight()}…';
    }
    for (final k in keys) {
      seen[k] = seen[k]! + _countOf(text, k);
    }
  }
  flush();
  return scenes;
}

/// Quantos separadores ("* * *", "#") ainda não estão no estilo "Cena".
int odfLooseSeparators(String xml) {
  final styles = _sceneStyles(xml);
  final bodyStart = xml.indexOf('<office:text');
  if (bodyStart < 0) return 0;
  var n = 0;
  for (final m in _bodyParas.allMatches(_noteRemoved(xml.substring(bodyStart)))) {
    if (m[2] != 'p') continue;
    final style = _styleNameAttr.firstMatch(m[3] ?? '')?[1];
    if (style != null && styles.contains(style)) continue;
    if (isSceneSeparatorText(_paragraphText(m[4] ?? ''))) n++;
  }
  return n;
}
