// A tela nos recursos da Fase 2, com o kit falso: localizar e substituir,
// a paleta, o painel Formatar e "Revelar formatação", o clique direito com
// a ortografia, tabela e imagem, os estilos e o tema Clássico 97.
import 'package:flutter/gestures.dart' show kSecondaryButton;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/l10n/gen/app_localizations_pt.dart';
import 'package:psito_quill/src/app.dart';
import 'package:psito_quill/src/commands/command_registry.dart';
import 'package:psito_quill/src/commands/commands_book.dart';
import 'package:psito_quill/src/commands/commands_document.dart';
import 'package:psito_quill/src/commands/commands_page.dart';
import 'package:psito_quill/src/commands/commands_view.dart';
import 'package:psito_quill/src/commands/menus.dart';
import 'package:psito_quill/src/kit/fake/fake_quill_kit.dart';
import 'package:psito_quill/src/kit/quill_kit.dart';
import 'package:psito_quill/src/ui/atoms/w_button.dart';
import 'package:psito_quill/src/ui/atoms/w_color_swatch.dart';
import 'package:psito_quill/src/ui/organisms/classic_bars.dart';
import 'package:psito_quill/src/ui/organisms/document_view.dart';
import 'package:psito_quill/src/ui/organisms/find_panel.dart';
import 'package:psito_quill/src/ui/organisms/inspector.dart';
import 'package:psito_quill/src/ui/organisms/nav_rail.dart';
import 'package:psito_quill/src/ui/organisms/ribbon.dart';
import 'package:psito_quill/src/ui/molecules/style_card.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../support/harness.dart';

class _NoBookView implements BookViewActions {
  @override
  bool binderOpen = false;
  @override
  void newBook() {}
  @override
  void openBook() {}
  @override
  void importManuscript() {}
  @override
  void toggleBinder() {}
  @override
  void newChapter() {}
  @override
  void newPart() {}
  @override
  void newScene() {}
  @override
  void splitChapter() {}
  @override
  void joinChapter() {}
  @override
  void convertScenes() {}
  @override
  void takeSnapshot() {}
  @override
  void showSnapshots() {}
  @override
  void toggleNotes() {}
  @override
  bool get notesOpen => false;
  @override
  void newNote() {}
  @override
  void showGoals() {}
  @override
  void toggleCorkboard() {}
  @override
  bool get corkboardOpen => false;
}

class _NoPageView implements PageViewActions {
  @override
  void exportPdf() {}
  @override
  void printDocument() {}
  @override
  void editLink() {}
  @override
  void openLink(DocLink link) {}
  @override
  void specialCharacter() {}
}

class _NoView implements EditorViewActions {
  @override
  bool inspectorOpen = false, revealOpen = false, outlineOpen = false, stylesPanelOpen = false, ribbonCollapsed = false, rulerShown = true, zenOpen = false;
  @override
  void toggleZen() {}
  @override
  void zoomToFit({required bool page}) {}
  @override
  void toggleStatusBar() {}
  @override
  bool statusBarShown = true;
  @override
  String pageLayout = 'uma';
  @override
  void toggleRuler() {}
  @override
  void toggleOutline() {}
  @override
  void toggleStylesPanel() {}
  @override
  void toggleRibbon() {}
  @override
  void about() {}
  @override
  void insertImage() {}
  @override
  void insertTable() {}
  @override
  void manageStyles() {}
  @override
  void newStyle() {}
  @override
  void openFilePanel() {}
  @override
  void openFind({required bool replace}) {}
  @override
  void openPalette() {}
  @override
  void toggleInspector() {}
  @override
  void toggleReveal() {}
}

