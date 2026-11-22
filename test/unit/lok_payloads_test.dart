import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/kit/lok/lok_payloads.dart';
import 'package:psito_quill/src/kit/lok/lok_quill_kit.dart';
import 'package:psito_quill/src/kit/quill_kit.dart';
import 'package:psito_quill_kit/psito_quill_kit.dart';

void main() {
  group('retângulos', () {
    test('lê "x, y, w, h" e ignora parte e modo', () {
      expect(parseLokRect('1440, 2880, 300, 276, 0, 0'), const Rect.fromLTWH(1440, 2880, 300, 276));
    });

    test('EMPTY e vazio dão null', () {
      expect(parseLokRect('EMPTY, 0, 0'), isNull);
      expect(parseLokRect(''), isNull);
      expect(parseLokRect('1, 2'), isNull);
    });

    test('cursor aceita texto e o JSON com rectangle', () {
      expect(parseCursor('10, 20, 30, 40'), const Rect.fromLTWH(10, 20, 30, 40));
      expect(parseCursor('{"viewId":"0","rectangle":"10, 20, 30, 40"}'), const Rect.fromLTWH(10, 20, 30, 40));
      expect(parseCursor('EMPTY'), Rect.zero);
    });

    test('seleção com vários retângulos, sem os vazios', () {
      expect(parseSelection('0, 0, 100, 200; 0, 200, 50, 200; 5, 5, 0, 0'),
          const [Rect.fromLTWH(0, 0, 100, 200), Rect.fromLTWH(0, 200, 50, 200)]);
      expect(parseSelection(''), isEmpty);
    });
  });

  test('estado de comando nos dois formatos', () {
    expect(parseCommandState('.uno:Bold=true'), ('.uno:Bold', 'true'));
    expect(parseCommandState('.uno:PageStatus=Página 3 de 30'), ('.uno:PageStatus', 'Página 3 de 30'));
    expect(parseCommandState('{"commandName":".uno:Italic","state":"false"}'), ('.uno:Italic', 'false'));
    expect(parseCommandState('lixo'), isNull);
  });

  test('tamanho do documento e ladrilho', () {
    expect(parseDocumentSize('12474, 513944'), const Size(12474, 513944));
    final t = parseTilePlaced('7,1,3,1250')!;
    expect(t.slot, 7);
    expect(t.key, const TileKey(1, 3, 1250));
    expect(parseTilePlaced('1,2'), isNull);
    expect(parseOpened('{"width":12474,"height":513944,"parts":1}'), const Size(12474, 513944));
  });

  group('LokQuillKit.translate', () {
    test('eventos do plugin', () {
      expect(LokQuillKit.translate(PqkEvent.PQK_EVENT_READY, 'v'), isA<KitReady>());
      expect(LokQuillKit.translate(PqkEvent.PQK_EVENT_TILE, '0,0,0,1000'), isA<TilePlaced>());
      final done = LokQuillKit.translate(PqkEvent.PQK_EVENT_LUA_DONE, '{"ok":false,"error":"teto"}');
      expect(done, isA<PluginFinished>().having((e) => e.ok, 'ok', false).having((e) => e.error, 'erro', 'teto'));
    });

    test('callbacks do LOK', () {
      expect(LokQuillKit.translate(LibreOfficeKitCallbackType.LOK_CALLBACK_STATE_CHANGED, '.uno:Bold=true'),
          isA<CommandStateChanged>().having((e) => e.value, 'valor', 'true'));
      expect(LokQuillKit.translate(LibreOfficeKitCallbackType.LOK_CALLBACK_CURSOR_VISIBLE, 'true'),
          isA<CursorVisibility>().having((e) => e.visible, 'visível', true));
      expect(LokQuillKit.translate(LibreOfficeKitCallbackType.LOK_CALLBACK_TEXT_SELECTION, ''),
          isA<SelectionChanged>().having((e) => e.rects, 'retângulos', isEmpty));
      expect(LokQuillKit.translate(9999, 'x'), isA<OtherKitEvent>());
    });
  });
}
