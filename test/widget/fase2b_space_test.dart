// A interface que respira (Fase 2B, Etapa 7, D-049): o Início se adapta à
// largura sem rolar de lado a partir de 1280 px, e nada vaza nos quatro
// tamanhos de tela.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/app.dart';
import 'package:psito_quill/src/ui/atoms/w_slider.dart';
import 'package:psito_quill/src/ui/molecules/adaptive_ribbon.dart';
import 'package:psito_quill/src/ui/molecules/style_card.dart';
import 'package:psito_quill/src/ui/organisms/outline_panel.dart';
import 'package:psito_quill/src/ui/organisms/status_bar.dart';
import 'package:psito_quill/src/ui/organisms/styles_panel.dart';

import '../support/harness.dart';

void main() {
  Harness? current;

  Future<Harness> pumpApp(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.localesTestValue = [const Locale('pt', 'BR')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final h = current = Harness();
    await tester.pumpWidget(QuillApp(workspace: h.workspace, settings: h.settings, window: h.window, showMemory: false));
    h.doc.open('/livro/cap.odt');
    await tester.pump();
    await tester.pump();
    return h;
  }

  tearDown(() {
    current?.dispose();
    current = null;
  });

  test('os grupos de prioridade menor encolhem primeiro', () {
    RibbonGroupSpec g(String t, int p, List<double> ws) =>
        RibbonGroupSpec(title: t, priority: p, levels: [for (final w in ws) RibbonLevel(w, (_) => const SizedBox())]);
    final groups = [g('a', 1, [100, 50]), g('b', 9, [200, 150]), g('c', 2, [100, 40])];
    expect(chooseRibbonLevels(groups, 1000, 10), [0, 0, 0]);
    expect(chooseRibbonLevels(groups, 400, 10), [1, 0, 0], reason: 'a (prioridade 1) vai primeiro');
    expect(chooseRibbonLevels(groups, 350, 10), [1, 0, 1]);
    expect(chooseRibbonLevels(groups, 280, 10), [1, 1, 1]);
    expect(chooseRibbonLevels(groups, 10, 10), [1, 1, 1], reason: 'no menor de todos, para');
  });

  for (final size in const [Size(800, 600), Size(1024, 768), Size(1366, 768), Size(1920, 1080), Size(2560, 1440)]) {
    testWidgets('Início e rodapé em ${size.width.toInt()}×${size.height.toInt()}: nada vaza', (tester) async {
      await pumpApp(tester, size);
      expect(tester.takeException(), isNull);
      final ribbon = find.byType(AdaptiveRibbon);
      expect(ribbon, findsOneWidget);
      final scroll = find.descendant(of: ribbon, matching: find.byType(SingleChildScrollView));
      if (size.width >= 1280) expect(scroll, findsNothing, reason: 'a partir de 1280 px nada rola de lado');

      final statusBar = find.byType(StatusBar);
      expect(statusBar, findsOneWidget);
      // O zoom é a lupa −, a porcentagem e a lupa +, sem controle deslizante.
      expect(find.descendant(of: statusBar, matching: find.byType(WSlider)), findsNothing);
      final out = tester.getCenter(find.descendant(of: statusBar, matching: find.bySemanticsLabel('Diminuir o zoom')));
      final percent = tester.getCenter(find.descendant(of: statusBar, matching: find.text('100 %')));
      final inn = tester.getCenter(find.descendant(of: statusBar, matching: find.bySemanticsLabel('Aumentar o zoom')));
      expect(out.dx < percent.dx && percent.dx < inn.dx, isTrue, reason: '− % +');
    });
  }

  testWidgets('barra de status é clicável: clicar na página abre Estrutura', (tester) async {
    final h = await pumpApp(tester, const Size(1366, 768));
    h.kit.emitState('.uno:StatePageNumber', '1/1');
    await tester.pump();
    expect(find.byType(OutlinePanel), findsNothing);
    final statusPage = find.descendant(of: find.byType(StatusBar), matching: find.text('Página 1 de 1'));
    await tester.tap(statusPage);
    await tester.pump();
    expect(find.byType(OutlinePanel), findsOneWidget);
  });

  testWidgets('barra de status é clicável: clicar no estilo abre Estilos', (tester) async {
    final h = await pumpApp(tester, const Size(1366, 768));
    h.kit.emitState('.uno:StyleApply', 'Heading 1');
    await tester.pump();
    expect(find.byType(StylesPanel), findsNothing);
    final statusStyle = find.descendant(of: find.byType(StatusBar), matching: find.text('Título 1'));
    await tester.tap(statusStyle);
    await tester.pump();
    expect(find.byType(StylesPanel), findsOneWidget);
  });

  testWidgets('em tela larga a galeria mostra mais estilos', (tester) async {
    await pumpApp(tester, const Size(1366, 768));
    final narrow = find.byType(StyleCard).evaluate().length;
    current?.dispose();
    current = null;
    await pumpApp(tester, const Size(2560, 1440));
    expect(find.byType(StyleCard).evaluate().length, greaterThan(narrow));
  });
}
