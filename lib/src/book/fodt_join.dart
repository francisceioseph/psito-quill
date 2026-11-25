// O compilar (Fase 4, Etapa 1, D-086): os capítulos do livro, cada um numa
// cópia em ODT plano (FODT) que o motor gravou, viram um FODT só. É o inverso
// do corte do importador (`fodt_split.dart`).
//
//   - O cabeçalho (as configurações, as páginas, os estilos com nome) vem do
//     primeiro capítulo; os estilos com nome e as fontes que só os outros têm
//     entram junto.
//   - Os estilos automáticos de cada capítulo ganham um prefixo ("q3_P1"),
//     para não colidirem: o "P1" de um capítulo não é o "P1" do outro. Os do
//     primeiro ficam como estão, porque os cabeçalhos e os rodapés das
//     páginas usam os dele.
//   - A folha de rosto, o sumário, os títulos das partes e as quebras de
//     página entram aqui; o motor atualiza o sumário ao gravar.
//
// Um capítulo de cada vez: o corpo vai para um arquivo ao lado, e só os
// estilos (pequenos) ficam na memória até o fim. Roda num isolate.
import 'dart:convert';
import 'dart:io';

import '../document/fodt.dart';
import 'compile_style.dart';

/// Como o separador de cena sai no livro compilado.
enum SceneBreakMode {
  /// O parágrafo no estilo "Cena", como está no capítulo.
  keep,

  /// Trocado por "* * *".
  stars,

  /// Trocado por "#" (o do manuscrito).
  hash;

  String? get text => switch (this) {
        keep => null,
        stars => '* * *',
        hash => '#',
      };
}

/// Um item do livro compilado, na ordem.
sealed class JoinItem {
  const JoinItem();
}

/// O título de uma parte, numa página própria.
class JoinPart extends JoinItem {
  const JoinPart(this.title);
  final String title;
}

/// Um capítulo: a cópia em FODT e o título (que entra como Título 1 se o
/// capítulo não começa por um título).
class JoinChapter extends JoinItem {
  const JoinChapter(this.fodt, this.title);
  final String fodt;
  final String title;
}

/// O que vai além dos capítulos.
class JoinOptions {
  const JoinOptions({
    this.titlePage = true,
    this.title = '',
    this.subtitle = '',
    this.author = '',
    this.toc = true,
    this.tocTitle = 'Sumário',
    this.pageBreaks = true,
    this.chapterTitles = true,
    this.scenes = SceneBreakMode.keep,
    this.style = const OutputStyle(),
    this.cover,
    this.tocPageNumbers = true,
  });

  final bool titlePage;
  final String title, subtitle, author;
  final bool toc;
  final String tocTitle;

  /// Cada capítulo (e cada parte) começa numa página nova.
  final bool pageBreaks;

  /// O título do capítulo entra quando o capítulo não começa por um título.
  final bool chapterTitles;
  final SceneBreakMode scenes;

  /// O que o modelo troca: a página, o corpo, os cabeçalhos (D-087).
  final OutputStyle style;

  /// A imagem da capa (PNG ou JPEG), numa página antes da folha de rosto.
  final String? cover;

  /// O sumário com o número das páginas (o EPUB não tem páginas).
  final bool tocPageNumbers;
}

