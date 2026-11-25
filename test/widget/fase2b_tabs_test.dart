// A fileira das abas de documentos (D-054): aparece com duas, troca no
// clique e no Ctrl+Tab, fecha no X, no clique do meio e no Ctrl+W.
import 'package:flutter/gestures.dart' show kMiddleMouseButton;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/app.dart';
import 'package:psito_quill/src/ui/organisms/doc_tabs.dart';

import '../support/harness.dart';

void main() {
  Harness? current;

  Future<Harness> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.localesTestValue = [const Locale('pt', 'BR')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final h = current = Harness();
    await tester.pumpWidget(QuillApp(workspace: h.workspace, settings: h.settings, window: h.window, showMemory: false));
    await tester.pump();
    return h;
  }

  tearDown(() {
    current?.dispose();
    current = null;
  });

  testWidgets('com uma aba, sem fileira; com duas, a fileira com os nomes', (tester) async {
    final h = await pumpApp(tester);
    h.doc.open('/livro/cap1.odt');
    await tester.pump();
    expect(find.byType(DocTabStrip), findsNothing);
    h.doc.open('/livro/cap2.odt');
    await tester.pump();
    await tester.pump();
    expect(find.byType(DocTabStrip), findsOneWidget);
    expect(find.text('cap1.odt'), findsOneWidget);
    expect(find.text('cap2.odt'), findsOneWidget);
    expect(find.bySemanticsLabel('Fechar cap1.odt'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('o X fica dentro da aba da tela, no fundo dela', (tester) async {
    final h = await pumpApp(tester);
    h.doc.open('/livro/cap1.odt');
    h.doc.open('/livro/cap2.odt');
    await tester.pump();
    await tester.pump();
    final close = tester.getRect(find.bySemanticsLabel('Fechar cap2.odt'));
    final name = tester.getRect(find.text('cap2.odt'));
    // O fundo da aba: o AnimatedContainer em volta do nome que tem também o X.
    final back = find
        .ancestor(of: find.text('cap2.odt'), matching: find.byType(AnimatedContainer))
        .evaluate()
        .firstWhere((e) => (e.renderObject! as RenderBox).paintBounds.shift(tester.getTopLeft(find.byElementPredicate((x) => x == e))).contains(close.center));
    final tab = tester.getRect(find.byElementPredicate((x) => x == back));
    final deco = (back.widget as AnimatedContainer).decoration as BoxDecoration?;
    expect(deco?.color, isNotNull, reason: 'a aba da tela tem fundo');
    expect(tab.contains(name.center), isTrue);
    expect(tab.right, greaterThanOrEqualTo(close.right));
  });

  testWidgets('clicar troca; o ponto e o nome dizem que há alterações', (tester) async {
    final h = await pumpApp(tester);
    h.doc.open('/livro/cap1.odt');
    h.doc.open('/livro/cap2.odt');
    h.kit.emitState('.uno:ModifiedStatus', 'true');
    await tester.pump();
    await tester.pump();
    expect(find.bySemanticsLabel('cap2.odt, com alterações não salvas'), findsOneWidget);
    await tester.tap(find.text('cap1.odt'));
    await tester.pump();
    await tester.pump();
    expect(h.doc.path, '/livro/cap1.odt');
    expect(h.kit.activeId, h.doc.tabs.first.engineId);
    expect(find.bySemanticsLabel('cap2.odt, com alterações não salvas'), findsOneWidget);
  });

  testWidgets('Ctrl+Tab troca; Ctrl+W e o clique do meio fecham', (tester) async {
    final h = await pumpApp(tester);
    h.doc.open('/livro/cap1.odt');
    h.doc.open('/livro/cap2.odt');
    h.doc.open('/livro/cap3.odt');
    await tester.pump();
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(h.doc.path, '/livro/cap1.odt', reason: 'depois da última, a primeira');

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyW);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    await tester.pump();
    expect(h.doc.tabs.map(h.doc.tabPath), ['/livro/cap2.odt', '/livro/cap3.odt']);

    final g = await tester.startGesture(tester.getCenter(find.text('cap3.odt')), buttons: kMiddleMouseButton);
    await g.up();
    await tester.pump();
    await tester.pump();
    expect(h.doc.tabs, hasLength(1));
    expect(find.byType(DocTabStrip), findsNothing);
  });
}
