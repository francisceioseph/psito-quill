// Mudar estilos pela cópia (Fase 3, Etapa 3, D-075).
//
// A 24.2 não tem um comando `.uno:` para desligar o cabeçalho sem abrir uma
// janela (que trava o motor), nem para a primeira página diferente, as
// páginas pares diferentes, a capitular ou a hifenização num estilo. Mas o
// `.uno:LoadStyles` carrega os estilos de outro documento por cima dos do
// documento (sondado, D-075). Então:
//
//   1. o motor grava a cópia do documento (a do D-044, FODT);
//   2. o Quill tira o texto dela e muda só o que precisa (estas funções, que
//      trabalham no texto do XML e não sabem do motor);
//   3. o motor converte o resultado para ODT (o `LoadStyles` não lê o FODT);
//   4. o `LoadStyles` com a sobrescrita carrega os estilos de volta.
//
// Como a cópia tem todos os estilos do próprio documento, os outros voltam
// iguais. O Dart não escreve ODT: escreve o FODT, e o motor converte.

/// O que o Quill sabe das páginas e da hifenização pela cópia.
class PageSetup {
  const PageSetup({
    this.header = false,
    this.footer = false,
    this.firstDifferent = false,
    this.leftDifferent = false,
    this.hyphenation = false,
  });

  /// Algum estilo de página tem cabeçalho (ou rodapé).
  final bool header, footer;

  /// A primeira página tem cabeçalho e rodapé próprios.
  final bool firstDifferent;

  /// As páginas pares (à esquerda) têm cabeçalho e rodapé próprios.
  final bool leftDifferent;

  /// O estilo padrão de parágrafo hifeniza.
  final bool hyphenation;

  @override
  bool operator ==(Object other) =>
      other is PageSetup &&
      other.header == header &&
      other.footer == footer &&
      other.firstDifferent == firstDifferent &&
      other.leftDifferent == leftDifferent &&
      other.hyphenation == hyphenation;
  @override
  int get hashCode => Object.hash(header, footer, firstDifferent, leftDifferent, hyphenation);
}

/// Os tipos de estilo que o `LoadStyles` carrega (`SfxTemplateFlags`), e a
/// sobrescrita.
abstract final class StyleFlags {
  static const paragraph = 1, page = 4, overwrite = 16;
}

final _masterPages = RegExp(r'<style:master-page\b[^>]*?(/>|>[\s\S]*?</style:master-page>)');
final _defaultParagraph = RegExp(r'<style:default-style\s+style:family="paragraph"\s*(/>|>[\s\S]*?</style:default-style>)');
final _hyphenate = RegExp(r'fo:hyphenate="(true|false)"');

bool _has(String part, String tag) => RegExp('<style:$tag[\\s/>]').hasMatch(part);

PageSetup parsePageSetup(String xml) {
  final pages = [for (final m in _masterPages.allMatches(xml)) m[0]!];
  final hy = _defaultParagraph.firstMatch(xml)?[0];
  return PageSetup(
    header: pages.any((p) => _has(p, 'header')),
    footer: pages.any((p) => _has(p, 'footer')),
    firstDifferent: pages.any((p) => _has(p, 'header-first') || _has(p, 'footer-first')),
    leftDifferent: pages.any((p) => _has(p, 'header-left') || _has(p, 'footer-left')),
    hyphenation: hy != null && _hyphenate.firstMatch(hy)?[1] == 'true',
  );
}

/// A cópia sem o texto: os estilos não dependem dele, e o arquivo fica
/// pequeno (o capítulo de 30 páginas vai de ~1 MB a ~30 KB).
String stylesOnly(String xml) {
  final open = xml.indexOf('<office:text');
  final close = xml.lastIndexOf('</office:text>');
  if (open < 0 || close < 0) return xml;
  final start = xml.indexOf('>', open);
  if (start < 0 || start > close) return xml;
  if (xml[start - 1] == '/') return xml;
  return '${xml.substring(0, start + 1)}<text:p/>${xml.substring(close)}';
}

String _eachMasterPage(String xml, String Function(String page) change) =>
    xml.replaceAllMapped(_masterPages, (m) => change(m[0]!));

