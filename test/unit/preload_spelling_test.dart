// O dicionário carrega na tela inicial (D-069): o controlador escreve um
// documento pequeno em português nas cópias e pede ao motor que o abra oculto.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/document/document_controller.dart';
import 'package:psito_quill/src/kit/fake/fake_quill_kit.dart';

void main() {
  test('sem documento, escreve a frase e pede ao motor', () {
    final kit = FakeQuillKit();
    final doc = DocumentController(kit)..start();
    addTearDown(doc.dispose);
    doc.preloadSpelling();
    expect(kit.preloads, hasLength(1));
    final f = File(kit.preloads.single);
    addTearDown(() => f.existsSync() ? f.deleteSync() : null);
    expect(f.uri.pathSegments.last, startsWith(DocumentController.copyPrefixOfThisProcess),
        reason: 'se sobrar, a limpeza das cópias leva');
    final xml = f.readAsStringSync();
    expect(xml, contains('fo:language="pt"'));
    expect(xml, contains('<text:p>'));
  });

  test('com documento aberto, não faz nada', () {
    final kit = FakeQuillKit();
    final doc = DocumentController(kit)..start();
    addTearDown(doc.dispose);
    doc.open('/a.odt');
    doc.preloadSpelling();
    expect(kit.preloads, isEmpty);
  });
}
