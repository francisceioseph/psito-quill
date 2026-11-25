// O controle de alterações e o modo Leitura (Fase 4, Etapa 4, D-089): os três
// modos na barra de status e no Ctrl+Shift+E, o painel Alterações (a lista só
// com ele aberto, aceitar e rejeitar uma ou todas, ir ao trecho) e a Leitura
// (sem a faixa, nada se digita, as setas folheiam, o Esc sai).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/app.dart';
import 'package:psito_quill/src/commands/commands_view.dart';
import 'package:psito_quill/src/kit/lok/vcl_keys.dart';
import 'package:psito_quill/src/kit/quill_kit.dart';
import 'package:psito_quill/src/ui/organisms/changes_panel.dart';
import 'package:psito_quill/src/ui/organisms/reading_view.dart';
import 'package:psito_quill/src/ui/organisms/ribbon.dart';

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
    h.doc.open('/livro/cap.odt');
    await tester.pumpAndSettle();
    return h;
  }

  tearDown(() {
    current?.dispose();
    current = null;
  });

  Finder inPanel(Finder f) => find.descendant(of: find.byType(ChangesPanel), matching: f);

  Future<void> ctrlShiftE(WidgetTester tester) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
  }

  testWidgets('a Revisão, o painel Alterações, aceitar e rejeitar', (tester) async {
    final h = await pumpApp(tester);
    h.kit.author = 'Ana';

    // Ctrl+Shift+E liga a Revisão.
    await ctrlShiftE(tester);
    expect(h.kit.tracking, isTrue);
    expect(h.doc.tracking, isTrue);

    h.doc.insertText('Um ');
    h.doc.insertText('dois ');
    await tester.pumpAndSettle();
    expect(h.kit.changes, hasLength(2));
    // Sem o painel, a lista não é pedida.
    expect(h.kit.requestedValues, isNot(contains('.uno:AcceptTrackedChanges')));

    await tester.tap(find.bySemanticsLabel('Alterações').first);
    await tester.pumpAndSettle();
    expect(find.byType(ChangesPanel), findsOneWidget);
    expect(inPanel(find.text('2 alterações')), findsOneWidget);
    expect(inPanel(find.text('Inserir “Um ”')), findsOneWidget);
    expect(inPanel(find.textContaining('Inserção · Ana')), findsWidgets);

    // A próxima digitação pede a lista de novo, numa pausa.
    h.kit.requestedValues.clear();
    h.doc.insertText('três');
    await tester.pump(const Duration(milliseconds: 100));
    expect(h.kit.requestedValues, isEmpty);
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(h.kit.requestedValues, ['.uno:AcceptTrackedChanges']);
    expect(inPanel(find.text('3 alterações')), findsOneWidget);

    // Ir ao trecho.
    h.kit.mice.clear();
    await tester.tap(inPanel(find.text('Inserir “Um ”')));
    await tester.pumpAndSettle();
    expect(h.kit.mice.map((m) => m.$1), [MouseEventType.down, MouseEventType.up]);

    // Aceitar uma pelo índice; rejeitar todas.
    await tester.tap(inPanel(find.bySemanticsLabel('Aceitar')).first);
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(h.kit.unoArgs.last, contains('"AcceptTrackedChange"'));
    expect(inPanel(find.text('2 alterações')), findsOneWidget);
    await tester.tap(inPanel(find.text('Rejeitar todas')));
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(h.kit.unoCommands.last, '.uno:RejectAllTrackedChanges');
    expect(inPanel(find.textContaining('Nenhuma alteração neste capítulo')), findsOneWidget);

    // Mostrar na página alterna no motor; a chave da Revisão desliga.
    await tester.tap(inPanel(find.text('Mostrar na página')));
    await tester.pumpAndSettle();
    expect(h.kit.showChanges, isFalse);
    await tester.tap(inPanel(find.bySemanticsLabel('Revisão: marcar o que eu mudar')));
    await tester.pumpAndSettle();
    expect(h.kit.tracking, isFalse);

    // Fechar o painel solta a lista.
    await tester.tap(find.bySemanticsLabel('Fechar as alterações'));
    await tester.pumpAndSettle();
    expect(h.doc.liveChanges, isFalse);
  });

  testWidgets('a Leitura: sem a faixa, nada se digita, as setas folheiam, o Esc sai', (tester) async {
    final h = await pumpApp(tester);
    h.doc.insertText('Texto');
    await tester.pumpAndSettle();
    expect(find.byType(Ribbon), findsOneWidget);

    // Pela barra de status.
    await tester.tap(find.bySemanticsLabel('Leitura').last);
    await tester.pumpAndSettle();
    expect(find.byType(ReadingView), findsOneWidget);
    expect(find.byType(Ribbon), findsNothing);
    expect(h.doc.reading, isTrue);
    expect(h.doc.canEdit, isFalse);

    final before = h.kit.text;
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pumpAndSettle();
    expect(h.kit.text, before);

    h.kit.keys.clear();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(h.kit.keys.where((k) => k.$1 == KeyEventType.input).map((k) => k.$3), [VclKey.pageDown, VclKey.pageDown, VclKey.pageUp]);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(ReadingView), findsNothing);
    expect(find.byType(Ribbon), findsOneWidget);
    expect(h.doc.canEdit, isTrue);
  });

  testWidgets('a Leitura guarda a Revisão, e o botão sair volta a ela', (tester) async {
    final h = await pumpApp(tester);
    await ctrlShiftE(tester);
    expect(h.kit.tracking, isTrue);
    final state = tester.state(find.byWidgetPredicate((w) => w.runtimeType.toString() == 'EditorPage')) as EditorViewActions;
    state.setEditMode(EditMode.reading);
    await tester.pumpAndSettle();
    expect(state.editMode, EditMode.reading);
    expect(h.kit.tracking, isTrue);
    await tester.tap(find.text('Sair da leitura (Esc)'));
    await tester.pumpAndSettle();
    expect(state.editMode, EditMode.review);
    state.setEditMode(EditMode.editing);
    await tester.pumpAndSettle();
    expect(h.kit.tracking, isFalse);
  });
}
