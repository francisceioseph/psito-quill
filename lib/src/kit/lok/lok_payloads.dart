// Leitura dos textos que o LibreOfficeKit manda nos callbacks.
//
// Funções puras, testadas em test/unit/lok_payloads_test.dart. Os formatos
// estão nos comentários do LibreOfficeKitEnums.h.
import 'dart:convert';
import 'dart:ui' show Rect, Size;

import '../quill_kit.dart';

final _ints = RegExp(r'-?\d+');

/// "x, y, w, h" (twips). "EMPTY" ou vazio dá null.
Rect? parseLokRect(String payload) {
  final text = payload.trim();
  if (text.isEmpty || text.startsWith('EMPTY')) return null;
  final n = _ints.allMatches(text).take(4).map((m) => int.parse(m.group(0)!)).toList();
  if (n.length < 4) return null;
  return Rect.fromLTWH(n[0].toDouble(), n[1].toDouble(), n[2].toDouble(), n[3].toDouble());
}

/// Cursor: "x, y, w, h", ou JSON com "rectangle" (quando o LOK manda o id da
/// vista junto).
Rect parseCursor(String payload) {
  final text = payload.trim();
  if (text.startsWith('{')) {
    final json = jsonDecode(text) as Map<String, dynamic>;
    return parseLokRect('${json['rectangle'] ?? ''}') ?? Rect.zero;
  }
  return parseLokRect(text) ?? Rect.zero;
}

/// O link do cursor, no JSON do callback 1 (com o
/// `LOK_FEATURE_VIEWID_IN_VISCURSOR_INVALIDATION_CALLBACK`, D-076):
/// `"hyperlink": {"text": "...", "link": "..."}`, ou `{}` fora de um link.
DocLink? parseCursorLink(String payload) {
  final text = payload.trim();
  if (!text.startsWith('{')) return null;
  try {
    final h = (jsonDecode(text) as Map<String, dynamic>)['hyperlink'];
    if (h is! Map) return null;
    final url = h['link'];
    if (url is! String || url.isEmpty) return null;
    return DocLink('${h['text'] ?? ''}', url);
  } on FormatException {
    return null;
  }
}

/// Seleção: "x, y, w, h; x, y, w, h; ...", vazio quando não há.
List<Rect> parseSelection(String payload) => payload
    .split(';')
    .map(parseLokRect)
    .whereType<Rect>()
    .where((r) => r.width > 0 && r.height > 0)
    .toList();

/// Estado: ".uno:Bold=true". Algumas versões mandam JSON
/// {"commandName": ..., "state": ...}.
(String, String)? parseCommandState(String payload) {
  final text = payload.trim();
  if (text.startsWith('{')) {
    final json = jsonDecode(text) as Map<String, dynamic>;
    final name = json['commandName'];
    if (name is! String) return null;
    final state = json['state'];
    // Os estados compostos (recuos, espaçamento) seguem como JSON.
    return (name, state is Map || state is List ? jsonEncode(state) : '${state ?? ''}');
  }
  final eq = text.indexOf('=');
  if (eq <= 0) return null;
  return (text.substring(0, eq), text.substring(eq + 1));
}

/// Tamanho do documento: "largura, altura" (twips).
Size? parseDocumentSize(String payload) {
  final n = _ints.allMatches(payload).take(2).map((m) => int.parse(m.group(0)!)).toList();
  if (n.length < 2) return null;
  return Size(n[0].toDouble(), n[1].toDouble());
}

/// Evento de ladrilho do plugin: "vaga,coluna,linha,escalaMilli".
TilePlaced? parseTilePlaced(String payload) {
  final n = payload.split(',').map((s) => int.tryParse(s.trim())).toList();
  if (n.length != 4 || n.contains(null)) return null;
  return TilePlaced(n[0]!, TileKey(n[1]!, n[2]!, n[3]!));
}

/// Aberto: {"width":tw,"height":tw,"parts":n}.
Size parseOpened(String payload) {
  final json = jsonDecode(payload) as Map<String, dynamic>;
  return Size((json['width'] as num).toDouble(), (json['height'] as num).toDouble());
}

/// Convertido: {"id":n,"ok":bool,"error":"..."}.
FileConverted parseConverted(String payload) {
  final j = jsonDecode(payload) as Map<String, dynamic>;
  return FileConverted((j['id'] as num).toInt(), ok: j['ok'] == true, error: j['error'] as String? ?? '');
}