/// Junta [items] em [out] (um FODT). Lança [FormatException] se nenhum
/// capítulo é um texto. Síncrono: chame num isolate.
void joinFodt(List<JoinItem> items, JoinOptions o, String out) {
  final bodyFile = File('$out.corpo');
  final body = bodyFile.openSync(mode: FileMode.write);
  final j = _Joiner(o);
  if (o.cover != null) j.cover(File(o.cover!).readAsBytesSync());
  try {
    for (final item in items) {
      switch (item) {
        case JoinPart(:final title):
          j.part(title, body);
        case JoinChapter(:final fodt, :final title):
          j.chapter(File(fodt).readAsStringSync(), title, body);
      }
    }
  } finally {
    body.closeSync();
  }
  try {
    if (j.first == null) throw const FormatException('nenhum capítulo');
    final sink = File(out).openSync(mode: FileMode.write);
    try {
      sink.writeStringSync(j.head());
      final input = bodyFile.openSync();
      try {
        final buf = List<int>.filled(1 << 16, 0);
        for (var n = input.readIntoSync(buf); n > 0; n = input.readIntoSync(buf)) {
          sink.writeFromSync(buf, 0, n);
        }
      } finally {
        input.closeSync();
      }
      sink.writeStringSync('</office:text></office:body></office:document>\n');
    } finally {
      sink.closeSync();
    }
  } finally {
    if (bodyFile.existsSync()) bodyFile.deleteSync();
  }
}

/// O prefixo dos automáticos do capítulo [n] (o primeiro não tem).
String joinPrefix(int n) => n == 0 ? '' : 'q${n}_';

class _First {
  _First({
    required this.document,
    required this.settings,
    required this.scripts,
    required this.masters,
    required this.textOpen,
    required this.decls,
    required this.language,
  });
  final String document, settings, scripts, masters, textOpen, decls;
  final String? language;
}

class _Joiner {
  _Joiner(this.o);
  final JoinOptions o;

  _First? first;
  int _chapters = 0;
  int _tocLevel = 1;
  final _fonts = <String, String>{};
  final _styles = <String, String>{};
  final _autos = StringBuffer();

  /// A folha de rosto e o sumário já contam (eles vão no fim do head(): o
  /// sumário precisa do nível dos títulos de todos os capítulos).
  bool _frontCounted = false;

  /// O próximo bloco começa uma página: falso só no primeiro do livro.
  bool _needBreak = false;

  /// A capa, pronta para o corpo.
  String? _cover;

  void cover(List<int> bytes) {
    final size = imageSize(bytes);
    if (size == null) return;
    final (w, h) = size;
    // A largura de 12 cm, ou menos se a altura passaria de 18 cm.
    var width = 12.0, height = 12.0 * h / w;
    if (height > 18) {
      width = width * 18 / height;
      height = 18;
    }
    _cover = '<text:p text:style-name="QuillCapa"><draw:frame draw:name="QuillCapa" text:anchor-type="as-char" '
        'svg:width="${width.toStringAsFixed(2)}cm" svg:height="${height.toStringAsFixed(2)}cm">'
        '<draw:image><office:binary-data>${base64.encode(bytes)}</office:binary-data></draw:image></draw:frame></text:p>';
  }

  /// O começo de uma página nova: na página ímpar, pelo estilo de página da
  /// abertura (o motor põe a branca que faltar); senão, a quebra.
  String get _breakStyleAttr => o.style.rightPage ? ' style:master-page-name="$openingMaster"' : '';
  String get _breakProp => o.style.rightPage ? 'style:page-number="auto"' : 'fo:break-before="page"';

  /// O leiaute do corpo (o do estilo de página do primeiro capítulo).
  String? _mainLayout;

  void part(String title, RandomAccessFile body) {
    _front();
    final style = o.pageBreaks && _needBreak ? 'QuillParteQuebra' : 'QuillParte';
    body.writeStringSync('<text:h text:style-name="$style" text:outline-level="1">${_escape(title)}</text:h>');
    _needBreak = true;
    // O capítulo depois do título da parte vai na mesma página só se não há
    // quebras; com elas, ele começa outra.
  }

