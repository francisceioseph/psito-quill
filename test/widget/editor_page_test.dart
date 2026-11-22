import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/app.dart';
import 'package:psito_quill/src/document/document_controller.dart';
import 'package:psito_quill/src/kit/fake/fake_quill_kit.dart';
import 'package:psito_quill/src/kit/quill_kit.dart';
import 'package:psito_quill/src/ui/atoms/w_button.dart';
import 'package:psito_quill/src/ui/tokens/themes/themes.dart';

void main() {
  late FakeQuillKit kit;
  DocumentController? current;
  DocumentController track(DocumentController d) => current = d;

  Future<void> pumpApp(WidgetTester tester, {String path = '/livro/cap.docx'}) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.localesTestValue = const [Locale('pt', 'BR')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    kit = FakeQuillKit();
    final doc = track(DocumentController(kit)..start());
    await tester.pumpWidget(QuillApp(doc: doc, showMemory: false));
    doc.open(path);
    await tester.pump();
  }

  tearDown(() {
    current?.dispose();
    current = null;
  });

  testWidgets('o botão Negrito acende pelo estado do motor', (tester) async {
    await pumpApp(tester);
    WToggle bold() => tester.widget<WToggle>(find.widgetWithIcon(WToggle, Icons.format_bold));
    expect(bold().value, isFalse);
    await tester.tap(find.widgetWithIcon(WToggle, Icons.format_bold));
    await tester.pump();
    expect(kit.unoCommands, contains('.uno:Bold'));
    expect(bold().value, isTrue);
  });

  testWidgets('Salvar grava e a barra de status avisa', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.widgetWithIcon(WButton, Icons.save_outlined));
    await tester.pump();
    expect(kit.saved.single, ('/livro/cap.docx', 'docx'));
    expect(find.text('Salvo em /livro/cap.docx'), findsOneWidget);
  });

  testWidgets('Ctrl+B salva (Word em português)', (tester) async {
    await pumpApp(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(kit.saved, hasLength(1));
  });

  testWidgets('documento novo: Salvar fica desligado', (tester) async {
    await pumpApp(tester, path: '');
    final save = tester.widget<WButton>(find.widgetWithIcon(WButton, Icons.save_outlined));
    expect(save.onPressed, isNull);
  });

  testWidgets('o tema escuro troca a moldura e o papel do motor', (tester) async {
    await pumpApp(tester);
    kit.unoCommands.clear();
    await tester.tap(find.widgetWithIcon(WToggle, Icons.dark_mode_outlined));
    await tester.pumpAndSettle();
    expect(kit.unoCommands, ['.uno:ChangeTheme']);
    final scaffold = Theme.of(tester.element(find.byType(Scaffold)));
    expect(scaffold.scaffoldBackgroundColor, escuro.colors.frame);
  });

  testWidgets('motor que não liga aparece em vermelho na barra', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('pt', 'BR')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    kit = FakeQuillKit(failStart: true);
    final doc = track(DocumentController(kit)..start());
    await tester.pumpWidget(QuillApp(doc: doc, showMemory: false));
    expect(find.textContaining('O motor não ligou'), findsWidgets);
  });

  testWidgets('em inglês, os rótulos mudam', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    kit = FakeQuillKit();
    final doc = track(DocumentController(kit)..start());
    await tester.pumpWidget(QuillApp(doc: doc, showMemory: false));
    doc.open('/a.odt');
    await tester.pump();
    expect(tester.widget<WToggle>(find.widgetWithIcon(WToggle, Icons.format_bold)).label, 'Bold');
  });

  testWidgets('toda ação tem nome para o leitor de tela', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester);
    expect(find.bySemanticsLabel(RegExp('^Negrito')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Salvar')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Tema escuro')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Documento')), findsOneWidget);
    handle.dispose();
  });

  test('o kit falso cobre a porta inteira', () {
    // Se a porta ganhar um método, este teste lembra de cobrir no falso.
    final QuillKit k = FakeQuillKit();
    expect(k.textureId(0), -1);
  });
}