RegExp _block(String tag) => RegExp('<style:$tag(\\s[^>]*)?(/>|>[\\s\\S]*?</style:$tag>)');

/// Tira o cabeçalho ([footer] falso) ou o rodapé de todos os estilos de
/// página, com as versões da primeira página e das pares. É o que o
/// `.uno:InsertPageHeader` com `On` falso faria, sem a janela que pergunta
/// (e trava o motor na 24.2).
String xmlRemoveHeaderFooter(String xml, {required bool footer}) {
  final tag = footer ? 'footer' : 'header';
  var out = _eachMasterPage(xml, (p) {
    for (final t in [tag, '$tag-left', '$tag-first']) {
      p = p.replaceAll(_block(t), '');
    }
    return p;
  });
  // O espaço do cabeçalho na página: o estilo dele no leiaute some também.
  out = out.replaceAll(_block('$tag-style'), '<style:$tag-style/>');
  return out;
}

/// A primeira página com cabeçalho e rodapé próprios (vazios), ou não.
String xmlFirstDifferent(String xml, bool on) => _eachMasterPage(xml, (p) {
      for (final tag in ['header', 'footer']) {
        p = p.replaceAll(_block('$tag-first'), '');
        if (!on) continue;
        final main = _block(tag).firstMatch(p);
        if (main == null) continue;
        final style = tag == 'header' ? 'Header' : 'Footer';
        p = p.replaceRange(main.end, main.end, '<style:$tag-first><text:p text:style-name="$style"/></style:$tag-first>');
      }
      return p;
    });

/// As páginas pares com cabeçalho e rodapé próprios (começam iguais aos das
/// ímpares), ou não.
String xmlLeftDifferent(String xml, bool on) => _eachMasterPage(xml, (p) {
      for (final tag in ['header', 'footer']) {
        p = p.replaceAll(_block('$tag-left'), '');
        if (!on) continue;
        final main = _block(tag).firstMatch(p);
        if (main == null) continue;
        final body = main[0]!;
        final inner = body.endsWith('/>') ? '' : body.substring(body.indexOf('>') + 1, body.lastIndexOf('</'));
        p = p.replaceRange(main.end, main.end, '<style:$tag-left>$inner</style:$tag-left>');
      }
      return p;
    });

/// A hifenização automática do documento: no estilo padrão de parágrafo, e
/// nos estilos que a ligam ou desligam por conta própria, menos os títulos
/// (que não se hifenizam).
String xmlDocumentHyphenation(String xml, bool on) {
  final value = 'fo:hyphenate="$on"';
  String setIn(String style) {
    if (_hyphenate.hasMatch(style)) return style.replaceAll(_hyphenate, value);
    final props = RegExp(r'<style:text-properties\b').firstMatch(style);
    if (props != null) return style.replaceRange(props.end, props.end, ' $value');
    // Sem as propriedades de texto: entram antes do fim do estilo.
    if (style.endsWith('/>')) {
      return '${style.substring(0, style.length - 2)}><style:text-properties $value/></style:default-style>';
    }
    final end = style.lastIndexOf('</');
    return '${style.substring(0, end)}<style:text-properties $value/>${style.substring(end)}';
  }

  var out = xml.replaceFirstMapped(_defaultParagraph, (m) => setIn(m[0]!));
  out = out.replaceAllMapped(RegExp(r'<style:style\s[^>]*style:family="paragraph"[^>]*>[\s\S]*?</style:style>'), (m) {
    final s = m[0]!;
    final head = s.substring(0, s.indexOf('>'));
    if (!_hyphenate.hasMatch(s) || head.contains('style:default-outline-level')) return s;
    return s.replaceAll(_hyphenate, value);
  });
  return out;
}

/// "Text body" → "Text_20_body" (o nome de um estilo no XML). Como o
/// LibreOffice, guarda as letras (com acento também) e codifica o resto.
String encodeStyleName(String name) => name.replaceAllMapped(
      RegExp(r'[^\p{L}\p{N}_.-]', unicode: true),
      (m) => '_${m[0]!.codeUnitAt(0).toRadixString(16)}_',
    );

