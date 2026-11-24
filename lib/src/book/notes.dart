// As notas do livro (Fase 3, Etapa 8, D-082): Markdown em `notas/`, uma por
// arquivo, editadas no Flutter, sem o motor.
//
//   notas/ana-ruiz.md
//     ---
//     nome: Ana Ruiz
//     tipo: personagem
//     apelidos: Ana, a Ruiva
//     ---
//     Nasceu em [[Poço Fundo]]...
//
// O cabeçalho é o nosso, uma linha por campo (não é um leitor de YAML).
// O nome do arquivo sai do nome na criação e não muda depois: o nome de
// verdade é o do cabeçalho, como a ordem dos capítulos é a do `livro.json`.
// Os `[[Nome]]` ligam a uma nota (pelo nome ou por um apelido) ou a um
// capítulo (pelo título). Apagar manda para a `lixeira/` do livro.
//
// Nada fica na memória com o painel fechado: a lista (com o texto, pequeno)
// é lida quando o painel abre e solta quando ele fecha.
import 'dart:io';

import 'book_io.dart';

const notesDir = 'notas';

enum NoteKind {
  character('personagem'),
  place('lugar'),
  faction('faccao'),
  term('termo'),
  timeline('linha-do-tempo');

  const NoteKind(this.key);

  /// Como fica no cabeçalho.
  final String key;

  static NoteKind parse(String? key) =>
      NoteKind.values.firstWhere((k) => k.key == key?.trim().toLowerCase(), orElse: () => NoteKind.character);
}

class Note {
  const Note({required this.file, required this.name, this.kind = NoteKind.character, this.aliases = const [], this.body = ''});

  /// O nome do arquivo, dentro de `notas/`.
  final String file;
  final String name;
  final NoteKind kind;
  final List<String> aliases;
  final String body;

  Note copyWith({String? name, NoteKind? kind, List<String>? aliases, String? body}) => Note(
        file: file,
        name: name ?? this.name,
        kind: kind ?? this.kind,
        aliases: aliases ?? this.aliases,
        body: body ?? this.body,
      );

  /// O nome e os apelidos: o que um `[[...]]` aceita.
  Iterable<String> get names sync* {
    yield name;
    yield* aliases;
  }
}

final _fence = RegExp(r'^---[ \t]*$');

/// Lê uma nota do texto do arquivo [file]. Sem cabeçalho, o nome é o do
/// arquivo e o texto todo é o corpo.
Note parseNote(String file, String text) {
  final lines = text.replaceAll('\r\n', '\n').split('\n');
  String? name;
  var kind = NoteKind.character;
  var aliases = const <String>[];
  var start = 0;
  if (lines.isNotEmpty && _fence.hasMatch(lines.first)) {
    final end = lines.indexWhere(_fence.hasMatch, 1);
    if (end > 0) {
      for (final l in lines.sublist(1, end)) {
        final colon = l.indexOf(':');
        if (colon < 0) continue;
        final key = l.substring(0, colon).trim().toLowerCase(), value = l.substring(colon + 1).trim();
        switch (key) {
          case 'nome':
            name = value;
          case 'tipo':
            kind = NoteKind.parse(value);
          case 'apelidos':
            aliases = splitAliases(value);
        }
      }
      start = end + 1;
    }
  }
  final stem = file.endsWith('.md') ? file.substring(0, file.length - 3) : file;
  return Note(
    file: file,
    name: name == null || name.isEmpty ? stem : name,
    kind: kind,
    aliases: aliases,
    body: lines.sublist(start).join('\n'),
  );
}

/// "Ana, a Ruiva" → ["Ana", "a Ruiva"].
List<String> splitAliases(String text) =>
    [for (final a in text.split(',')) if (a.trim().isNotEmpty) a.trim()];

/// O texto do arquivo de [n].
String formatNote(Note n) {
  final b = StringBuffer()
    ..writeln('---')
    ..writeln('nome: ${n.name.replaceAll('\n', ' ').trim()}')
    ..writeln('tipo: ${n.kind.key}');
  if (n.aliases.isNotEmpty) b.writeln('apelidos: ${n.aliases.join(', ')}');
  b
    ..writeln('---')
    ..write(n.body);
  return b.toString();
}

String _path(String bookDir, String file) => '$bookDir/$notesDir/$file';