/// O número do documento no PQK_EVENT_OPENED e no PQK_EVENT_ACTIVATED.
int parseDocumentId(String payload) => ((jsonDecode(payload) as Map<String, dynamic>)['id'] as num?)?.toInt() ?? 1;

// ------------------------------------------------- estados da barra de status --
// O texto vem no idioma da interface do LibreOffice ("Página 3 de 30",
// "Page 3 of 30"). Só os números interessam: a frase é da l10n do app.

final _number = RegExp(r'\d[\d.,  ]*');

int _toInt(String s) => int.parse(s.replaceAll(RegExp(r'[^\d]'), ''));

/// `.uno:StatePageNumber`: "Página 3 de 30" → (3, 30). Com mais números
/// ("Página 3 de 30 (Página 5)"), valem os dois primeiros.
(int, int)? parsePageStatus(String? payload) {
  if (payload == null) return null;
  final n = _number.allMatches(payload).map((m) => _toInt(m.group(0)!)).toList();
  return n.length < 2 ? null : (n[0], n[1]);
}

/// `.uno:StateWordCount`: "21.069 palavras, 117.537 caracteres", ou
/// "Selecionado: 1 palavra, 4 caracteres" (a seleção tem dois-pontos).
({int words, int characters, bool selection})? parseWordCount(String? payload) {
  if (payload == null) return null;
  final n = _number.allMatches(payload).map((m) => _toInt(m.group(0)!)).toList();
  if (n.length < 2) return null;
  return (words: n[0], characters: n[1], selection: payload.contains(':'));
}

/// Um idioma como o motor diz: o nome na língua da interface do LibreOffice
/// ("Inglês (EUA)") e a etiqueta ("en-US"). O nome é o que o
/// `.uno:LanguageStatus` aceita para trocar (sondado na 24.2, D-063).
typedef DocLanguage = ({String name, String tag});

/// O estado `.uno:LanguageStatus` ("Português (Brasil);pt-BR"; "[Nenhum];-"
/// sem verificação).
DocLanguage? parseLanguage(String? state) {
  if (state == null) return null;
  final i = state.lastIndexOf(';');
  if (i <= 0) return null;
  return (name: state.substring(0, i), tag: state.substring(i + 1));
}

/// `getCommandValues(".uno:LanguageStatus")`: os idiomas com ortografia
/// instalada, em ordem do nome.
List<DocLanguage> parseLanguageList(String json) {
  try {
    final values = (jsonDecode(json) as Map<String, dynamic>)['commandValues'];
    if (values is! List) return const [];
    return [
      for (final v in values)
        if (v is String) ?parseLanguage(v),
    ]..sort((a, b) => a.name.compareTo(b.name));
  } on FormatException {
    return const [];
  }
}

/// `getCommandValues(".uno:CharFontName")`: as fontes instaladas, em ordem.
List<String> parseFontList(String json) {
  try {
    final values = (jsonDecode(json) as Map<String, dynamic>)['commandValues'];
    if (values is! Map) return const [];
    // Vem como {"": {"Fonte": [tamanhos]}} ou {"Fonte": [tamanhos]}.
    final inner = values.length == 1 && values.values.first is Map ? values.values.first as Map : values;
    final names = inner.keys.whereType<String>().where((n) => n.isNotEmpty).toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return names;
  } on FormatException {
    return const [];
  }
}

// ------------------------------------------------------- Fase 2 --

/// LOK_CALLBACK_SEARCH_RESULT_SELECTION: {"searchResultSelection": [
/// {"part": "0", "rectangles": "x, y, w, h; ..."}], "highlightAll": "true"}.
SearchResult? parseSearchResult(String payload) {
  try {
    final json = jsonDecode(payload) as Map<String, dynamic>;
    final list = json['searchResultSelection'];
    if (list is! List) return null;
    return SearchResult(
      [for (final m in list) parseSelection('${(m as Map)['rectangles'] ?? ''}')],
      all: '${json['highlightAll']}' == 'true',
    );
  } on FormatException {
    return null;
  }
}

