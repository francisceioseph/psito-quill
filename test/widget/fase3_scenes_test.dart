// As cenas no fichário (Fase 3, Etapa 5, D-079): as de um capítulo fechado
// vêm do livro.json e abrem pela seta ou pela tecla →; o clique abre o
// capítulo; o menu Livro tem os comandos; e o soltar ignora as linhas de
// cena.
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
import 'package:psito_quill/src/ui/organisms/binder_panel.dart';

import '../support/harness.dart';

void main() {
  Harness? current;

  String makeBook(Harness h) {
    final dir = '${h.dir.path}/Dustland.psitobook';
    createBookDir(dir);
    for (final f in ['001-abertura', '002-a-poeira']) {
      File('$dir/capitulos/$f.odt').writeAsStringSync('');
    }
    writeBook(
      dir,
      Book(title: 'Dustland', nodes: [
        BookNode(id: 'a', kind: BookNodeKind.chapter, title: 'Abertura', file: 'capitulos/001-abertura.odt'),
        BookNode(
          id: 'b',
          kind: BookNodeKind.chapter,
          title: 'A poeira',
          file: 'capitulos/002-a-poeira.odt',
          words: 2000,
          scenes: ['A estrada vazia', 'O vento parou'],
        ),
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

  testWidgets('as cenas de um capítulo fechado: → mostra, o clique abre o capítulo, ← esconde', (tester) async {
    final h = await pumpApp(tester);
    final dir = makeBook(h);
    await tester.runAsync(() => h.workspace.openPath(dir));
    await tester.pump();
    await tester.pump();
    // Fechadas: o capítulo diz quantas tem, e as linhas não estão lá.
    expect(find.bySemanticsLabel(RegExp(r'^A poeira, Rascunho, 2000 palavras, 2 cenas$')), findsOneWidget);
    expect(find.text('A estrada vazia'), findsNothing);
    expect(h.doc.isOn('.uno:ModifiedStatus'), isFalse);

    await tester.tap(find.text('Abertura'));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(find.text('A estrada vazia'), findsOneWidget);
    expect(find.text('O vento parou'), findsOneWidget);
    expect(find.bySemanticsLabel('Cena 2, O vento parou'), findsOneWidget);
    expect(h.doc.path, '$dir/capitulos/001-abertura.odt', reason: 'a seta só mostra, não abre');

    await tester.tap(find.text('O vento parou'));
    await tester.pump();
    await tester.pump();
    expect(h.doc.path, '$dir/capitulos/002-a-poeira.odt');

    // ← numa cena volta ao capítulo e esconde as cenas (o capítulo da tela
    // começa com elas à mostra; as dele vêm da cópia, que o falso não tem).
    await tester.tap(find.text('Abertura'));
    await tester.pump();
    await tester.pump();
    expect(find.text('A estrada vazia'), findsOneWidget);
    await tester.tap(find.text('A estrada vazia'));
    await tester.pump();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(find.text('A estrada vazia'), findsNothing);
    expect(tester.takeException(), isNull);
    // Os timers da interface (as dicas, a pausa da Estrutura ao vivo) terminam.
    await tester.pump(const Duration(seconds: 3));
  });

  test('o menu Livro do Clássico 97 tem os comandos das cenas, e o Inserir a nova cena', () {
    final menus = editorMenus(AppLocalizationsPt());
    final book = menus.firstWhere((m) => m.items.contains(BookCommandIds.newChapter));
    expect(menus.firstWhere((m) => m.title == 'Inserir').items, contains(BookCommandIds.newScene));
    expect(
      book.items,
      containsAllInOrder([
        BookCommandIds.newScene,
        BookCommandIds.splitChapter,
        BookCommandIds.joinChapter,
        BookCommandIds.convertScenes,
      ]),
    );
  });

  group('soltar com as cenas à mostra', () {
    Book book() => Book(title: 'x', nodes: [
          BookNode(id: 'a', kind: BookNodeKind.chapter, title: 'A', scenes: ['1', '2']),
          BookNode(id: 'b', kind: BookNodeKind.chapter, title: 'B'),
          BookNode(id: 'c', kind: BookNodeKind.chapter, title: 'C'),
        ]);
    // As linhas: A(0) a1(1) a2(2) B(3) C(4).
    List<BinderRow> rows(Book b) => binderRows(b, scenesOf: (c) => c.scenes.length);

    test('as cenas ficam embaixo do capítulo delas', () {
      final b = book();
      expect([for (final r in rows(b)) r.scene], [null, 0, 1, null, null]);
    });
    test('soltar entre as cenas de A cai depois de A', () {
      final b = book();
      expect(binderDrop(b, rows(b), 4, 2), (partId: null, index: 1));
    });
    test('A com as cenas dele, solto embaixo de B', () {
      final b = book();
      expect(binderDrop(b, rows(b), 0, 4), (partId: null, index: 2));
    });
  });
}