void main() {
  late Harness h;
  late FakeQuillKit kit;
  Harness? current;

  Future<void> pumpApp(WidgetTester tester, {bool inspector = false, String theme = 'claro'}) async {
    await tester.binding.setSurfaceSize(const Size(1500, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.localesTestValue = [const Locale('pt', 'BR')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    h = current = Harness();
    kit = h.kit;
    h.settings
      ..inspector = inspector
      ..theme = theme;
    await tester.pumpWidget(QuillApp(workspace: h.workspace, settings: h.settings, window: h.window, showMemory: false));
    h.doc.open('/livro/cap.odt');
    await tester.pump();
  }

  tearDown(() {
    current?.dispose();
    current = null;
  });

  Future<void> keys(WidgetTester tester, LogicalKeyboardKey key, {bool ctrl = true, bool shift = false}) async {
    if (ctrl) await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(key);
    if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    if (ctrl) await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
  }

  test('todo item dos menus é um comando registrado', () {
    final harness = Harness();
    addTearDown(harness.dispose);
    final l10n = AppLocalizationsPt();
    final registry = CommandRegistry();
    registerEditorCommands(registry, doc: harness.doc, workspace: harness.workspace, l10n: l10n);
    registerViewCommands(registry, doc: harness.doc, view: _NoView(), l10n: l10n);
    registerBookCommands(registry, doc: harness.doc, workspace: harness.workspace, view: _NoBookView(), l10n: l10n);
    registerPageCommands(registry, doc: harness.doc, view: _NoPageView(), l10n: l10n);
    for (final m in editorMenus(l10n)) {
      for (final id in m.items.whereType<String>()) {
        expect(registry[id], isNotNull, reason: '${m.title}: $id');
      }
    }
  });

  testWidgets('Ctrl+U abre o painel Localizar e substituir; Enter acha, "Todas" conta, Esc fecha', (tester) async {
    await pumpApp(tester);
    h.doc.insertText('Um texto e outro texto.');
    // O Ctrl+L abre a busca única (D-050); o painel com as opções é o Ctrl+U.
    await keys(tester, LogicalKeyboardKey.keyU);
    expect(find.byType(FindPanel), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'texto');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(kit.unoCommands.last, '.uno:ExecuteSearch');
    await tester.tap(find.widgetWithText(WButton, 'Todas'));
    await tester.pump();
    expect(find.text('2 ocorrências'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'nada');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('Nada encontrado'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(FindPanel), findsNothing);
  });

  testWidgets('Ctrl+U abre substituir; "Substituir todas" diz quantas', (tester) async {
    await pumpApp(tester);
    h.doc.insertText('gato e gato');
    await keys(tester, LogicalKeyboardKey.keyU);
    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(2));
    await tester.enterText(fields.at(0), 'gato');
    await tester.enterText(fields.at(1), 'cão');
    await tester.tap(find.widgetWithText(WTextButton, 'Substituir todas'));
    await tester.pump();
    expect(kit.text, 'cão e cão');
    expect(find.text('2 trocadas'), findsOneWidget);
  });

  testWidgets('Ctrl+K: a paleta acha o comando sem acento e roda com Enter', (tester) async {
    await pumpApp(tester);
    await keys(tester, LogicalKeyboardKey.keyK);
    await tester.enterText(find.byType(TextField), 'italico');
    await tester.pump();
    expect(find.text('Itálico'), findsWidgets);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(kit.unoCommands.last, '.uno:Italic');
  });

  testWidgets('o painel Formatar: cor, recuo e "Revelar formatação" (Shift+F1)', (tester) async {
    await pumpApp(tester, inspector: true);
    expect(find.byType(Inspector), findsOneWidget);
    await tester.tap(find.byWidgetPredicate((w) => w is WColorSwatch && w.label == 'Vermelho'));
    await tester.pump();
    expect(kit.unoCommands.last, '.uno:Color');
    expect(kit.unoArgs.last, contains('${0xC9211E}'));

    // O recuo está na seção Parágrafo: só a seção escolhida é construída.
    await tester.tap(find.descendant(of: find.byType(NavRail<InspectorPart>), matching: find.text('Parágrafo')));
    await tester.pump();
    final indent = find.descendant(
      of: find.ancestor(of: find.text('Esquerda'), matching: find.byType(Column)).first,
      matching: find.byType(TextField),
    );
    await tester.enterText(indent, '1,5');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(kit.unoCommands.last, '.uno:LeftRightParaMargin');
    expect(kit.unoArgs.last, contains('1500'));

    kit.emitState('.uno:Bold', 'true');
    kit.emitState('.uno:CharFontName', 'Liberation Serif');
    await keys(tester, LogicalKeyboardKey.f1, ctrl: false, shift: true);
    expect(find.text('Revelar formatação'), findsWidgets);
    expect(find.text('Negrito'), findsWidgets);
    expect(find.textContaining('Liberation Serif'), findsWidgets);

    await keys(tester, LogicalKeyboardKey.f10, ctrl: false);
    expect(find.byType(Inspector), findsNothing);
    expect(h.settings.inspector, isFalse);
  });

  testWidgets('clique direito numa palavra errada: as sugestões do motor', (tester) async {
    await pumpApp(tester);
    kit.misspelled = {'erru': ['erro']};
    h.doc.insertText('um erru');
    await tester.pump();
    final view = tester.getCenter(find.byType(DocumentView));
    await tester.tapAt(view, buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    expect(kit.mice.where((m) => m.$1 == MouseEventType.down), hasLength(1), reason: 'só o direito, como botão 4');
    expect(find.text('erro'), findsOneWidget);
    expect(find.text('Ignorar'), findsOneWidget);
    expect(find.text('Copiar'), findsOneWidget);
    await tester.tap(find.text('erro'));
    await tester.pumpAndSettle();
    expect(kit.text, 'um erro');
  });

  testWidgets('clique direito › Parágrafo › Manter com o próximo (D-061)', (tester) async {
    await pumpApp(tester);
    h.doc.insertText('um parágrafo');
    await tester.pump();
    await tester.tapAt(tester.getCenter(find.byType(DocumentView)), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(SubmenuButton, 'Estilo'), findsOneWidget);
    expect(find.text('Selecionar tudo'), findsOneWidget);
    await tester.tap(find.widgetWithText(SubmenuButton, 'Parágrafo'));
    await tester.pumpAndSettle();
    expect(find.text('Permitir separar do próximo'), findsOneWidget);
    expect(find.text('Permitir dividir as linhas'), findsOneWidget);
    await tester.tap(find.text('Manter com o próximo'));
    await tester.pumpAndSettle();
    expect(kit.unoCommands.last, '.uno:ParaKeepTogether');
    expect(kit.unoArgs.last, contains('"value":true'));
    expect(find.widgetWithText(SubmenuButton, 'Estilo'), findsNothing, reason: 'o menu fechou');

    await tester.tapAt(tester.getCenter(find.byType(DocumentView)), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SubmenuButton, 'Parágrafo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manter as linhas juntas'));
    await tester.pumpAndSettle();
    expect(kit.unoCommands.last, '.uno:ParaSplit');
    expect(kit.unoArgs.last, contains('"value":false'), reason: 'manter juntas é não dividir');

    // O Esc fecha com o foco no documento, e não vai ao motor.
    await tester.tapAt(tester.getCenter(find.byType(DocumentView)), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    expect(find.text('Selecionar tudo'), findsOneWidget);
    final keys = kit.keys.length;
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Selecionar tudo'), findsNothing);
    expect(kit.keys.length, keys);
  });

  testWidgets('Inserir › Tabela: a grade insere, e a aba Tabela aparece', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.widgetWithText(WTextButton, 'Inserir'));
    await tester.pump();
    await tester.tap(find.widgetWithText(WBigButton, 'Tabela…'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(kit.unoCommands, contains('.uno:InsertTable'));
    expect(kit.unoArgs.last, allOf(contains('"Rows":{"type":"long","value":2}'), contains('"value":4}')));
    await tester.tap(find.widgetWithText(WTextButton, 'Tabela'));
    await tester.pump();
    await tester.tap(find.widgetWithIcon(WButton, Symbols.call_merge_rounded));
    expect(kit.unoCommands.last, '.uno:MergeCells');
  });

  testWidgets('Inserir › Imagem: escolhe o arquivo, mostra as alças e arrasta', (tester) async {
    await pumpApp(tester);
    h.dialogs.imageAnswer = '/fotos/capa.png';
    await tester.tap(find.widgetWithText(WTextButton, 'Inserir'));
    await tester.pump();
    await tester.tap(find.widgetWithText(WBigButton, 'Imagem…'));
    await tester.pumpAndSettle();
    expect(h.dialogs.images, ['Imagens']);
    expect(h.doc.graphic, isNotNull);
    expect(find.widgetWithText(WTextButton, 'Imagem'), findsOneWidget, reason: 'a aba contextual');

    // A alça de baixo à direita, arrastada 40 px.
    final viewBox = tester.renderObject<RenderBox>(find.byType(DocumentView));
    final g = PageGeometry(zoom: h.doc.zoom, viewSize: viewBox.size, documentTwips: h.doc.documentSize);
    final handle = viewBox.localToGlobal(g.toLocal(h.doc.graphic!).bottomRight);
    await tester.dragFrom(handle, const Offset(40, 40));
    await tester.pumpAndSettle();
    expect(kit.graphicDrags.map((d) => d.$1), [GraphicDrag.start, GraphicDrag.end]);
    expect(kit.graphicDrags.last.$2, greaterThan(kit.graphicDrags.first.$2));
  });

  testWidgets('novo estilo: nome repetido não passa; o criado entra na galeria', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.widgetWithText(WTextButton, 'Estilos'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(WButton, 'Novo estilo a partir da seleção…'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Heading 1');
    await tester.pump();
    expect(find.text('Já existe um estilo com esse nome'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Cena');
    await tester.pump();
    await tester.tap(find.widgetWithText(WTextButton, 'Criar'));
    await tester.pumpAndSettle();
    expect(kit.unoCommands, contains('.uno:StyleNewByExample'));
    final card = find.descendant(of: find.byType(Ribbon), matching: find.ancestor(of: find.text('Cena'), matching: find.byType(StyleCard)));
    expect(card, findsOneWidget);
    expect(tester.widget<StyleCard>(card).selected, isTrue);
  });

  testWidgets('Clássico 97: menus completos com atalhos, barras Padrão e Formatação', (tester) async {
    await pumpApp(tester, theme: 'classico97');
    expect(find.byType(Ribbon), findsNothing);
    expect(find.byType(ClassicMenuBar), findsOneWidget);
    expect(find.byType(ClassicToolbars), findsOneWidget);
    for (final m in ['Arquivo', 'Editar', 'Exibir', 'Inserir', 'Formatar', 'Estilos', 'Ferramentas', 'Tabela', 'Ajuda']) {
      expect(find.text(m), findsOneWidget, reason: m);
    }
    await tester.tap(find.text('Formatar'));
    await tester.pumpAndSettle();
    final bold = find.widgetWithText(MenuItemButton, 'Negrito');
    expect(bold, findsOneWidget);
    final shortcut = tester.widget<MenuItemButton>(bold).shortcut! as SingleActivator;
    expect((shortcut.trigger, shortcut.control), (LogicalKeyboardKey.keyN, true));
    await tester.tap(bold);
    await tester.pumpAndSettle();
    expect(kit.unoCommands.last, '.uno:Bold');

    // O tema volta pelo menu Exibir › Tema.
    await tester.tap(find.text('Exibir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tema'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Claro'));
    await tester.pumpAndSettle();
    expect(h.settings.theme, 'claro');
    expect(find.byType(Ribbon), findsOneWidget);
  });
}