/// O nome no XML do estilo de parágrafo [name] (o nome ou o de exibição);
/// sem ele na cópia, o nome codificado.
String paragraphStyleXmlName(String xml, String name) {
  for (final m in RegExp(r'<style:style\s[^>]*>').allMatches(xml)) {
    final head = m[0]!;
    if (!head.contains('style:family="paragraph"')) continue;
    final xmlName = RegExp(r'style:name="([^"]*)"').firstMatch(head)?[1];
    final display = RegExp(r'style:display-name="([^"]*)"').firstMatch(head)?[1];
    if (xmlName == null) continue;
    if (xmlName == name || (display != null && _unescape(display) == name)) return xmlName;
  }
  return encodeStyleName(name);
}

/// O sufixo do estilo de capitular que o Quill cria.
const dropCapSuffix = ' · capitular';

/// Um estilo de parágrafo novo, filho de [base] (o nome do LibreOffice), com
/// a letra capitular de [lines] linhas, chamado "[label] · capitular N"
/// ([label] é o nome que a interface mostra). Devolve o XML e o nome do
/// estilo para o `.uno:StyleApply`. A capitular é do parágrafo, e o Writer só a
/// muda pelo estilo ou pela janela (o `.uno:FormatDropcap` não aceita as
/// linhas pelo LOK, D-075).
(String, String) addDropCapStyle(String xml, {required String base, required String label, required int lines}) {
  final name = '$label$dropCapSuffix $lines';
  final encoded = encodeStyleName(name);
  final style = '<style:style style:name="$encoded" style:display-name="${_escape(name)}" style:family="paragraph" '
      'style:parent-style-name="${paragraphStyleXmlName(xml, base)}"><style:paragraph-properties>'
      '<style:drop-cap style:lines="$lines" style:length="1" style:distance="0.1cm"/>'
      '</style:paragraph-properties></style:style>';
  // Já existe (uma capitular de antes): troca.
  final existing = RegExp('<style:style\\s+style:name="${RegExp.escape(encoded)}"[\\s\\S]*?</style:style>');
  final cleaned = xml.replaceAll(existing, '');
  final at = cleaned.indexOf('</office:styles>');
  if (at < 0) return (xml, name);
  return (cleaned.replaceRange(at, at, style), name);
}

/// O estilo de base de um estilo de capitular do Quill; null se não é um.
String? dropCapBase(String? style) {
  if (style == null) return null;
  final i = style.lastIndexOf(dropCapSuffix);
  return i < 0 ? null : style.substring(0, i);
}

String _unescape(String s) =>
    s.replaceAll('&lt;', '<').replaceAll('&gt;', '>').replaceAll('&quot;', '"').replaceAll('&apos;', "'").replaceAll('&amp;', '&');

String _escape(String s) => s.replaceAll('&', '&amp;').replaceAll('"', '&quot;').replaceAll('<', '&lt;');

// ------------------------------------------- o estilo da cena (D-079) --

/// O estilo de parágrafo do separador de cena: centrado, sem recuo, com um
/// respiro em cima e embaixo, e preso ao parágrafo seguinte (o separador
/// não fica sozinho no pé da página). Filho do "Padrão", para usar a fonte
/// do livro.
const sceneStyleXml = '<style:style style:name="Cena" style:display-name="Cena" style:family="paragraph" '
    'style:parent-style-name="Standard" style:class="text"><style:paragraph-properties fo:text-align="center" '
    'fo:margin-left="0cm" fo:margin-right="0cm" fo:margin-top="0.42cm" fo:margin-bottom="0.42cm" '
    'fo:text-indent="0cm" fo:keep-with-next="always"/></style:style>';

final _sceneStyleDecl = RegExp(r'<style:style\s+style:name="Cena"[\s>/]');

/// [xml] com o estilo "Cena" em `office:styles`, se ainda não tem.
String addSceneStyle(String xml) {
  final styles = xml.indexOf('<office:styles>');
  final at = xml.indexOf('</office:styles>');
  if (styles < 0 || at < styles) return xml;
  if (_sceneStyleDecl.hasMatch(xml.substring(styles, at))) return xml;
  return xml.replaceRange(at, at, sceneStyleXml);
}
