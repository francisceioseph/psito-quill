// A casca do editor da Fase 2B (Etapa 2, D-043): a fileira de abas com a
// pesquisa e o Recolher, o trilho com os painéis da esquerda, o painel
// Formatar com uma seção de cada vez, e a barra de status com o zoom.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/app.dart';
import 'package:psito_quill/src/kit/fake/fake_quill_kit.dart';
import 'package:psito_quill/src/ui/atoms/w_button.dart';
import 'package:psito_quill/src/ui/atoms/w_chip.dart';
import 'package:psito_quill/src/ui/atoms/w_segmented.dart';
import 'package:psito_quill/src/ui/atoms/w_slider.dart';
import 'package:psito_quill/src/ui/molecules/style_card.dart';
import 'package:psito_quill/src/ui/organisms/command_palette.dart';
import 'package:psito_quill/src/ui/organisms/inspector.dart';
import 'package:psito_quill/src/ui/organisms/nav_rail.dart';
import 'package:psito_quill/src/ui/organisms/outline_panel.dart';
import 'package:psito_quill/src/ui/organisms/ribbon.dart';
import 'package:psito_quill/src/ui/organisms/styles_panel.dart';

import '../support/harness.dart';

void main() {
  late Harness h;
  late FakeQuillKit kit;
  Harness? current;

  Future<void> pumpApp(WidgetTester tester, {bool inspector = false, String theme = 'claro', Size size = const Size(1920, 1080)}) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.localesTestValue = [const Locale('pt', 'BR')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    h = current = Harness();
    kit = h.kit;
    h.settings
      ..inspector = inspector
      ..theme = theme;
    await tester.pumpWidget(QuillApp(workspace: h.workspace, settings: h.settings, window: h.window, showMemory: false));
    h.doc.open('/livro/cap.odt');
    await tester.pump();
  }

  /// Um item do trilho pelo nome (o mesmo nome aparece na aba e no painel).
  Finder rail(String label) =>
      find.descendant(of: find.byWidgetPredicate((w) => w is NavRail), matching: find.bySemanticsLabel(label)).first;

  tearDown(() {
    current?.dispose();
    current = null;
  });

  testWidgets('a aba Estilos mostra os cartões; o aplicado fica marcado', (tester) async {
    await pumpApp(tester);
    kit.emitState('.uno:StyleApply', 'Heading 1');
    await tester.pump();
    await tester.tap(find.widgetWithText(WTextButton, 'Estilos'));
    await tester.pump();
    final card = find.ancestor(of: find.text('Título 1'), matching: find.byType(StyleCard)).first;
    expect(tester.widget<StyleCard>(card).selected, isTrue);
  });

  testWidgets('Ctrl+F1 recolhe a faixa (e guarda); clicar numa aba mostra de novo', (tester) async {
    await pumpApp(tester);
    expect(find.text('Área de transferência'), findsOneWidget);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.f1);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(find.text('Área de transferência'), findsNothing);
    expect(h.settings.ribbonCollapsed, isTrue);
    await tester.tap(find.widgetWithText(WTextButton, 'Início'));
    await tester.pump();
    expect(find.text('Área de transferência'), findsOneWidget);
    expect(h.settings.ribbonCollapsed, isFalse);
  });

  testWidgets('a pesquisa da fileira de abas abre a paleta', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Pesquisar no texto e nos comandos'));
    await tester.pumpAndSettle();
    expect(find.byType(CommandPalette), findsOneWidget);
  });

  testWidgets('janela estreita: a pesquisa vira ícone e a fileira não estoura', (tester) async {
    await pumpApp(tester, size: const Size(900, 700));
    expect(find.text('Pesquisar no texto e nos comandos'), findsNothing);
    expect(find.byTooltip('Pesquisar (Ctrl+K)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('o trilho abre a Estrutura e os Estilos, e fecha clicando de novo', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester);
    await tester.tap(rail('Estrutura'));
    await tester.pump();
    expect(find.byType(OutlinePanel), findsOneWidget);
    expect(find.textContaining('Os títulos do documento'), findsOneWidget);
    await tester.tap(rail('Estilos'));
    await tester.pump();
    expect(find.byType(StylesPanel), findsOneWidget);
    expect(find.byType(OutlinePanel), findsNothing);
    // Clicar num estilo da lista aplica.
    await tester.tap(find.descendant(of: find.byType(StylesPanel), matching: find.text('Título 2')));
    await tester.pump();
    expect(kit.unoCommands.last, '.uno:StyleApply');
    expect(kit.unoArgs.last, contains('"Heading 2"'));
    handle.dispose();
  });

  testWidgets('o trilho: Localizar e substituir abre e fecha o painel', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester);
    await tester.tap(rail('Localizar'));
    await tester.pumpAndSettle();
    expect(find.text('Localizar'), findsWidgets);
    expect(find.byType(TextField), findsNWidgets(2), reason: 'localizar e substituir');
    handle.dispose();
  });

  testWidgets('o painel Formatar constrói só a seção escolhida', (tester) async {
    await pumpApp(tester, inspector: true);
    final panel = find.byType(Inspector);
    expect(find.descendant(of: panel, matching: find.text('Recuo à esquerda')), findsNothing);
    expect(find.descendant(of: panel, matching: find.text('Cor da fonte')), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(WSegmented<InspectorPart>), matching: find.text('Página')));
    await tester.pump();
    expect(find.descendant(of: panel, matching: find.text('Cor da fonte')), findsNothing);
    expect(find.descendant(of: panel, matching: find.widgetWithText(WChip, 'A5')), findsWidgets);
    // O botão de fechar do painel diz o atalho e fecha.
    await tester.tap(find.byTooltip('Fechar o painel Formatar (F10)'));
    await tester.pump();
    expect(find.byType(Inspector), findsNothing);
    expect(h.settings.inspector, isFalse);
  });

  testWidgets('as seções Imagem e Tabela aparecem com a seleção e somem com ela', (tester) async {
    await pumpApp(tester, inspector: true);
    expect(find.descendant(of: find.byType(WSegmented<InspectorPart>), matching: find.text('Tabela')), findsNothing);
    h.doc.insertTable(2, 2);
    await tester.pump();
    expect(find.descendant(of: find.byType(WSegmented<InspectorPart>), matching: find.text('Tabela')), findsOneWidget);
  });

  testWidgets('Aumentar e Diminuir a fonte andam pela lista de tamanhos', (tester) async {
    await pumpApp(tester);
    kit.emitState('.uno:FontHeight', '12');
    await tester.pump();
    await tester.tap(find.byTooltip('Aumentar a fonte'));
    await tester.pump();
    expect(kit.unoArgs.last, contains('"value":14'));
    kit.emitState('.uno:FontHeight', '10.5');
    await tester.pump();
    await tester.tap(find.byTooltip('Diminuir a fonte'));
    await tester.pump();
    expect(kit.unoArgs.last, contains('"value":10'));
    expect(nextFontSize(72, up: true), 72);
    expect(nextFontSize(8, up: false), 8);
  });

  testWidgets('a cor da fonte da faixa abre as amostras e aplica', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('Cor da fonte'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Vermelho'));
    await tester.pumpAndSettle();
    expect(kit.unoCommands.last, '.uno:Color');
    expect(kit.unoArgs.last, contains('${0xC9211E}'));
  });

  testWidgets('o zoom da barra de status: arrastar só manda ao soltar', (tester) async {
    await pumpApp(tester);
    final before = h.doc.zoom;
    final slider = find.descendant(of: find.byType(WSlider), matching: find.byType(Slider));
    final gesture = await tester.startGesture(tester.getCenter(slider));
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    expect(h.doc.zoom, before, reason: 'no meio do arrasto, o motor não recebe nada');
    await gesture.up();
    await tester.pump();
    expect(h.doc.zoom, greaterThan(before));
  });

  testWidgets('a casca não estoura em nenhum tema, com tudo aberto', (tester) async {
    final handle = tester.ensureSemantics();
    for (final theme in ['claro', 'escuro', 'classico97']) {
      await pumpApp(tester, inspector: true, theme: theme);
      if (theme != 'classico97') {
        await tester.tap(rail('Estrutura'));
      }
      await tester.pump();
      expect(tester.takeException(), isNull, reason: theme);
      current?.dispose();
      current = null;
    }
    handle.dispose();
  });
}
