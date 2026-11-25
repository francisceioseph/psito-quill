// Os comentários (Fase 4, Etapa 3, D-088): o painel (comentar, responder,
// resolver, os resolvidos escondidos, excluir, ir ao trecho), o Ctrl+Alt+C,
// a marca na página e a contagem no fichário.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/app.dart';
import 'package:psito_quill/src/book/book.dart';
import 'package:psito_quill/src/book/book_io.dart';
import 'package:psito_quill/src/kit/quill_kit.dart';
import 'package:psito_quill/src/ui/organisms/comments_panel.dart';

import '../support/harness.dart';

void main() {
  Harness? current;

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

  Finder inPanel(Finder f) => find.descendant(of: find.byType(CommentsPanel), matching: f);
  Finder field(String hintOrLabel) => inPanel(find.byWidgetPredicate(
      (w) => w is TextField && (w.decoration?.hintText == hintOrLabel || w.decoration?.labelText == hintOrLabel)));
  Finder button(String label) => inPanel(find.bySemanticsLabel(label));

  Future<void> ctrlAltC(WidgetTester tester) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
  }

  testWidgets('comentar, responder, resolver, os resolvidos, excluir e ir ao trecho', (tester) async {
    final h = await pumpApp(tester);
    h.doc.author = 'Ana Souza';
    expect(h.kit.author, 'Ana Souza');
    h.doc.open('/livro/cap.odt');
    await tester.pumpAndSettle();
    expect(h.kit.requestedValues, contains('.uno:ViewAnnotations'));

    // Ctrl+Alt+C abre o painel com o foco no campo.
    await ctrlAltC(tester);
    expect(find.byType(CommentsPanel), findsOneWidget);
    expect(find.textContaining('Nenhum comentário neste capítulo'), findsOneWidget);
    final newField = field('Selecione um trecho e escreva aqui');
    expect(tester.widget<TextField>(newField).focusNode?.hasFocus, isTrue);

    await tester.enterText(newField, 'Gato ou cão?');
    await tester.tap(button('Comentar'));
    await tester.pumpAndSettle();
    expect(h.kit.unoCommands, contains('.uno:InsertAnnotation'));
    expect(h.kit.unoArgs.last, contains('Gato ou cão?'));
    expect(inPanel(find.text('Gato ou cão?')), findsOneWidget);
    expect(inPanel(find.textContaining('Ana Souza')), findsOneWidget);
    expect(h.doc.comments.single.range, isNotEmpty);
    // A marca do trecho na página.
    expect(
        find.byWidgetPredicate((w) =>
            w is DecoratedBox && w.decoration is BoxDecoration && (w.decoration as BoxDecoration).border is Border),
        findsWidgets);

    // Responder.
    await tester.tap(button('Responder').first);
    await tester.pumpAndSettle();
    await tester.enterText(field('Resposta'), 'Gato.');
    await tester.tap(button('Responder').last);
    await tester.pumpAndSettle();
    expect(h.kit.unoCommands, contains('.uno:ReplyComment'));
    expect(inPanel(find.text('Gato.')), findsOneWidget);
    expect(h.doc.comments, hasLength(2));

    // Ir ao trecho: um clique no começo dele.
    h.kit.mice.clear();
    await tester.tap(inPanel(find.text('Gato ou cão?')));
    await tester.pumpAndSettle();
    expect(h.kit.mice.map((m) => m.$1), [MouseEventType.down, MouseEventType.up]);
    expect(h.kit.mice.first.$2, 5124);

    // Resolver: a conversa some, e a caixa dos resolvidos aparece.
    await tester.tap(button('Resolver'));
    await tester.pumpAndSettle();
    expect(inPanel(find.text('Gato ou cão?')), findsNothing);
    expect(find.textContaining('Todos os comentários estão resolvidos'), findsOneWidget);
    await tester.tap(inPanel(find.text('Mostrar os resolvidos (1)')));
    await tester.pumpAndSettle();
    expect(inPanel(find.text('Gato ou cão?')), findsOneWidget);
    await tester.tap(button('Reabrir'));
    await tester.pumpAndSettle();
    expect(h.doc.comments.first.resolved, isFalse);

    // Excluir a conversa: a resposta e o comentário.
    await tester.tap(button('Excluir a conversa'));
    await tester.pumpAndSettle();
    expect(h.kit.unoCommands.where((c) => c == '.uno:DeleteComment'), hasLength(2));
    expect(h.doc.comments, isEmpty);
    expect(find.textContaining('Nenhum comentário neste capítulo'), findsOneWidget);
  });

  testWidgets('no modo só leitura, sem o campo nem os botões', (tester) async {
    final h = await pumpApp(tester);
    h.doc.open('/livro/cap.odt');
    await tester.pumpAndSettle();
    h.kit.uno('.uno:InsertAnnotation', '{"Text":{"type":"string","value":"Velho"}}');
    h.doc.readOnly = true;
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Comentários').first);
    await tester.pumpAndSettle();
    expect(inPanel(find.text('Velho')), findsOneWidget);
    expect(field('Selecione um trecho e escreva aqui'), findsNothing);
    expect(button('Resolver'), findsNothing);
  });

  testWidgets('o fichário conta os comentários abertos de cada capítulo', (tester) async {
    final h = await pumpApp(tester);
    final dir = '${h.dir.path}/Dustland.psitobook';
    createBookDir(dir);
    for (final f in ['001-abertura', '002-a-poeira']) {
      File('test/fixtures/capitulo-curto.odt').copySync('$dir/capitulos/$f.odt');
    }
    final stamp = File('$dir/capitulos/002-a-poeira.odt').lastModifiedSync().millisecondsSinceEpoch;
    writeBook(
      dir,
      Book(title: 'Dustland', nodes: [
        BookNode(id: 'a', kind: BookNodeKind.chapter, title: 'Abertura', file: 'capitulos/001-abertura.odt'),
        BookNode(
            id: 'b',
            kind: BookNodeKind.chapter,
            title: 'A poeira',
            file: 'capitulos/002-a-poeira.odt',
            wordsStamp: stamp,
            comments: 2),
      ]),
    );
    await tester.runAsync(() => h.workspace.openPath(dir));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp(r'^A poeira.*2 comentários abertos')), findsOneWidget);
  });
}
