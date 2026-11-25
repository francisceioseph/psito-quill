// Os estilos de saída do compilar (Fase 4, Etapa 2, D-087): a página, a fonte
// do corpo, o espaçamento, o recuo e os cabeçalhos que um modelo troca no
// livro juntado. São contas no texto do XML, como as do `style_patch.dart`:
// não sabem do motor, e o `fodt_join.dart` chama cada uma na sua parte.
//
// "Manter" (o `keep` de cada escolha) é não tocar: vale o que o capítulo tem.

/// O tamanho da página, com as margens de cada um (em cm).
enum PageChoice {
  keep(0, 0, 0, 0, 0, 0),
  a4(21, 29.7, 2.5, 2.5, 2.5, 2.5),
  letter(21.59, 27.94, 2.54, 2.54, 2.54, 2.54),
  a5(14.8, 21, 2, 2, 2, 2),

  /// O livro de 15,24 × 22,86 cm, com as margens espelhadas: a de dentro
  /// (a esquerda da página ímpar) maior, para a lombada.
  sixByNine(15.24, 22.86, 1.8, 1.8, 2.2, 1.6);

  const PageChoice(this.width, this.height, this.top, this.bottom, this.inner, this.outer);
  final double width, height, top, bottom, inner, outer;

  bool get mirrored => this == sixByNine;
}

/// O espaço entre as linhas do corpo.
enum LineSpacing {
  keep(0),
  single(100),
  oneHalf(150),
  double(200);

  const LineSpacing(this.percent);
  final int percent;
}

/// O recuo da primeira linha do corpo.
enum IndentChoice { keep, on, off }

/// Os cabeçalhos do livro.
enum HeaderMode {
  keep,
  none,

  /// "Sobrenome / TÍTULO / página", à direita, em todas as páginas.
  manuscript,

  /// Alternados: o título do livro nas pares, o do capítulo nas ímpares, e
  /// o número de página do lado de fora.
  book,
}

/// O que o modelo troca no livro.
class OutputStyle {
  const OutputStyle({
    this.page = PageChoice.keep,
    this.font = '',
    this.fontSize = 0,
    this.spacing = LineSpacing.keep,
    this.indent = IndentChoice.keep,
    this.headers = HeaderMode.keep,
    this.rightPage = false,
  });

  final PageChoice page;

  /// A fonte do corpo ('' mantém).
  final String font;

  /// O tamanho do corpo em pontos (0 mantém).
  final int fontSize;
  final LineSpacing spacing;
  final IndentChoice indent;
  final HeaderMode headers;

  /// Cada capítulo (e cada parte) começa numa página ímpar, sem cabeçalho.
  final bool rightPage;

  bool get touchesBody =>
      font.trim().isNotEmpty || fontSize > 0 || spacing != LineSpacing.keep || indent != IndentChoice.keep;

  OutputStyle copyWith({
    PageChoice? page,
    String? font,
    int? fontSize,
    LineSpacing? spacing,
    IndentChoice? indent,
    HeaderMode? headers,
    bool? rightPage,
  }) =>
      OutputStyle(
        page: page ?? this.page,
        font: font ?? this.font,
        fontSize: fontSize ?? this.fontSize,
        spacing: spacing ?? this.spacing,
        indent: indent ?? this.indent,
        headers: headers ?? this.headers,
        rightPage: rightPage ?? this.rightPage,
      );

  Map<String, Object?> toJson() => {
        'pagina': page.name,
        if (font.trim().isNotEmpty) 'fonte': font.trim(),
        if (fontSize > 0) 'tamanho': fontSize,
        'espacamento': spacing.name,
        'recuo': indent.name,
        'cabecalhos': headers.name,
        'impar': rightPage,
      };

  static T _enum<T extends Enum>(List<T> values, Object? name, T fallback) =>
      values.where((v) => v.name == name).firstOrNull ?? fallback;

