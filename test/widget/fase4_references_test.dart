// As referências (Fase 4, Etapa 5, D-090): a faixa Referências (o sumário, os
// índices, a legenda), a janela dos marcadores (inserir, ir, excluir, o nome
// que não serve) e a da referência cruzada (a um título, a um marcador, a
// uma legenda).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/app.dart';
import 'package:psito_quill/src/document/references.dart';
import 'package:psito_quill/src/kit/lok/quill_macros.dart';
import 'package:psito_quill/src/kit/quill_kit.dart';
import 'package:psito_quill/src/ui/atoms/w_button.dart';

import '../support/harness.dart';

const _caption = '<text:p text:style-name="Caption">Figura <text:sequence text:ref-name="refFigure0" '
    'text:name="Figure" text:formula="ooow:Figure+1" style:num-format="1">1</text:sequence>: Mapa</text:p>';

void main() {
  Harness? current;

  Future<Harness> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1500, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.localesTestValue = [const Locale('pt', 'BR')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final h = current = Harness();
    h.kit
      ..headings = [(1, 'Capítulo um'), (2, 'Parte b')]
      ..bodyParagraphs = ['O gato.']
      ..bookmark = 'mapa'
      ..extraBodyXml = _caption;
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

  /// A janela espera a cópia nova (um isolate lê o arquivo).
  Future<void> waitCopy(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pumpAndSettle();
  }

  /// Um botão da faixa (ela rola de lado quando falta espaço).
  Future<void> tapRibbon(WidgetTester tester, String label) async {
    final f = find.bySemanticsLabel(label);
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pump();
  }

  Finder inDialog(Finder f) => find.descendant(of: find.byType(AlertDialog), matching: f);

  Future<void> openReferences(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(WTextButton, 'Referências'));
    await tester.pumpAndSettle();
  }

  testWidgets('a faixa Referências: o sumário, os índices, atualizar e a legenda', (tester) async {
    final h = await pumpApp(tester);
    await openReferences(tester);

    await tapRibbon(tester, 'Inserir o sumário');
    expect(h.kit.unoCommands.last, quillMacro('Sumario', [const MacroText('Sumário'), 3]));

    await tapRibbon(tester, 'Índice de figuras');
    expect(h.kit.unoCommands.last, quillMacro('Figuras', [const MacroText('Índice de figuras'), MacroName('Figure')]));

    await tapRibbon(tester, 'Índice de tabelas');
    expect(h.kit.unoCommands.last, contains('"Table")'));

    await tapRibbon(tester, 'Inserir o índice remissivo');
    expect(h.kit.unoCommands.last, quillMacro('Remissivo', [const MacroText('Índice remissivo')]));

    await tapRibbon(tester, 'Atualizar o sumário e os índices');
    expect(h.kit.unoCommands, contains(quillMacro('Atualizar')));

    // A legenda só com uma imagem selecionada ou o cursor numa tabela.
    final before = h.kit.unoCommands.length;
    await tapRibbon(tester, 'Inserir a legenda');
    expect(h.kit.unoCommands.length, before);
    h.kit.emit(const TableSelected(true));
    await tester.pumpAndSettle();
    await tapRibbon(tester, 'Inserir a legenda');
    expect(h.kit.unoCommands.where((c) => c.contains('.Legenda(')).single,
        quillMacro('Legenda', [const MacroText('Tabela'), MacroName('Tabela')]));

    // Marcar a entrada pede uma seleção.
    expect(h.kit.unoCommands.where((c) => c.contains('MarcarEntrada')), isEmpty);
    await waitCopy(tester);
  });

  testWidgets('os marcadores: inserir, o nome que não serve, ir e excluir', (tester) async {
    final h = await pumpApp(tester);

    Future<void> open() async {
      // Ctrl+Shift+F5, como no Word.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.f5);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await waitCopy(tester);
      expect(find.text('Marcadores'), findsWidgets);
    }

    await open();
    expect(inDialog(find.text('mapa')), findsOneWidget);
    final field = find.byType(TextField);
    await tester.enterText(field, 'a.b');
    await tester.pump();
    expect(find.textContaining('O nome não pode'), findsOneWidget);
    await tester.enterText(field, 'mapa');
    await tester.pump();
    expect(find.text('Já existe um marcador com esse nome.'), findsOneWidget);
    await tester.enterText(field, 'rio');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Inserir'));
    await tester.pumpAndSettle();
    expect(h.kit.unoArgs[h.kit.unoCommands.lastIndexOf('.uno:InsertBookmark')], bookmarkArgs('rio'));
    expect(h.kit.bookmark, 'rio');
    h.kit.bookmark = 'mapa';

    await open();
    await tester.tap(find.bySemanticsLabel('Ir para mapa'));
    await tester.pumpAndSettle();
    expect(h.kit.unoCommands.last, quillMacro('IrMarcador', [const MacroText('mapa')]));

    await open();
    await tester.tap(find.bySemanticsLabel('Excluir mapa'));
    await tester.pumpAndSettle();
    expect(h.kit.unoCommands, contains('.uno:DeleteBookmark'));
    expect(find.text('Nenhum marcador ainda.'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await waitCopy(tester);
  });

  testWidgets('a referência cruzada: a um título, a um marcador e a uma legenda', (tester) async {
    final h = await pumpApp(tester);
    await openReferences(tester);

    Future<void> open() async {
      await tapRibbon(tester, 'Referência cruzada');
      await waitCopy(tester);
    }

    // O título, pela página.
    await open();
    expect(find.textContaining('Capítulo um'), findsWidgets);
    await tester.tap(find.textContaining('Parte b'));
    await tester.tap(find.bySemanticsLabel('A página'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Inserir'));
    await tester.pumpAndSettle();
    final macro = h.kit.unoCommands.last;
    expect(macro, startsWith('macro:///PsitoQuill.Referencias.RefTitulo("1","0050006100720074006500200062","__RefHeading__quill_'));
    expect(macro, endsWith('","0")'));

    // O marcador, pelo texto.
    await open();
    await tester.tap(inDialog(find.bySemanticsLabel('Marcadores')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('mapa'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Inserir'));
    await tester.pumpAndSettle();
    expect(h.kit.unoCommands.last, '.uno:InsertField');
    expect(h.kit.unoArgs.last, bookmarkRefArgs('mapa', RefFormat.text));

    // A legenda: "Figura e número".
    await open();
    await tester.tap(inDialog(find.bySemanticsLabel('Legendas')));
    await tester.pumpAndSettle();
    expect(find.text('Figura e número'), findsOneWidget);
    await tester.tap(find.text('Figura 1: Mapa'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Inserir'));
    await tester.pumpAndSettle();
    expect(h.kit.unoArgs.last,
        captionRefArgs(const CaptionEntry(sequence: 'Figure', number: 0, text: 'Figura 1: Mapa'), RefFormat.text));
    await waitCopy(tester);
  });
}