/// LOK_CALLBACK_CONTEXT_MENU: {"menu": [{"text", "type", "command",
/// "enabled", "menu"}]}. O tipo "separator" vira separador.
List<EngineMenuItem> parseContextMenu(String payload) {
  List<EngineMenuItem> items(Object? list) => [
        if (list is List)
          for (final i in list.whereType<Map>())
            if (i['type'] == 'separator')
              const EngineMenuItem.separator()
            else
              EngineMenuItem(
                text: '${i['text'] ?? ''}'.replaceAll('~', ''),
                command: '${i['command'] ?? ''}',
                enabled: '${i['enabled']}' != 'false',
                children: items(i['menu']),
              ),
      ];
  try {
    return items((jsonDecode(payload) as Map<String, dynamic>)['menu']);
  } on FormatException {
    return const [];
  }
}

/// LOK_CALLBACK_GRAPHIC_SELECTION: "x, y, w, h, ângulo[, {json}]" ou "EMPTY".
Rect? parseGraphicSelection(String payload) => parseLokRect(payload);

/// LOK_CALLBACK_TABLE_SELECTED: "{ }" fora da tabela; dentro, as colunas e
/// as linhas.
bool parseTableSelected(String payload) {
  try {
    final json = jsonDecode(payload);
    return json is Map && json.isNotEmpty;
  } on FormatException {
    return false;
  }
}

/// `getCommandValues(".uno:StyleApply")`: os estilos por família, com os
/// nomes de programa do LibreOffice ("Heading 1", "Text body").
({List<String> paragraph, List<String> character}) parseStyleLists(String json) {
  try {
    final values = (jsonDecode(json) as Map<String, dynamic>)['commandValues'];
    List<String> list(String family) =>
        values is Map && values[family] is List ? [for (final s in values[family] as List) '$s'] : const [];
    return (paragraph: list('ParagraphStyles'), character: list('CharacterStyles'));
  } on FormatException {
    return (paragraph: const [], character: const []);
  }
}

/// Um número do motor, com vírgula ou ponto ("0,5" ou "0.5").
double? parseLokNumber(Object? v) => v == null ? null : double.tryParse('$v'.trim().replaceAll(',', '.'));

/// Os estados com medidas (`.uno:LeftRightParaMargin`, `.uno:ULSpacing`):
/// {"left": "0,5", "right": "0,0", "firstline": "0,0", "unit": "inch"}.
/// Devolve as medidas em centímetros.
Map<String, double> parseMeasures(String? payload) {
  if (payload == null || !payload.trim().startsWith('{')) return const {};
  try {
    final json = jsonDecode(payload) as Map<String, dynamic>;
    final factor = switch ('${json['unit'] ?? 'inch'}') {
      'inch' => 2.54,
      'cm' => 1.0,
      'mm' => 0.1,
      'pt' => 2.54 / 72,
      _ => 2.54,
    };
    return {
      for (final e in json.entries)
        if (e.key != 'unit')
          if (parseLokNumber(e.value) case final v?) e.key: v * factor,
    };
  } on FormatException {
    return const {};
  }
}

/// `.uno:Size` de uma imagem: "9029 x 9029" (centésimos de milímetro).
Size? parseObjectSize(String? payload) {
  if (payload == null) return null;
  final n = _ints.allMatches(payload).map((m) => int.parse(m.group(0)!)).toList();
  return n.length < 2 ? null : Size(n[0].toDouble(), n[1].toDouble());
}

/// O callback 35 da 24.2:
/// `{ "margin1": 0, "margin2": 18000, "leftOffset": 2000, "pageOffset": 501,
/// "pageWidth": 21001, "tabs": { "": { "position": 2000, "style": 4}, ...},
/// "unit": " cm"}`. As tabulações vêm com a chave repetida (`""`), que o
/// `jsonDecode` juntaria numa só: por isso as expressões regulares.
RulerInfo? parseRuler(String payload) {
  int? field(String name) => switch (RegExp('"$name"\\s*:\\s*(-?\\d+)').firstMatch(payload)) {
        final m? => int.parse(m[1]!),
        null => null,
      };
  final pageWidth = field('pageWidth'), left = field('leftOffset'), width = field('margin2');
  if (pageWidth == null || left == null || width == null) return null;
  return RulerInfo(
    pageWidth: pageWidth,
    leftMargin: left,
    textWidth: width,
    indent: field('margin1') ?? 0,
    pageOffset: field('pageOffset'),
    tabs: [
      for (final m in RegExp(r'"position"\s*:\s*(-?\d+)\s*,\s*"style"\s*:\s*(\d+)').allMatches(payload))
        (position: int.parse(m[1]!), style: int.parse(m[2]!)),
    ],
  );
}

