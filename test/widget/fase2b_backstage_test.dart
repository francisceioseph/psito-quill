// Os bastidores do Arquivo e a tela inicial (Etapa 7, passo 7, D-064).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/l10n/gen/app_localizations_pt.dart';
import 'package:psito_quill/src/app.dart';
import 'package:psito_quill/src/files/open_folder.dart';
import 'package:psito_quill/src/ui/organisms/file_panel.dart';
import 'package:psito_quill/src/ui/organisms/start_screen.dart';

import '../support/harness.dart';

void main() {
  Harness? current;

  Future<Harness> pumpApp(WidgetTester tester, {bool open = true}) async {
    await tester.binding.setSurfaceSize(const Size(1500, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.localesTestValue = [const Locale('pt', 'BR')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final h = current = Harness();
    await tester.pumpWidget(QuillApp(workspace: h.workspace, settings: h.settings, window: h.window, showMemory: false));
    if (open) {
      await h.workspace.openPath(h.file('capitulo-1.odt'));
      await tester.pump();
      await tester.pump();
    }
    return h;
  }

  tearDown(() {
    current?.dispose();
    current = null;
  });

  test('o tamanho do arquivo', () {
    final l10n = AppLocalizationsPt();
    expect(formatFileSize(900, l10n), '900 bytes');
    expect(formatFileSize(12 * 1024, l10n), '12 KB');
    expect(formatFileSize(1468006, l10n), '1,4 MB');
  });

  testWidgets('com um arquivo salvo, o Arquivo abre nas Informações', (tester) async {
    final h = await pumpApp(tester);
    h.kit.emitState('.uno:StateWordCount', '250 palavras, 1400 caracteres');
    await tester.pump();
    await tester.tap(find.text('Arquivo'));
    await tester.pumpAndSettle();
    expect(find.byType(FilePanel), findsOneWidget);
    expect(find.text('capitulo-1.odt'), findsOneWidget);
    expect(find.text('Tamanho'), findsOneWidget);
    expect(find.text('1 bytes'), findsOneWidget);
    expect(find.text('250'), findsOneWidget);
    expect(find.text('1400'), findsOneWidget);

    final opened = <String>[];
    final before = openFolder;
    openFolder = (d) async => opened.add(d);
    addTearDown(() => openFolder = before);
    await tester.tap(find.text('Abrir a pasta do arquivo'));
    expect(opened, [h.dir.path]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Recentes: a tabela com a pasta, e o que sumiu fica apagado', (tester) async {
    final h = await pumpApp(tester);
    h.recents.add('/nao/existe/velho.odt');
    await tester.tap(find.text('Arquivo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recentes'));
    await tester.pumpAndSettle();
    expect(find.text('Arquivos recentes'), findsOneWidget);
    expect(find.text('Não encontrado'), findsOneWidget);
    await tester.tap(find.text('velho.odt'));
    await tester.pumpAndSettle();
    expect(h.kit.opened.last, isNot('/nao/existe/velho.odt'), reason: 'apagado, não abre');
  });

  testWidgets('Fechar a última aba leva à tela inicial; o cartão abre um documento', (tester) async {
    final h = await pumpApp(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyW);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(h.doc.tabs, isEmpty);
    expect(find.byType(StartScreen), findsOneWidget);
    expect(find.text('capitulo-1.odt'), findsOneWidget, reason: 'nos recentes');
    await tester.tap(find.text('Documento em branco'));
    await tester.pump();
    await tester.pump();
    expect(h.doc.tabs, hasLength(1));
    expect(find.byType(StartScreen), findsNothing);
  });

  testWidgets('"Mais informações…" das palavras abre as Informações', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.textContaining('palavra'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mais informações…'));
    await tester.pumpAndSettle();
    expect(find.byType(FilePanel), findsOneWidget);
    expect(find.text('Tamanho'), findsOneWidget);
  });

  testWidgets('Preferências: a abertura sem arquivo', (tester) async {
    final h = await pumpApp(tester);
    await tester.tap(find.text('Arquivo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preferências'));
    await tester.pumpAndSettle();
    expect(h.settings.startScreen, isTrue);
    await tester.tap(find.text('Documento em branco'));
    await tester.pumpAndSettle();
    expect(h.settings.startScreen, isFalse);
  });
}
