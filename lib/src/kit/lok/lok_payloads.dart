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
    return (name, '${json['state'] ?? ''}');
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
