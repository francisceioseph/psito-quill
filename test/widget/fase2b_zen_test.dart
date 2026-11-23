// O modo zen (Fase 2B, Etapa 6, D-048): F11 entra em tela cheia só com a
// página e a barrinha; Esc sai e devolve a faixa.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/app.dart';
import 'package:psito_quill/src/ui/organisms/ribbon.dart';
import 'package:psito_quill/src/ui/organisms/status_bar.dart';
import 'package:psito_quill/src/ui/organisms/zen_view.dart';

import '../support/harness.dart';

void main() {
  late Harness h;
  Harness? current;

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1500, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.localesTestValue = [const Locale('pt', 'BR')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    h = current = Harness();
    await tester.pumpWidget(QuillApp(workspace: h.workspace, settings: h.settings, window: h.window, showMemory: false));
    h.doc.open('/livro/cap.odt');
    await tester.pump();
    await tester.pump();
  }

  tearDown(() {
    current?.dispose();
    current = null;
  });

  testWidgets('F11 entra: tela cheia, sem faixa nem barra de status; Esc sai', (tester) async {
    await pumpApp(tester);
    expect(find.byType(Ribbon), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.f11);
    await tester.pump();
    expect(find.byType(ZenView), findsOneWidget);
    expect(find.byType(Ribbon), findsNothing);
    expect(find.byType(StatusBar), findsNothing);
    expect(h.window.fullscreen, [true]);
    await tester.pump(const Duration(seconds: 3));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.byType(ZenView), findsNothing);
    expect(find.byType(Ribbon), findsOneWidget);
    expect(h.window.fullscreen, [true, false]);
    expect(h.settings.zen, isFalse);
  });

  testWidgets('a barrinha liga e desliga o foco e a máquina de escrever, e troca o papel', (tester) async {
    await pumpApp(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.f11);
    await tester.pump();
    final focus = h.settings.zenFocus, typewriter = h.settings.zenTypewriter, paper = h.settings.zenPaper;
    await tester.tap(find.text('Foco no parágrafo'));
    await tester.pump();
    await tester.tap(find.text('Máquina de escrever'));
    await tester.pump();
    await tester.tap(find.text('Papel'));
    await tester.pump();
    expect(h.settings.zenFocus, !focus);
    expect(h.settings.zenTypewriter, !typewriter);
    expect(h.settings.zenPaper, isNot(paper));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(seconds: 3));
  });
}
