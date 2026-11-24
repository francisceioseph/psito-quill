import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/l10n/gen/app_localizations.dart';
import 'package:psito_quill/src/commands/command_registry.dart';
import 'package:psito_quill/src/commands/commands_document.dart';
import 'package:psito_quill/src/document/document_controller.dart';
import 'package:psito_quill/src/kit/fake/fake_quill_kit.dart';
import 'package:psito_quill/src/kit/lok/vcl_keys.dart';
import 'package:psito_quill/src/kit/quill_kit.dart';
import 'package:psito_quill/src/ui/organisms/document_view.dart';
import 'package:psito_quill/src/ui/tokens/themes/themes.dart';
import 'package:psito_quill/src/ui/tokens/tokens.dart';

import '../support/harness.dart';
import 'helpers.dart';

void main() {
  late FakeQuillKit kit;
  Harness? h;
  late DocumentController doc;
  late CommandRegistry commands;

  Future<void> pump(WidgetTester tester, {String? lockOwner}) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    h = Harness();
    kit = h!.kit;
    doc = h!.doc..open('/livro/cap.docx', lockOwner: lockOwner);
    commands = CommandRegistry();
    await tester.pumpWidget(themed(Builder(builder: (context) {
      if (commands.all.isEmpty) {
        registerEditorCommands(commands, doc: doc, workspace: h!.workspace, l10n: AppLocalizations.of(context));
      }
      return DocumentView(doc: doc, commands: commands, semanticLabel: 'Documento');
    }), claro));
    await tester.pump();
  }

  tearDown(() {
    h?.dispose();
    h = null;
  });

  test('geometria: twips ↔ pixels, centralizada', () {
    const g = PageGeometry(zoom: 1, viewSize: Size(1200, 800), documentTwips: Size(12000, 30000));
    expect(g.documentWidth, 800);
    expect(g.origin, const Offset(200, 24));
    expect(g.toTwips(const Offset(200 + 100, 24 + 10)), const Offset(1500, 150));
    // Só o documento: os lados vazios não pedem ladrilhos.
    expect(g.visibleTwips(0, 24), const Rect.fromLTWH(0, 0, 12000, 12000));
    // No fim, só até o fim do documento.
    expect(g.visibleTwips(0, 24 + 25000 / 15).bottom, 30000);
  });

  test('geometria com zoom alto: a página passa da janela e rola para o lado', () {
    // 12000 twips a 300 % = 2400 px, numa janela de 1200.
    const g = PageGeometry(zoom: 3, viewSize: Size(1200, 800), documentTwips: Size(12000, 30000));
    expect(g.contentWidth, 2400 + 48);
    expect(g.origin.dx, 24);
    final v = g.visibleTwips(624, 24);
    expect(v.left, 3000);
    expect(v.width, 6000);
  });

  test('zoom ancorado: o ponto sob a âncora continua lá', () {
    const before = PageGeometry(zoom: 1, viewSize: Size(1200, 800), documentTwips: Size(12000, 30000));
    const after = PageGeometry(zoom: 2, viewSize: Size(1200, 800), documentTwips: Size(12000, 30000));
    const anchor = Offset(600, 400);
    const scroll = Offset(0, 1000);
    final point = before.toTwips(anchor + scroll);
    final s = after.scrollFor(point, anchor);
    expect(after.toTwips(anchor + s), point);
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

  testWidgets('o texto vem pelo IME; Enter e setas vão direto ao motor', (tester) async {
    await pump(tester);
    expect(tester.testTextInput.hasAnyClients, isTrue, reason: 'com o foco, a conexão com o IME abre');
    tester.testTextInput.updateEditingValue(const TextEditingValue(text: 'a'));
    await tester.pump();
    expect(kit.text, 'a');
    // Um caractere vai como tecla, para o autocorrigir do motor (D-076).
    expect(kit.keys.first, (KeyEventType.input, 0x61, 0));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    expect(kit.keys.where((k) => k.$1 == KeyEventType.input && k.$3 != 0).map((k) => k.$3), [VclKey.enter, VclKey.left]);
  });

  testWidgets('acento composto (´ + e): pré-edição e depois o texto final', (tester) async {
    await pump(tester);
    tester.testTextInput.updateEditingValue(
        const TextEditingValue(text: '´', composing: TextRange(start: 0, end: 1)));
    await tester.pump();
    expect(kit.preedit, '´');
    expect(kit.text, '');
    // Durante a composição, as teclas são do IME (o Backspace não apaga o
    // documento).
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    expect(kit.keys, isEmpty);
    tester.testTextInput.updateEditingValue(const TextEditingValue(text: 'é'));
    await tester.pump();
    expect(kit.preedit, '');
    expect(kit.text, 'é');
  });

  testWidgets('pré-edição cancelada (´ e depois Esc): o ´ sai do motor', (tester) async {
    await pump(tester);
    tester.testTextInput.updateEditingValue(
        const TextEditingValue(text: '´', composing: TextRange(start: 0, end: 1)));
    await tester.pump();
    expect(kit.preedit, '´');
    // O IME cancela: o valor volta vazio, sem composição.
    tester.testTextInput.updateEditingValue(TextEditingValue.empty);
    await tester.pump();
    expect(kit.preedit, '', reason: 'antes, o controlador ignorava o texto vazio e o ´ ficava');
    expect(kit.text, '');
  });

  testWidgets('Ctrl+letra que não é atalho do Quill não chega ao motor', (tester) async {
    await pump(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyL, character: 'l');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(kit.keys, isEmpty);
    expect(kit.unoCommands, isEmpty);
  });

  testWidgets('Ctrl+setas andam por palavra (vão ao motor com o Ctrl)', (tester) async {
    await pump(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(kit.keys.first.$3, VclKey.right | VclKey.mod1);
  });

  testWidgets('só leitura: anda, mas não apaga nem abre o IME', (tester) async {
    await pump(tester, lockOwner: 'Maria');
    expect(tester.testTextInput.hasAnyClients, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    expect(kit.keys.map((k) => k.$3).toSet(), {VclKey.down});
  });

  testWidgets('zoom pelo botão mantém o centro da tela no mesmo ponto do documento', (tester) async {
    await pump(tester);
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    scroll.jumpTo(1500);
    await tester.pump();
    const size = Size(1200, 800);
    final before = PageGeometry(zoom: 1, viewSize: size, documentTwips: kit.documentSize);
    final center = before.toTwips(Offset(600, 400 + scroll.pixels));
    doc.setZoom(2);
    await tester.pump();
    await tester.pump();
    final after = PageGeometry(zoom: 2, viewSize: size, documentTwips: kit.documentSize);
    final h = tester.state<ScrollableState>(find.byType(Scrollable).at(1)).position.pixels;
    final now = after.toTwips(Offset(600 + h, 400 + scroll.pixels));
    expect((now - center).distance, lessThan(30), reason: 'no máximo 2 twips de erro por pixel');
  });

  testWidgets('no zoom, os ladrilhos da escala anterior ficam por baixo até os novos chegarem', (tester) async {
    await pump(tester);
    final before = doc.tiles.map((t) => t.key).toSet();
    doc.setZoom(1.5);
    await tester.pump();
    await tester.pump();
    expect(doc.staleTiles.map((t) => t.key).toSet(), before);
    expect(doc.tiles.every((t) => t.key.scaleMilli != before.first.scaleMilli), isTrue);
  });

  testWidgets('clique triplo seleciona o parágrafo (vai como 4 ao motor)', (tester) async {
    await pump(tester);
    final at = tester.getCenter(find.byType(DocumentView));
    for (var i = 0; i < 3; i++) {
      await tester.tapAt(at);
      await tester.pump(const Duration(milliseconds: 120));
    }
    expect(kit.mice.where((m) => m.$1 == MouseEventType.down).map((m) => m.$4), [1, 2, 4]);
  });

  testWidgets('Ctrl + roda do mouse muda o zoom e pede ladrilhos na escala nova', (tester) async {
    await pump(tester);
    final center = tester.getCenter(find.byType(DocumentView));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendEventToBinding(PointerScrollEvent(position: center, scrollDelta: const Offset(0, -50)));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    await tester.pump();
    expect(doc.zoom, closeTo(1.1, 1e-9));
    expect(kit.viewports.last.$1, (tester.view.devicePixelRatio * 1100).round());
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

  testWidgets('o cursor aparece e pisca logo ao abrir, antes de digitar', (tester) async {
    await pump(tester);
    bool caret() => tester
        .widgetList<ColoredBox>(find.byType(ColoredBox))
        .any((b) => b.color == claro.colors.cursor);
    expect(caret(), isTrue, reason: 'o LOK não manda "visível" ao abrir; o cursor aparece mesmo assim');
    await tester.pump(const QuillMotion().caretBlink);
    expect(caret(), isFalse, reason: 'pisca');
    await tester.pump(const QuillMotion().caretBlink);
    expect(caret(), isTrue);
    kit.emit(const CursorVisibility(false));
    await tester.pump();
    expect(caret(), isFalse, reason: 'o motor pode esconder (com uma imagem selecionada, por exemplo)');
  });

  testWidgets('cursor e seleção usam as cores do tema', (tester) async {
    await pump(tester);
    tester.testTextInput.updateEditingValue(const TextEditingValue(text: 'a')); // mexe o cursor
    await tester.pump();
    final boxes = tester.widgetList<ColoredBox>(find.byType(ColoredBox)).map((b) => b.color).toSet();
    expect(boxes, contains(claro.colors.cursor));
    expect(boxes, contains(claro.colors.backdrop));
  });
}