  void chapter(String xml, String title, RandomAccessFile body) {
    final n = _chapters++;
    final prefix = joinPrefix(n);
    final textOpen = _bodyOpen.firstMatch(xml);
    final textClose = xml.lastIndexOf('</office:text>');
    if (textOpen == null || textClose < textOpen.end) return;

    // As fontes e os estilos com nome: o primeiro que aparece fica.
    for (final f in _children(_section(xml, 'office:font-face-decls') ?? '')) {
      _fonts.putIfAbsent(_key(f), () => f);
    }
    for (final s in _children(_section(xml, 'office:styles') ?? '')) {
      _styles.putIfAbsent(_key(s), () => s);
    }

    // Os automáticos: os do primeiro como estão (as páginas usam), os dos
    // outros com o prefixo e sem as páginas (só o primeiro manda nelas).
    final autos = <String>[];
    final names = <String>{};
    if (n == 0) {
      final masters = _whole(xml, 'office:master-styles') ?? '';
      _mainLayout = masterLayoutName(masters, mainMasterName(masters));
    }
    for (var a in _children(_section(xml, 'office:automatic-styles') ?? '')) {
      final isLayout = a.startsWith('<style:page-layout');
      if (n > 0 && isLayout) continue;
      if (isLayout) {
        a = styleLayout(a, o.style);
        if (o.style.rightPage && _attr(a, 'style:name') == _mainLayout) autos.add(openingLayoutOf(a));
      } else {
        a = styleAuto(a, o.style);
      }
      autos.add(a);
      if (n > 0) {
        final name = _attr(a, 'style:name');
        if (name != null) names.add(name);
      }
    }

    var inner = xml.substring(textOpen.end, textClose);
    if (o.scenes.text != null) inner = _replaceScenes(inner, sceneStyleNames(xml), o.scenes.text!);

    // Os blocos do corpo: as declarações do primeiro vão no começo do livro;
    // as dos outros saem (os campos deles usam as do primeiro).
    final decls = StringBuffer();
    final blocks = <String>[];
    for (final b in _children(inner)) {
      if (b.startsWith('<text:soft-page-break')) continue;
      if (_isDecl(b)) {
        if (n == 0) decls.write(b);
        continue;
      }
      blocks.add(b);
    }

    if (n == 0) {
      first = _First(
        document: _documentOpen.firstMatch(xml)?[0] ?? '<office:document office:version="1.3">',
        settings: _whole(xml, 'office:settings') ?? '',
        scripts: _whole(xml, 'office:scripts') ?? '',
        masters: _whole(xml, 'office:master-styles') ?? '',
        textOpen: textOpen[0]!,
        decls: decls.toString(),
        language: RegExp(r'<dc:language>([^<]*)</dc:language>').firstMatch(xml)?[1],
      );
    }

    // O título que falta e a quebra de página no primeiro bloco.
    final lead = blocks.indexWhere((b) => !b.startsWith('<text:bookmark') && !b.startsWith('<office:annotation'));
    final startsWithHeading = lead >= 0 && blocks[lead].startsWith('<text:h');
    _front();
    final breakHere = o.pageBreaks && _needBreak;
    if (!startsWithHeading && o.chapterTitles && title.trim().isNotEmpty) {
      final style = breakHere ? 'QuillCapituloQuebra' : 'QuillCapitulo';
      blocks.insert(lead < 0 ? 0 : lead, '<text:h text:style-name="$style" text:outline-level="1">${_escape(title)}</text:h>');
    } else if (breakHere) {
      final at = lead < 0 ? 0 : lead;
      final broken = lead < 0 ? null : _withBreak(blocks[at], 'QuillQuebra$n', autos, right: o.style.rightPage);
      if (broken != null) {
        blocks[at] = broken;
      } else {
        blocks.insert(at, '<text:p text:style-name="QuillQuebra"/>');
      }
    }
    // O sumário vai até o nível do título que abre cada capítulo.
    final h = blocks.firstWhere((b) => b.startsWith('<text:h'), orElse: () => '');
    final level = int.tryParse(RegExp(r'text:outline-level="(\d+)"').firstMatch(h)?[1] ?? '') ?? 1;
    if (level > _tocLevel) _tocLevel = level.clamp(1, 3);

    var text = blocks.join();
    if (n > 0) {
      text = _prefixed(text, names, prefix);
      for (var i = 0; i < autos.length; i++) {
        autos[i] = _prefixed(autos[i], names, prefix);
      }
    }
    for (final a in autos) {
      _autos.write(a);
    }
    body.writeStringSync(text);
    _needBreak = true;
  }

