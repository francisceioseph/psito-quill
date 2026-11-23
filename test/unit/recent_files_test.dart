import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/files/recent_files.dart';

void main() {
  late Directory dir;
  late File store;
  setUp(() {
    dir = Directory.systemTemp.createTempSync('quill-recentes-');
    store = File('${dir.path}/sub/recentes.json');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('o mais recente primeiro, sem repetir', () {
    final r = RecentFiles(store)
      ..add('/a.odt')
      ..add('/b.odt')
      ..add('/a.odt');
    expect(r.paths, ['/a.odt', '/b.odt']);
    r.dispose();
  });

  test('guarda no máximo N', () {
    final r = RecentFiles(store, max: 3);
    for (var i = 0; i < 5; i++) {
      r.add('/$i.odt');
    }
    expect(r.paths, ['/4.odt', '/3.odt', '/2.odt']);
    r.dispose();
  });

  test('sobrevive a reabrir o app, e tirar um também fica', () {
    RecentFiles(store)
      ..add('/a.odt')
      ..add('/b.odt')
      ..remove('/a.odt')
      ..dispose();
    final again = RecentFiles(store);
    expect(again.paths, ['/b.odt']);
    again.dispose();
  });

  test('arquivo estragado: começa vazio', () {
    store
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('{não é json');
    final r = RecentFiles(store);
    expect(r.paths, isEmpty);
    r.dispose();
  });

  test('avisa quem escuta', () {
    final r = RecentFiles(store);
    var n = 0;
    r.addListener(() => n++);
    r.add('/a.odt');
    expect(n, 1);
    r.dispose();
  });
}
