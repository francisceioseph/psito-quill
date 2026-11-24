// Os instantâneos de um capítulo (Fase 3, Etapa 7, D-081): cópias do ODT em
// `versoes/<id do capítulo>/`, com um índice pequeno ao lado.
//
//   versoes/n1abc/versoes.json        a data, o nome, as palavras e se é
//                                     automático, de cada um
//   versoes/n1abc/20261124-140210.odt
//
// A pasta é pelo id do capítulo, não pelo arquivo: o arquivo pode mudar de
// nome. Quem grava o ODT é o motor (o capítulo da tela) ou uma cópia do
// arquivo (os fechados); o Dart nunca escreve ODT. Apagar manda para a
// `lixeira/` do livro, como no fichário; só os automáticos mais velhos que o
// limite saem de vez.
import 'dart:convert';
import 'dart:io';

import 'book_io.dart';

const versionsDir = 'versoes';
const _indexName = 'versoes.json';

/// Quantos automáticos ficam por capítulo (um por dia: um mês).
const autoSnapshotsKept = 30;

class Snapshot {
  const Snapshot({required this.file, required this.at, this.name = '', this.auto = false, this.words = 0});

  /// O nome do ODT, dentro da pasta do capítulo.
  final String file;
  final DateTime at;
  final String name;
  final bool auto;
  final int words;

  Map<String, Object?> toJson() => {
        'arquivo': file,
        'data': at.toIso8601String(),
        if (name.isNotEmpty) 'nome': name,
        if (auto) 'automatico': true,
        'palavras': words,
      };

  static Snapshot? fromJson(Object? j) {
    if (j is! Map<String, Object?>) return null;
    final file = j['arquivo'], at = DateTime.tryParse(j['data'] as String? ?? '');
    if (file is! String || at == null || file.contains('/')) return null;
    return Snapshot(
      file: file,
      at: at,
      name: j['nome'] as String? ?? '',
      auto: j['automatico'] == true,
      words: (j['palavras'] as num?)?.toInt() ?? 0,
    );
  }
}

/// A pasta dos instantâneos do capítulo [id].
String snapshotDir(String bookDir, String id) => '$bookDir/$versionsDir/$id';

/// O caminho absoluto do instantâneo [s] do capítulo [id].
String snapshotPath(String bookDir, String id, Snapshot s) => '${snapshotDir(bookDir, id)}/${s.file}';

/// Os instantâneos do capítulo [id], do mais novo ao mais velho. Os que
/// perderam o arquivo ficam de fora.
List<Snapshot> listSnapshots(String bookDir, String id) {
  final dir = snapshotDir(bookDir, id);
  final list = <Snapshot>[];
  try {
    final raw = jsonDecode(File('$dir/$_indexName').readAsStringSync());
    if (raw is List) {
      for (final j in raw) {
        final s = Snapshot.fromJson(j);
        if (s != null && File('$dir/${s.file}').existsSync()) list.add(s);
      }
    }
  } on FileSystemException {
    return const [];
  } on FormatException {
    return const [];
  }
  list.sort((a, b) => b.at.compareTo(a.at));
  return list;
}

void _writeIndex(String dir, List<Snapshot> list) {
  final tmp = File('$dir/.$_indexName.tmp');
  tmp.writeAsStringSync(const JsonEncoder.withIndent('  ').convert([for (final s in list) s.toJson()]), flush: true);
  tmp.renameSync('$dir/$_indexName');
}

String _two(int n) => n.toString().padLeft(2, '0');

/// Um nome de arquivo novo para um instantâneo em [at], que ainda não existe
/// na pasta do capítulo [id] (cria a pasta).
String newSnapshotPath(String bookDir, String id, DateTime at) {
  final dir = snapshotDir(bookDir, id);
  Directory(dir).createSync(recursive: true);
  final base = '${at.year}${_two(at.month)}${_two(at.day)}-${_two(at.hour)}${_two(at.minute)}${_two(at.second)}';
  var name = '$base.odt';
  for (var i = 2; File('$dir/$name').existsSync(); i++) {
    name = '$base-$i.odt';
  }
  return '$dir/$name';
}

/// Põe no índice o instantâneo já gravado em [path] (de [newSnapshotPath]).
/// Os automáticos além do limite saem de vez. Devolve o instantâneo.
Snapshot recordSnapshot(String bookDir, String id, String path, {required DateTime at, String name = '', bool auto = false, int words = 0}) {
  final dir = snapshotDir(bookDir, id);
  final s = Snapshot(file: path.split('/').last, at: at, name: name.trim(), auto: auto, words: words);
  final list = [s, ...listSnapshots(bookDir, id).where((o) => o.file != s.file)];
  final autos = list.where((o) => o.auto).toList();
  for (final old in autos.skip(autoSnapshotsKept)) {
    list.remove(old);
    try {
      File('$dir/${old.file}').deleteSync();
    } on FileSystemException {
      // Já foi.
    }
  }
  _writeIndex(dir, list);
  return s;
}

/// Tira [s] do índice e manda o arquivo para a `lixeira/` do livro.
void removeSnapshot(String bookDir, String id, Snapshot s) {
  final dir = snapshotDir(bookDir, id);
  _writeIndex(dir, [for (final o in listSnapshots(bookDir, id)) if (o.file != s.file) o]);
  try {
    moveToTrash(bookDir, '$versionsDir/$id/${s.file}');
  } on FileSystemException {
    // Fora do índice, ele não aparece mais.
  }
}

/// Já há um automático do capítulo [id] no dia de [now].
bool hasAutoSnapshotOn(String bookDir, String id, DateTime now) => listSnapshots(bookDir, id)
    .any((s) => s.auto && s.at.year == now.year && s.at.month == now.month && s.at.day == now.day);