  /// O primeiro item vem depois da folha de rosto e do sumário: quebra.
  void _front() {
    if (_frontCounted) return;
    _frontCounted = true;
    if (o.titlePage || o.toc || _cover != null) _needBreak = true;
  }

  /// A folha de rosto e o sumário, no começo do corpo.
  String _frontXml() {
    final out = StringBuffer();
    if (_cover != null) out.write(_cover);
    if (o.titlePage) {
      out.write('<text:p text:style-name="QuillRostoTitulo">${_escape(o.title)}</text:p>');
      if (o.subtitle.trim().isNotEmpty) out.write('<text:p text:style-name="QuillRostoSubtitulo">${_escape(o.subtitle)}</text:p>');
      if (o.author.trim().isNotEmpty) out.write('<text:p text:style-name="QuillRostoAutor">${_escape(o.author)}</text:p>');
    }
    if (o.toc) out.write(_tocXml());
    return out.toString();
  }

  String _tocXml() {
    final title = _escape(o.tocTitle);
    final titleStyle = o.pageBreaks && o.titlePage ? 'QuillSumarioQuebra' : 'Contents_20_Heading';
    final entries = StringBuffer();
    for (var l = 1; l <= _tocLevel; l++) {
      entries.write('<text:table-of-content-entry-template text:outline-level="$l" text:style-name="Contents_20_$l">'
          '<text:index-entry-link-start text:style-name="Index_20_Link"/><text:index-entry-text/>'
          '${o.tocPageNumbers ? '<text:index-entry-tab-stop style:type="right" style:leader-char="."/><text:index-entry-page-number/>' : ''}'
          '<text:index-entry-link-end/></text:table-of-content-entry-template>');
    }
    return '<text:table-of-content text:name="QuillSumario" text:protected="true">'
        '<text:table-of-content-source text:outline-level="$_tocLevel">'
        '<text:index-title-template text:style-name="$titleStyle">$title</text:index-title-template>'
        '$entries</text:table-of-content-source>'
        '<text:index-body><text:index-title text:name="QuillSumario_Head">'
        '<text:p text:style-name="$titleStyle">$title</text:p></text:index-title></text:index-body>'
        '</text:table-of-content>';
  }

  /// O cabeçalho do livro: depois de todos os capítulos (os estilos de todos).
  String head() {
    final f = first!;
    final font = o.style.font.trim();
    final meta = StringBuffer('<office:meta>');
    if (o.title.trim().isNotEmpty) meta.write('<dc:title>${_escape(o.title)}</dc:title>');
    if (o.author.trim().isNotEmpty) {
      meta.write('<meta:initial-creator>${_escape(o.author)}</meta:initial-creator><dc:creator>${_escape(o.author)}</dc:creator>');
    }
    if (f.language != null) meta.write('<dc:language>${f.language}</dc:language>');
    meta.write('</office:meta>');
    final out = StringBuffer('<?xml version="1.0" encoding="UTF-8"?>\n')
      ..write(f.document)
      ..write(meta)
      ..write(f.settings)
      ..write(f.scripts)
      ..write('<office:font-face-decls>')
      ..writeAll(_fonts.values)
      ..write(font.isNotEmpty && !_fonts.containsKey('style:font-face|$font|') ? fontFaceXml(font) : '')
      ..write('</office:font-face-decls><office:styles>')
      ..writeAll(_styles.values.map((e) => styleNamed(e, o.style)))
      ..write('</office:styles><office:automatic-styles>')
      ..write(_autos)
      ..write(_ownAutos.replaceAll(_breakMarker, _breakProp).replaceAll(_breakStyleMarker, _breakStyleAttr))
      ..write(o.style.headers == HeaderMode.manuscript || o.style.headers == HeaderMode.book ? headerAutos : '')
      ..write('</office:automatic-styles>')
      ..write(styleMasters(f.masters, o.style, title: o.title, author: o.author))
      ..write('<office:body>')
      ..write(f.textOpen)
      ..write(f.decls)
      ..write(_frontXml());
    return out.toString();
  }

