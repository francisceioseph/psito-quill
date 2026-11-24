// Várias páginas e a Estrutura (Fase 2B, Etapa 5, D-047): a disposição na
// barra de status, as colunas pelo zoom, e os títulos da cópia com o atual
// marcado e o salto.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/app.dart';
import 'package:psito_quill/src/kit/fake/fake_quill_kit.dart';
import 'package:psito_quill/src/kit/quill_kit.dart';
import 'package:psito_quill/src/ui/organisms/document_view.dart';
import 'package:psito_quill/src/ui/organisms/nav_rail.dart';
import 'package:psito_quill/src/ui/organisms/outline_panel.dart';

import '../support/harness.dart';

void main() {
  late Harness h;
  late FakeQuillKit kit;
  Harness? current;

  Future<void> pumpApp(WidgetTester tester, {List<(int, String)> headings = const []}) async {
    await tester.binding.setSurfaceSize(const Size(1500, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.localesTestValue = [const Locale('pt', 'BR')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    h = current = Harness();
    kit = h.kit..headings = headings;
    h.settings.inspector = false;
    await tester.pumpWidget(QuillApp(workspace: h.workspace, settings: h.settings, window: h.window, showMemory: false));
    h.doc.open('/livro/cap.odt');
    await tester.runAsync(() async {
      for (var i = 0; i < 50 && h.doc.snapshot.styles.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pump();
    await tester.pump();
  }

  tearDown(() {
    current?.dispose();
    current = null;
  });

  List<String> layouts() => [
        for (var i = 0; i < kit.unoCommands.length; i++)
          if (kit.unoCommands[i] == '.uno:ViewLayout') kit.unoArgs[i],
      ];

  testWidgets('Livro: duas colunas no modo livro; Uma volta; o mesmo não repete', (tester) async {
    await pumpApp(tester);
    expect(layouts(), isEmpty, reason: 'uma página é o padrão: nada a mandar');
    await tester.tap(find.byTooltip('Livro (pares)'));
    await tester.pump();
    expect(layouts().last, allOf(contains('"value":2'), contains('BookMode":{"type":"boolean","value":true}')));
    expect(h.settings.pageLayout, 'livro');
    await tester.tap(find.byTooltip('Livro (pares)'));
    await tester.pump();
    expect(layouts(), hasLength(1));
    await tester.tap(find.byTooltip('Uma página'));
    await tester.pump();
    expect(layouts().last, contains('"ViewLayout.Columns":{"type":"short","value":1}'));
  });

  testWidgets('Várias: as colunas saem do zoom e mudam com ele', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('Várias páginas'));
    await tester.pump();
    final at100 = h.doc.viewColumns;
    h.doc.setZoom(0.3);
    await tester.pump();
    await tester.pump();
    expect(h.doc.viewColumns, greaterThan(at100), reason: 'em 30 % cabem mais páginas');
    expect(h.doc.zoom, 0.3, reason: 'o zoom mínimo caiu para 20 %');
  });

  testWidgets('a Estrutura: os títulos da cópia, recuados, e o clique leva até lá', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester, headings: const [(1, 'Capítulo 3 · A estrada'), (2, 'Cena 1 · O posto'), (2, 'Cena 2 · A tempestade')]);
    await tester.tap(find.descendant(of: find.byWidgetPredicate((w) => w is NavRail), matching: find.bySemanticsLabel('Estrutura')).first);
    await tester.pump();
    expect(find.byType(OutlinePanel), findsOneWidget);
    expect(find.text('Cena 2 · A tempestade'), findsOneWidget);
    expect(h.doc.liveOutline, isTrue);
    final item = tester.widget<PanelListItem>(find.ancestor(of: find.text('Cena 1 · O posto'), matching: find.byType(PanelListItem)));
    expect(item.level, 2);
    expect(tester.widget<PanelListItem>(find.ancestor(of: find.text('Cena 2 · A tempestade'), matching: find.byType(PanelListItem))).selected, isTrue,
        reason: 'os três estão na página 1, a do cursor: o atual é o último dela');
    await tester.tap(find.text('Cena 2 · A tempestade'));
    await tester.pump();
    // O salto (D-072): ao começo, e uma busca a mais que as ocorrências antes.
    final n = kit.unoCommands.length;
    expect(kit.unoCommands.sublist(n - 2), ['.uno:GoToStartOfDoc', '.uno:ExecuteSearch']);
    expect(kit.unoArgs.last, contains('Cena 2 · A tempestade'));
    expect(h.doc.search.query, isNull, reason: 'o salto não acende o Localizar');
    handle.dispose();
  });

  testWidgets('o cursor fora da tela: a vista rola até ele (D-072)', (tester) async {
    await pumpApp(tester);
    ScrollPosition vertical() => tester
        .stateList<ScrollableState>(find.descendant(of: find.byType(DocumentView), matching: find.byType(Scrollable)))
        .map((s) => s.position)
        .firstWhere((p) => p.axis == Axis.vertical);
    expect(vertical().pixels, 0);
    final far = h.doc.documentSize.height * 0.6;
    kit.emit(CursorMoved(Rect.fromLTWH(2000, far, 20, 280)));
    await tester.pump();
    await tester.pump();
    final at = vertical().pixels;
    expect(at, greaterThan(0), reason: 'o salto longe rola');
    // Rolar com a roda não puxa a vista de volta: o cursor não mudou.
    vertical().jumpTo(0);
    await tester.pump();
    await tester.pump();
    expect(vertical().pixels, 0);
    // Uma tecla move o cursor um pouco: a vista vai até ele de novo.
    kit.emit(CursorMoved(Rect.fromLTWH(2120, far, 20, 280)));
    await tester.pump();
    await tester.pump();
    expect(vertical().pixels, closeTo(at, 2));
  });

  testWidgets('com a Estrutura aberta, uma pausa de 2 s na digitação refaz a cópia; fechada, não', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester);
    final before = kit.copies.length;
    h.doc.insertText('a');
    await tester.pump(const Duration(seconds: 3));
    expect(kit.copies.length, before, reason: 'com o painel fechado, nenhuma cópia');
    await tester.tap(find.descendant(of: find.byWidgetPredicate((w) => w is NavRail), matching: find.bySemanticsLabel('Estrutura')).first);
    await tester.pump();
    final opened = kit.copies.length;
    expect(opened, before + 1, reason: 'abrir com edição pendente refaz na hora');
    h.doc.insertText('b');
    await tester.pump(const Duration(seconds: 1));
    h.doc.insertText('c');
    await tester.pump(const Duration(seconds: 1));
    expect(kit.copies.length, opened, reason: 'ainda digitando');
    await tester.pump(const Duration(seconds: 2));
    expect(kit.copies.length, opened + 1);
    handle.dispose();
  });
}
