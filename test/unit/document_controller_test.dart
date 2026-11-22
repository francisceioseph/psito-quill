
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/document/document_controller.dart';
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
