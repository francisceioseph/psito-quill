// As prévias de fontes e estilos (Fase 2B, Etapa 3, D-044 e D-045): a lista
// de fontes desenhada na própria fonte, com busca, filtros e seções, e os
// cartões de estilo com as propriedades da cópia temporária.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/app.dart';
import 'package:psito_quill/src/kit/fake/fake_quill_kit.dart';
import 'package:psito_quill/src/kit/quill_kit.dart' show FontClass;
import 'package:psito_quill/src/ui/atoms/w_chip.dart';
import 'package:psito_quill/src/ui/atoms/w_text_field.dart';
import 'package:psito_quill/src/ui/molecules/style_card.dart';
import 'package:psito_quill/src/ui/organisms/font_picker.dart';
import 'package:psito_quill/src/ui/organisms/styles_dialog.dart';

import 'package:psito_quill/src/ui/atoms/w_button.dart';

import '../support/harness.dart';

void main() {
  late Harness h;
  late FakeQuillKit kit;
  Harness? current;

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1500, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.localesTestValue = [const Locale('pt', 'BR')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    h = current = Harness();
    kit = h.kit;
    h.settings.inspector = false;
    await tester.pumpWidget(QuillApp(workspace: h.workspace, settings: h.settings, window: h.window, showMemory: false));
    h.doc.open('/livro/cap.odt');
    // A cópia temporária é lida num isolate: espera de verdade.
    await tester.runAsync(() async {
      for (var i = 0; i < 50 && h.doc.snapshot.styles.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pump();
  }

  tearDown(() {
    current?.dispose();
    current = null;
  });

  group('a lista achatada', () {
    const titles = (inDocument: 'Doc', recent: 'Rec', all: 'Todas');
    const all = ['Liberation Mono', 'Liberation Sans', 'Liberation Serif', 'Noto Serif'];
    const classes = {
      'Liberation Mono': FontClass.mono,
      'Liberation Sans': FontClass.sans,
      'Liberation Serif': FontClass.serif,
      'Noto Serif': FontClass.serif,
    };

    test('as seções, com a fonte repetida em Todas', () {
      final items = fontListItems(
          all: all, inDocument: ['Liberation Serif'], recent: ['Noto Serif'], classes: classes, query: '', filter: FontFilter.all, titles: titles);
      expect(items.where((i) => i.header).map((i) => i.text), ['Doc', 'Rec', 'Todas']);
      expect(items.where((i) => !i.header && i.text == 'Liberation Serif'), hasLength(2));
    });

    test('a busca e o filtro; seção vazia some; fonte que não existe não aparece', () {
      final items = fontListItems(
          all: all, inDocument: ['Fonte Sumida'], recent: const [], classes: classes, query: 'lib', filter: FontFilter.serif, titles: titles);
      expect(items, [const FontListItem.header('Todas'), const FontListItem.font('Liberation Serif')]);
    });
  });

  testWidgets('a lista de fontes: na própria fonte, seções, busca e filtro', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byType(FontPicker));
    await tester.pumpAndSettle();
    expect(find.text('Neste documento'), findsOneWidget, reason: 'a fonte declarada na cópia');
    final noto = tester.widget<Text>(find.text('Noto Serif'));
    expect(noto.style!.fontFamily, 'Noto Serif');

    await tester.enterText(find.descendant(of: find.byType(WTextField), matching: find.byType(TextField)), 'noto');
    await tester.pump();
    expect(find.text('Liberation Sans'), findsNothing);
    expect(find.text('Noto Serif'), findsOneWidget);

    await tester.tap(find.widgetWithText(WChip, 'Mono'));
    await tester.pump();
    expect(find.text('Nenhuma fonte com esse nome'), findsOneWidget);
  });

  testWidgets('escolher uma fonte aplica, guarda nas recentes e fecha', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byType(FontPicker));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Noto Serif').last);
    await tester.pumpAndSettle();
    expect(kit.unoCommands.last, '.uno:CharFontName');
    expect(kit.unoArgs.last, contains('"Noto Serif"'));
    expect(h.settings.recentFonts, ['Noto Serif']);
    expect(find.text('Neste documento'), findsNothing, reason: 'a lista fechou');

    await tester.tap(find.byType(FontPicker));
    await tester.pumpAndSettle();
    expect(find.text('Recentes'), findsOneWidget);
  });

  testWidgets('Enter na busca aplica a primeira que sobrou', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byType(FontPicker));
    await tester.pumpAndSettle();
    await tester.enterText(find.descendant(of: find.byType(WTextField), matching: find.byType(TextField)), 'sans');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(kit.unoArgs.last, contains('"Liberation Sans"'));
  });

  testWidgets('os cartões de estilo usam as propriedades da cópia', (tester) async {
    await pumpApp(tester);
    // A aba Estilos mostra a galeria inteira (o Início, só o que cabe).
    await tester.tap(find.widgetWithText(WTextButton, 'Estilos'));
    await tester.pump();
    final h1 = tester.widget<StyleCard>(find.ancestor(of: find.text('Título 1'), matching: find.byType(StyleCard)).first);
    expect(h1.sample.bold, isTrue);
    expect(h1.sample.fontFamily, 'Liberation Serif');
    expect(h1.sample.scale, closeTo(18 / 12, 0.01));
    final quote = tester.widget<StyleCard>(find.ancestor(of: find.text('Citação'), matching: find.byType(StyleCard)).first);
    expect(quote.sample.italic, isTrue);
  });

  testWidgets('Revelar formatação: o itálico no corpo de texto é direto', (tester) async {
    await pumpApp(tester);
    h.settings.inspector = true;
    kit.emitState('.uno:StyleApply', 'Text body');
    kit.emitState('.uno:Italic', 'true');
    kit.emitState('.uno:CharFontName', 'Liberation Serif');
    kit.emitState('.uno:FontHeight', '12');
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.f1);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp(r'Efeitos: Itálico, direto')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'Fonte: Liberation Serif, 12 pt, estilo')), findsOneWidget);
    expect(find.widgetWithText(WChip, 'Tirar o que é direto'), findsOneWidget);
  });

  testWidgets('a galeria aberta: busca, do livro, o atalho no cartão', (tester) async {
    await pumpApp(tester);
    h.doc.newStyleFromSelection('Cena');
    await tester.pump();
    await tester.tap(find.text('Estilos').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Gerenciar estilos…').first);
    await tester.pumpAndSettle();
    final dialog = find.byType(Dialog);
    final h1 = tester.widget<StyleCard>(find.descendant(of: dialog, matching: find.ancestor(of: find.text('Título 1'), matching: find.byType(StyleCard))).first);
    expect(h1.shortcut, 'Ctrl+Alt+1');
    await tester.tap(find.descendant(of: dialog, matching: find.widgetWithText(WChip, 'Do livro')));
    await tester.pump();
    expect(find.descendant(of: dialog, matching: find.byType(StyleCard)), findsOneWidget, reason: 'só a Cena é do autor');
    await tester.tap(find.descendant(of: dialog, matching: find.widgetWithText(WChip, 'Todas')));
    await tester.enterText(find.descendant(of: dialog, matching: find.byType(TextField)), 'citação');
    await tester.pump();
    expect(find.descendant(of: dialog, matching: find.byType(StyleCard)), findsOneWidget);
  });

  testWidgets('o ▾ da galeria do Início desce todos os estilos; escolher aplica e fecha (D-055)', (tester) async {
    await pumpApp(tester);
    expect(find.byType(Dialog), findsNothing);
    await tester.tap(find.byTooltip('Mais estilos'));
    await tester.pumpAndSettle();
    final panel = find.byType(StylesDialog);
    expect(panel, findsOneWidget);
    expect(find.byType(Dialog), findsNothing, reason: 'desce da galeria, não é uma janela');
    final cards = find.descendant(of: panel, matching: find.byType(StyleCard));
    expect(cards.evaluate().length, h.doc.paragraphStyles.length, reason: 'todos os do documento');
    await tester.enterText(find.descendant(of: panel, matching: find.byType(TextField)), 'citação');
    await tester.pump();
    expect(cards, findsOneWidget);
    await tester.tap(cards);
    await tester.pumpAndSettle();
    expect(find.byType(StylesDialog), findsNothing, reason: 'escolher fecha');
    expect(kit.unoArgs.last, contains('Quotations'));

    await tester.tap(find.byTooltip('Mais estilos'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(StylesDialog), findsNothing, reason: 'Esc fecha');
    expect(tester.takeException(), isNull);
  });
}