/// As notas do livro, pelo nome (sem acento nem maiúscula). Um arquivo que
/// não dá para ler fica de fora.
List<Note> listNotes(String bookDir) {
  final dir = Directory('$bookDir/$notesDir');
  if (!dir.existsSync()) return const [];
  final out = <Note>[];
  for (final f in dir.listSync().whereType<File>()) {
    final file = f.uri.pathSegments.last;
    if (!file.endsWith('.md') || file.startsWith('.')) continue;
    try {
      out.add(parseNote(file, f.readAsStringSync()));
    } on FileSystemException {
      continue;
    } on FormatException {
      continue; // não é UTF-8
    }
  }
  out.sort((a, b) => foldName(a.name).compareTo(foldName(b.name)));
  return out;
}

/// Grava [n] de forma atômica: escreve ao lado e renomeia.
void writeNote(String bookDir, Note n) {
  Directory('$bookDir/$notesDir').createSync(recursive: true);
  final tmp = File(_path(bookDir, '.${n.file}.tmp'));
  tmp.writeAsStringSync(formatNote(n), flush: true);
  tmp.renameSync(_path(bookDir, n.file));
}

/// Cria e grava uma nota nova chamada [name].
Note createNote(String bookDir, String name, NoteKind kind) {
  Directory('$bookDir/$notesDir').createSync(recursive: true);
  final slug = slugOf(name);
  final base = slug.isEmpty ? 'nota' : slug;
  var file = '$base.md';
  for (var i = 2; File(_path(bookDir, file)).existsSync(); i++) {
    file = '$base-$i.md';
  }
  final n = Note(file: file, name: name.trim(), kind: kind);
  writeNote(bookDir, n);
  return n;
}

/// Manda a nota [file] para a `lixeira/` do livro.
void removeNote(String bookDir, String file) => moveToTrash(bookDir, '$notesDir/$file');

/// Para comparar nomes: minúsculas, sem acento, espaços simples.
String foldName(String s) {
  final b = StringBuffer();
  for (final ch in s.trim().toLowerCase().split('')) {
    b.write(accentFold[ch] ?? ch);
  }
  return b.toString().replaceAll(RegExp(r'\s+'), ' ');
}

final _link = RegExp(r'\[\[([^\[\]\n]+)\]\]');

/// Os `[[Nome]]` de [text], cada um uma vez, na ordem em que aparecem.
List<String> noteLinks(String text) {
  final seen = <String>{}, out = <String>[];
  for (final m in _link.allMatches(text)) {
    final name = m[1]!.trim();
    if (name.isNotEmpty && seen.add(foldName(name))) out.add(name);
  }
  return out;
}

/// Os trechos `[[...]]` de [text] (o começo e o fim de cada um), para o
/// destaque no campo.
Iterable<(int, int)> noteLinkRanges(String text) => _link.allMatches(text).map((m) => (m.start, m.end));

/// A nota de [notes] chamada [name] (pelo nome ou por um apelido).
Note? findNote(List<Note> notes, String name) {
  final key = foldName(name);
  for (final n in notes) {
    if (n.names.any((x) => foldName(x) == key)) return n;
  }
  return null;
}

/// As notas de [notes] que ligam a [note] por um `[[...]]`.
List<Note> mentionsOf(List<Note> notes, Note note) {
  final keys = {for (final x in note.names) foldName(x)};
  return [
    for (final n in notes)
      if (n.file != note.file && noteLinks(n.body).any((l) => keys.contains(foldName(l)))) n,
  ];
}

/// [n] combina com a busca [query]: pelo nome, por um apelido ou pelo texto.
bool noteMatches(Note n, String query) {
  final q = foldName(query);
  if (q.isEmpty) return true;
  return n.names.any((x) => foldName(x).contains(q)) || foldName(n.body).contains(q);
}

/// Um evento da linha do tempo: quando (no mundo do livro) e o quê.
typedef TimelineEvent = ({String when, String text});

final _event = RegExp(r'^\s*[-*]\s+(.+?)\s*(?::|—|–| - )\s*(.+)$');

/// Os eventos de uma nota de linha do tempo: as linhas de lista no formato
/// `- quando: o quê` (ou com um travessão), na ordem em que estão escritas.
/// A ordem é a de quem escreve: as datas do mundo do livro não se ordenam
/// sozinhas ("antes da Poeira", "Ano 3").
List<TimelineEvent> timelineEvents(String body) => [
      for (final l in body.split('\n'))
        if (_event.firstMatch(l) case final m?) (when: m[1]!.trim(), text: m[2]!.trim()),
    ];
