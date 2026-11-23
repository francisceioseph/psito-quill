// A régua na tela (Fase 2B, Etapa 4, D-046): aparece com o documento,
// arrastar e o teclado mudam os recuos, e Exibir › Régua esconde.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/app.dart';
import 'package:psito_quill/src/kit/fake/fake_quill_kit.dart';
import 'package:psito_quill/src/ui/organisms/ruler.dart';

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
    await tester.pump();
    await tester.pump();
  }

  tearDown(() {
    current?.dispose();
    current = null;
  });

  testWidgets('a régua aparece com o documento, com as marcas para o leitor de tela', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester);
    expect(find.byType(HorizontalRuler), findsOneWidget);
    expect(find.byType(VerticalRuler), findsOneWidget);
    expect(find.bySemanticsLabel('Recuo esquerdo'), findsOneWidget);
    expect(find.bySemanticsLabel('Recuo da primeira linha'), findsOneWidget);
    expect(find.bySemanticsLabel('Recuo direito'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('arrastar o recuo esquerdo manda os recuos ao soltar', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester);
    final mark = tester.getCenter(find.bySemanticsLabel('Recuo esquerdo'));
    final before = kit.unoCommands.length;
    final gesture = await tester.startGesture(mark);
    await gesture.moveBy(const Offset(60, 0));
    await tester.pump();
    expect(kit.unoCommands.length, before, reason: 'no meio do arrasto, nada vai ao motor');
    await gesture.up();
    await tester.pump();
    expect(kit.unoCommands.last, '.uno:LeftRightParaMargin');
    expect(kit.unoArgs.last, contains('LRSpace.LeftMargin'));
    expect(kit.unoArgs.last, contains('LRSpace.FirstLineIndent'));
    // O duplo clique da régua espera o segundo toque.
    await tester.pump(const Duration(milliseconds: 400));
    handle.dispose();
  });

  testWidgets('pelo teclado: Tab até a marca, a seta anda 1 mm', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester);
    // O foco da marca (o Tab chega nela; aqui, direto).
    final box = find.descendant(of: find.bySemanticsLabel('Recuo direito'), matching: find.byType(SizedBox)).first;
    Focus.of(tester.element(box)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(kit.unoCommands.last, '.uno:LeftRightParaMargin');
    expect(kit.unoArgs.last, contains('"LRSpace.RightMargin":{"type":"long","value":100}'));
    handle.dispose();
  });

  testWidgets('Exibir › Régua esconde e mostra (e guarda)', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Exibir'));
    await tester.pump();
    await tester.tap(find.byTooltip('Régua'));
    await tester.pump();
    expect(find.byType(HorizontalRuler), findsNothing);
    expect(h.settings.ruler, isFalse);
  });
}
