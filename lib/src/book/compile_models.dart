// Os modelos de compilação (Fase 4, Etapa 2, D-087): os três que vêm prontos
// (Manuscrito, Livro 6×9 e E-book) e os de quem escreve, gravados no
// `compilar.json` do livro, que viaja com ele:
//
//   {"versao": 1,
//    "ultimo": "pronto:manuscrito",       // o modelo da última vez
//    "escolhas": {...},                   // a janela da última vez, inteira
//    "modelos": [{"nome": "Revista", ...}]}
//
// Um modelo guarda as escolhas da janela, menos o que é do livro (os
// capítulos, o título, o subtítulo, o autor e a capa).
import 'dart:convert';
import 'dart:io';

import 'compile.dart';
import 'compile_style.dart';
import 'fodt_join.dart';

const compileFileName = 'compilar.json';

/// Os modelos que vêm prontos.
enum BuiltInModel {
  /// O manuscrito para enviar: Times 12, espaço duplo, o recuo, o cabeçalho
  /// "Sobrenome / TÍTULO / página" e o "#" nas cenas, em DOCX.
  manuscript(CompileSettings(
    toc: false,
    scenes: SceneBreakMode.hash,
    format: CompileFormat.docx,
    style: OutputStyle(
      page: PageChoice.a4,
      font: 'Times New Roman',
      fontSize: 12,
      spacing: LineSpacing.double,
      indent: IndentChoice.on,
      headers: HeaderMode.manuscript,
    ),
  )),

  /// O livro impresso de 15,24 × 22,86 cm: as margens espelhadas, os
  /// cabeçalhos alternados e o capítulo na página ímpar, em PDF.
  sixByNine(CompileSettings(
    style: OutputStyle(page: PageChoice.sixByNine, headers: HeaderMode.book, rightPage: true),
  )),

  /// O e-book: EPUB, o sumário sem páginas e sem cabeçalhos.
  ebook(CompileSettings(
    format: CompileFormat.epub,
    style: OutputStyle(headers: HeaderMode.none),
  ));

  const BuiltInModel(this.settings);
  final CompileSettings settings;

  String get id => 'pronto:$name';
}

/// Um modelo de quem escreve.
class CompileModel {
  const CompileModel(this.name, this.settings);
  final String name;
  final CompileSettings settings;

  Map<String, Object?> toJson() => {'nome': name, ...settings.modelJson()};
}

/// O `compilar.json` de um livro.
class CompileStore {
  CompileStore({List<CompileModel>? models, this.last, this.choices}) : models = models ?? [];

  /// Os modelos de quem escreve, na ordem em que foram criados.
  final List<CompileModel> models;

  /// O modelo da última vez: o [BuiltInModel.id] ou o nome; null sem modelo.
  String? last;

  /// A janela da última vez.
  CompileSettings? choices;

  CompileModel? named(String name) => models.where((m) => m.name == name).firstOrNull;

  /// As escolhas do modelo [id] (um pronto ou de quem escreve); null se não há.
  CompileSettings? settingsOf(String id) =>
      BuiltInModel.values.where((b) => b.id == id).firstOrNull?.settings ?? named(id)?.settings;

  /// Grava [settings] como o modelo [name] (troca um que já tem o nome).
  void save(String name, CompileSettings settings) {
    final model = CompileModel(name, settings);
    final i = models.indexWhere((m) => m.name == name);
    i < 0 ? models.add(model) : models[i] = model;
    last = name;
  }

  void rename(String from, String to) {
    final i = models.indexWhere((m) => m.name == from);
    if (i < 0) return;
    models[i] = CompileModel(to, models[i].settings);
    if (last == from) last = to;
  }

  void delete(String name) {
    models.removeWhere((m) => m.name == name);
    if (last == name) last = null;
  }

  /// Lê o `compilar.json` de [dir]; um arquivo que falta ou não se entende é
  /// um livro sem modelos.
  static CompileStore read(String dir) {
    try {
      final j = jsonDecode(File('$dir/$compileFileName').readAsStringSync());
      if (j is! Map) return CompileStore();
      final list = j['modelos'];
      return CompileStore(
        models: [
          if (list is List)
            for (final m in list)
              if (m is Map && m['nome'] is String && (m['nome'] as String).trim().isNotEmpty)
                CompileModel(m['nome'] as String, CompileSettings.fromJson(m)),
        ],
        last: j['ultimo'] is String ? j['ultimo'] as String : null,
        choices: j['escolhas'] is Map ? CompileSettings.fromJson(j['escolhas']) : null,
      );
    } on FileSystemException {
      return CompileStore();
    } on FormatException {
      return CompileStore();
    }
  }

  Map<String, Object?> toJson() => {
        'versao': 1,
        if (last != null) 'ultimo': last,
        if (choices != null) 'escolhas': choices!.toJson(),
        'modelos': [for (final m in models) m.toJson()],
      };

  /// Grava de forma atômica, como o `livro.json`.
  void write(String dir) {
    final tmp = File('$dir/.$compileFileName.tmp');
    tmp.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(toJson()), flush: true);
    tmp.renameSync('$dir/$compileFileName');
  }
}
