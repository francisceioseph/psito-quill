// As abas de documentos (D-054): vários documentos no motor, um na tela.
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/document/document_controller.dart';
import 'package:psito_quill/src/kit/fake/fake_quill_kit.dart';
import 'package:psito_quill/src/kit/quill_kit.dart';

void main() {
  late FakeQuillKit kit;
  late DocumentController doc;

  setUp(() {
    kit = FakeQuillKit();
    doc = DocumentController(kit)..start();
  });
  tearDown(() => doc.dispose());

  test('abrir dois: duas abas no motor, a segunda na tela', () {
    doc.open('/a.odt');
    doc.open('/b.odt');
    expect(doc.tabs, hasLength(2));
    expect(doc.path, '/b.odt');
    expect(kit.openIds, hasLength(2));
    expect(doc.currentTab, doc.tabs.last);
  });

  test('trocar de aba: o motor troca, e cada uma guarda o seu estado', () {
    doc.open('/a.odt');
    doc.setZoom(1.5);
    doc.insertText('primeiro');
    kit.emitState('.uno:Bold', 'true');
    doc.open('/b.odt');
    kit.emitState('.uno:ModifiedStatus', 'true');
    expect(doc.isOn('.uno:Bold'), isFalse);
    expect(doc.zoom, 1.0);
    final a = doc.tabs.first, b = doc.tabs.last;
    final rev = doc.tabRevision;
    doc.activateTab(a);
    expect(doc.tabRevision, greaterThan(rev));
    expect(kit.activeId, a.engineId);
    expect(doc.path, '/a.odt');
    expect(doc.zoom, 1.5);
    expect(kit.text, 'primeiro');
    expect(doc.isOn('.uno:Bold'), isTrue);
    expect(doc.tabModified(b), isTrue);
    expect(doc.tabPath(b), '/b.odt');
    doc.cycleTab();
    expect(doc.path, '/b.odt');
    expect(doc.modified, isTrue);
    expect(doc.isOn('.uno:Bold'), isFalse);
  });

  test('um documento novo e vazio dá lugar ao que se abre', () {
    doc.open('');
    doc.open('/a.odt');
    expect(doc.tabs, hasLength(1));
    expect(kit.openIds, hasLength(1));
    expect(doc.path, '/a.odt');
  });

  test('um documento novo com alterações fica', () {
    doc.open('');
    kit.emitState('.uno:ModifiedStatus', 'true');
    doc.open('/a.odt');
    expect(doc.tabs, hasLength(2));
  });

  test('fechar a aba da tela traz a vizinha; fechar a última não deixa nenhuma', () async {
    doc.open('/a.odt');
    doc.open('/b.odt');
    doc.open('/c.odt');
    doc.activateTab(doc.tabs[1]);
    await doc.closeTab(doc.currentTab!);
    expect(doc.tabs.map(doc.tabPath), ['/a.odt', '/c.odt']);
    expect(doc.path, '/c.odt');
    expect(kit.activeId, doc.currentTab!.engineId);
    await doc.closeTab(doc.tabs.first);
    expect(doc.tabs, hasLength(1));
    expect(doc.path, '/c.odt');
    await doc.closeTab(doc.currentTab!);
    expect(doc.tabs, isEmpty);
    expect(doc.docStatus, DocStatus.none);
    expect(kit.openIds, isEmpty);
  });

  test('fechar tudo fecha todos no motor', () async {
    doc.open('/a.odt');
    doc.open('/b.odt');
    await doc.close();
    expect(kit.openIds, isEmpty);
    expect(doc.tabs, isEmpty);
    expect(doc.docStatus, DocStatus.none);
  });

  test('até o motor confirmar a troca, os eventos do documento anterior saem', () {
    final slow = _SlowKit();
    final d = DocumentController(slow)..start();
    d.open('/a.odt');
    d.open('/b.odt');
    d.activateTab(d.tabs.first);
    // Atrasado, do /b.odt: não pode cair no /a.odt.
    slow.emitState('.uno:Bold', 'true');
    slow.emit(const CursorMoved(Rect.fromLTWH(9, 9, 20, 280)));
    expect(d.isOn('.uno:Bold'), isFalse);
    slow.confirm();
    slow.emitState('.uno:Italic', 'true');
    expect(d.isOn('.uno:Italic'), isTrue);
    d.dispose();
  });

  test('o limite: além de 8, a aba salva usada há mais tempo sai do motor e reabre ao voltar', () {
    for (var i = 0; i < DocumentController.maxLoadedTabs + 1; i++) {
      doc.open('/cap$i.odt');
    }
    expect(doc.tabs, hasLength(9));
    expect(kit.openIds, hasLength(DocumentController.maxLoadedTabs));
    final first = doc.tabs.first;
    expect(first.engineId, isNull);
    final opens = kit.opened.length;
    doc.activateTab(first);
    expect(kit.opened.length, opens + 1);
    expect(kit.opened.last, '/cap0.odt');
    expect(doc.path, '/cap0.odt');
    expect(doc.isOpen, isTrue);
    // Reabrir de novo passou do limite: outra salva saiu.
    expect(kit.openIds, hasLength(DocumentController.maxLoadedTabs));
  });

  test('o limite não fecha uma aba com alterações', () {
    doc.open('/cap0.odt');
    kit.emitState('.uno:ModifiedStatus', 'true');
    for (var i = 1; i < DocumentController.maxLoadedTabs + 1; i++) {
      doc.open('/cap$i.odt');
    }
    expect(doc.tabs.first.engineId, isNotNull);
    expect(doc.tabs[1].engineId, isNull);
  });
}

/// Um kit que só confirma a troca de documento quando o teste manda.
class _SlowKit extends FakeQuillKit {
  int? _waiting;

  @override
  void activate(int id) => _waiting = id;

  void confirm() => super.activate(_waiting!);
}