  static OutputStyle fromJson(Object? j) {
    if (j is! Map) return const OutputStyle();
    final size = j['tamanho'];
    return OutputStyle(
      page: _enum(PageChoice.values, j['pagina'], PageChoice.keep),
      font: j['fonte'] is String ? j['fonte'] as String : '',
      fontSize: size is num && size >= 4 && size <= 72 ? size.toInt() : 0,
      spacing: _enum(LineSpacing.values, j['espacamento'], LineSpacing.keep),
      indent: _enum(IndentChoice.values, j['recuo'], IndentChoice.keep),
      headers: _enum(HeaderMode.values, j['cabecalhos'], HeaderMode.keep),
      rightPage: j['impar'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is OutputStyle &&
      other.page == page &&
      other.font == font &&
      other.fontSize == fontSize &&
      other.spacing == spacing &&
      other.indent == indent &&
      other.headers == headers &&
      other.rightPage == rightPage;
  @override
  int get hashCode => Object.hash(page, font, fontSize, spacing, indent, headers, rightPage);
}

// ------------------------------------------------------- os atributos --

String _cm(double v) => '${v.toStringAsFixed(2)}cm';

/// O elemento [el] com os atributos [attrs] na marca de abertura de
/// `<[tag]>` (trocados, ou acrescentados). Sem a marca, null.
String? _setIn(String el, String tag, Map<String, String> attrs) {
  final open = RegExp('<${RegExp.escape(tag)}\\b([^>]*?)(/?)>').firstMatch(el);
  if (open == null) return null;
  var a = open[1]!;
  for (final MapEntry(:key, :value) in attrs.entries) {
    final re = RegExp('\\s${RegExp.escape(key)}="[^"]*"');
    a = re.hasMatch(a) ? a.replaceFirst(re, ' $key="$value"') : '$a $key="$value"';
  }
  return el.replaceRange(open.start, open.end, '<$tag$a${open[2]}>');
}

/// [el] (um `style:style` ou um `style:default-style`) com as propriedades de
/// [tag] (`paragraph-properties` ou `text-properties`), criando a marca se
/// falta: as de parágrafo vêm antes das de texto.
String _withProps(String el, String tag, Map<String, String> attrs) {
  if (attrs.isEmpty) return el;
  final set = _setIn(el, 'style:$tag', attrs);
  if (set != null) return set;
  final props = '<style:$tag${[for (final e in attrs.entries) ' ${e.key}="${e.value}"'].join()}/>';
  final open = RegExp(r'^<(style:[a-z-]+)\b([^>]*?)(/?)>').firstMatch(el);
  if (open == null) return el;
  final name = open[1]!;
  if (open[3] == '/') return '<$name${open[2]}>$props</$name>';
  if (tag == 'paragraph-properties') return el.replaceRange(open.end, open.end, props);
  final close = el.lastIndexOf('</$name>');
  return close < 0 ? el : el.replaceRange(close, close, props);
}

/// [el] sem os atributos [names], em qualquer marca.
String _strip(String el, Iterable<String> names) {
  var out = el;
  for (final n in names) {
    out = out.replaceAll(RegExp('\\s${RegExp.escape(n)}="[^"]*"'), '');
  }
  return out;
}

String? _attr(String el, String name) {
  final open = RegExp(r'^<[^>]*>').firstMatch(el)?[0] ?? '';
  return RegExp('\\s${RegExp.escape(name)}="([^"]*)"').firstMatch(open)?[1];
}

// ---------------------------------------------------------- a página --

/// Um `style:page-layout` com o tamanho, as margens e o espaço do cabeçalho
/// do modelo.
String styleLayout(String layout, OutputStyle s) {
  var out = layout;
  final p = s.page;
  if (p != PageChoice.keep) {
    out = _setIn(out, 'style:page-layout-properties', {
          'fo:page-width': _cm(p.width),
          'fo:page-height': _cm(p.height),
          'style:print-orientation': 'portrait',
          'fo:margin-top': _cm(p.top),
          'fo:margin-bottom': _cm(p.bottom),
          'fo:margin-left': _cm(p.inner),
          'fo:margin-right': _cm(p.outer),
        }) ??
        out;
    out = _setIn(out, 'style:page-layout', {'style:page-usage': p.mirrored ? 'mirrored' : 'all'}) ?? out;
  }
  if (s.headers != HeaderMode.keep) {
    final style = s.headers == HeaderMode.none
        ? '<style:header-style/>'
        : '<style:header-style><style:header-footer-properties fo:min-height="0cm" fo:margin-bottom="0.5cm"/></style:header-style>';
    final existing = RegExp(r'<style:header-style\b[^>]*?(/>|>[\s\S]*?</style:header-style>)');
    if (existing.hasMatch(out)) {
      out = out.replaceFirst(existing, style);
    } else {
      final after = RegExp(r'<style:page-layout-properties\b[^>]*?(/>|>[\s\S]*?</style:page-layout-properties>)').firstMatch(out);
      if (after != null) out = out.replaceRange(after.end, after.end, style);
    }
  }
  return out;
}

/// O nome do estilo de página do corpo: o "Standard", ou o primeiro.
String mainMasterName(String masters) {
  final names = [for (final m in RegExp(r'<style:master-page\b[^>]*>').allMatches(masters)) _attr(m[0]!, 'style:name')];
  return names.contains('Standard') ? 'Standard' : (names.whereType<String>().firstOrNull ?? 'Standard');
}

/// O `style:page-layout-name` do estilo de página [master].
String? masterLayoutName(String masters, String master) {
  for (final m in RegExp(r'<style:master-page\b[^>]*>').allMatches(masters)) {
    if (_attr(m[0]!, 'style:name') == master) return _attr(m[0]!, 'style:page-layout-name');
  }
  return null;
}

/// O estilo de página da abertura do capítulo e o leiaute dele.
const openingMaster = 'QuillAbertura', openingLayout = 'QuillAberturaPm';

/// O leiaute da abertura: o do corpo, só nas páginas ímpares e sem
/// cabeçalho (a abertura do capítulo não tem).
String openingLayoutOf(String layout) {
  var out = layout.replaceFirst(RegExp(r'\sstyle:name="[^"]*"'), ' style:name="$openingLayout"');
  out = _setIn(out, 'style:page-layout', {'style:page-usage': 'right'}) ?? out;
  return out.replaceFirst(RegExp(r'<style:header-style\b[^>]*?(/>|>[\s\S]*?</style:header-style>)'), '<style:header-style/>');
}

String _escape(String s) => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');

/// O sobrenome do manuscrito: a última palavra do autor.
String surnameOf(String author) {
  final words = author.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  return words.isEmpty ? '' : words.last;
}

const _pageNumber = '<text:page-number text:select-page="current">1</text:page-number>';

/// Os cabeçalhos do modelo, para o começo de um `style:master-page`.
String headersXml(HeaderMode mode, {required String title, required String author}) {
  final t = _escape(title.trim());
  switch (mode) {
    case HeaderMode.keep || HeaderMode.none:
      return '';
    case HeaderMode.manuscript:
      final parts = [_escape(surnameOf(author)), t.toUpperCase()].where((p) => p.isNotEmpty);
      return '<style:header><text:p text:style-name="QuillCabecalhoManuscrito">'
          '${parts.map((p) => '$p / ').join()}$_pageNumber</text:p></style:header>';
    case HeaderMode.book:
      return '<style:header><text:p text:style-name="QuillCabecalhoImpar">'
          '<text:chapter text:display="name" text:outline-level="1"/> $_pageNumber</text:p></style:header>'
          '<style:header-left><text:p text:style-name="QuillCabecalhoPar">$_pageNumber $t</text:p></style:header-left>';
  }
}

/// Os automáticos dos cabeçalhos.
const headerAutos = '<style:style style:name="QuillCabecalhoManuscrito" style:family="paragraph" style:parent-style-name="Header">'
    '<style:paragraph-properties fo:text-align="end" fo:text-indent="0cm"/></style:style>'
    '<style:style style:name="QuillCabecalhoImpar" style:family="paragraph" style:parent-style-name="Header">'
    '<style:paragraph-properties fo:text-align="end" fo:text-indent="0cm"/><style:text-properties fo:font-size="9pt"/></style:style>'
    '<style:style style:name="QuillCabecalhoPar" style:family="paragraph" style:parent-style-name="Header">'
    '<style:paragraph-properties fo:text-align="start" fo:text-indent="0cm"/><style:text-properties fo:font-size="9pt"/></style:style>';

final _masterPage = RegExp(r'<style:master-page\b[^>]*?(/>|>[\s\S]*?</style:master-page>)');

RegExp _block(String tag) => RegExp('<style:$tag(\\s[^>]*)?(/>|>[\\s\\S]*?</style:$tag>)');

/// `office:master-styles` com os cabeçalhos do modelo em todos os estilos de
/// página e, com [OutputStyle.rightPage], o da abertura do capítulo (o
/// rodapé do corpo, sem cabeçalho, e depois o corpo).
String styleMasters(String masters, OutputStyle s, {required String title, required String author}) {
  var out = masters;
  if (s.headers != HeaderMode.keep) {
    final headers = headersXml(s.headers, title: title, author: author);
    out = out.replaceAllMapped(_masterPage, (m) {
      var p = m[0]!;
      for (final t in ['header', 'header-left', 'header-first']) {
        p = p.replaceAll(_block(t), '');
      }
      if (headers.isEmpty) return p;
      if (p.endsWith('/>')) return '${p.substring(0, p.length - 2)}>$headers</style:master-page>';
      final open = p.indexOf('>') + 1;
      return p.replaceRange(open, open, headers);
    });
  }
  if (s.rightPage) {
    final main = mainMasterName(out);
    final body = _masterPage.allMatches(out).map((m) => m[0]!).where((p) => _attr(p, 'style:name') == main).firstOrNull ?? '';
    final footers = [
      for (final t in ['footer', 'footer-left']) ...[for (final m in _block(t).allMatches(body)) m[0]!],
    ].join();
    final opening = '<style:master-page style:name="$openingMaster" style:page-layout-name="$openingLayout" '
        'style:next-style-name="$main">$footers</style:master-page>';
    final close = out.lastIndexOf('</office:master-styles>');
    if (close >= 0) {
      out = out.replaceRange(close, close, opening);
    } else {
      out = '<office:master-styles>$opening</office:master-styles>';
    }
  }
  return out;
}

// ------------------------------------------------------------ o corpo --

/// Os estilos que não são o corpo do texto: os títulos, os cabeçalhos, o
/// sumário, as legendas, a cena e os do Quill. Eles não ganham a fonte, o
/// espaçamento nem o recuo do corpo.
bool isFurniture(String? name) {
  if (name == null) return false;
  const prefixes = [
    'Heading', 'Title', 'Subtitle', 'Header', 'Footer', 'Contents', 'Index', 'Caption', 'Footnote', 'Endnote', //
    'Table', 'Illustration', 'Figure', 'Drawing', 'Frame', 'Cena', 'Quill', 'Marginalia',
  ];
  return prefixes.any(name.startsWith);
}

const _fontAttrs = ['style:font-name', 'fo:font-family', 'style:font-family-generic', 'style:font-pitch'];
const _spacingAttrs = ['fo:line-height', 'style:line-height-at-least', 'style:line-spacing'];
const _marginAttrs = ['fo:margin-top', 'fo:margin-bottom'];

Map<String, String> _bodyParagraph(OutputStyle s) => {
      if (s.spacing != LineSpacing.keep) ...{
        'fo:line-height': '${s.spacing.percent}%',
        'fo:margin-top': '0cm',
        'fo:margin-bottom': '0cm',
      },
      if (s.indent != IndentChoice.keep) 'fo:text-indent': s.indent == IndentChoice.on ? '1.27cm' : '0cm',
    };

Map<String, String> _bodyText(OutputStyle s) => {
      if (s.font.trim().isNotEmpty) 'style:font-name': _escape(s.font.trim()),
      if (s.fontSize > 0) 'fo:font-size': '${s.fontSize}pt',
    };

/// Os atributos que o corpo herda do modelo, tirados de um estilo que o
/// sobrescreveria.
List<String> _overridden(OutputStyle s, {required bool text}) => [
      if (s.font.trim().isNotEmpty) ..._fontAttrs,
      if (s.fontSize > 0) 'fo:font-size',
      if (!text && s.spacing != LineSpacing.keep) ...[..._spacingAttrs, ..._marginAttrs],
      if (!text && s.indent != IndentChoice.keep) 'fo:text-indent',
    ];

/// Um estilo com nome (de `office:styles`): o padrão de parágrafo e o
/// "Standard" ganham a fonte; eles e o "Text_20_body" ganham o espaçamento
/// e o recuo; os outros do corpo perdem o que mudaria isso; os títulos não
/// ganham o recuo.
String styleNamed(String el, OutputStyle s) {
  if (!s.touchesBody) return el;
  final isDefault = el.startsWith('<style:default-style') && _attr(el, 'style:family') == 'paragraph';
  if (!isDefault && (!el.startsWith('<style:style') || _attr(el, 'style:family') != 'paragraph')) {
    return el;
  }
  final name = _attr(el, 'style:name');
  if (isDefault || name == 'Standard') {
    // A fonte vem só pelo nome (a declaração): a família de antes sai.
    var out = s.font.trim().isEmpty ? el : _strip(el, _fontAttrs);
    out = _withProps(out, 'paragraph-properties', _bodyParagraph(s));
    return _withProps(out, 'text-properties', _bodyText(s));
  }
  if (isFurniture(name)) {
    return s.indent == IndentChoice.on ? _withProps(el, 'paragraph-properties', {'fo:text-indent': '0cm'}) : el;
  }
  if (name == 'Text_20_body') {
    final out = _strip(el, _overridden(s, text: true));
    return _withProps(out, 'paragraph-properties', _bodyParagraph(s));
  }
  return _strip(el, _overridden(s, text: false));
}

/// Um estilo automático: os de parágrafo do corpo e os de texto perdem o que
/// mudaria a fonte, o espaçamento e o recuo do modelo (o que é direto no
/// capítulo); os dos títulos não ganham o recuo.
String styleAuto(String el, OutputStyle s) {
  if (!s.touchesBody || !el.startsWith('<style:style')) return el;
  final family = _attr(el, 'style:family');
  if (family == 'text') return _strip(el, _overridden(s, text: true));
  if (family != 'paragraph') return el;
  final parent = _attr(el, 'style:parent-style-name');
  if (isFurniture(parent) || isFurniture(_attr(el, 'style:name'))) {
    return s.indent == IndentChoice.on ? _withProps(el, 'paragraph-properties', {'fo:text-indent': '0cm'}) : el;
  }
  return _strip(el, _overridden(s, text: false));
}

/// A declaração da fonte do corpo, para `office:font-face-decls`.
String fontFaceXml(String font) {
  final f = _escape(font.trim());
  final mono = RegExp(r'courier|mono', caseSensitive: false).hasMatch(font);
  return '<style:font-face style:name="$f" svg:font-family="\'$f\'" style:font-family-generic="${mono ? 'modern' : 'roman'}"'
      '${mono ? ' style:font-pitch="fixed"' : ''}/>';
}

// ------------------------------------------------------------- a capa --

/// A largura e a altura (em pixels) de um PNG ou de um JPEG; null se não é um.
(int, int)? imageSize(List<int> b) {
  if (b.length > 24 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) {
    int be(int i) => (b[i] << 24) | (b[i + 1] << 16) | (b[i + 2] << 8) | b[i + 3];
    return (be(16), be(20));
  }
  if (b.length > 4 && b[0] == 0xFF && b[1] == 0xD8) {
    var i = 2;
    while (i + 9 < b.length) {
      if (b[i] != 0xFF) return null;
      final marker = b[i + 1];
      final len = (b[i + 2] << 8) | b[i + 3];
      // Os SOF (menos o DHT, o JPG e o DAC): a altura e a largura.
      if (marker >= 0xC0 && marker <= 0xCF && marker != 0xC4 && marker != 0xC8 && marker != 0xCC) {
        return ((b[i + 7] << 8) | b[i + 8], (b[i + 5] << 8) | b[i + 6]);
      }
      i += 2 + len;
    }
  }
  return null;
}
