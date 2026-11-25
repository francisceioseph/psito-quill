// As Preferências e os modelos (Fase 4, Etapa 8, D-093): o atalho de um
// comando com o aviso de conflito (e a tecla passa a rodar o outro), o acesso
// rápido escolhido, as regras da ortografia, e o novo a partir do modelo (sem
// arquivo) e salvar como modelo.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/app.dart';
import 'package:psito_quill/src/document/templates.dart';
import 'package:psito_quill/src/ui/atoms/w_button.dart';

import '../support/harness.dart';

void main() {
  Harness? current;
  late Directory models;

  setUp(() {
    models = Directory.systemTemp.createTempSync('quill-modelos-');
    templatesDirOverride = models;
  });
  tearDown(() {
    current?.dispose();
    current = null;
    templatesDirOverride = null;
    models.deleteSync(recursive: true);
  });

  Future<Harness> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1500, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.localesTestValue = [const Locale('pt', 'BR')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final h = current = Harness();
    h.kit.bodyParagraphs = ['O gato.'];
    h.settings.inspector = false;
    await tester.pumpWidget(QuillApp(workspace: h.workspace, settings: h.settings, window: h.window, showMemory: false));
    h.doc.open('/livro/cap.odt');
    await tester.pumpAndSettle();
    return h;
  }

  Future<void> waitAsync(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pumpAndSettle();
  }

  Future<void> openPreferences(WidgetTester tester, String section) async {
    await tester.tap(find.text('Arquivo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preferências').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(section).last);
    await tester.pumpAndSettle();
  }

  Finder inDialog(Finder f) => find.descendant(of: find.byType(AlertDialog), matching: f);

  testWidgets('o atalho de um comando: o aviso de conflito, e a tecla roda o novo', (tester) async {
    final h = await pumpApp(tester);
    await openPreferences(tester, 'Atalhos de teclado');
    await tester.enterText(find.byType(TextField).last, 'Itálico');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(WTextButton, 'Mudar').first);
    await tester.pumpAndSettle();
    expect(inDialog(find.text('Pressione as teclas do atalho')), findsOneWidget);

    // Uma letra sozinha não serve.
    await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
    await tester.pump();
    expect(inDialog(find.textContaining('uma letra sozinha')), findsOneWidget);

    // O Ctrl+N é do Negrito.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(inDialog(find.text('Ctrl+N')), findsOneWidget);
    expect(inDialog(find.textContaining('Este já é o atalho de Negrito')), findsOneWidget);
    await tester.tap(inDialog(find.widgetWithText(FilledButton, 'Atribuir')));
    await tester.pumpAndSettle();
    expect(h.settings.customShortcuts.keys, containsAll(['formatar.italico', 'formatar.negrito']));
    expect(h.settings.customShortcuts['formatar.negrito'], '');

    // De volta ao documento, o Ctrl+N põe itálico.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(h.kit.unoCommands.last, '.uno:Italic');
    await waitAsync(tester);
  });

  testWidgets('o acesso rápido e as regras da ortografia', (tester) async {
    final h = await pumpApp(tester);
    await openPreferences(tester, 'Acesso rápido');
    await tester.tap(find.bySemanticsLabel('Tirar Desfazer'));
    await tester.pumpAndSettle();
    expect(h.settings.quickAccess, ['arquivo.salvar', 'editar.refazer']);
    await tester.tap(find.bySemanticsLabel('Subir Refazer'));
    await tester.pumpAndSettle();
    expect(h.settings.quickAccess, ['editar.refazer', 'arquivo.salvar']);
    await tester.tap(find.text('Voltar ao padrão'));
    await tester.pumpAndSettle();
    expect(h.settings.quickAccess, ['arquivo.salvar', 'editar.desfazer', 'editar.refazer']);

    await tester.tap(find.text('Geral').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.bySemanticsLabel('Não verificar as palavras em MAIÚSCULAS'));
    await tester.tap(find.bySemanticsLabel('Não verificar as palavras em MAIÚSCULAS'));
    await tester.pumpAndSettle();
    expect(h.settings.spellIgnoreUpper, isTrue);
    expect(find.textContaining('próxima vez que o Quill abrir'), findsOneWidget);
    await waitAsync(tester);
  });

  testWidgets('novo a partir do modelo abre sem arquivo; salvar como modelo vai para a pasta', (tester) async {
    final h = await pumpApp(tester);
    File('${models.path}/Manuscrito.ott').writeAsStringSync('modelo');
    await tester.tap(find.text('Arquivo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Novo a partir do modelo…'));
    await tester.pumpAndSettle();
    await tester.tap(inDialog(find.text('Manuscrito')));
    await waitAsync(tester);
    final (source, target, format) = h.kit.conversions.last;
    expect(source, '${models.path}/Manuscrito.ott');
    expect(format, 'odt');
    expect(h.doc.tabs, hasLength(2));
    expect(h.doc.path, isNull, reason: 'o documento novo não tem arquivo');
    expect(h.doc.tabPath(h.doc.currentTab!), isNull, reason: 'a aba não mostra a cópia');
    expect(h.kit.opened.last, target);

    await tester.tap(find.text('Arquivo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar como modelo…'));
    await tester.pumpAndSettle();
    await tester.enterText(inDialog(find.byType(TextField)), 'Manuscrito');
    await tester.pump();
    expect(inDialog(find.text('Já existe um modelo com esse nome.')), findsOneWidget);
    await tester.enterText(inDialog(find.byType(TextField)), 'Carta');
    await tester.pump();
    await tester.tap(inDialog(find.widgetWithText(FilledButton, 'Salvar')));
    await waitAsync(tester);
    expect(h.kit.conversions.last.$2, '${models.path}/Carta.ott');
    expect(h.kit.conversions.last.$3, 'ott');
  });
}
