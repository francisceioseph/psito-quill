// Acessibilidade (Etapa 9, D-067): os temas de alto contraste, o texto da
// interface a 200 %, os botões maiores, o cursor, reduzir movimento, o zoom
// ao abrir e o documento para o leitor de tela.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/app.dart';
import 'package:psito_quill/src/kit/quill_kit.dart';
import 'package:psito_quill/src/ui/atoms/w_switch.dart';
import 'package:psito_quill/src/ui/organisms/document_view.dart';
import 'package:psito_quill/src/ui/organisms/inspector.dart';
import 'package:psito_quill/src/ui/organisms/ribbon.dart';
import 'package:psito_quill/src/ui/tokens/themes/themes.dart';
import 'package:psito_quill/src/ui/tokens/tokens.dart';

import '../support/harness.dart';

void main() {
  Harness? current;

  Future<Harness> pumpApp(WidgetTester tester, {Size size = const Size(1500, 900), void Function(Harness h)? before}) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.localesTestValue = [const Locale('pt', 'BR')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final h = current = Harness();
    before?.call(h);
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

  for (final id in ['altoContrasteEscuro', 'altoContrasteClaro']) {
    testWidgets('o tema $id troca a moldura e o papel', (tester) async {
      final h = await pumpApp(tester, before: (h) => h.settings.theme = id);
      final theme = themeById(id);
      expect(Theme.of(tester.element(find.byType(Scaffold))).scaffoldBackgroundColor, theme.colors.frame);
      expect(h.kit.unoArgs.any((a) => a.contains(theme.paperScheme)), isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  for (final (size, scale) in const [(Size(1366, 768), 1.5), (Size(1920, 1080), 2.0), (Size(2560, 1440), 2.0)]) {
    testWidgets('a interface a ${(scale * 100).round()} % em ${size.width.toInt()} px: nada vaza na faixa nem no painel', (tester) async {
      await pumpApp(tester, size: size, before: (h) {
        h.settings
          ..uiScale = scale
          ..inspector = true;
      });
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byType(Ribbon));
      expect(MediaQuery.sizeOf(ctx).width, size.width / scale, reason: 'a área encolhe e tudo cresce junto');
      expect(MediaQuery.devicePixelRatioOf(ctx), closeTo(tester.view.devicePixelRatio * scale, 0.001));
      expect(tester.getRect(find.byType(Ribbon)).width, closeTo(size.width, 1), reason: 'desenhada na janela inteira');
      expect(find.byType(Inspector), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('botões maiores: a densidade confortável', (tester) async {
    await pumpApp(tester, before: (h) => h.settings.comfortable = true);
    expect(QuillTokens.of(tester.element(find.byType(Ribbon))).density.control, 44);
    expect(tester.takeException(), isNull);
  });

  testWidgets('o cursor: a espessura e o piscar vêm das preferências', (tester) async {
    await pumpApp(tester, before: (h) {
      h.settings
        ..caretWidth = 3
        ..caretBlink = false;
    });
    final view = tester.widget<DocumentView>(find.byType(DocumentView));
    expect(view.caretWidth, 3);
    expect(view.caretBlink, isFalse);
  });

  testWidgets('reduzir movimento: sem animações e as durações a zero', (tester) async {
    await pumpApp(tester, before: (h) => h.settings.reduceMotion = true);
    final ctx = tester.element(find.byType(Ribbon));
    expect(MediaQuery.disableAnimationsOf(ctx), isTrue);
    expect(QuillTokens.of(ctx).motion.fast, Duration.zero);
  });

  testWidgets('o zoom ao abrir: ajustar à largura', (tester) async {
    final h = await pumpApp(tester, before: (h) => h.settings.zoomOnOpen = 'largura');
    await tester.pumpAndSettle();
    expect(h.doc.zoom, isNot(1.0));
  });

  testWidgets('o documento para o leitor de tela: o parágrafo e o cursor', (tester) async {
    final h = await pumpApp(tester);
    expect(h.kit.accessibility, isEmpty, reason: 'desligado por padrão');
    h.settings.screenReaderDoc = true;
    await tester.pump();
    await tester.pump();
    expect(h.kit.accessibility, [true]);
    h.kit.emit(const A11yParagraph('Era uma vez um livro.', 7));
    await tester.pump();
    final node = tester.getSemantics(find.byType(DocumentSemantics));
    expect(node.value, 'Era uma vez um livro.');
    expect(node.textSelection, const TextSelection.collapsed(offset: 7));
    expect(node.flagsCollection.isTextField, isTrue);
    h.kit.emit(const A11yCaret(12));
    await tester.pump();
    expect(tester.getSemantics(find.byType(DocumentSemantics)).textSelection, const TextSelection.collapsed(offset: 12));

    h.settings.screenReaderDoc = false;
    await tester.pump();
    await tester.pump();
    expect(h.kit.accessibility, [true, false]);
    expect(tester.getSemantics(find.byType(DocumentSemantics)).value, isEmpty);
  });

  testWidgets('Preferências › Acessibilidade: os botões maiores pelo interruptor', (tester) async {
    final h = await pumpApp(tester);
    await tester.tap(find.text('Arquivo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preferências'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Acessibilidade'));
    await tester.pumpAndSettle();
    expect(find.text('Tamanho da interface'), findsOneWidget);
    await tester.tap(find.byWidgetPredicate((w) => w is WSwitch && w.label == 'Botões maiores'));
    await tester.pumpAndSettle();
    expect(h.settings.comfortable, isTrue);
    await tester.tap(find.text('200 %'));
    await tester.pumpAndSettle();
    expect(h.settings.uiScale, 2);
    expect(tester.takeException(), isNull);
  });
}