  /// Onde a quebra das partes e dos capítulos entra (ver [_breakProp]).
  static const _breakMarker = 'QUILL_BREAK_PROP', _breakStyleMarker = ' QUILL_BREAK_STYLE';

  /// Os automáticos do compilar. Os pais são estilos que o LibreOffice sempre
  /// tem (Título, Subtítulo, Título 1, Sumário), mesmo sem estar no arquivo.
  static const _ownAutos = '<style:style style:name="QuillRostoTitulo" style:family="paragraph" style:parent-style-name="Title">'
      '<style:paragraph-properties fo:margin-top="6cm" fo:text-align="center" fo:text-indent="0cm"/></style:style>'
      '<style:style style:name="QuillRostoSubtitulo" style:family="paragraph" style:parent-style-name="Subtitle">'
      '<style:paragraph-properties fo:text-align="center" fo:text-indent="0cm"/></style:style>'
      '<style:style style:name="QuillRostoAutor" style:family="paragraph" style:parent-style-name="Standard">'
      '<style:paragraph-properties fo:margin-top="2cm" fo:text-align="center" fo:text-indent="0cm"/><style:text-properties fo:font-size="14pt"/></style:style>'
      '<style:style style:name="QuillSumarioQuebra" style:family="paragraph" style:parent-style-name="Contents_20_Heading">'
      '<style:paragraph-properties fo:break-before="page" fo:text-indent="0cm"/></style:style>'
      '<style:style style:name="QuillParte" style:family="paragraph" style:parent-style-name="Heading_20_1">'
      '<style:paragraph-properties fo:margin-top="6cm" fo:text-align="center" fo:text-indent="0cm"/></style:style>'
      '<style:style style:name="QuillParteQuebra" style:family="paragraph" style:parent-style-name="Heading_20_1"$_breakStyleMarker>'
      '<style:paragraph-properties fo:margin-top="6cm" fo:text-align="center" fo:text-indent="0cm" $_breakMarker/></style:style>'
      '<style:style style:name="QuillCapitulo" style:family="paragraph" style:parent-style-name="Heading_20_1">'
      '<style:paragraph-properties fo:text-indent="0cm"/></style:style>'
      '<style:style style:name="QuillCapa" style:family="paragraph" style:parent-style-name="Standard">'
      '<style:paragraph-properties fo:text-align="center" fo:text-indent="0cm" fo:margin-top="0cm" fo:margin-bottom="0cm" '
      'fo:line-height="100%" fo:break-after="page"/></style:style>'
      '<style:style style:name="QuillCapituloQuebra" style:family="paragraph" style:parent-style-name="Heading_20_1"$_breakStyleMarker>'
      '<style:paragraph-properties fo:text-indent="0cm" $_breakMarker/></style:style>'
      '<style:style style:name="QuillQuebra" style:family="paragraph" style:parent-style-name="Standard"$_breakStyleMarker>'
      '<style:paragraph-properties $_breakMarker fo:margin-top="0cm" fo:margin-bottom="0cm" fo:text-indent="0cm"/>'
      '<style:text-properties fo:font-size="1pt"/></style:style>';
}

// ------------------------------------------------------------ o XML --

final _bodyOpen = RegExp(r'<office:text\b[^>]*>');
final _documentOpen = RegExp(r'<office:document\b[^>]*>');
final _token = RegExp(r'<(/?)([A-Za-z0-9:_.-]+)\b[^>]*?(/?)>|<!--[\s\S]*?-->|<\?[\s\S]*?\?>|[^<]+');

/// O conteúdo de `<tag>…</tag>` (o primeiro); null sem a seção.
String? _section(String xml, String tag) {
  final open = RegExp('<$tag\\b[^>]*?(/?)>').firstMatch(xml);
  if (open == null) return null;
  if (open[1] == '/') return '';
  final close = xml.indexOf('</$tag>', open.end);
  return close < 0 ? null : xml.substring(open.end, close);
}

