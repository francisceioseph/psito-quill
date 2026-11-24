// A pasta do livro no disco (D-071): ler e gravar o `livro.json`, dar nome
// aos arquivos dos capítulos, mandar para a lixeira e contar as palavras dos
// capítulos fechados.
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import '../document/fodt.dart';
import 'book.dart';
import 'odt_zip.dart';

const bookExtension = '.psitobook';
const bookFileName = 'livro.json';
const chaptersDir = 'capitulos';
const trashDir = 'lixeira';

/// [path] é a pasta de um livro (pelo nome ou pelo `livro.json` dentro).
bool isBookPath(String path) =>
    path.endsWith(bookExtension) || File('$path/$bookFileName').existsSync() || path.endsWith('/$bookFileName');

/// A pasta do livro a partir de [path] (a pasta ou o `livro.json`).
String bookDirOf(String path) =>
    path.endsWith('/$bookFileName') ? path.substring(0, path.length - bookFileName.length - 1) : path;

/// Lê o `livro.json`. Lança [FileSystemException] ou [FormatException].
Book readBook(String dir) =>
    Book.fromJson(jsonDecode(File('$dir/$bookFileName').readAsStringSync()) as Map<String, Object?>);

/// Grava o `livro.json` de forma atômica: escreve ao lado e renomeia, para
/// uma queda no meio não deixar o livro sem o índice.
void writeBook(String dir, Book book) {
  final tmp = File('$dir/.$bookFileName.tmp');
  tmp.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(book.toJson()), flush: true);
  tmp.renameSync('$dir/$bookFileName');
}

/// Cria a pasta do livro (com `capitulos/`). Lança se ela já tem um livro.
void createBookDir(String dir) {
  if (File('$dir/$bookFileName').existsSync()) {
    throw FileSystemException('já existe um livro aqui', dir);
  }
  Directory('$dir/$chaptersDir').createSync(recursive: true);
}

/// O nome de pasta de um livro com o título [title] ("Dustland.psitobook").
String bookFolderName(String title) {
  final clean = title.trim().replaceAll(RegExp(r'[/\\:*?"<>|]'), '').replaceAll(RegExp(r'\s+'), ' ');
  return '${clean.isEmpty ? 'Livro' : clean}$bookExtension';
}

const _accents = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', //
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', 'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', //
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ç': 'c', 'ñ': 'n',
};

/// O título em minúsculas, sem acentos, com hífens: "A Poeira!" → "a-poeira".
String slugOf(String title) {
  final s = StringBuffer();
  for (final ch in title.toLowerCase().split('')) {
    s.write(_accents[ch] ?? ch);
  }
  final slug = s.toString().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
  return slug.length > 40 ? slug.substring(0, 40).replaceAll(RegExp(r'-+$'), '') : slug;
}

final _numbered = RegExp(r'^(\d+)-');

/// Um arquivo novo para o capítulo [title]: o próximo número depois do
/// maior que já existe na pasta (`capitulos/007-o-poco.odt`).
String newChapterFile(String dir, String title, {Set<String> taken = const {}}) {
  var next = 1;
  final folder = Directory('$dir/$chaptersDir');
  final names = [
    if (folder.existsSync()) for (final f in folder.listSync()) f.uri.pathSegments.last,
    for (final t in taken) t.split('/').last,
  ];
  for (final n in names) {
    final m = _numbered.firstMatch(n);
    if (m != null) next = max(next, int.parse(m[1]!) + 1);
  }
  final slug = slugOf(title);
  return '$chaptersDir/${next.toString().padLeft(3, '0')}${slug.isEmpty ? '' : '-$slug'}.odt';
}

/// Um id novo, único no livro.
String newNodeId(Book book) {
  final taken = {for (final n in book.nodes) n.id, for (final n in book.nodes) for (final c in n.children) c.id};
  final r = Random();
  while (true) {
    final id = 'n${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${r.nextInt(1296).toRadixString(36)}';
    if (!taken.contains(id)) return id;
  }
}

/// Move o arquivo [relative] para a `lixeira/` do livro. Um nome repetido
/// ganha a data na frente. Devolve o caminho novo, relativo.
String? moveToTrash(String dir, String relative) {
  final f = File('$dir/$relative');
  if (!f.existsSync()) return null;
  Directory('$dir/$trashDir').createSync(recursive: true);
  var name = relative.split('/').last;
  if (File('$dir/$trashDir/$name').existsSync()) name = '${DateTime.now().millisecondsSinceEpoch}-$name';
  f.renameSync('$dir/$trashDir/$name');
  return '$trashDir/$name';
}

/// As palavras dos capítulos [files] (caminhos absolutos), num isolate: o
/// `content.xml` de cada um é lido, contado e solto. Os que não dão para ler
/// ficam de fora. Devolve também a data de cada arquivo.
Future<Map<String, (int words, int stamp)>> countChapterWords(List<String> files) {
  if (files.isEmpty) return Future.value(const {});
  return Isolate.run(() {
    final out = <String, (int, int)>{};
    for (final path in files) {
      final f = File(path);
      if (!f.existsSync()) continue;
      final stamp = f.lastModifiedSync().millisecondsSinceEpoch;
      final xml = readOdtContent(path);
      if (xml == null) continue;
      final open = xml.indexOf('<office:text');
      final close = xml.lastIndexOf('</office:text>');
      out[path] = (open < 0 || close < open ? 0 : odfWordCount(xml.substring(open, close)), stamp);
    }
    return out;
  });
}
