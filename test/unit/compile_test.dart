// O compilar (Fase 4, Etapa 1, D-086): a ordem dos capítulos e das partes, o
// que fica de fora, as cópias pelo motor, o cancelar e a limpeza.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/book/book.dart';
import 'package:psito_quill/src/book/compile.dart';
import 'package:psito_quill/src/document/document_controller.dart';
import 'package:psito_quill/src/kit/fake/fake_quill_kit.dart';

void main() {
  late Directory tmp;
  late FakeQuillKit kit;
  setUp(() {
    tmp = Directory.systemTemp.createTempSync('quill-compilar-');
    DocumentController.copyDirOverride = tmp.path;
    kit = FakeQuillKit();
    // O motor falso: o capítulo sai em FODT com o título dele no corpo, e o
    // livro "gravado" é o FODT juntado.
    kit.onConvert = (source, target, format) {
      if (format == 'fodt') {
        final title = File(source).readAsStringSync();
        final fixture = File('test/fixtures/livro-teste.fodt').readAsStringSync();
        File(target).writeAsStringSync(fixture.replaceFirstMapped(
            RegExp(r'(<office:text\b[^>]*>)[\s\S]*(</office:text>)'),
            (m) => '${m[1]}<text:h text:style-name="P3" text:outline-level="1">$title</text:h>${m[2]}'));
      } else {
        File(source).copySync(target);
      }
    };
  });
  tearDown(() {
    DocumentController.copyDirOverride = null;
    kit.dispose();
    tmp.deleteSync(recursive: true);
  });

  BookNode chapter(String id, String title, {ChapterStatus status = ChapterStatus.draft}) {
    final file = File('${tmp.path}/$id.odt')..writeAsStringSync(title);
    return BookNode(id: id, kind: BookNodeKind.chapter, title: title, file: file.path, status: status);
  }

  Book book() => Book(title: 'Dustland', nodes: [
        chapter('a', 'Abertura'),
        BookNode(id: 'p', kind: BookNodeKind.part, title: 'Parte Um', children: [chapter('b', 'A poeira'), chapter('c', 'O poço')]),
        chapter('d', 'Epílogo', status: ChapterStatus.done),
      ]);

  Future<CompileSource?> fromFile(BookNode n) async => (path: n.file!, flat: false);

  test('os capítulos na ordem do livro, sem os de fora', () {
    final b = book();
    expect([for (final e in compiledChapters(b, const CompileSettings())) e.$2.id], ['a', 'b', 'c', 'd']);
    final some = compiledChapters(b, const CompileSettings(excluded: {'b', 'd'}));
    expect([for (final e in some) e.$2.id], ['a', 'c']);
    expect(some[1].$1?.id, 'p');
  });

  test('compila: os capítulos pelo motor, a parte, o sumário e a limpeza', () async {
    final target = '${tmp.path}/livro.pdf';
    final stages = <CompileStage>[];
    final r = await CompileJob(kit).run(book(), const CompileSettings(title: 'Dustland', author: 'Fulano'), target,
        sourceOf: fromFile, onProgress: (s, _, _) => stages.add(s));
    expect(r.ok, isTrue);
    expect(stages.first, CompileStage.chapters);
    expect(stages.sublist(stages.length - 2), [CompileStage.joining, CompileStage.writing]);
    // Quatro capítulos em FODT, e o livro no formato pedido, com o sumário.
    expect(kit.conversions.where((c) => c.$3 == 'fodt').length, 4);
    expect(kit.conversions.last.$3, 'pdf');
    expect(kit.indexUpdates, 1);
    expect(kit.trims, greaterThan(0));
    final xml = File(target).readAsStringSync();
    final order = ['Abertura', 'Parte Um', 'A poeira', 'O poço', 'Epílogo'].map(xml.indexOf).toList();
    expect(order.every((i) => i > 0), isTrue);
    expect(order, [...order]..sort());
    // As cópias temporárias saíram.
    expect(tmp.listSync().whereType<File>().where((f) => f.uri.pathSegments.last.contains('compilar-')), isEmpty);
  });

  test('sem sumário, o motor não atualiza os índices; sem os títulos de parte', () async {
    final target = '${tmp.path}/livro.epub';
    final r = await CompileJob(kit).run(
        book(), const CompileSettings(toc: false, partTitles: false, format: CompileFormat.epub), target,
        sourceOf: fromFile);
    expect(r.ok, isTrue);
    expect(kit.indexUpdates, 0);
    expect(File(target).readAsStringSync(), isNot(contains('Parte Um')));
  });

  test('o capítulo da tela vai pela cópia, sem passar pelo motor', () async {
    final flat = File('${tmp.path}/tela.fodt')..writeAsStringSync(File('test/fixtures/livro-teste.fodt').readAsStringSync());
    final target = '${tmp.path}/livro.odt';
    final r = await CompileJob(kit).run(book(), const CompileSettings(excluded: {'b', 'c', 'd'}, format: CompileFormat.odt), target,
        sourceOf: (n) async => (path: flat.path, flat: true));
    expect(r.ok, isTrue);
    expect(kit.conversions.where((c) => c.$3 == 'fodt'), isEmpty);
    expect(flat.existsSync(), isTrue, reason: 'a cópia da tela não é nossa');
  });

  test('cancelar para no próximo passo; nenhum capítulo; a falha diz qual', () async {
    final job = CompileJob(kit);
    final r = await job.run(book(), const CompileSettings(), '${tmp.path}/x.pdf', sourceOf: (n) async {
      job.cancel();
      return fromFile(n);
    });
    expect(r.outcome, CompileOutcome.cancelled);
    expect(File('${tmp.path}/x.pdf').existsSync(), isFalse);

    final none = await CompileJob(kit).run(book(), const CompileSettings(excluded: {'a', 'b', 'c', 'd'}), '${tmp.path}/y.pdf',
        sourceOf: fromFile);
    expect(none.outcome, CompileOutcome.noChapters);

    kit.failConversions = true;
    final failed = await CompileJob(kit).run(book(), const CompileSettings(), '${tmp.path}/z.pdf', sourceOf: fromFile);
    expect(failed.outcome, CompileOutcome.chapterFailed);
    expect(failed.chapter, 'Abertura');
  });
}