/// A seção inteira, com as marcas; null sem ela.
String? _whole(String xml, String tag) {
  final open = RegExp('<$tag\\b[^>]*?(/?)>').firstMatch(xml);
  if (open == null) return null;
  if (open[1] == '/') return open[0];
  final close = xml.indexOf('</$tag>', open.end);
  return close < 0 ? null : xml.substring(open.start, close + tag.length + 3);
}

/// Os elementos de primeiro nível de [inner], inteiros.
List<String> _children(String inner) {
  final out = <String>[];
  var depth = 0;
  var start = 0;
  for (final m in _token.allMatches(inner)) {
    final name = m[2];
    if (name == null) continue;
    if (m[1] == '/') {
      depth--;
      if (depth == 0) out.add(inner.substring(start, m.end));
    } else if (m[3] == '/') {
      if (depth == 0) out.add(m[0]!);
    } else {
      if (depth == 0) start = m.start;
      depth++;
    }
  }
  return out;
}

String? _attr(String element, String name) {
  final open = RegExp(r'^<[^>]*>').firstMatch(element)?[0] ?? '';
  return RegExp('\\s${RegExp.escape(name)}="([^"]*)"').firstMatch(open)?[1];
}

/// A chave de um estilo ou de uma fonte: o elemento, o nome e a família.
String _key(String element) {
  final tag = RegExp(r'^<([A-Za-z0-9:_.-]+)').firstMatch(element)?[1] ?? '';
  return '$tag|${_attr(element, 'style:name') ?? ''}|${_attr(element, 'style:family') ?? ''}';
}

bool _isDecl(String b) =>
    b.startsWith('<text:sequence-decls') ||
    b.startsWith('<text:variable-decls') ||
    b.startsWith('<text:user-field-decls') ||
    b.startsWith('<text:dde-connection-decls') ||
    b.startsWith('<office:forms') ||
    b.startsWith('<table:calculation-settings');

final _styleRef = RegExp(r'(\s[A-Za-z0-9-]+:(?:[A-Za-z0-9-]*style-name|name))="([^"]*)"');
final _idRef = RegExp(r'(\s(?:text:id|xml:id|text:ref-name))="([^"]*)"');

/// Os nomes de [names] com o [prefix], onde quer que um atributo de estilo os
/// use; e os ids (as notas, os comentários) com ele também.
String _prefixed(String xml, Set<String> names, String prefix) {
  var out = xml.replaceAllMapped(_styleRef, (m) {
    final attr = m[1]!;
    final value = m[2]!;
    final isStyle = attr.endsWith('style-name') || attr == ' style:name';
    return isStyle && names.contains(value) ? '$attr="$prefix$value"' : m[0]!;
  });
  out = out.replaceAllMapped(_idRef, (m) => '${m[1]}="$prefix${m[2]}"');
  return out;
}

final _paraOpen = RegExp(r'<text:p\b([^>]*?)(/?)>');
final _styleNameAttr = RegExp(r'\stext:style-name="([^"]*)"');

/// Os separadores de cena (os parágrafos nos estilos [styles]) com o [text].
String _replaceScenes(String inner, Set<String> styles, String text) {
  final out = StringBuffer();
  var at = 0;
  for (final m in _paraOpen.allMatches(inner)) {
    if (m.start < at) continue;
    final style = _styleNameAttr.firstMatch(m[1]!)?[1];
    if (style == null || !styles.contains(style)) continue;
    var end = m.end;
    if (m[2] != '/') {
      final close = inner.indexOf('</text:p>', m.end);
      if (close < 0) continue;
      // Um parágrafo com outro dentro (uma nota) não é um separador.
      if (inner.substring(m.end, close).contains('<text:p')) continue;
      end = close + '</text:p>'.length;
    }
    out
      ..write(inner.substring(at, m.start))
      ..write('<text:p${m[1]}>${_escape(text)}</text:p>');
    at = end;
  }
  out.write(inner.substring(at));
  return out.toString();
}

