// A leitura da cópia temporária em ODT plano (D-044): as propriedades dos
// estilos, as fontes declaradas e os títulos (a Estrutura da Etapa 5).
//
// Um leitor pequeno, por expressões regulares, só do que o Quill usa: o
// arquivo vem sempre do próprio LibreOffice, com o mesmo formato. Roda num
// isolate (`Isolate.run`), e o que volta é pouco: um mapa de estilos e uma
// lista de títulos. O texto do documento não fica guardado.
import 'package:flutter/foundation.dart';

import 'outline.dart';

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
  });

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
  for (final m in _bodyMarks.allMatches(body)) {
    if (m[1] != null) {
      page++;
      continue;
    }
    final text = _headingText(m[3]!);
    if (text.isEmpty) continue;
    outline.add(OutlineEntry(level: int.tryParse(_attrs(m[2]!)['text:outline-level'] ?? '') ?? 1, text: text, page: page));
  }

  return FodtSnapshot(
    styles: resolved,
    fonts: fonts.values.toSet().toList()..sort(),
    outline: outline,
    pageMargins: _pageMargins(xml),
    words: int.tryParse(statistic['meta:word-count'] ?? ''),
    characters: int.tryParse(statistic['meta:character-count'] ?? ''),
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
  const TextSearchResult(this.hits, this.total);

  /// As primeiras ocorrências (até o limite) e quantas há ao todo.
  final List<TextHit> hits;
  final int total;

  static const empty = TextSearchResult([], 0);
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

/// Acha [query] no corpo da cópia, sem diferenciar maiúsculas. O contexto
/// tem até [context] caracteres de cada lado, cortado no parágrafo.
TextSearchResult searchFodtText(String xml, String query, {int limit = 50, int context = 28}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return TextSearchResult.empty;
  final bodyStart = xml.indexOf('<office:text');
  final body = bodyStart < 0 ? xml : xml.substring(bodyStart);
  final hits = <TextHit>[];
  var total = 0;
  var page = 1;
  for (final m in _bodyParas.allMatches(body)) {
    if (m[1] != null) {
      page++;
      continue;
    }
    final inner = m[4];
    if (inner == null) continue;
    // Uma quebra no meio do parágrafo: o resto dele já está na página seguinte.
    final breaks = _softBreak.allMatches(inner).length;
    final text = _paragraphText(inner);
    final lower = text.toLowerCase();
    for (var i = lower.indexOf(q); i >= 0; i = lower.indexOf(q, i + q.length)) {
      total++;
      if (hits.length >= limit) continue;
      final from = (i - context).clamp(0, text.length);
      final to = (i + q.length + context).clamp(0, text.length);
      hits.add(TextHit(
        page: page,
        before: text.substring(from, i),
        match: text.substring(i, i + q.length),
        after: text.substring(i + q.length, to),
      ));
    }
    page += breaks;
  }
  return TextSearchResult(hits, total);
}
