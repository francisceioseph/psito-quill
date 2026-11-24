// O painel Notas (Fase 3, Etapa 8, D-082): pelo trilho, nova nota, gravar
// sozinho, as ligações (criar, abrir a nota, abrir o capítulo), as menções,
// o filtro e a linha do tempo.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/l10n/gen/app_localizations_pt.dart';
import 'package:psito_quill/src/app.dart';
import 'package:psito_quill/src/book/book.dart';
import 'package:psito_quill/src/book/book_io.dart';
import 'package:psito_quill/src/book/notes.dart';
import 'package:psito_quill/src/commands/commands_book.dart';
import 'package:psito_quill/src/commands/menus.dart';
import 'package:psito_quill/src/ui/organisms/notes_panel.dart';

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

  Finder inPanel(Finder f) => find.descendant(of: find.byType(NotesPanel), matching: f);
  Finder field(String label) => inPanel(find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == label));
  NotesPanelState panel(WidgetTester tester) => tester.state<NotesPanelState>(find.byType(NotesPanel));

  testWidgets('nova nota, gravar sozinho, as ligações e as menções', (tester) async {
    final h = await pumpApp(tester);
    final dir = makeBook(h);
    await tester.runAsync(() => h.workspace.openPath(dir));
    await tester.pump();

    // Pelo trilho.
    await tester.tap(find.text('Notas').first);
    await tester.pumpAndSettle();
    expect(find.byType(NotesPanel), findsOneWidget);
    expect(find.textContaining('Nenhuma nota ainda'), findsOneWidget);

    // A busca vira o nome da nota nova.
    await tester.enterText(field('Buscar nas notas'), 'Ana Ruiz');
    await tester.tap(find.bySemanticsLabel('Nova nota').first);
    await tester.pumpAndSettle();
    expect(panel(tester).openNote?.name, 'Ana Ruiz');
    expect(File('$dir/notas/ana-ruiz.md').existsSync(), isTrue);

    await tester.enterText(field('Apelidos, separados por vírgula'), 'Ruiva');
    await tester.enterText(field('Escreva aqui. [[Nome]] liga a outra nota ou a um capítulo.'),
        'Nasceu em [[Poço Fundo]]. Aparece em [[A poeira]].');
    await tester.pump();
    // Ctrl+Z no campo é do campo, não do capítulo.
    h.kit.emitState('.uno:Undo', 'enabled');
    await tester.pump();
    expect(h.doc.canUndo, isTrue);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(h.kit.unoCommands, isNot(contains('.uno:Undo')));
    expect(find.text('Criar Poço Fundo'), findsOneWidget);
    expect(find.text('A poeira'), findsWidgets);
    // Grava sozinho, 1 s depois.
    await tester.pump(const Duration(milliseconds: 1100));
    final saved = parseNote('ana-ruiz.md', File('$dir/notas/ana-ruiz.md').readAsStringSync());
    expect(saved.aliases, ['Ruiva']);
    expect(saved.body, contains('[[Poço Fundo]]'));

    // Uma ligação que não existe cria a nota e abre.
    await tester.tap(find.text('Criar Poço Fundo'));
    await tester.pumpAndSettle();
    expect(panel(tester).openNote?.name, 'Poço Fundo');
    expect(File('$dir/notas/poco-fundo.md').existsSync(), isTrue);
    // A Ana menciona o Poço.
    expect(find.text('Mencionada em'), findsOneWidget);
    await tester.tap(inPanel(find.text('Ana Ruiz')));
    await tester.pumpAndSettle();
    expect(panel(tester).openNote?.name, 'Ana Ruiz');

    // A ligação a um capítulo abre o capítulo.
    await tester.tap(inPanel(find.text('A poeira')));
    await tester.pumpAndSettle();
    expect(h.doc.path, endsWith('002-a-poeira.odt'));

    // A lista: o filtro pelo tipo e a busca pelo apelido.
    await tester.tap(find.bySemanticsLabel('Voltar às notas'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Buscar nas notas'), '');
    await tester.pump();
    expect(inPanel(find.text('Ana Ruiz')), findsOneWidget);
    expect(inPanel(find.text('Poço Fundo')), findsOneWidget);
    await tester.tap(inPanel(find.text('Lugares')));
    await tester.pump();
    expect(inPanel(find.text('Ana Ruiz')), findsNothing);
    await tester.tap(inPanel(find.text('Todas')));
    await tester.enterText(field('Buscar nas notas'), 'ruiva');
    await tester.pump();
    expect(inPanel(find.text('Ana Ruiz')), findsOneWidget);
    expect(inPanel(find.text('Poço Fundo')), findsNothing);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('a linha do tempo mostra os eventos; apagar manda para a lixeira', (tester) async {
    final h = await pumpApp(tester);
    final dir = makeBook(h);
    writeNote(
      dir,
      const Note(file: 'tempo.md', name: 'Cronologia', kind: NoteKind.timeline, body: '- Ano 1: o poço seca\n- Ano 3: a Poeira chega'),
    );
    await tester.runAsync(() => h.workspace.openPath(dir));
    await tester.pump();
    await tester.tap(find.text('Notas').first);
    await tester.pumpAndSettle();
    expect(inPanel(find.text('Cronologia')), findsOneWidget);
    await tester.tap(inPanel(find.text('Cronologia')));
    await tester.pumpAndSettle();
    // Com eventos, abre na vista da linha do tempo.
    expect(inPanel(find.text('Ano 1')), findsOneWidget);
    expect(inPanel(find.text('a Poeira chega')), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Mandar a nota para a lixeira'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Mandar para a lixeira'));
    await tester.pumpAndSettle();
    expect(File('$dir/notas/tempo.md').existsSync(), isFalse);
    expect(File('$dir/lixeira/tempo.md').existsSync(), isTrue);
    expect(find.textContaining('Nenhuma nota ainda'), findsOneWidget);

    // O trilho fecha o painel aberto.
    await tester.tap(find.text('Notas').first);
    await tester.pumpAndSettle();
    expect(find.byType(NotesPanel), findsNothing);
    await tester.pump(const Duration(seconds: 3));
  });

  test('o menu Livro do Clássico 97 tem as notas', () {
    final book = editorMenus(AppLocalizationsPt()).firstWhere((m) => m.items.contains(BookCommandIds.newChapter));
    expect(book.items, containsAllInOrder([BookCommandIds.notes, BookCommandIds.newNote, BookCommandIds.closeBook]));
  });
}
