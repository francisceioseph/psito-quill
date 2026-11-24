// O compilar (Fase 4, Etapa 1, D-086): a janela (os capítulos, o filtro dos
// prontos, o leitor de tela), o andamento e o aviso no fim; o comando nos
// menus.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/l10n/gen/app_localizations_pt.dart';
import 'package:psito_quill/src/app.dart';
import 'package:psito_quill/src/book/book.dart';
import 'package:psito_quill/src/book/book_io.dart';
import 'package:psito_quill/src/commands/commands_book.dart';
import 'package:psito_quill/src/commands/menus.dart';
import 'package:psito_quill/src/ui/atoms/w_checkbox.dart';
import 'package:psito_quill/src/ui/organisms/compile_dialog.dart';
import 'package:psito_quill/src/ui/pages/editor_page.dart';

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
      Book(title: 'Dustland', author: 'Fulano', nodes: [
        BookNode(id: 'a', kind: BookNodeKind.chapter, title: 'Abertura', file: 'capitulos/001-abertura.odt', status: ChapterStatus.done),
        BookNode(id: 'p', kind: BookNodeKind.part, title: 'Parte dois', children: [
          BookNode(id: 'b', kind: BookNodeKind.chapter, title: 'A poeira', file: 'capitulos/002-a-poeira.odt'),
          BookNode(id: 'c', kind: BookNodeKind.chapter, title: 'O poço', file: 'capitulos/003-o-poco.odt', status: ChapterStatus.done),
        ]),
      ]),
    );
    return dir;
  }

  Future<Harness> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1500, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.localesTestValue = [const Locale('pt', 'BR')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final h = current = Harness();
    // O motor falso: cada capítulo sai num FODT de verdade, e o livro
    // "gravado" é o FODT juntado.
    h.kit.onConvert = (source, target, format) {
      if (format == 'fodt') {
        File('test/fixtures/livro-teste.fodt').copySync(target);
      } else {
        File(source).copySync(target);
      }
    };
    await tester.pumpWidget(QuillApp(workspace: h.workspace, settings: h.settings, window: h.window, showMemory: false));
    await tester.pump();
    return h;
  }

  tearDown(() {
    current?.dispose();
    current = null;
  });

  Future<void> settleUntil(WidgetTester tester, bool Function() done) async {
    for (var i = 0; i < 200 && !done(); i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
    }
  }

  testWidgets('a janela, o filtro dos prontos e o livro compilado', (tester) async {
    final h = await pumpApp(tester);
    final dir = makeBook(h);
    await tester.runAsync(() => h.workspace.openPath(dir));
    await tester.pump();

    (tester.state(find.byType(EditorPage)) as BookViewActions).compileBook();
    await tester.pumpAndSettle();
    expect(find.byType(CompileDialog), findsOneWidget);
    expect(find.text('Compilar Dustland'), findsOneWidget);
    expect(find.textContaining('3 de 3 capítulos'), findsOneWidget);
    // Os capítulos e a parte têm nome para o leitor de tela, marcados.
    expect(tester.getSemantics(find.widgetWithText(WCheckbox, 'A poeira')), isSemantics(label: 'A poeira', isChecked: true));

    await tester.tap(find.text('Só os prontos'));
    await tester.pumpAndSettle();
    expect(find.textContaining('2 de 3 capítulos'), findsOneWidget);
    // A parte pela metade fica desmarcada: marcar põe todos os dela, e
    // desmarcar tira todos.
    await tester.tap(find.widgetWithText(WCheckbox, 'Parte dois'));
    await tester.pumpAndSettle();
    expect(find.textContaining('3 de 3 capítulos'), findsOneWidget);
    await tester.tap(find.widgetWithText(WCheckbox, 'Parte dois'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1 de 3 capítulos'), findsOneWidget);
    await tester.tap(find.text('Todos'));
    await tester.pumpAndSettle();

    final target = '${h.dir.path}/Dustland.pdf';
    h.dialogs.exportAnswer = target;
    await tester.tap(find.text('Compilar…'));
    await tester.pump();
    await settleUntil(tester, () => h.kit.trims > 0);
    await tester.pumpAndSettle();
    expect(find.byType(CompileDialog), findsNothing);
    expect(h.dialogs.exports.last, 'Dustland.pdf');
    final xml = File(target).readAsStringSync();
    expect(xml, contains('<dc:title>Dustland</dc:title>'));
    expect(xml, contains('<dc:creator>Fulano</dc:creator>'));
    expect(xml, contains('>Parte dois</text:h>'));
    expect(h.kit.conversions.last.$3, 'pdf');
    expect(h.kit.indexUpdates, 1);
    expect(find.textContaining('Livro compilado em'), findsWidgets);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('cancelar a janela não compila', (tester) async {
    final h = await pumpApp(tester);
    await tester.runAsync(() => h.workspace.openPath(makeBook(h)));
    await tester.pump();
    (tester.state(find.byType(EditorPage)) as BookViewActions).compileBook();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.byType(CompileDialog), findsNothing);
    expect(h.kit.conversions.where((c) => c.$3 == 'pdf'), isEmpty);
    await tester.pump(const Duration(seconds: 3));
  });

  test('o compilar no menu Livro', () {
    final book = editorMenus(AppLocalizationsPt()).firstWhere((m) => m.items.contains(BookCommandIds.newChapter));
    expect(book.items, contains(BookCommandIds.compile));
  });
}
