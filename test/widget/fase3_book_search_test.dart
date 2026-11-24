// A busca no livro (Fase 3, Etapa 6, D-080): "No livro" no painel
// Localizar lista as ocorrências de todos os capítulos, agrupadas; o clique
// abre o capítulo e seleciona; o capítulo da tela com alterações vale o do
// motor.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/app.dart';
import 'package:psito_quill/src/book/book.dart';
import 'package:psito_quill/src/book/book_io.dart';
import 'package:psito_quill/src/ui/organisms/find_panel.dart';

import '../support/harness.dart';

void main() {
  Harness? current;

  String makeBook(Harness h) {
    final dir = '${h.dir.path}/Dustland.psitobook';
    createBookDir(dir);
    for (final f in ['001-abertura', '002-a-poeira']) {
      File('test/fixtures/capitulo-curto.odt').copySync('$dir/capitulos/$f.odt');
    }
    writeBook(
      dir,
      Book(title: 'Dustland', nodes: [
        BookNode(id: 'a', kind: BookNodeKind.chapter, title: 'Abertura', file: 'capitulos/001-abertura.odt'),
        BookNode(id: 'b', kind: BookNodeKind.chapter, title: 'A poeira', file: 'capitulos/002-a-poeira.odt'),
      ]),
    );
    return dir;
  }

  Future<Harness> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1500, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.localesTestValue = [const Locale('pt', 'BR')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final h = current = Harness();
    await tester.pumpWidget(QuillApp(workspace: h.workspace, settings: h.settings, window: h.window, showMemory: false));
    await tester.pump();
    return h;
  }

  tearDown(() {
    current?.dispose();
    current = null;
  });

  Future<void> openFind(WidgetTester tester) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyU);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.descendant(of: find.byType(FindPanel), matching: find.byType(EditableText)).first, text);
    await tester.pump(const Duration(milliseconds: 550));
    // O isolate lê os capítulos.
    for (var i = 0; i < 20 && find.text('Procurando no documento…').evaluate().isNotEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
    }
  }

  testWidgets('"No livro" agrupa por capítulo; o clique abre o outro capítulo e seleciona', (tester) async {
    final h = await pumpApp(tester);
    final dir = makeBook(h);
    await tester.runAsync(() => h.workspace.openPath(dir));
    await tester.pump();
    // O capítulo da tela vem da cópia do motor (o falso); o outro, do arquivo.
    h.kit.bodyParagraphs = ['O vento da abertura.'];
    await openFind(tester);
    expect(find.text('Neste capítulo'), findsOneWidget);
    await tester.tap(find.text('No livro'));
    await tester.pump();
    await type(tester, 'vento');
    expect(find.bySemanticsLabel(RegExp(r'^Abertura, 1 ocorrência$')), findsOneWidget);
    // Só as linhas visíveis existem: o segundo capítulo aparece rolando.
    final list = find.descendant(of: find.byType(FindPanel), matching: find.byType(Scrollable)).last;
    await tester.scrollUntilVisible(
      find.descendant(of: find.byType(FindPanel), matching: find.text('A poeira')),
      300,
      scrollable: list,
    );
    expect(find.bySemanticsLabel(RegExp(r'^A poeira, \d+ ocorrências$')), findsWidgets);
    await tester.drag(list, const Offset(0, -150));
    await tester.pump();
    expect(find.text('7 ocorrências em 2 capítulos'), findsOneWidget);

    final hit = find.bySemanticsLabel(RegExp(r'vento.*, A poeira, página 1$')).first;
    final searches = h.kit.unoCommands.where((c) => c == '.uno:ExecuteSearch').length;
    await tester.tap(hit);
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    await tester.pump();
    expect(h.doc.path, endsWith('002-a-poeira.odt'));
    final after = h.kit.unoCommands.where((c) => c == '.uno:ExecuteSearch').length;
    expect(after, greaterThan(searches), reason: 'a ocorrência é selecionada quando o capítulo abre');
    expect(h.kit.unoArgs.lastWhere((a) => a.contains('SearchItem')), contains('vento'));
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('o capítulo da tela com alterações vale o do motor; a expressão que não vale avisa', (tester) async {
    final h = await pumpApp(tester);
    final dir = makeBook(h);
    await tester.runAsync(() => h.workspace.openPath(dir));
    await tester.pump();
    h.kit.bodyParagraphs = ['O xilofone tocou na estrada.'];
    h.doc.insertText('x');
    await tester.pump();
    expect(h.doc.modified, isTrue);
    await openFind(tester);
    await tester.tap(find.text('No livro'));
    await tester.pump();
    await type(tester, 'xilofone');
    // Só no capítulo da tela, pela cópia do motor: o arquivo não tem.
    expect(find.text('1 ocorrência em 1 capítulo'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'xilofone.*, Abertura, página 1$')), findsOneWidget);

    await tester.tap(find.byTooltip('Expressão regular'));
    await type(tester, '(xilo');
    expect(find.text('A expressão regular não vale'), findsOneWidget);

    // De volta ao capítulo: a mesma pergunta, na cópia da tela.
    await tester.tap(find.byTooltip('Expressão regular'));
    await tester.tap(find.text('Neste capítulo'));
    await type(tester, 'xilofone');
    expect(find.text('1 ocorrência'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });
}
