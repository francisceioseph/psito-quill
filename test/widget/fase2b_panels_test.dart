// Os painéis na largura que têm (D-056): as cores numa linha só, e as ações
// (estilo, limpar formatação) na largura toda, sem cortar o nome.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/app.dart';
import 'package:psito_quill/src/ui/atoms/w_color_swatch.dart';
import 'package:psito_quill/src/ui/atoms/w_dropdown.dart';
import 'package:psito_quill/src/ui/molecules/panel_action.dart';
import 'package:psito_quill/src/ui/organisms/outline_panel.dart';
import 'package:psito_quill/src/ui/organisms/status_bar.dart';
import 'package:psito_quill/src/ui/organisms/styles_panel.dart';

import '../support/harness.dart';

void main() {
  for (final size in const [Size(1366, 768), Size(1920, 1080)]) {
    testWidgets('Formatar em ${size.width.toInt()}: cada fileira de cores numa linha, ações na largura toda', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      tester.platformDispatcher.localesTestValue = [const Locale('pt', 'BR')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      final h = Harness();
      addTearDown(h.dispose);
      h.settings.inspector = true;
      await tester.pumpWidget(QuillApp(workspace: h.workspace, settings: h.settings, window: h.window, showMemory: false));
      h.doc.open('/livro/cap.odt');
      await tester.pump();
      await tester.pump();

      final rows = {for (final e in find.byType(WColorSwatch).evaluate()) tester.getTopLeft(find.byWidget(e.widget)).dy};
      expect(rows, hasLength(2), reason: 'a cor da fonte numa linha e o realce em outra');

      final actions = find.byType(PanelAction);
      expect(actions, findsNWidgets(3));
      final widths = {for (final e in actions.evaluate()) tester.getSize(find.byWidget(e.widget)).width};
      expect(widths, hasLength(1), reason: 'todas da mesma largura');

      final dropdown = find.byType(WDropdown<String>);
      expect(dropdown, findsOneWidget);
      expect(tester.getSize(dropdown).width, widths.first, reason: 'dropdown e ações com a mesma largura');

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('painéis da esquerda (Estrutura e Estilos) têm largura 280 px', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1366, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.localesTestValue = [const Locale('pt', 'BR')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final h = Harness();
    addTearDown(h.dispose);
    await tester.pumpWidget(QuillApp(workspace: h.workspace, settings: h.settings, window: h.window, showMemory: false));
    h.doc.open('/livro/cap.odt');
    h.kit.emitState('.uno:StatePageNumber', '1/1');
    h.kit.emitState('.uno:StyleApply', 'Standard');
    await tester.pump();
    await tester.pump();

    // Abre a Estrutura clicando no rodapé
    final statusPage = find.descendant(of: find.byType(StatusBar), matching: find.text('Página 1 de 1'));
    await tester.tap(statusPage);
    await tester.pump();
    expect(find.byType(OutlinePanel), findsOneWidget);
    expect(tester.getSize(find.byType(OutlinePanel)).width, 280);

    // Fecha a Estrutura
    await tester.tap(find.byTooltip('Fechar a estrutura'));
    await tester.pump();
    expect(find.byType(OutlinePanel), findsNothing);

    // Abre os Estilos pelo rodapé
    final statusStyle = find.descendant(of: find.byType(StatusBar), matching: find.text('Padrão'));
    await tester.tap(statusStyle);
    await tester.pump();
    expect(find.byType(StylesPanel), findsOneWidget);
    expect(tester.getSize(find.byType(StylesPanel)).width, 280);
  });
}
