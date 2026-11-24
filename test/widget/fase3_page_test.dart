// A página do livro, as notas, os links e a impressão (Fase 3, Etapas 3 e 4,
// D-075 e D-076), com o motor falso.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/app.dart';
import 'package:psito_quill/src/kit/fake/fake_quill_kit.dart';
import 'package:psito_quill/src/kit/quill_kit.dart';
import 'package:psito_quill/src/ui/atoms/w_button.dart';

import '../support/harness.dart';

void main() {
  late Harness h;
  late FakeQuillKit kit;
  Harness? current;
  tearDown(() {
    current?.dispose();
    current = null;
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1500, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.localesTestValue = [const Locale('pt', 'BR')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    h = current = Harness();
    kit = h.kit;
    await tester.pumpWidget(QuillApp(workspace: h.workspace, settings: h.settings, window: h.window, showMemory: false));
    h.doc.open('/livro/cap.odt');
    await tester.pump();
  }

  Future<void> insertTab(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(WTextButton, 'Inserir'));
    await tester.pump();
  }

  Future<void> tapBig(WidgetTester tester, String label) async {
    final b = find.widgetWithText(WBigButton, label);
    await tester.ensureVisible(b);
    await tester.pump();
    await tester.tap(b);
    await tester.pumpAndSettle();
  }

  testWidgets('Ctrl+P: o PDF vai para a impressão, e a barra de status avisa', (tester) async {
    await pumpApp(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(kit.copies.last.$2, 'pdf');
    expect(kit.prints, hasLength(1));
    expect(kit.prints.single.$1, kit.copies.last.$1);
    expect(find.text('Enviado à impressora.'), findsOneWidget);
  });

  testWidgets('a impressão cancelada não avisa nada', (tester) async {
    await pumpApp(tester);
    kit.printOutcome = PrintOutcome.cancelled;
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(kit.prints, hasLength(1));
    expect(find.text('Enviado à impressora.'), findsNothing);
  });

  testWidgets('Ctrl+Alt+F e a faixa inserem a nota de rodapé', (tester) async {
    await pumpApp(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(kit.unoCommands.last, '.uno:InsertFootnote');
    await insertTab(tester);
    kit.unoCommands.clear();
    await tapBig(tester, 'Nota de rodapé');
    expect(kit.unoCommands, ['.uno:InsertFootnote']);
  });

  testWidgets('o caractere especial: a busca sem acento acha, o clique insere', (tester) async {
    await pumpApp(tester);
    await insertTab(tester);
    await tapBig(tester, 'Caractere especial…');
    expect(find.text('Caracteres especiais'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'travessao');
    await tester.pump();
    final dash = find.bySemanticsLabel('travessão (—)');
    expect(dash, findsOneWidget);
    await tester.tap(dash);
    await tester.pumpAndSettle();
    expect(find.text('Caracteres especiais'), findsNothing);
    expect(kit.text, endsWith('—'));
  });

  testWidgets('o link: a janela manda o texto e o endereço ao motor', (tester) async {
    await pumpApp(tester);
    await insertTab(tester);
    await tapBig(tester, 'Link…');
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'o site');
    await tester.enterText(fields.at(1), 'https://exemplo.org');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Aplicar'));
    await tester.pumpAndSettle();
    expect(kit.unoCommands.last, '.uno:SetHyperlink');
    expect(kit.unoArgs.last, allOf(contains('"value":"o site"'), contains('"value":"https://exemplo.org"')));
  });

  testWidgets('abrir um link pergunta antes; um file: nem pergunta', (tester) async {
    await pumpApp(tester);
    kit.emit(const CursorMoved(Rect.fromLTWH(1440, 1440, 20, 280), link: DocLink('site', 'https://exemplo.org')));
    await tester.pump();
    expect(h.doc.link?.url, 'https://exemplo.org');
    h.doc.onLinkClicked!(h.doc.link!);
    await tester.pumpAndSettle();
    expect(find.text('Abrir o link?'), findsOneWidget);
    // Cancelar: nada abre.
    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('Abrir o link?'), findsNothing);

    h.doc.onLinkClicked!(const DocLink('x', 'file:///home/x/rodar.desktop'));
    await tester.pumpAndSettle();
    expect(find.text('Abrir o link?'), findsNothing);
    expect(find.textContaining('só abre endereços da web'), findsOneWidget);
  });

  testWidgets('o cabeçalho liga pela faixa; com ele ligado, o cursor vai até ele', (tester) async {
    await pumpApp(tester);
    await insertTab(tester);
    final menu = find.text('Cabeçalho').first;
    await tester.ensureVisible(menu);
    await tester.pump();
    await tester.tap(menu);
    await tester.pumpAndSettle();
    // O menu do grupo: o primeiro item é o próprio Cabeçalho.
    await tester.tap(find.text('Cabeçalho').last);
    await tester.pumpAndSettle();
    expect(kit.unoCommands, contains('.uno:InsertPageHeader'));
    expect(kit.unoArgs[kit.unoCommands.lastIndexOf('.uno:InsertPageHeader')], contains('"On"'));
  });
}
