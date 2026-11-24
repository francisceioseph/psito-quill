// A cortiça (Fase 3, Etapa 10, D-084): os capítulos como cartões no lugar
// da página, a mesma árvore do fichário (arrastar e Alt+setas reordenam), a
// sinopse no cartão, o escopo de uma parte e o duplo clique que abre.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/l10n/gen/app_localizations_pt.dart';
import 'package:psito_quill/src/app.dart';
import 'package:psito_quill/src/book/book.dart';
import 'package:psito_quill/src/book/book_io.dart';
import 'package:psito_quill/src/commands/commands_book.dart';
import 'package:psito_quill/src/commands/menus.dart';
import 'package:psito_quill/src/ui/organisms/corkboard.dart';
import 'package:psito_quill/src/ui/organisms/document_view.dart';

import '../support/harness.dart';

void main() {
  Harness? current;

  String makeBook(Harness h) {
    final dir = '${h.dir.path}/Dustland.psitobook';
    createBookDir(dir);
    for (final f in ['001-abertura', '002-a-poeira', '003-o-poco']) {
      File('test/fixtures/capitulo-curto.odt').copySync('$dir/capitulos/$f.odt');
    }
    writeBook(
      dir,
      Book(title: 'Dustland', nodes: [
        BookNode(id: 'a', kind: BookNodeKind.chapter, title: 'Abertura', file: 'capitulos/001-abertura.odt', synopsis: 'A Ana chega.'),
        BookNode(id: 'p', kind: BookNodeKind.part, title: 'Parte dois', children: [
          BookNode(id: 'b', kind: BookNodeKind.chapter, title: 'A poeira', file: 'capitulos/002-a-poeira.odt'),
          BookNode(id: 'c', kind: BookNodeKind.chapter, title: 'O poço', file: 'capitulos/003-o-poco.odt', label: 1),
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

  tearDown(() {
    current?.dispose();
    current = null;
  });

  Finder card(String title) => find.descendant(of: find.byType(Corkboard), matching: find.text(title));
  List<String> order(Harness h) => [for (final c in h.workspace.book.book!.chapters) c.id];

  Future<void> openCork(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel('Cortiça').first);
    await tester.pumpAndSettle();
    expect(find.byType(Corkboard), findsOneWidget);
  }

  testWidgets('os cartões no lugar da página; arrastar e Alt+setas reordenam', (tester) async {
    final h = await pumpApp(tester);
    final dir = makeBook(h);
    await tester.runAsync(() => h.workspace.openPath(dir));
    await tester.pump();
    // Pelo fichário (que abre com o livro).
    await openCork(tester);
    expect(find.byType(DocumentView), findsNothing, reason: 'a página sai da tela');
    expect(card('Abertura'), findsOneWidget);
    expect(card('A Ana chega.'), findsOneWidget);
    expect(card('Sem sinopse'), findsNWidgets(2));

    // Arrastar o "O poço" para o lugar da "Abertura": vai para o primeiro nível, antes dela.
    final g = await tester.startGesture(tester.getCenter(card('O poço')));
    await tester.pump(const Duration(milliseconds: 50));
    await g.moveTo(tester.getCenter(card('Abertura')));
    await tester.pump();
    await g.up();
    await tester.pumpAndSettle();
    expect(order(h), ['c', 'a', 'b']);
    expect(h.workspace.book.book!.parentOf('c'), isNull);

    // Pelo teclado: o foco está no cartão que se moveu; Alt+→ o leva de volta um passo.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pumpAndSettle();
    expect(order(h), ['a', 'c', 'b']);
    // Gravado no livro.json.
    expect([for (final c in readBook(dir).chapters) c.id], ['a', 'c', 'b']);

    // F2 edita a sinopse; Ctrl+Enter grava.
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.pumpAndSettle();
    await tester.enterText(find.descendant(of: find.byType(Corkboard), matching: find.byType(EditableText)), 'O poço seca.');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(h.workspace.book.book!.find('c')!.$1.synopsis, 'O poço seca.');
    expect(card('O poço seca.'), findsOneWidget);

    // Esc volta à página.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(Corkboard), findsNothing);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('o escopo de uma parte e o duplo clique que abre o capítulo', (tester) async {
    final h = await pumpApp(tester);
    final dir = makeBook(h);
    await tester.runAsync(() => h.workspace.openPath(dir));
    await tester.pump();
    await openCork(tester);

    await tester.tap(find.text('Todos os capítulos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Parte dois').last);
    await tester.pumpAndSettle();
    expect(card('Abertura'), findsNothing);
    expect(card('A poeira'), findsOneWidget);

    await tester.tap(card('A poeira'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(card('A poeira'));
    await tester.pumpAndSettle();
    expect(find.byType(Corkboard), findsNothing);
    expect(h.doc.path, endsWith('002-a-poeira.odt'));
    await tester.pump(const Duration(seconds: 3));
  });

  test('onde um cartão cai', () {
    final book = Book(title: 'D', nodes: [
      BookNode(id: 'a', kind: BookNodeKind.chapter, title: 'a'),
      BookNode(id: 'p', kind: BookNodeKind.part, title: 'p', children: [
        BookNode(id: 'b', kind: BookNodeKind.chapter, title: 'b'),
        BookNode(id: 'c', kind: BookNodeKind.chapter, title: 'c'),
      ]),
    ]);
    final cards = corkCards(book, null);
    expect(cards.map((c) => c.id), ['a', 'b', 'c']);
    expect(corkCards(book, 'p').map((c) => c.id), ['b', 'c']);
    expect(corkDrop(book, cards, 0, 2), (partId: 'p', index: 2), reason: 'para a frente: depois do destino');
    expect(corkDrop(book, cards, 2, 0), (partId: null, index: 0), reason: 'para trás: antes');
  });

  test('o menu Livro do Clássico 97 tem a cortiça', () {
    final book = editorMenus(AppLocalizationsPt()).firstWhere((m) => m.items.contains(BookCommandIds.newChapter));
    expect(book.items, contains(BookCommandIds.corkboard));
  });
}
