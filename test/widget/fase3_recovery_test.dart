// A recuperação na tela inicial (Fase 3, Etapa 2, D-073).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/app.dart';
import 'package:psito_quill/src/document/recovery.dart';

import '../support/harness.dart';

void main() {
  Harness? current;
  tearDown(() {
    current?.dispose();
    current = null;
  });

  Future<(Harness, RecoveryStore)> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1500, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.localesTestValue = [const Locale('pt', 'BR')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final h = current = Harness();
    final dir = Directory('${h.dir.path}/recuperacao');
    final old = RecoveryStore(dir, session: 'caiu')..ensureDir();
    for (final (n, original, title) in [
      (1, '${h.dir.path}/livros/Silicon.odt', null),
      (2, null, 'Dustland — A poeira'),
    ]) {
      File(old.writingPath(old.idFor(n))).writeAsStringSync('odt');
      old.commit(old.idFor(n), original: original, title: title, at: DateTime(2026, 11, 20 + n, 9, 30));
    }
    h.doc.recovery = RecoveryStore(dir, session: 'agora');
    h.workspace.loadRecoverable();
    await tester.pumpWidget(QuillApp(workspace: h.workspace, settings: h.settings, window: h.window, showMemory: false));
    await tester.pump();
    return (h, old);
  }

  testWidgets('a tela inicial oferece as cópias, com o nome e a data', (tester) async {
    await pumpApp(tester);
    expect(find.text('Recuperar arquivos'), findsOneWidget);
    expect(find.text('Silicon.odt'), findsOneWidget);
    expect(find.text('Dustland — A poeira'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Dustland — A poeira, cópia de ')), findsOneWidget);
    expect(find.bySemanticsLabel('Recuperar'), findsNWidgets(2));
    expect(find.bySemanticsLabel('Descartar'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Recuperar abre numa aba "(recuperado)" e some da lista', (tester) async {
    final (h, _) = await pumpApp(tester);
    await tester.tap(find.bySemanticsLabel('Recuperar').first);
    await tester.pump();
    await tester.pump();
    expect(h.doc.isOpen, isTrue);
    expect(h.doc.path, isNull);
    // A fileira das abas só aparece com duas (D-054): o nome está no título.
    expect(h.window.titles.last, contains('Dustland — A poeira (recuperado)'));
    expect(h.workspace.recoverable, hasLength(1));
  });

  testWidgets('Descartar pergunta antes e apaga a cópia', (tester) async {
    final (h, old) = await pumpApp(tester);
    await tester.tap(find.bySemanticsLabel('Descartar').last);
    await tester.pumpAndSettle();
    expect(find.text('Descartar a cópia?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Descartar'));
    await tester.pumpAndSettle();
    expect(find.text('Silicon.odt'), findsNothing);
    expect(File(old.writingPath(old.idFor(1)).replaceAll('.gravando', '')).existsSync(), isFalse);
    expect(h.workspace.recoverable, hasLength(1));
  });
}