/// Callback 62 (sondado na 24.2, D-067):
/// `{"content": "...", "position": "35", "start": "-1", "end": "-1"}`.
A11yParagraph? parseA11yParagraph(String json) {
  try {
    final m = jsonDecode(json);
    if (m is! Map || m['content'] is! String) return null;
    return A11yParagraph(m['content'] as String, int.tryParse('${m['position']}') ?? 0);
  } on FormatException {
    return null;
  }
}

/// Callback 63: `{"position": "34"}`.
A11yCaret? parseA11yCaret(String json) {
  try {
    final m = jsonDecode(json);
    if (m is! Map) return null;
    final p = int.tryParse('${m['position']}');
    return p == null ? null : A11yCaret(p);
  } on FormatException {
    return null;
  }
}

// ---------------------------------------------------------- comentários --

/// Um comentário no JSON do motor (D-088). O id é texto no callback e número
/// na lista; o "0" do parentId é "sem pai"; a data vem com vírgula antes dos
/// nanossegundos.
DocComment? parseComment(Object? json) {
  if (json is! Map) return null;
  final id = '${json['id'] ?? ''}';
  if (id.isEmpty) return null;
  final parent = '${json['parentId'] ?? '0'}';
  return DocComment(
    id: id,
    parentId: parent == '0' ? '' : parent,
    author: '${json['author'] ?? ''}',
    text: '${json['text'] ?? ''}',
    resolved: '${json['resolved']}' == 'true',
    date: _commentDate('${json['dateTime'] ?? ''}'),
    anchor: parseLokRect('${json['anchorPos'] ?? ''}'),
    range: parseSelection('${json['textRange'] ?? ''}'),
  );
}

DateTime? lokDate(String s) => _commentDate(s);

DateTime? _commentDate(String s) {
  // "2026-11-25T08:48:34,468242030": o Dart só lê até os microssegundos.
  final m = RegExp(r'^(\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d)(?:[.,](\d{1,6})\d*)?').firstMatch(s);
  if (m == null) return null;
  return DateTime.tryParse(m[2] == null ? m[1]! : '${m[1]}.${m[2]}');
}

/// O callback 32: {"comment": {"action": "Add", ...}}.
CommentChanged? parseCommentChanged(String payload) {
  try {
    final c = (jsonDecode(payload) as Map<String, dynamic>)['comment'];
    if (c is! Map) return null;
    final action = switch ('${c['action']}') {
      'Add' => CommentAction.add,
      'Modify' => CommentAction.modify,
      'Resolve' => CommentAction.resolve,
      'Remove' => CommentAction.remove,
      _ => null,
    };
    final comment = parseComment(c);
    if (action == null || comment == null) return null;
    return CommentChanged(action, comment);
  } on FormatException {
    return null;
  }
}

/// A lista do `.uno:ViewAnnotations`: {"comments": [...]}.
List<DocComment> parseCommentList(String json) {
  try {
    final list = (jsonDecode(json) as Map<String, dynamic>)['comments'];
    if (list is! List) return const [];
    return [for (final c in list) ?parseComment(c)];
  } on FormatException {
    return const [];
  }
}

// ------------------------------------------------- as alterações (D-089) --

/// A lista do `.uno:AcceptTrackedChanges`: {"redlines": [...]}, na ordem do
/// motor (não a do texto).
List<TrackedChange> parseTrackedChanges(String json) {
  try {
    final list = (jsonDecode(json) as Map<String, dynamic>)['redlines'];
    if (list is! List) return const [];
    return [
      for (final r in list)
        if ((r is Map ? int.tryParse('${r['index']}') : null) case final index?)
          TrackedChange(
            index: index,
            kind: switch ('${(r as Map)['type']}') {
              'Insert' => TrackedChangeKind.insert,
              'Delete' => TrackedChangeKind.delete,
              'Format' || 'Attributes' || 'ParagraphFormat' => TrackedChangeKind.format,
              _ => TrackedChangeKind.other,
            },
            author: '${r['author'] ?? ''}',
            description: '${r['description'] ?? ''}',
            comment: '${r['comment'] ?? ''}',
            date: lokDate('${r['dateTime'] ?? ''}'),
            range: parseSelection('${r['textRange'] ?? ''}'),
          ),
    ];
  } on FormatException {
    return const [];
  }
}
