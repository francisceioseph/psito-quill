
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/document/document_controller.dart';
import 'package:psito_quill/src/document/text_clipboard.dart';
import 'package:psito_quill/src/kit/fake/fake_quill_kit.dart';
import 'package:psito_quill/src/kit/quill_kit.dart';
import 'package:psito_quill/src/plugins/plugin_host.dart';

void main() {
  late FakeQuillKit kit;
  late DocumentController doc;

  setUp(() {
    kit = FakeQuillKit();
    doc = DocumentController(kit)..start();
  });
  tearDown(() => doc.dispose());

  test('liga o motor e abre', () {
    expect(doc.kitStatus, KitStatus.ready);
    doc.open('/livros/cap1.docx');
    expect(doc.docStatus, DocStatus.open);
    expect(doc.documentSize, kit.documentSize);
    expect(doc.cursorVisible, isTrue);
  });

  test('motor que não liga vira erro', () {
    final failing = DocumentController(FakeQuillKit(failStart: true))..start();
    expect(failing.kitStatus, KitStatus.failed);
    expect(failing.message, isA<ErrorMessage>());
    failing.dispose();
  });

  test('a área visível pede ladrilhos, e só os da escala atual aparecem', () {
    doc.open('a.odt');
    doc.setViewport(const Rect.fromLTWH(0, 0, 18000, 12000), 1000);
    final at1x = doc.tiles.length;
    expect(at1x, greaterThan(0));
    expect(kit.viewports.last.$1, 1000);
    doc.setViewport(const Rect.fromLTWH(0, 0, 18000, 12000), 1250);
    expect(doc.tiles.every((t) => t.key.scaleMilli == 1250), isTrue);
  });

  test('sem documento aberto, não pede ladrilhos', () {
    doc.setViewport(const Rect.fromLTWH(0, 0, 100, 100), 1000);
    expect(kit.viewports, isEmpty);
  });

  test('digitar manda tecla e soltura, e marca modificado', () {
    doc.open('a.odt');
    doc.postKey(0x61, 0);
    expect(kit.keys, [(KeyEventType.input, 0x61, 0), (KeyEventType.up, 0x61, 0)]);
    expect(doc.modified, isTrue);
    expect(doc.cursor.left, greaterThan(1440)); // o cursor andou
  });

  test('negrito: o estado vem do motor', () {
    doc.open('a.odt');
    expect(doc.isOn('.uno:Bold'), isFalse);
    doc.uno('.uno:Bold');
    expect(doc.isOn('.uno:Bold'), isTrue);
  });

  test('salvar usa o formato do arquivo e limpa o modificado', () {
    doc.open('/livros/cap1.docx');
    doc.postKey(0x61, 0);
    expect(doc.save(), isTrue);
    expect(kit.saved.single, ('/livros/cap1.docx', 'docx'));
    expect(doc.modified, isFalse);
    expect(doc.message, isA<SavedMessage>());
  });

  test('fechar espera o motor e limpa o estado', () async {
    doc.open('/livros/cap1.docx');
    await doc.close();
    expect(kit.openedPath, isNull);
    expect(doc.docStatus, DocStatus.none);
    expect(doc.tiles, isEmpty);
    await doc.close(); // sem documento: não faz nada
  });

  test('fechar não trava se o motor não responder', () async {
    final mute = _MuteKit();
    final d = DocumentController(mute)..start();
    d.open('a.odt');
    await d.close(timeout: const Duration(milliseconds: 50));
    d.dispose();
  });

  test('documento novo não tem onde salvar', () {
    doc.open('');
    expect(doc.save(), isFalse);
  });

  test('o papel troca pelo .uno:ChangeTheme', () {
    doc.open('a.odt');
    doc.setPaperScheme('PsitoQuillEscuro');
    expect(kit.unoCommands.last, '.uno:ChangeTheme');
  });

  test('o "olá" do plugin chega na barra de status', () async {
    await PluginHost(kit, bundle: _Bundle('psito.log("olá")')).runBundled('ola');
    expect(kit.luaRuns.single, 'ola/plugin.lua');
    expect(doc.message, isA<PluginMessage>().having((m) => m.text, 'texto', 'olá'));
  });

  group('Fase 1', () {
    late MemoryTextClipboard clip;
    setUp(() {
      clip = MemoryTextClipboard();
      doc.dispose();
      kit = FakeQuillKit();
      doc = DocumentController(kit, clipboard: clip)..start();
      doc.open('/a.odt');
    });

    test('o IME: pré-edição e texto confirmado', () {
      doc.composeText('´');
      expect(kit.preedit, '´');
      doc.insertText('é');
      expect((kit.preedit, kit.text), ('', 'é'));
    });

    test('desfazer e refazer seguem o motor', () {
      expect(doc.canUndo, isFalse);
      doc.insertText('olá');
      expect(doc.canUndo, isTrue);
      doc.undo();
      expect((kit.text, doc.canRedo), ('', true));
      doc.redo();
      expect(kit.text, 'olá');
    });

    test('copiar põe o texto na área do sistema; colar o mesmo usa o do motor', () async {
      kit
        ..selectedText = 'trecho'
        ..emit(const SelectionChanged([Rect.fromLTWH(0, 0, 10, 10)]));
      doc.copy();
      expect(clip.text, 'trecho');
      expect(kit.unoCommands, ['.uno:Copy']);
      await doc.paste();
      expect(kit.unoCommands.last, '.uno:Paste');
      clip.text = 'de outro app';
      await doc.paste();
      expect(kit.pasted, ['de outro app']);
    });

    test('recortar pede o texto antes de cortar', () {
      kit.text = 'um trecho';
      kit
        ..selectedText = 'trecho'
        ..emit(const SelectionChanged([Rect.fromLTWH(0, 0, 10, 10)]));
      doc.cut();
      expect(clip.text, 'trecho');
      expect(kit.text, 'um ');
    });

    test('só leitura: não edita, mas copia', () {
      doc.open('/b.odt', lockOwner: 'maria');
      doc.insertText('x');
      doc.uno('.uno:Bold');
      doc.undo();
      expect(kit.text, '');
      expect(kit.unoCommands, isEmpty);
      expect(doc.save(), isFalse, reason: 'só leitura vira Salvar como');
      kit.emit(const SelectionChanged([Rect.fromLTWH(0, 0, 10, 10)]));
      kit.selectedText = 'lido';
      doc.copy();
      expect(clip.text, 'lido');
    });

    test('zoom em passos de 5 %, entre 50 % e 300 %', () {
      doc.setZoom(1.234);
      expect(doc.zoom, 1.25);
      doc.setZoom(10);
      expect(doc.zoom, maxZoom);
      doc.setZoom(0);
      expect(doc.zoom, minZoom);
    });

    test('página, palavras, estilo e fontes vêm do motor', () {
      kit.emitState('.uno:StatePageNumber', 'Página 2 de 3');
      expect(doc.page, (2, 3));
      doc.insertText('duas palavras');
      expect(doc.wordCount?.words, 2);
      expect(doc.paragraphStyle, 'Estilo de parágrafo padrão');
      expect(doc.fonts, contains('Noto Serif'));
    });

    test('salvar como passa a ser o arquivo novo', () {
      doc.saveAs('/c.docx');
      expect(kit.saved.single, ('/c.docx', 'docx'));
      expect(doc.path, '/c.docx');
    });

    test('arquivo que não abre: mensagem com o caminho', () {
      kit.openFails = true;
      doc.open('/ruim.docx');
      expect(doc.docStatus, DocStatus.failed);
      expect((doc.message as OpenFailedMessage).path, '/ruim.docx');
    });
  });
}


class _Bundle extends Fake implements AssetBundle {
  _Bundle(this.source);
  final String source;
  @override
  Future<String> loadString(String key, {bool cache = true}) async => source;
}

/// Um kit que abre mas nunca confirma o fechamento.
class _MuteKit extends FakeQuillKit {
  @override
  void close() {}
}
