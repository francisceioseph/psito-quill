// As notas do livro (Fase 3, Etapa 8, D-082): o cabeçalho, as ligações
// `[[Nome]]`, as menções, a linha do tempo e a gravação em `notas/`.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:psito_quill/src/book/notes.dart';

void main() {
  late Directory book;
  setUp(() => book = Directory.systemTemp.createTempSync('pq-notas'));
  tearDown(() => book.deleteSync(recursive: true));

  test('o cabeçalho vai e volta; sem cabeçalho, o nome é o do arquivo', () {
    const n = Note(file: 'ana.md', name: 'Ana Ruiz', kind: NoteKind.faction, aliases: ['Ana', 'a Ruiva'], body: 'Linha 1\n---\nLinha 3');
    final back = parseNote('ana.md', formatNote(n));
    expect(back.name, 'Ana Ruiz');
    expect(back.kind, NoteKind.faction);
    expect(back.aliases, ['Ana', 'a Ruiva']);
    expect(back.body, 'Linha 1\n---\nLinha 3', reason: 'um --- no texto não fecha o cabeçalho de novo');
    final bare = parseNote('poco-fundo.md', 'Só texto\r\nsegunda');
    expect(bare.name, 'poco-fundo');
    expect(bare.kind, NoteKind.character);
    expect(bare.body, 'Só texto\nsegunda');
    expect(parseNote('x.md', '---\ntipo: desconhecido\n---\n').kind, NoteKind.character);
  });

  test('criar, gravar, listar pelo nome e mandar para a lixeira', () {
    final a = createNote(book.path, 'Zé do Poço', NoteKind.character);
    final b = createNote(book.path, 'Árvore Seca', NoteKind.place);
    final c = createNote(book.path, 'Zé do Poço', NoteKind.term);
    expect(a.file, 'ze-do-poco.md');
    expect(c.file, 'ze-do-poco-2.md');
    writeNote(book.path, b.copyWith(body: 'Fica no [[Zé do Poço]].'));
    expect(Directory('${book.path}/notas').listSync().map((f) => f.path).where((p) => p.endsWith('.tmp')), isEmpty);
    final list = listNotes(book.path);
    expect(list.map((n) => n.name), ['Árvore Seca', 'Zé do Poço', 'Zé do Poço'], reason: 'sem acento na ordem');
    expect(list.first.body, 'Fica no [[Zé do Poço]].');
    removeNote(book.path, a.file);
    expect(listNotes(book.path), hasLength(2));
    expect(File('${book.path}/lixeira/ze-do-poco.md').existsSync(), isTrue);
    expect(listNotes('${book.path}/nao-existe'), isEmpty);
  });

  test('as ligações, a nota pelo apelido e as menções', () {
    expect(noteLinks('A [[Ana]] e [[Poço Fundo]], de novo [[ana]]. [[]] [[a\nb]]'), ['Ana', 'Poço Fundo']);
    expect(noteLinkRanges('x [[A]] y').toList(), [(2, 7)]);
    const ana = Note(file: 'ana.md', name: 'Ana Ruiz', aliases: ['Ruiva']);
    const poco = Note(file: 'poco.md', name: 'Poço Fundo', kind: NoteKind.place, body: 'A [[ruiva]] nasceu aqui.');
    const outra = Note(file: 'o.md', name: 'Outra', body: 'Nada.');
    final notes = [ana, poco, outra];
    expect(findNote(notes, 'RUIVA'), same(ana));
    expect(findNote(notes, 'poco  fundo'), same(poco));
    expect(findNote(notes, 'Ninguém'), isNull);
    expect(mentionsOf(notes, ana), [poco]);
    expect(noteMatches(poco, 'nasceu'), isTrue);
    expect(noteMatches(ana, 'ruí'), isTrue);
    expect(noteMatches(outra, 'ruiva'), isFalse);
  });

  test('os eventos da linha do tempo, na ordem escrita', () {
    const body = '# Antes\n- Ano 3: a Poeira chega\n* Ano 1 — o [[Poço Fundo]] seca\ntexto solto\n- antes da Poeira - nasce a Ana';
    expect(timelineEvents(body), [
      (when: 'Ano 3', text: 'a Poeira chega'),
      (when: 'Ano 1', text: 'o [[Poço Fundo]] seca'),
      (when: 'antes da Poeira', text: 'nasce a Ana'),
    ]);
  });
}
