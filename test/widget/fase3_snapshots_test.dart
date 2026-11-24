// Os instantâneos (Fase 3, Etapa 7, D-081): a janela pelo menu do fichário,
// guardar com nome, restaurar (com o "Antes de restaurar"), comparar com a
// faixa e o automático antes do primeiro salvamento do dia.
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/app.dart';
import 'package:psito_quill/src/book/book.dart';
import 'package:psito_quill/src/book/book_io.dart';
import 'package:psito_quill/src/book/snapshots.dart';

import '../support/harness.dart';

void main() {
  Harness? current;

  String makeBook(Harness h) {
    final dir = '${h.dir.path}/Dustland.psitobook';
    createBookDir(dir);
    for (final f in ['001-abertura', '002-a-poeira']) {
      File('test/fixtures/capitulo-curto.odt').copySync('$dir/capitulos/$f.odt');
    }
    writeBook(
      dir,
      Book(title: 'Dustland', nodes: [
        BookNode(id: 'a', kind: BookNodeKind.chapter, title: 'Abertura', file: 'capitulos/001-abertura.odt'),
        BookNode(id: 'b', kind: BookNodeKind.chapter, title: 'A poeira', file: 'capitulos/002-a-poeira.odt'),
      ]),
    );
    return dir;
  }

  Future<Harness> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1500, 900));
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

  /// Espera o isolate (as palavras do instantâneo) até [done].
  Future<void> settleUntil(WidgetTester tester, bool Function() done) async {
    for (var i = 0; i < 40 && !done(); i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
    }
  }

  Future<void> openSnapshots(WidgetTester tester, String chapter) async {
    await tester.tap(find.text(chapter).first, buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Instantâneos…'));
    await tester.pumpAndSettle();
    expect(find.text('Instantâneos de $chapter'), findsOneWidget);
  }

  testWidgets('guardar com nome e restaurar um capítulo fechado', (tester) async {
    final h = await pumpApp(tester);
    final dir = makeBook(h);
    await tester.runAsync(() => h.workspace.openPath(dir));
    await tester.pump();
    final poeira = h.workspace.book.book!.find('b')!.$1;

    await openSnapshots(tester, 'A poeira');
    expect(find.textContaining('Nenhum instantâneo ainda'), findsOneWidget);
    await tester.enterText(find.descendant(of: find.byType(AlertDialog), matching: find.byType(EditableText)), 'primeira');
    await tester.tap(find.text('Guardar agora'));
    await settleUntil(tester, () => find.textContaining('primeira ·').evaluate().isNotEmpty);
    expect(find.textContaining(RegExp(r'^primeira · \d+ palavras$')), findsOneWidget);
    final snap = h.workspace.snapshotsOf(poeira).single;
    expect(snap.words, greaterThan(0), reason: 'as palavras saem do content.xml da cópia');

    // O capítulo muda no disco; restaurar volta ao instantâneo.
    final file = File('$dir/capitulos/002-a-poeira.odt');
    final original = file.readAsBytesSync();
    file.writeAsStringSync('outro texto');
    await tester.tap(find.byTooltip('Restaurar'));
    await tester.pumpAndSettle();
    expect(find.text('Restaurar o instantâneo?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Restaurar'));
    await settleUntil(tester, () => find.text('Instantâneos de A poeira').evaluate().isEmpty);
    expect(file.readAsBytesSync(), original);
    final after = h.workspace.snapshotsOf(poeira);
    expect(after.map((s) => s.name), containsAll(['Antes de restaurar', 'primeira']));
    // O "antes" guardou o que estava no disco.
    final before = after.firstWhere((s) => s.name == 'Antes de restaurar');
    expect(File(h.workspace.snapshotFile(poeira, before)!).readAsStringSync(), 'outro texto');
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('comparar abre o instantâneo ao lado, só para leitura, com a faixa', (tester) async {
    final h = await pumpApp(tester);
    final dir = makeBook(h);
    await tester.runAsync(() => h.workspace.openPath(dir));
    await tester.pump();
    final abertura = h.workspace.book.book!.find('a')!.$1;
    final chapterPath = h.doc.path;

    await openSnapshots(tester, 'Abertura');
    await tester.tap(find.text('Guardar agora'));
    await settleUntil(tester, () => h.workspace.snapshotsOf(abertura).isNotEmpty);
    await tester.pump();
    // O da tela vem do motor, com o que não foi salvo.
    expect(h.kit.copies.last.$2, 'odt');
    expect(h.kit.copies.last.$1, contains('/versoes/a/'));

    await tester.tap(find.byTooltip('Abrir ao lado, só para leitura'));
    await tester.pumpAndSettle();
    expect(h.doc.path, contains('/versoes/a/'));
    expect(h.doc.canEdit, isFalse);
    expect(h.kit.unoCommands, isNot(contains('.uno:CompareDocuments')));
    expect(find.textContaining(RegExp(r'^Instantâneo: Abertura, ')), findsOneWidget, reason: 'o nome da aba');
    expect(find.textContaining(RegExp(r'^Instantâneo de Abertura, .*só para leitura')), findsOneWidget);
    expect(find.textContaining('salve uma cópia'), findsNothing, reason: 'não é a faixa do arquivo travado');

    await tester.tap(find.text('Fechar o instantâneo'));
    await tester.pumpAndSettle();
    expect(h.doc.path, chapterPath);
    expect(find.textContaining('só para leitura'), findsNothing);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('o primeiro salvamento do dia guarda o capítulo como estava, uma vez', (tester) async {
    final h = await pumpApp(tester);
    final dir = makeBook(h);
    await tester.runAsync(() => h.workspace.openPath(dir));
    await tester.pump();
    final abertura = h.workspace.book.book!.find('a')!.$1;
    final before = File('$dir/capitulos/001-abertura.odt').readAsBytesSync();

    h.doc.insertText('x');
    await tester.runAsync(() => h.workspace.save());
    await settleUntil(tester, () => h.workspace.snapshotsOf(abertura).isNotEmpty);
    final autos = h.workspace.snapshotsOf(abertura);
    expect(autos.single.auto, isTrue);
    expect(File(h.workspace.snapshotFile(abertura, autos.single)!).readAsBytesSync(), before);

    h.doc.insertText('y');
    await tester.runAsync(() => h.workspace.save());
    await settleUntil(tester, () => false);
    expect(h.workspace.snapshotsOf(abertura), hasLength(1), reason: 'um por dia');
    expect(hasAutoSnapshotOn(dir, 'a', DateTime.now()), isTrue);

    // Desligado nas preferências: nada.
    final poeira = h.workspace.book.book!.find('b')!.$1;
    h.settings.autoSnapshots = false;
    h.workspace.autoSnapshots = h.settings.autoSnapshots;
    h.workspace.openChapter(poeira);
    await tester.pump();
    h.doc.insertText('z');
    await tester.runAsync(() => h.workspace.save());
    await settleUntil(tester, () => false);
    expect(h.workspace.snapshotsOf(poeira), isEmpty);
    await tester.pump(const Duration(seconds: 3));
  });
}
