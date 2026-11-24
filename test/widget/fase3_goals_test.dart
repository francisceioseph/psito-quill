// As metas (Fase 3, Etapa 9, D-083): a meta do dia na barra de status, com
// o capítulo da tela pelo motor, a janela das metas (gravar no livro.json, a
// sessão só na memória) e o histórico no metas.json.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/l10n/gen/app_localizations_pt.dart';
import 'package:psito_quill/src/app.dart';
import 'package:psito_quill/src/book/book.dart';
import 'package:psito_quill/src/book/book_io.dart';
import 'package:psito_quill/src/book/goals.dart';
import 'package:psito_quill/src/commands/commands_book.dart';
import 'package:psito_quill/src/commands/menus.dart';
import 'package:psito_quill/src/ui/organisms/goals_chart.dart';

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
    // Ontem, 400 palavras.
    final y = DateTime.now().subtract(const Duration(days: 1));
    GoalLog(days: {dayKey(y): 400}).write(dir);
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

  Future<void> settleUntil(WidgetTester tester, bool Function() done) async {
    for (var i = 0; i < 40 && !done(); i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
    }
  }

  testWidgets('a meta do dia na barra, a janela das metas e o histórico', (tester) async {
    final h = await pumpApp(tester);
    final dir = makeBook(h);
    await tester.runAsync(() => h.workspace.openPath(dir));
    final books = h.workspace.book;
    await settleUntil(tester, () => books.goalLog != null);
    expect(books.goalLog, isNotNull, reason: 'a primeira contagem põe a base do dia');
    final base = books.book!.find('a')!.$1.words;
    expect(find.textContaining('meta hoje'), findsNothing, reason: 'sem meta do dia');

    books.setGoals(const BookGoals(daily: 1000));
    await tester.pump();
    expect(find.text('meta hoje 0/1.000'), findsOneWidget);

    // O capítulo da tela pelo motor: 250 palavras a mais.
    h.kit.emitState('.uno:StateWordCount', '${base + 250} palavras, 900 caracteres');
    await tester.pump();
    expect(find.text('meta hoje 250/1.000'), findsOneWidget);
    // Cortar não conta ao contrário.
    h.kit.emitState('.uno:StateWordCount', '${base - 100} palavras, 900 caracteres');
    await tester.pump();
    expect(find.text('meta hoje 0/1.000'), findsOneWidget);
    h.kit.emitState('.uno:StateWordCount', '${base + 250} palavras, 900 caracteres');
    await tester.pump();

    // O clique abre as metas.
    await tester.tap(find.text('meta hoje 250/1.000'));
    await tester.pumpAndSettle();
    expect(find.text('Metas de Dustland'), findsOneWidget);
    expect(find.text('Hoje: 250 de 1.000'), findsOneWidget);
    final chart = tester.widget<GoalsChart>(find.byType(GoalsChart));
    expect(chart.days, hasLength(30));
    expect(chart.days.last, 250);
    expect(chart.days[28], 400, reason: 'ontem, do metas.json');
    expect(chart.goal, 1000);

    final fields = find.descendant(
        of: find.byType(AlertDialog), matching: find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == 'Vazio: sem meta'));
    expect(fields.evaluate(), hasLength(3));
    await tester.enterText(fields.at(0), '90.000');
    await tester.enterText(fields.at(2), '500');
    await tester.pump();
    expect(find.textContaining(RegExp(r'^Livro: [\d.]+ de 90\.000 palavras')), findsOneWidget);
    expect(find.text('Sessão: 0 de 500'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    final json = jsonDecode(File('$dir/livro.json').readAsStringSync()) as Map<String, Object?>;
    expect(json['metas'], {'livro': 90000, 'dia': 1000});
    expect(books.sessionGoal, 500);
    expect(find.text('sessão 0/500'), findsOneWidget, reason: 'a sessão começa agora');
    h.kit.emitState('.uno:StateWordCount', '${base + 300} palavras, 900 caracteres');
    await tester.pump();
    expect(find.text('sessão 50/500'), findsOneWidget);

    // Salvar o capítulo grava o dia no metas.json.
    File('$dir/capitulos/001-abertura.odt').setLastModifiedSync(DateTime.now().add(const Duration(seconds: 5)));
    await tester.runAsync(() => books.refreshWords());
    await tester.pump();
    final log = GoalLog.read(dir);
    expect(log.baseDay, dayKey(DateTime.now()));
    expect(log.base.keys, containsAll(['a', 'b']));

    // Fechar o livro esquece a sessão.
    await tester.runAsync(() => h.workspace.closeBook());
    await tester.pump();
    expect(books.sessionGoal, isNull);
    await tester.pump(const Duration(seconds: 3));
  });

  test('o menu Livro do Clássico 97 tem as metas', () {
    final book = editorMenus(AppLocalizationsPt()).firstWhere((m) => m.items.contains(BookCommandIds.newChapter));
    expect(book.items, containsAllInOrder([BookCommandIds.newNote, BookCommandIds.goals, BookCommandIds.closeBook]));
  });
}