/// O bloco [block] (um parágrafo ou um título) começando uma página: um
/// automático novo, [name], copiado do dele com a quebra (ou filho do estilo
/// com nome dele), entra em [autos]. null se o bloco não é um parágrafo.
String? _withBreak(String block, String name, List<String> autos, {bool right = false}) {
  final open = RegExp(r'^<text:(p|h)\b([^>]*?)(/?)>').firstMatch(block);
  if (open == null) return null;
  final style = _styleNameAttr.firstMatch(open[2]!)?[1];
  String def;
  final source = style == null ? null : autos.where((a) => _attr(a, 'style:name') == style && _attr(a, 'style:family') == 'paragraph').firstOrNull;
  if (source != null) {
    def = _breakBefore(source.replaceFirst(RegExp(r'\sstyle:name="[^"]*"'), ' style:name="$name"'), right: right);
  } else {
    final parent = style ?? 'Standard';
    def = right
        ? '<style:style style:name="$name" style:family="paragraph" style:parent-style-name="$parent" '
            'style:master-page-name="$openingMaster"><style:paragraph-properties style:page-number="auto"/></style:style>'
        : '<style:style style:name="$name" style:family="paragraph" style:parent-style-name="$parent">'
            '<style:paragraph-properties fo:break-before="page"/></style:style>';
  }
  autos.add(def);
  final attrs = style == null ? '${open[2]} text:style-name="$name"' : open[2]!.replaceFirst(_styleNameAttr, ' text:style-name="$name"');
  return '<text:${open[1]}$attrs${open[3]}>${block.substring(open.end)}';
}

/// A definição [def] de um estilo com `fo:break-before="page"`; com [right],
/// começando no estilo de página da abertura (numa página ímpar).
String _breakBefore(String def, {bool right = false}) {
  if (right) {
    var out = def.replaceAll(RegExp(r'\sfo:break-before="[^"]*"'), '');
    out = out.replaceAll(RegExp(r'\sstyle:master-page-name="[^"]*"'), '');
    final open = RegExp(r'^<style:style\b([^>]*?)(/?)>').firstMatch(out)!;
    out = out.replaceRange(open.start, open.end, '<style:style${open[1]} style:master-page-name="$openingMaster"${open[2]}>');
    final props = RegExp(r'<style:paragraph-properties\b([^>]*?)(/?)>').firstMatch(out);
    if (props != null) {
      final a = props[1]!.replaceAll(RegExp(r'\sstyle:page-number="[^"]*"'), '');
      return out.replaceRange(props.start, props.end, '<style:paragraph-properties$a style:page-number="auto"${props[2]}>');
    }
    const p = '<style:paragraph-properties style:page-number="auto"/>';
    final o2 = RegExp(r'^<style:style\b([^>]*?)(/?)>').firstMatch(out)!;
    return o2[2] == '/' ? '<style:style${o2[1]}>$p</style:style>' : out.replaceRange(o2.end, o2.end, p);
  }
  final props = RegExp(r'<style:paragraph-properties\b([^>]*?)(/?)>').firstMatch(def);
  if (props != null) {
    final attrs = props[1]!.contains('fo:break-before=')
        ? props[1]!.replaceFirst(RegExp(r'fo:break-before="[^"]*"'), 'fo:break-before="page"')
        : '${props[1]} fo:break-before="page"';
    return def.replaceRange(props.start, props.end, '<style:paragraph-properties$attrs${props[2]}>');
  }
  final open = RegExp(r'^<style:style\b([^>]*?)(/?)>').firstMatch(def)!;
  const p = '<style:paragraph-properties fo:break-before="page"/>';
  return open[2] == '/'
      ? '<style:style${open[1]}>$p</style:style>'
      : def.replaceRange(open.end, open.end, p);
}

String _escape(String s) => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');
