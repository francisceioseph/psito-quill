import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/files/lo_lock.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('quill-trava-'));
  tearDown(() => dir.deleteSync(recursive: true));

  const ours = 'file:///home/eu/.config/psito-quill/lo-profile';
  final inspector = LockInspector(profileUrl: ours, hostname: 'notebook');

  String doc() => (File('${dir.path}/cap 1.docx')..writeAsStringSync('x')).path;
  void lock(String path, String content) => LoLock.fileFor(path).writeAsStringSync(content);

  test('a trava fica ao lado, com o nome do arquivo', () {
    expect(LoLock.fileFor('/livros/cap 1.docx').path, '/livros/.~lock.cap 1.docx#');
  });

  test('lê o formato do LibreOffice (nome vazio, usuário, máquina, data, perfil)', () {
    final l = LoLock.parse(',francisco,notebook,22.11.2026 20:09,file:///tmp/perfil;')!;
    expect((l.name, l.user, l.host, l.when, l.profileUrl),
        ('', 'francisco', 'notebook', '22.11.2026 20:09', 'file:///tmp/perfil'));
    expect(l.owner, 'francisco');
    expect(LoLock.parse('Maria Souza,maria,pc,1,file:///x;')!.owner, 'Maria Souza');
    expect(LoLock.parse('lixo'), isNull);
  });

  test('sem trava: abre normal', () {
    expect(inspector.inspect(doc()), isA<Unlocked>());
  });

  test('trava do nosso perfil nesta máquina é velha: apaga', () {
    final p = doc();
    lock(p, ',eu,notebook,22.11.2026 10:00,$ours;');
    expect(inspector.inspect(p), isA<StaleLockRemoved>());
    expect(LoLock.fileFor(p).existsSync(), isFalse);
  });

  test('o URL do perfil compara sem a barra do fim e sem %20', () {
    final p = doc();
    lock(p, ',eu,notebook,1,$ours/;');
    expect(inspector.inspect(p), isA<StaleLockRemoved>());
  });

  test('trava de outro perfil (um LibreOffice aberto): só leitura, e não apaga', () {
    final p = doc();
    lock(p, ',eu,notebook,1,file:///home/eu/.config/libreoffice/4;');
    final v = inspector.inspect(p);
    expect(v, isA<LockedBy>());
    expect((v as LockedBy).lock.owner, 'eu');
    expect(LoLock.fileFor(p).existsSync(), isTrue);
  });

  test('trava do nosso perfil em outra máquina (pasta em rede): só leitura', () {
    final p = doc();
    lock(p, ',eu,outro-pc,1,$ours;');
    expect(inspector.inspect(p), isA<LockedBy>());
  });
}
