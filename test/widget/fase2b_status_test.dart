// A barra de status maior e clicável (Etapa 7, passo 6, D-063): os campos
// abrem menus (as estatísticas, o idioma, o zoom), recebem o foco pelo Tab e
// respondem ao Enter.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/app.dart';
import 'package:psito_quill/src/kit/lok/lok_payloads.dart';
import 'package:psito_quill/src/ui/organisms/document_view.dart';
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

  test('o idioma e a lista do motor', () {
    expect(parseLanguage('Português (Brasil);pt-BR'), (name: 'Português (Brasil)', tag: 'pt-BR'));
    expect(parseLanguage('[Nenhum];-'), (name: '[Nenhum]', tag: '-'));
    expect(parseLanguage('sem etiqueta'), isNull);
    expect(
      parseLanguageList('{"commandName":".uno:LanguageStatus","commandValues":["Português (Brasil);pt-BR","Inglês (EUA);en-US"]}'),
      [(name: 'Inglês (EUA)', tag: 'en-US'), (name: 'Português (Brasil)', tag: 'pt-BR')],
    );
    expect(parseLanguageList('{"commandValues":{}}'), isEmpty);
  });

  test('o zoom que faz caber a largura e a página', () {
    // A4 em pé: 11906 twips de largura, 16838 de altura (mais o espaço).
    const row = 11906 + 2 * 284.0, page = 16838 + 284.0;
    final width = fitZoom(const Size(1000, 700), rowTwips: row, pageHeightTwips: page, whole: false);
    expect(width, closeTo((1000 - 48) * 15 / row, 0.05));
    final whole = fitZoom(const Size(1000, 700), rowTwips: row, pageHeightTwips: page, whole: true);
    expect(whole, lessThan(width), reason: 'a página inteira cabe na altura');
    expect((whole * 20) % 1, 0, reason: 'em passos de 5 %');
    expect(fitZoom(Size.zero, rowTwips: row, pageHeightTwips: page, whole: true), 1);
  });

  testWidgets('o idioma abre o menu com os do motor e troca o do parágrafo', (tester) async {
    final h = await pumpApp(tester);
    expect(h.doc.languages.map((l) => l.tag), ['en-US', 'pt-BR']);
    await tester.tap(find.text('Português (Brasil)'));
    await tester.pumpAndSettle();
    expect(find.text('Idioma do parágrafo'), findsOneWidget);
    await tester.tap(find.text('Inglês (EUA)'));
    await tester.pumpAndSettle();
    expect(h.kit.unoCommands.last, '.uno:LanguageStatus');
    expect(h.kit.unoArgs.last, contains('Paragraph_Inglês (EUA)'));

    await tester.tap(find.text('Português (Brasil)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sem verificação de ortografia'));
    await tester.pumpAndSettle();
    expect(h.kit.unoArgs.last, contains('Paragraph_LANGUAGE_NONE'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('as palavras abrem as estatísticas', (tester) async {
    final h = await pumpApp(tester);
    h.kit.emitState('.uno:StateWordCount', '1.204 palavras, 7.010 caracteres');
    await tester.pump();
    await tester.tap(find.text('1204 palavras'));
    await tester.pumpAndSettle();
    expect(find.text('Caracteres'), findsOneWidget);
    expect(find.text('7010'), findsOneWidget);
    expect(find.text('Páginas'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Caracteres'), findsNothing);
  });

  testWidgets('o zoom: as medidas e o ajuste à largura', (tester) async {
    final h = await pumpApp(tester);
    await tester.tap(find.bySemanticsLabel('100 %').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('150 %'));
    await tester.pumpAndSettle();
    expect(h.doc.zoom, 1.5);
    await tester.tap(find.bySemanticsLabel('150 %').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajustar à largura'));
    await tester.pumpAndSettle();
    expect(h.doc.zoom, isNot(1.5));
    expect(h.doc.zoom, greaterThan(0.5));
  });

  testWidgets('pelo teclado: o foco num campo e Enter', (tester) async {
    await pumpApp(tester);
    final page = find.text('Página 1 de 3');
    Focus.of(tester.element(page)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(OutlinePanel), findsOneWidget);
  });

  testWidgets('"modificado" salva no clique', (tester) async {
    final h = await pumpApp(tester);
    h.kit.emitState('.uno:ModifiedStatus', 'true');
    await tester.pump();
    await tester.tap(find.text('modificado'));
    await tester.pumpAndSettle();
    expect(h.kit.saved, isNotEmpty);
  });
}
