import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/l10n/gen/app_localizations.dart';
import 'package:psito_quill/src/commands/command_registry.dart';
import 'package:psito_quill/src/commands/commands_document.dart';
import 'package:psito_quill/src/document/document_controller.dart';
import 'package:psito_quill/src/kit/fake/fake_quill_kit.dart';
import 'package:psito_quill/src/kit/quill_kit.dart';
import 'package:psito_quill/src/ui/organisms/document_view.dart';
import 'package:psito_quill/src/ui/tokens/themes/themes.dart';

import 'helpers.dart';

void main() {
  late FakeQuillKit kit;
  DocumentController? created;
  late DocumentController doc;
  late CommandRegistry commands;

  Future<void> pump(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    kit = FakeQuillKit();
    doc = created = DocumentController(kit)
      ..start()
      ..open('/livro/cap.docx');
    commands = CommandRegistry();
    await tester.pumpWidget(themed(Builder(builder: (context) {
      if (commands.all.isEmpty) registerDocumentCommands(commands, doc, AppLocalizations.of(context));
      return DocumentView(doc: doc, commands: commands, semanticLabel: 'Documento');
    }), claro));
    await tester.pump();
  }

  tearDown(() {
    created?.dispose();
    created = null;
  });

  test('geometria: twips ↔ pixels, centralizada', () {
    const g = PageGeometry(zoom: 1, viewSize: Size(1200, 800), documentTwips: Size(12000, 30000));
    expect(g.documentWidth, 800);
    expect(g.origin, const Offset(200, 24));
    expect(g.toTwips(const Offset(200 + 100, 24 + 10)), const Offset(1500, 150));
    expect(g.visibleTwips(24), const Rect.fromLTWH(0, 0, 18000, 12000));
  });

  test('ladrilhos encostam sem fresta em escala fracionária', () {
    for (final scale in [1000, 1100, 1250, 1500]) {
      for (var c = 0; c < 10; c++) {
        final a = tileRectTwips(TileKey(c, 0, scale), 256), b = tileRectTwips(TileKey(c + 1, 0, scale), 256);
        expect(a.right, b.left, reason: 'escala $scale coluna $c');
      }
    }
  });

  testWidgets('abre e pede os ladrilhos da tela', (tester) async {
    await pump(tester);
    expect(kit.viewports, isNotEmpty);
    expect(doc.tiles, isNotEmpty);
    // O kit falso não tem texturas: os ladrilhos aparecem como papel.
    expect(find.byType(Texture), findsNothing);
  });

  testWidgets('rolar pede a nova área ao motor', (tester) async {
    await pump(tester);
    final before = kit.viewports.last.$2.top;
    await tester.drag(find.byType(DocumentView), const Offset(0, -400));
    await tester.pump();
    expect(kit.viewports.last.$2.top, greaterThan(before));
  });

  testWidgets('digitar manda o caractere ao motor', (tester) async {
    await pump(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA, character: 'a');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(kit.keys.where((k) => k.$1 == KeyEventType.input).map((k) => k.$2), [0x61, 13]);
  });

  testWidgets('Ctrl+N é negrito (Word em português), e não vai como texto', (tester) async {
    await pump(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN, character: 'n');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(kit.unoCommands, ['.uno:Bold']);
    expect(kit.keys, isEmpty);
  });

  testWidgets('clique vira evento de mouse em twips', (tester) async {
    await pump(tester);
    // O documento falso tem 12474 twips (831,6 px) de largura: centralizado em 1200.
    final origin = tester.getTopLeft(find.byType(DocumentView)) + const Offset((1200 - 12474 / 15) / 2, 24);
    await tester.tapAt(origin + const Offset(100, 50));
    expect(kit.mice.first.$1, MouseEventType.down);
    expect(kit.mice.first.$2, closeTo(1500, 1));
    expect(kit.mice.first.$3, closeTo(750, 1));
  });

  testWidgets('cursor e seleção usam as cores do tema', (tester) async {
    await pump(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA, character: 'a'); // dá o foco e mexe o cursor
    await tester.pump();
    final boxes = tester.widgetList<ColoredBox>(find.byType(ColoredBox)).map((b) => b.color).toSet();
    expect(boxes, contains(claro.colors.cursor));
    expect(boxes, contains(claro.colors.backdrop));
  });
}
