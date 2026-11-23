// O trabalho depois de abrir (D-068): a cópia e as listas esperam o primeiro
// ladrilho, para não atrasar a primeira tela; sem ladrilho, vão depois de 1 s.
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/document/document_controller.dart';
import 'package:psito_quill/src/kit/fake/fake_quill_kit.dart';

void main() {
  test('espera o primeiro ladrilho', () {
    final kit = FakeQuillKit();
    final doc = DocumentController(kit, deferOpenWork: true)..start();
    addTearDown(doc.dispose);
    doc.open('/a.odt');
    expect(kit.copies, isEmpty, reason: 'a cópia não vai junto com o abrir');
    expect(doc.fonts, isEmpty);
    doc.setViewport(const Rect.fromLTWH(0, 0, 12000, 8000), 1000);
    expect(doc.tiles, isNotEmpty);
    expect(kit.copies, hasLength(1), reason: 'o primeiro ladrilho solta o trabalho');
    expect(doc.fonts, isNotEmpty);
    doc.setViewport(const Rect.fromLTWH(0, 8000, 12000, 8000), 1000);
    expect(kit.copies, hasLength(1), reason: 'só uma vez por abrir');
  });

  test('sem ladrilho, vai depois de 1 s', () async {
    final kit = FakeQuillKit();
    final doc = DocumentController(kit, deferOpenWork: true)..start();
    addTearDown(doc.dispose);
    doc.open('/a.odt');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(kit.copies, isEmpty);
    await Future<void>.delayed(DocumentController.openWorkFallback);
    expect(kit.copies, hasLength(1));
  });
}
