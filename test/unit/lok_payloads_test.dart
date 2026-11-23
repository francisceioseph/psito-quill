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

  group('estados da barra de status', () {
    test('página: os dois primeiros números, em qualquer idioma', () {
      expect(parsePageStatus('Página 3 de 30'), (3, 30));
      expect(parsePageStatus('Page 12 of 1.204'), (12, 1204));
      expect(parsePageStatus('Página 3 de 30 (Página 5)'), (3, 30));
      expect(parsePageStatus(null), isNull);
      expect(parsePageStatus('Página'), isNull);
    });

    test('palavras: milhar com ponto, e a seleção com dois-pontos', () {
      expect(parseWordCount('21.069 palavras, 117.537 caracteres'), (words: 21069, characters: 117537, selection: false));
      expect(parseWordCount('Selecionado: 1 palavra, 4 caracteres'), (words: 1, characters: 4, selection: true));
      expect(parseWordCount('1,234 words, 5,678 characters'), (words: 1234, characters: 5678, selection: false));
    });

    test('fontes: do JSON do getCommandValues, em ordem, sem vazias', () {
      const json = '{"commandName":".uno:CharFontName","commandValues":{"":{"Noto Serif":["12"],"aqua":["10"],"":[]}}}';
      expect(parseFontList(json), ['aqua', 'Noto Serif']);
      expect(parseFontList('{"commandValues":{"Liberation Sans":[]}}'), ['Liberation Sans']);
      expect(parseFontList('não é json'), isEmpty);
    });
  });

  test('a seleção como texto e os valores de um comando viram eventos', () {
    expect((LokQuillKit.translate(PqkEvent.PQK_EVENT_TEXT_SELECTION, 'text/plain\nolá\nmundo') as TextSelectionContent).text,
        'olá\nmundo');
    final v = LokQuillKit.translate(PqkEvent.PQK_EVENT_COMMAND_VALUES, '.uno:CharFontName\n{}') as CommandValues;
    expect((v.command, v.json), ('.uno:CharFontName', '{}'));
  });

  test('vagas de ladrilho: cobrem a tela, com margem, dentro dos limites', () {
    expect(tileSlotsFor(const Size(1920, 1080)), 9 * 8);
    expect(tileSlotsFor(const Size(800, 600)), 48, reason: 'mínimo');
    expect(tileSlotsFor(const Size(7680, 4320)), 256, reason: 'máximo');
    expect(tileSlotsFor(Size.zero), 128, reason: 'sem saber a tela');
  });
}
