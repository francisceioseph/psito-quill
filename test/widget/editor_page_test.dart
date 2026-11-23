import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/app.dart';
import 'package:psito_quill/src/commands/command_registry.dart';
import 'package:psito_quill/src/document/document_controller.dart';
import 'package:psito_quill/src/kit/fake/fake_quill_kit.dart';
import 'package:psito_quill/src/kit/quill_kit.dart';
import 'package:psito_quill/src/ui/atoms/w_button.dart';
import 'package:psito_quill/src/ui/atoms/w_dropdown.dart';
import 'package:psito_quill/src/ui/tokens/themes/themes.dart';

import '../support/harness.dart';

void main() {
  Harness? current;
  late Harness h;
  late FakeQuillKit kit;

  Future<void> pumpApp(
    WidgetTester tester, {
    String path = '/livro/cap.docx',
    String? lockOwner,
    Locale locale = const Locale('pt', 'BR'),
    FakeQuillKit? fake,
    bool inspector = false,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.localesTestValue = [locale];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    h = current = Harness(kit: fake);
    kit = h.kit;
    // O painel Formatar repete os botões da faixa: os testes da faixa o
    // fecham, para cada ícone aparecer uma vez.
    h.settings.inspector = inspector;
    await tester.pumpWidget(QuillApp(workspace: h.workspace, settings: h.settings, window: h.window, showMemory: false));
    if (h.doc.kitStatus == KitStatus.ready) h.doc.open(path, lockOwner: lockOwner);
    await tester.pump();
  }

  tearDown(() {
    current?.dispose();
    current = null;
  });

  Future<void> ctrl(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(key);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
  }

  void type(WidgetTester tester, String text) => tester.testTextInput.updateEditingValue(TextEditingValue(text: text));

  testWidgets('o botão Negrito acende pelo estado do motor', (tester) async {
    await pumpApp(tester);
    WToggle bold() => tester.widget<WToggle>(find.widgetWithIcon(WToggle, Icons.format_bold));
    expect(bold().value, isFalse);
    await tester.tap(find.widgetWithIcon(WToggle, Icons.format_bold));
    await tester.pump();
    expect(kit.unoCommands, contains('.uno:Bold'));
    expect(bold().value, isTrue);
  });

  testWidgets('a aba Início tem os grupos da faixa', (tester) async {
    await pumpApp(tester);
    for (final g in ['Área de transferência', 'Estilos', 'Fonte', 'Parágrafo']) {
      expect(find.text(g), findsWidgets, reason: g);
    }
    for (final icon in [
      Icons.save_outlined, // acesso rápido, ao lado das abas
      Icons.undo,
      Icons.content_paste,
      Icons.format_italic,
      Icons.format_align_center,
    ]) {
      expect(find.byIcon(icon), findsOneWidget);
    }
  });

  testWidgets('a dica do botão traz o atalho do jogo atual', (tester) async {
    await pumpApp(tester);
    expect(tester.widget<WToggle>(find.widgetWithIcon(WToggle, Icons.format_bold)).tooltip, 'Negrito (Ctrl+N)');
  });

  testWidgets('Salvar grava e a barra de status avisa', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.widgetWithIcon(WButton, Icons.save_outlined));
    await tester.pump();
    expect(kit.saved.single, ('/livro/cap.docx', 'docx'));
    expect(find.text('Salvo em /livro/cap.docx'), findsOneWidget);
  });

  testWidgets('documento novo: Salvar pergunta onde', (tester) async {
    await pumpApp(tester, path: '');
    h.dialogs.saveAnswer = '/livro/novo.odt';
    await ctrl(tester, LogicalKeyboardKey.keyB);
    await tester.pump();
    expect(h.dialogs.saves.single, 'Documento sem título.odt');
    expect(kit.saved.single, ('/livro/novo.odt', 'odt'));
    expect(h.recents.paths.first, '/livro/novo.odt');
  });

  testWidgets('Desfazer e Refazer seguem o estado do motor', (tester) async {
    await pumpApp(tester);
    WButton undo() => tester.widget<WButton>(find.widgetWithIcon(WButton, Icons.undo));
    expect(undo().onPressed, isNull);
    type(tester, 'olá');
    await tester.pump();
    expect(undo().onPressed, isNotNull);
    await ctrl(tester, LogicalKeyboardKey.keyZ);
    expect(kit.text, '');
    await ctrl(tester, LogicalKeyboardKey.keyR); // Refazer no Word em português
    expect(kit.text, 'olá');
  });

  testWidgets('copiar e colar: o texto vai para a área de transferência', (tester) async {
    await pumpApp(tester);
    kit.selectedText = 'palavra';
    await ctrl(tester, LogicalKeyboardKey.keyC); // sem seleção, Copiar não faz nada
    expect(h.clipboard.text, isNull);
    kit.emit(const SelectionChanged([Rect.fromLTWH(0, 0, 100, 100)]));
    await ctrl(tester, LogicalKeyboardKey.keyC);
    expect(h.clipboard.text, 'palavra');
    await ctrl(tester, LogicalKeyboardKey.keyV);
    await tester.pump();
    expect(kit.unoCommands.last, '.uno:Paste', reason: 'o que o Quill copiou cola com formatação');
    h.clipboard.text = 'de fora';
    await ctrl(tester, LogicalKeyboardKey.keyV);
    await tester.pump();
    expect(kit.pasted, ['de fora']);
  });

  testWidgets('a galeria de estilos aplica pelo nome do LibreOffice', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.widgetWithText(WTextButton, 'Título 2'));
    await tester.pump();
    expect(kit.unoCommands.last, '.uno:StyleApply');
    expect(kit.unoArgs.last, contains('"Heading 2"'));
  });

  testWidgets('a lista de fontes vem do motor, e o tamanho aplica em pontos', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byWidgetPredicate((w) => w is WDropdown && w.label == 'Fonte'));
    await tester.pumpAndSettle();
    expect(find.text('Noto Serif'), findsOneWidget);
    await tester.tap(find.text('Noto Serif'));
    await tester.pumpAndSettle();
    expect(kit.unoArgs.last, contains('"Noto Serif"'));
    await tester.tap(find.byWidgetPredicate((w) => w is WDropdown && w.label == 'Tamanho da fonte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10,5'));
    await tester.pumpAndSettle();
    expect(kit.unoCommands.last, '.uno:FontHeight');
    expect(kit.unoArgs.last, contains('10.5'));
  });

  testWidgets('barra de status: página, palavras, zoom', (tester) async {
    await pumpApp(tester);
    kit
      ..emitState('.uno:StatePageNumber', 'Página 2 de 30')
      ..emitState('.uno:StateWordCount', '21.069 palavras, 117.537 caracteres');
    await tester.pump();
    expect(find.text('Página 2 de 30'), findsOneWidget);
    expect(find.text('21069 palavras'), findsOneWidget);
    expect(find.text('100 %'), findsOneWidget);
    await tester.tap(find.widgetWithIcon(WButton, Icons.zoom_in));
    await tester.pump();
    expect(find.text('110 %'), findsOneWidget);
  });

  testWidgets('só leitura: aviso com quem está com o arquivo, e Salvar vira Salvar como', (tester) async {
    await pumpApp(tester, lockOwner: 'Maria');
    expect(find.textContaining('Maria está com este arquivo aberto'), findsOneWidget);
    expect(find.text('só leitura'), findsOneWidget);
    expect(tester.widget<WToggle>(find.widgetWithIcon(WToggle, Icons.format_bold)).onPressed, isNull);
    h.dialogs.saveAnswer = '/livro/copia.docx';
    await tester.tap(find.text('Salvar uma cópia…'));
    await tester.pump();
    expect(kit.saved.single.$1, '/livro/copia.docx');
    await tester.pump();
    // A cópia reabre, editável.
    expect(kit.opened.last, '/livro/copia.docx');
    expect(h.doc.readOnly, isFalse);
  });

  testWidgets('o título da janela mostra o nome e o "modificado"', (tester) async {
    await pumpApp(tester);
    expect(h.window.titles.last, 'cap.docx — Psito Quill');
    type(tester, 'x');
    await tester.pump();
    expect(h.window.titles.last, '• cap.docx — Psito Quill');
  });

  testWidgets('Novo com alterações pergunta; Cancelar mantém o documento', (tester) async {
    await pumpApp(tester);
    type(tester, 'texto');
    await tester.pump();
    await ctrl(tester, LogicalKeyboardKey.keyO); // Novo, no Word em português
    await tester.pumpAndSettle();
    expect(find.text('Salvar as alterações?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(kit.opened, ['/livro/cap.docx']);
    await ctrl(tester, LogicalKeyboardKey.keyO);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Não salvar'));
    await tester.pumpAndSettle();
    expect(kit.opened.last, '');
    expect(kit.saved, isEmpty);
  });

  testWidgets('painel Arquivo: recentes abrem, Esc volta', (tester) async {
    await pumpApp(tester);
    final recent = h.file('capitulo-2.odt');
    h.recents.add(recent);
    await tester.tap(find.text('Arquivo'));
    await tester.pumpAndSettle();
    expect(find.text('Recentes'), findsOneWidget);
    await tester.tap(find.text('capitulo-2.odt'));
    await tester.pumpAndSettle();
    expect(kit.opened.last, recent);
    expect(find.text('Recentes'), findsNothing, reason: 'o painel fecha');
    await tester.tap(find.text('Arquivo'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Recentes'), findsNothing);
  });

  testWidgets('preferências: o jogo de atalhos em inglês troca Ctrl+S e Ctrl+B', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Arquivo'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Word em inglês'));
    await tester.pumpAndSettle();
    expect(h.settings.shortcuts, ShortcutScheme.wordEn);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await ctrl(tester, LogicalKeyboardKey.keyB);
    expect(kit.unoCommands.last, '.uno:Bold');
    await ctrl(tester, LogicalKeyboardKey.keyS);
    expect(kit.saved, hasLength(1));
  });

  testWidgets('o tema escuro troca a moldura e o papel do motor, e fica nas preferências', (tester) async {
    await pumpApp(tester);
    kit.unoCommands.clear();
    await tester.tap(find.widgetWithIcon(WToggle, Icons.dark_mode_outlined));
    await tester.pumpAndSettle();
    expect(kit.unoCommands, ['.uno:ChangeTheme']);
    expect(h.settings.theme, 'escuro');
    final scaffold = Theme.of(tester.element(find.byType(Scaffold)));
    expect(scaffold.scaffoldBackgroundColor, escuro.colors.frame);
  });

  testWidgets('arquivo que não abre aparece em vermelho com o nome', (tester) async {
    await pumpApp(tester, fake: FakeQuillKit(openFails: true), path: '/livro/estragado.docx');
    expect(find.textContaining('Não foi possível abrir estragado.docx'), findsWidgets);
  });

  testWidgets('motor que não liga aparece em vermelho na barra', (tester) async {
    await pumpApp(tester, fake: FakeQuillKit(failStart: true));
    expect(find.textContaining('O motor não ligou'), findsWidgets);
  });

  testWidgets('em inglês, os rótulos mudam', (tester) async {
    await pumpApp(tester, locale: const Locale('en'));
    expect(tester.widget<WToggle>(find.widgetWithIcon(WToggle, Icons.format_bold)).label, 'Bold');
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('toda ação tem nome para o leitor de tela', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester);
    for (final name in ['Negrito', 'Itálico', 'Desfazer', 'Colar', 'Centralizar', 'Fonte', 'Tamanho da fonte',
        'Título 1', 'Localizar', 'Inserir', 'Tema escuro', 'Documento', 'Arquivo', 'Aumentar o zoom']) {
      expect(find.bySemanticsLabel(RegExp('^$name')), findsWidgets, reason: name);
    }
    handle.dispose();
  });

  test('o kit falso cobre a porta inteira', () {
    // Se a porta ganhar um método, este teste lembra de cobrir no falso.
    final QuillKit k = FakeQuillKit();
    expect(k.textureId(0), -1);
  });
}
