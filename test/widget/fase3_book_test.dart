// O modo Livro (Fase 3, Etapa 1, D-071): o fichário no trilho, abrir os
// capítulos, o teclado, o título da janela, a barra de status, a tela
// inicial e os recentes.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/app.dart';
import 'package:psito_quill/src/book/book.dart';
import 'package:psito_quill/src/book/book_io.dart';
import 'package:psito_quill/src/ui/organisms/binder_panel.dart';
import 'package:psito_quill/src/ui/organisms/nav_rail.dart';

import '../support/harness.dart';

void main() {
  Harness? current;

  /// Um livro com um capítulo solto e uma parte com dois.
  String makeBook(Harness h) {
    final dir = '${h.dir.path}/Dustland.psitobook';
    createBookDir(dir);
    for (final f in ['001-abertura', '002-a-poeira', '003-o-poco']) {
      File('$dir/capitulos/$f.odt').writeAsStringSync('');
    }
    writeBook(
      dir,
      Book(title: 'Dustland', nodes: [
        BookNode(id: 'a', kind: BookNodeKind.chapter, title: 'Abertura', file: 'capitulos/001-abertura.odt', words: 100),
        BookNode(id: 'p', kind: BookNodeKind.part, title: 'Parte I', children: [
          BookNode(id: 'b', kind: BookNodeKind.chapter, title: 'A poeira', file: 'capitulos/002-a-poeira.odt', words: 2000),
          BookNode(id: 'c', kind: BookNodeKind.chapter, title: 'O poço', file: 'capitulos/003-o-poco.odt', words: 3000),
        ]),
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

  Future<void> openBook(WidgetTester tester, Harness h, String dir) async {
    await tester.runAsync(() => h.workspace.openPath(dir));
    await tester.pump();
    await tester.pump();
  }

  tearDown(() {
    current?.dispose();
    current = null;
  });

  testWidgets('abrir um livro: o fichário no trilho, o primeiro capítulo numa aba e o título', (tester) async {
    final h = await pumpApp(tester);
    final dir = makeBook(h);
    await openBook(tester, h, dir);
    expect(h.doc.path, '$dir/capitulos/001-abertura.odt');
    expect(find.byType(BinderPanel), findsOneWidget);
    final rail = tester.widget<NavRail<Object?>>(find.byWidgetPredicate((w) => w is NavRail && w.label == 'Painéis'));
    expect(rail.items.first.label, 'Fichário');
    expect(h.window.titles.last, 'Dustland — Abertura — Psito Quill');
    expect(h.recents.paths.first, dir, reason: 'o livro entra nos recentes');
    expect(h.recents.paths, isNot(contains('$dir/capitulos/001-abertura.odt')), reason: 'os capítulos não');
    // O livro inteiro: 5.100 no livro.json, com a Abertura (100) pelo que o
    // motor conta agora (o falso abre com 0 palavras).
    expect(find.text('livro 5.000'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('o clique abre o capítulo; o aberto fica marcado para o leitor de tela', (tester) async {
    final h = await pumpApp(tester);
    final dir = makeBook(h);
    await openBook(tester, h, dir);
    await tester.tap(find.text('O poço'));
    await tester.pump();
    await tester.pump();
    expect(h.doc.path, '$dir/capitulos/003-o-poco.odt');
    expect(h.doc.tabs.length, 2, reason: 'cada capítulo numa aba (D-054)');
    expect(
      find.bySemanticsLabel(RegExp(r'^O poço, Rascunho, 3000 palavras$')),
      findsOneWidget,
    );
    expect(h.window.titles.last, 'Dustland — O poço — Psito Quill');
  });

  testWidgets('o teclado: Alt+setas move, F2 renomeia, Delete manda para a lixeira', (tester) async {
    final h = await pumpApp(tester);
    final dir = makeBook(h);
    await openBook(tester, h, dir);
    final book = h.workspace.book;

    await tester.tap(find.text('Abertura'));
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pump();
    expect(book.book!.nodes.first.title, 'Parte I');
    expect(book.book!.nodes.first.children.first.title, 'Abertura', reason: 'descer sobre a parte entra nela');
    expect(readBook(dir).nodes.first.children.first.id, 'a', reason: 'grava na hora');

    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.pump();
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'Prólogo');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(book.book!.find('a')!.$1.title, 'Prólogo');

    await tester.tap(find.text('A poeira'));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();
    expect(find.text('Mandar para a lixeira?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Mandar para a lixeira'));
    await tester.pumpAndSettle();
    expect(book.book!.find('b'), isNull);
    expect(File('$dir/lixeira/002-a-poeira.odt').existsSync(), isTrue);
  });

  testWidgets('o item escolhido: o status, o rótulo e a sinopse', (tester) async {
    final h = await pumpApp(tester);
    final dir = makeBook(h);
    await openBook(tester, h, dir);
    await tester.tap(find.text('A poeira'));
    await tester.pump();
    await tester.tap(find.descendant(of: find.byType(BinderPanel), matching: find.text('Revisão')));
    await tester.pump();
    await tester.tap(find.descendant(of: find.byType(BinderPanel), matching: find.byTooltip('Verde')));
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, 'Eles chegam à cidade.');
    await tester.pump(const Duration(milliseconds: 700));
    final b = readBook(dir).find('b')!.$1;
    expect((b.status, b.label, b.synopsis), (ChapterStatus.revision, 2, 'Eles chegam à cidade.'));
  });

  testWidgets('a tela inicial tem o livro novo e a importação; o livro aparece nos recentes', (tester) async {
    final h = await pumpApp(tester);
    final dir = makeBook(h);
    h.recents.add(dir);
    await tester.pump();
    expect(find.bySemanticsLabel('Novo livro'), findsOneWidget);
    expect(find.bySemanticsLabel('Importar um manuscrito'), findsOneWidget);
    expect(find.text('Dustland.psitobook'), findsOneWidget, reason: 'o nome da pasta do livro');
    expect(find.text('Não encontrado'), findsNothing, reason: 'a data vem do livro.json');
  });

  testWidgets('fechar o livro fecha as abas dele e o fichário', (tester) async {
    final h = await pumpApp(tester);
    final dir = makeBook(h);
    await openBook(tester, h, dir);
    await tester.runAsync(() => h.workspace.closeBook());
    await tester.pump();
    await tester.pump();
    expect(h.workspace.book.isOpen, isFalse);
    expect(h.doc.tabs, isEmpty);
    expect(find.byType(BinderPanel), findsNothing);
  });

  group('soltar no fichário (binderDrop)', () {
    Book book() => Book(title: 'x', nodes: [
          BookNode(id: 'a', kind: BookNodeKind.chapter, title: 'A'),
          BookNode(id: 'p', kind: BookNodeKind.part, title: 'P', children: [
            BookNode(id: 'b', kind: BookNodeKind.chapter, title: 'B'),
            BookNode(id: 'c', kind: BookNodeKind.chapter, title: 'C'),
          ]),
          BookNode(id: 'd', kind: BookNodeKind.chapter, title: 'D'),
        ]);
    // As linhas: A(0) P(1) B(2) C(3) D(4).

    test('um capítulo logo abaixo da parte entra nela', () {
      final b = book();
      expect(binderDrop(b, binderRows(b), 4, 2), (partId: 'p', index: 0));
    });
    test('abaixo de um capítulo da parte, fica na parte depois dele', () {
      final b = book();
      expect(binderDrop(b, binderRows(b), 0, 3), (partId: 'p', index: 1));
    });
    test('no topo, o primeiro do livro', () {
      final b = book();
      expect(binderDrop(b, binderRows(b), 3, 0), (partId: null, index: 0));
    });
    test('uma parte vai sempre para o primeiro nível, depois de quem está acima', () {
      final b = book();
      expect(binderDrop(b, binderRows(b), 1, 5), (partId: null, index: 3));
      expect(binderDrop(b, binderRows(b), 1, 0), (partId: null, index: 0));
    });
  });
}
