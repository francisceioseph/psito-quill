// A aba Exibir (Etapa 7, passo 8, D-065): as caixas do que se mostra, a
// disposição das páginas e os ajustes do zoom.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/app.dart';
import 'package:psito_quill/src/ui/molecules/command_check.dart';
import 'package:psito_quill/src/ui/organisms/ruler.dart';
import 'package:psito_quill/src/ui/organisms/status_bar.dart';

import '../support/harness.dart';

void main() {
  Harness? current;

  Future<Harness> pumpView(WidgetTester tester, {Size size = const Size(1500, 900)}) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.localesTestValue = [const Locale('pt', 'BR')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final h = current = Harness();
    await tester.pumpWidget(QuillApp(workspace: h.workspace, settings: h.settings, window: h.window, showMemory: false));
    h.doc.open('/livro/cap.odt');
    await tester.pump();
    await tester.pump();
    await tester.ensureVisible(find.text('Exibir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exibir'));
    await tester.pumpAndSettle();
    return h;
  }

  tearDown(() {
    current?.dispose();
    current = null;
  });

  for (final size in const [Size(1024, 768), Size(1366, 768), Size(1920, 1080)]) {
    testWidgets('em ${size.width.toInt()} px, nada vaza', (tester) async {
      await pumpView(tester, size: size);
      expect(find.byType(CommandCheck), findsNWidgets(6));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('as caixas mostram e escondem a barra de status e a régua', (tester) async {
    final h = await pumpView(tester);
    expect(find.byType(StatusBar), findsOneWidget);
    expect(tester.getSemantics(find.widgetWithText(CommandCheck, 'Barra de status')), isSemantics(isChecked: true));
    await tester.tap(find.widgetWithText(CommandCheck, 'Barra de status'));
    await tester.pumpAndSettle();
    expect(find.byType(StatusBar), findsNothing);
    expect(h.settings.statusBar, isFalse);
    expect(tester.getSemantics(find.widgetWithText(CommandCheck, 'Barra de status')), isSemantics(isChecked: false),
        reason: 'a caixa acompanha (a faixa memoizada sabe da preferência)');
    await tester.tap(find.widgetWithText(CommandCheck, 'Barra de status'));
    await tester.pumpAndSettle();
    expect(find.byType(StatusBar), findsOneWidget);

    expect(find.byType(HorizontalRuler), findsOneWidget);
    await tester.tap(find.widgetWithText(CommandCheck, 'Régua'));
    await tester.pumpAndSettle();
    expect(find.byType(HorizontalRuler), findsNothing);
  });

  testWidgets('a disposição e os ajustes do zoom', (tester) async {
    final h = await pumpView(tester);
    await tester.tap(find.text('Várias páginas'));
    await tester.pumpAndSettle();
    expect(h.settings.pageLayout, 'varias');
    await tester.tap(find.text('Livro (pares)'));
    await tester.pumpAndSettle();
    expect(h.settings.pageLayout, 'livro');
    expect(h.doc.bookMode, isTrue);
    await tester.tap(find.text('Uma página'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ajustar à página'));
    await tester.pumpAndSettle();
    final page = h.doc.zoom;
    await tester.tap(find.text('Ajustar à largura'));
    await tester.pumpAndSettle();
    expect(h.doc.zoom, greaterThanOrEqualTo(page), reason: 'a largura deixa a página maior que a página inteira');
  });
}
