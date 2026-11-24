// Os instantâneos (Fase 3, Etapa 7, D-081): o índice em `versoes/<id>/`, a
// ordem, o limite dos automáticos e o apagar para a lixeira.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/book/snapshots.dart';

void main() {
  late Directory book;
  setUp(() => book = Directory.systemTemp.createTempSync('pq-instantaneos'));
  tearDown(() => book.deleteSync(recursive: true));

  String write(DateTime at, [String text = 'x']) {
    final p = newSnapshotPath(book.path, 'c1', at);
    File(p).writeAsStringSync(text);
    return p;
  }

  test('grava e lista, do mais novo ao mais velho, com o nome e as palavras', () {
    final a = DateTime(2026, 11, 20, 9), b = DateTime(2026, 11, 24, 14, 2, 10);
    recordSnapshot(book.path, 'c1', write(a), at: a, name: ' primeira versão ', words: 120);
    final pb = write(b);
    expect(pb, endsWith('versoes/c1/20261124-140210.odt'));
    recordSnapshot(book.path, 'c1', pb, at: b, auto: true, words: 130);
    final list = listSnapshots(book.path, 'c1');
    expect(list.map((s) => s.at), [b, a]);
    expect(list.last.name, 'primeira versão');
    expect(list.first.auto, isTrue);
    expect(list.first.words, 130);
    expect(snapshotPath(book.path, 'c1', list.first), pb);
    expect(listSnapshots(book.path, 'outro'), isEmpty);
  });

  test('dois no mesmo segundo não se sobrescrevem', () {
    final at = DateTime(2026, 11, 24, 14);
    final p1 = write(at), p2 = write(at);
    expect(p1, isNot(p2));
    expect(p2, endsWith('-2.odt'));
  });

  test('os automáticos além do limite saem de vez; os com nome ficam', () {
    final named = DateTime(2026, 1, 1);
    recordSnapshot(book.path, 'c1', write(named), at: named, name: 'guardar');
    for (var d = 0; d < autoSnapshotsKept + 2; d++) {
      final at = DateTime(2026, 2, 1).add(Duration(days: d));
      recordSnapshot(book.path, 'c1', write(at), at: at, auto: true);
    }
    final list = listSnapshots(book.path, 'c1');
    expect(list.where((s) => s.auto), hasLength(autoSnapshotsKept));
    expect(list.where((s) => s.name == 'guardar'), hasLength(1));
    // Os dois mais velhos saíram do disco também.
    expect(File('${snapshotDir(book.path, 'c1')}/20260201-000000.odt').existsSync(), isFalse);
    expect(Directory(snapshotDir(book.path, 'c1')).listSync().whereType<File>().where((f) => f.path.endsWith('.odt')),
        hasLength(autoSnapshotsKept + 1));
  });

  test('apagar manda para a lixeira do livro', () {
    final at = DateTime(2026, 11, 24, 10);
    final s = recordSnapshot(book.path, 'c1', write(at), at: at);
    removeSnapshot(book.path, 'c1', s);
    expect(listSnapshots(book.path, 'c1'), isEmpty);
    expect(File('${book.path}/lixeira/20261124-100000.odt').existsSync(), isTrue);
  });

  test('o automático do dia; o índice estragado ou o arquivo sumido não quebram', () {
    final at = DateTime(2026, 11, 24, 8);
    final p = write(at);
    recordSnapshot(book.path, 'c1', p, at: at, auto: true);
    expect(hasAutoSnapshotOn(book.path, 'c1', DateTime(2026, 11, 24, 23)), isTrue);
    expect(hasAutoSnapshotOn(book.path, 'c1', DateTime(2026, 11, 25, 1)), isFalse);
    File(p).deleteSync();
    expect(listSnapshots(book.path, 'c1'), isEmpty);
    File('${snapshotDir(book.path, 'c1')}/versoes.json').writeAsStringSync('{não é json');
    expect(listSnapshots(book.path, 'c1'), isEmpty);
  });
}
