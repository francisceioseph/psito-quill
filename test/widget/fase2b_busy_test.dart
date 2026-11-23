// Ocupado sem janelas (Etapa 8, D-066): salvar e abrir travam a tela com o
// véu, o progresso fica no rodapé, e as teclas param.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/app.dart';
import 'package:psito_quill/src/document/document_controller.dart';
import 'package:psito_quill/src/kit/lok/lok_quill_kit.dart';
import 'package:psito_quill/src/kit/quill_kit.dart';
import 'package:psito_quill/src/ui/organisms/busy_scope.dart';
import 'package:psito_quill/src/ui/organisms/status_bar.dart';

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
    await h.workspace.openPath(h.file('cap.odt'));
    await tester.pump();
    await tester.pump();
    return h;
  }

  tearDown(() {
    current?.dispose();
    current = null;
  });

  test('os callbacks 9, 10 e 11 viram o progresso', () {
    expect((LokQuillKit.translate(9, 'Carregando: ')! as ProgressStarted).label, 'Carregando:');
    expect((LokQuillKit.translate(10, '75')! as ProgressValue).percent, 75);
    expect((LokQuillKit.translate(10, '140')! as ProgressValue).percent, 100);
    expect(LokQuillKit.translate(11, ''), isA<ProgressFinished>());
  });

  testWidgets('salvar trava a tela até o motor responder, sem janela', (tester) async {
    final h = await pumpApp(tester);
    h.kit.holdSaves = true;
    h.kit.emitState('.uno:ModifiedStatus', 'true');
    await tester.pump();
    final saved = h.workspace.save();
    await tester.pump();
    expect(h.doc.busy, BusyKind.saving);
    expect(tester.widget<BusyScope>(find.byType(BusyScope)).busy, isTrue);
    expect(find.descendant(of: find.byType(StatusBar), matching: find.byType(StatusProgress)), findsOneWidget);
    expect(find.bySemanticsLabel('Salvando…'), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);

    // As teclas param enquanto salva.
    final keys = h.kit.keys.length;
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(h.kit.keys.length, keys);
    h.doc.insertText('x');
    expect(h.kit.text, isNot(contains('x')));

    h.kit.finishSave();
    await tester.pump();
    expect(await saved, isTrue);
    expect(h.doc.busy, isNull);
    expect(tester.widget<BusyScope>(find.byType(BusyScope)).busy, isFalse);
    expect(find.byType(StatusProgress), findsNothing);
  });

  testWidgets('o progresso de abrir vai no rodapé, com o número', (tester) async {
    final h = await pumpApp(tester);
    // Um pedido ainda sem resposta: o motor manda o progresso.
    h.doc.docStatus = DocStatus.opening;
    h.kit.emit(const ProgressStarted('Carregando: '));
    h.kit.emit(const ProgressValue(50));
    await tester.pump();
    expect(find.bySemanticsLabel('Abrindo… 50 %'), findsOneWidget);
    h.kit.emit(const ProgressFinished());
    h.doc.docStatus = DocStatus.open;
    h.kit.emitState('.uno:ModifiedStatus', 'false');
    await tester.pump();
    expect(find.byType(StatusProgress), findsNothing);
  });

  testWidgets('um trabalho de fundo aparece no rodapé e não trava', (tester) async {
    final h = await pumpApp(tester);
    h.kit.emit(const ProgressStarted('Verificando: '));
    await tester.pump();
    expect(h.doc.backgroundTask, 'Verificando: ');
    expect(find.bySemanticsLabel('Verificando 0 %'), findsOneWidget);
    expect(h.doc.busy, isNull);
    expect(tester.widget<BusyScope>(find.byType(BusyScope)).busy, isFalse);
    h.kit.emit(const ProgressFinished());
    await tester.pump();
    expect(find.byType(StatusProgress), findsNothing);
  });

  testWidgets('se o motor nunca responder, a tela destrava', (tester) async {
    final h = await pumpApp(tester);
    h.kit.holdSaves = true;
    h.doc.save();
    await tester.pump();
    expect(h.doc.busy, BusyKind.saving);
    await tester.pump(DocumentController.savingTimeout + const Duration(seconds: 1));
    expect(h.doc.busy, isNull);
  });
}
