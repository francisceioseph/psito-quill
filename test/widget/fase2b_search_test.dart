// A busca única (D-050): um campo para o texto e os comandos. As
// ocorrências vêm da cópia, o clique leva a ela, e a cópia sai ao fechar.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/app.dart';
import 'package:psito_quill/src/kit/fake/fake_quill_kit.dart';
import 'package:psito_quill/src/ui/organisms/command_palette.dart';
import 'package:psito_quill/src/ui/organisms/find_bar.dart';

import '../support/harness.dart';

void main() {
  late Harness h;
  late FakeQuillKit kit;
  Harness? current;

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.localesTestValue = [const Locale('pt', 'BR')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    h = current = Harness();
    kit = h.kit..bodyParagraphs = const ['Ele disse a estrada velha acabou.', 'Nada aqui.', 'Na estrada, o posto.'];
    await tester.pumpWidget(QuillApp(workspace: h.workspace, settings: h.settings, window: h.window, showMemory: false));
    h.doc.open('/livro/cap.odt');
    await tester.pump();
    await tester.pump();
  }

  tearDown(() {
    current?.dispose();
    current = null;
  });

  Future<void> typeAndWait(WidgetTester tester, String text) async {
    await tester.enterText(find.descendant(of: find.byType(CommandPalette), matching: find.byType(EditableText)), text);
    await tester.pump(const Duration(milliseconds: 300));
    // A leitura da cópia roda num isolate: tempo de verdade.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
    await tester.pump();
  }

  testWidgets('Ctrl+L abre a busca única: o texto e os comandos juntos', (tester) async {
    await pumpApp(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.byType(CommandPalette), findsOneWidget);
    await typeAndWait(tester, 'estrada');
    expect(find.text('No documento'), findsOneWidget);
    expect(find.text('2 ocorrências'), findsOneWidget);
    expect(find.text('p. 1'), findsNWidgets(2));
    final copy = kit.copies.last.$1;
    expect(File(copy).existsSync(), isTrue, reason: 'a cópia vive enquanto a busca está aberta');
    await tester.tap(find.textContaining('posto', findRichText: true));
    await tester.pumpAndSettle();
    expect(find.byType(CommandPalette), findsNothing);
    expect(kit.unoCommands.last, '.uno:ExecuteSearch');
    expect(kit.unoArgs.last, contains(r'(?<=Na )estrada(?=, o posto\\.)'));
    expect(File(copy).existsSync(), isFalse, reason: 'fechou, a cópia saiu');
  });

  testWidgets('os comandos continuam: "negrito" acha e roda', (tester) async {
    await pumpApp(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    await typeAndWait(tester, 'negrito');
    expect(find.text('Comandos'), findsOneWidget);
    expect(find.text('Nada no documento'), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(kit.unoCommands.last, '.uno:Bold');
  });

  testWidgets('"com opções" abre o painel Localizar e substituir com a palavra', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Pesquisar no texto e nos comandos'));
    await tester.pumpAndSettle();
    await typeAndWait(tester, 'estrada');
    await tester.tap(find.text('Localizar e substituir, com opções…'));
    await tester.pumpAndSettle();
    expect(find.byType(FindBar), findsOneWidget);
    expect(find.widgetWithText(TextField, 'estrada'), findsWidgets);
  });
}
