// A Página Inicial, o Layout e o Inserir (Fase 4, Etapa 7, D-092): o pincel,
// o Aa e as listas de vários níveis; as colunas, os números de linha, a cor
// da página, a marca d'água e a ordem das imagens; a caixa de texto.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/app.dart';
import 'package:psito_quill/src/commands/commands_layout.dart';
import 'package:psito_quill/src/document/document_controller.dart';
import 'package:psito_quill/src/kit/lok/quill_macros.dart';
import 'package:psito_quill/src/kit/quill_kit.dart';
import 'package:psito_quill/src/ui/atoms/w_button.dart';

import '../support/harness.dart';

void main() {
  Harness? current;

  Future<Harness> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1500, 900));
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

  tearDown(() {
    current?.dispose();
    current = null;
  });

  Future<void> waitCopy(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pumpAndSettle();
  }

  Future<void> tapLabel(WidgetTester tester, String label) async {
    final f = find.bySemanticsLabel(label).first;
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  /// Abre o menu da faixa [menu] e escolhe [item].
  Future<void> pick(WidgetTester tester, String menu, String item) async {
    // O botão do menu, não o título do grupo de mesmo nome.
    final f = find.descendant(of: find.byType(MenuAnchor), matching: find.bySemanticsLabel(menu)).first;
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
    await tester.tap(find.text(item).last);
    await tester.pumpAndSettle();
  }

  Future<void> openTab(WidgetTester tester, String tab) async {
    await tester.tap(find.widgetWithText(WTextButton, tab));
    await tester.pumpAndSettle();
  }

  testWidgets('o Início: o pincel, o Aa com uma seleção e a lista de vários níveis', (tester) async {
    final h = await pumpApp(tester);
    await tapLabel(tester, 'Copiar a formatação');
    expect(h.kit.unoCommands.last, '.uno:FormatPaintbrush');
    h.kit.emitState('.uno:FormatPaintbrush', 'true');
    await tester.pump();
    expect(h.workspace.doc.paintbrushOn, isTrue);

    h.kit.emit(const SelectionChanged([Rect.fromLTWH(0, 0, 100, 100)]));
    await tester.pump();
    await pick(tester, 'Maiúsculas e minúsculas', 'MAIÚSCULAS');
    expect(h.kit.unoCommands.last, '.uno:ChangeCaseToUpper');

    await pick(tester, 'Lista de vários níveis', 'Lista 1 · 1.1 · 1.1.1');
    expect(h.kit.unoCommands.last, '.uno:SetOutline');
    expect(h.kit.unoArgs.last, contains('"value":7'));
    await pick(tester, 'Lista de vários níveis', 'Descer um nível na lista');
    expect(h.kit.unoCommands.last, '.uno:DecrementLevel');
    await waitCopy(tester);
  });

  testWidgets('o Layout: as colunas, os números de linha, a cor da página e a marca d\'água', (tester) async {
    final h = await pumpApp(tester);
    await openTab(tester, 'Layout');

    await pick(tester, 'Colunas', '2 colunas');
    expect(h.kit.unoCommands.last, '.uno:PageColumnType');
    expect(h.kit.unoArgs.last, contains('"value":2'));
    h.kit.emitState('.uno:PageColumnType', '2');
    await tester.pump();
    expect(h.workspace.doc.pageColumns, 2);

    await tapLabel(tester, 'Números de linha');
    expect(h.kit.unoCommands, contains(quillMacro('Linhas', [true])));

    final colorMenu = find.descendant(of: find.byType(MenuAnchor), matching: find.bySemanticsLabel('Cor da página')).first;
    await tester.tap(colorMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Creme').last);
    await tester.pumpAndSettle();
    expect(h.kit.unoCommands, contains(quillMacro('CorPagina', [0xFFF5E0])));
    await waitCopy(tester);

    await pick(tester, 'Marca d\'água…', 'Marca d\'água…');
    await tester.enterText(find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)), 'Rascunho "1"');
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Na horizontal'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Aplicar'));
    await tester.pumpAndSettle();
    expect(h.kit.unoCommands.last, '.uno:Watermark');
    expect(h.kit.unoArgs.last, contains(r'"value":"Rascunho \"1\""'));
    expect(h.kit.unoArgs.last, contains('"Angle":{"type":"short","value":0}'));
    await waitCopy(tester);
  });

  testWidgets('a ordem só com uma imagem, e a caixa de texto no Inserir', (tester) async {
    final h = await pumpApp(tester);
    await openTab(tester, 'Layout');
    final before = h.kit.unoCommands.length;
    await tapLabel(tester, 'Enviar para trás');
    expect(h.kit.unoCommands.length, before, reason: 'sem imagem, nada');
    h.kit.emit(const GraphicSelected(Rect.fromLTWH(1440, 2000, 2880, 2880)));
    await tester.pumpAndSettle();
    await tapLabel(tester, 'Enviar para trás');
    expect(h.kit.unoCommands.last, '.uno:SendToBack');
    h.kit.emit(const GraphicSelected(null));
    await tester.pumpAndSettle();

    await openTab(tester, 'Inserir');
    await tapLabel(tester, 'Caixa de texto');
    expect(h.kit.unoCommands.last, quillMacro('Caixa', [6000]));
    expect(LayoutCommandIds.arrange, hasLength(4));
    await waitCopy(tester);
  });
}
