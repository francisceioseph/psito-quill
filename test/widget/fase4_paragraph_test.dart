// Os ajustes da Estrutura, do parágrafo e das Informações (Fase 4, Etapa 6,
// D-091): "Início do documento", o nível e o recolher; a janela do parágrafo
// (o fundo, as bordas, as tabulações) só com o que mudou; as contagens e as
// propriedades editáveis.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/app.dart';
import 'package:psito_quill/src/document/paragraph_format.dart';
import 'package:psito_quill/src/kit/lok/quill_macros.dart';
import 'package:psito_quill/src/kit/quill_kit.dart';
import 'package:psito_quill/src/ui/organisms/nav_rail.dart';
import 'package:psito_quill/src/ui/organisms/outline_panel.dart';

import '../support/harness.dart';

void main() {
  Harness? current;

  Future<Harness> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1500, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.localesTestValue = [const Locale('pt', 'BR')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final h = current = Harness();
    h.kit
      ..headings = [(1, 'Capítulo um'), (2, 'Parte a'), (2, 'Parte b'), (1, 'Capítulo dois')]
      ..bodyParagraphs = ['O gato.']
      ..extraMetaXml = '<dc:title>Dustland</dc:title><meta:keyword>deserto</meta:keyword>';
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

  Future<void> tapRibbon(WidgetTester tester, String label) async {
    final f = find.bySemanticsLabel(label).first;
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Finder inDialog(Finder f) => find.descendant(of: find.byType(AlertDialog), matching: f);

  testWidgets('a Estrutura: o início do documento, recolher e o nível', (tester) async {
    final h = await pumpApp(tester);
    await waitCopy(tester);
    await tester.tap(find.descendant(of: find.byWidgetPredicate((w) => w is NavRail), matching: find.bySemanticsLabel('Estrutura')).first);
    await tester.pumpAndSettle();
    expect(find.byType(OutlinePanel), findsOneWidget);
    expect(find.text('Parte b'), findsOneWidget);

    await tester.tap(find.text('Início do documento'));
    await tester.pump();
    expect(h.kit.unoCommands.last, '.uno:GoToStartOfDoc');

    // Recolher o Capítulo um esconde as partes; o dois fica.
    await tester.tap(find.bySemanticsLabel('Recolher Capítulo um'));
    await tester.pump();
    expect(find.text('Parte a'), findsNothing);
    expect(find.text('Capítulo dois'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Expandir tudo'));
    await tester.pump();
    expect(find.text('Parte a'), findsOneWidget);

    // Até o nível 1.
    await tester.tap(find.bySemanticsLabel('Mostrar até o nível'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Até o nível 1').last);
    await tester.pumpAndSettle();
    expect(find.text('Parte b'), findsNothing);
    expect(find.text('Capítulo dois'), findsOneWidget);
  });

  testWidgets('a janela do parágrafo manda só o que mudou', (tester) async {
    final h = await pumpApp(tester);
    await waitCopy(tester);

    // O fundo.
    await tapRibbon(tester, 'Parágrafo…');
    expect(find.text('Parágrafo'), findsWidgets);
    final apply = inDialog(find.widgetWithText(FilledButton, 'Aplicar'));
    expect(tester.widget<FilledButton>(apply).onPressed, isNull, reason: 'sem mudança, nada a aplicar');
    await tester.tap(inDialog(find.bySemanticsLabel('Amarelo')));
    await tester.pump();
    await tester.tap(apply);
    await tester.pumpAndSettle();
    expect(h.kit.unoCommands.last, '.uno:BackgroundColor');
    expect(h.kit.unoArgs.last, contains('16776960'));
    expect(h.kit.unoCommands.where((c) => c.startsWith('macro:')), isEmpty, reason: 'o resto ficou como estava');

    // As bordas: em volta, média.
    await tapRibbon(tester, 'Parágrafo…');
    await tester.tap(inDialog(find.bySemanticsLabel('Bordas')));
    await tester.pumpAndSettle();
    await tester.tap(inDialog(find.text('Em volta')));
    await tester.tap(inDialog(find.bySemanticsLabel('Média')));
    await tester.pump();
    await tester.tap(inDialog(find.widgetWithText(FilledButton, 'Aplicar')));
    await tester.pumpAndSettle();
    expect(h.kit.unoCommands.last, quillMacro('Bordas', [BorderSides.box, BorderWeight.medium.mm100, 0, 100]));

    // As tabulações, pela régua: remover a única volta às do estilo.
    h.kit.emit(const RulerUpdated(RulerInfo(
      pageWidth: 21000,
      leftMargin: 2000,
      textWidth: 17000,
      tabs: [(position: 3000, style: 0), (position: 5002, style: 4)],
    )));
    await tester.pump();
    await tapRibbon(tester, 'Parágrafo…');
    await tester.tap(inDialog(find.bySemanticsLabel('Tabulações')));
    await tester.pumpAndSettle();
    expect(find.textContaining('3 cm'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Remover a tabulação em 3 cm'));
    await tester.pump();
    await tester.enterText(inDialog(find.byType(TextField)), '4,5');
    await tester.pump();
    await tester.tap(inDialog(find.text('Adicionar')));
    await tester.pump();
    await tester.tap(inDialog(find.widgetWithText(FilledButton, 'Aplicar')));
    await tester.pumpAndSettle();
    expect(h.kit.unoCommands.last, quillMacro('Tabulacoes', [MacroName('1_4500_0_32')]));
  });

  testWidgets('as Informações: as contagens e as propriedades', (tester) async {
    final h = await pumpApp(tester);
    await waitCopy(tester);
    await tester.tap(find.text('Arquivo'));
    await tester.pumpAndSettle();
    expect(find.text('Parágrafos'), findsOneWidget);
    expect(find.text('5'), findsOneWidget, reason: 'os quatro títulos e o parágrafo');
    expect(find.text('Caracteres (sem espaços)'), findsOneWidget);

    final title = find.widgetWithText(TextField, 'Dustland');
    expect(title, findsOneWidget);
    expect(find.widgetWithText(TextField, 'deserto'), findsOneWidget);
    await tester.enterText(title, 'Dustland, o livro');
    await tester.pump();
    await tester.tap(find.text('Aplicar as propriedades'));
    await tester.pump();
    expect(
      h.kit.unoCommands,
      contains(propertiesMacro(const DocProperties(title: 'Dustland, o livro', keywords: ['deserto']))),
    );
    await waitCopy(tester);
  });
}
