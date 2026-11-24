// As cópias de recuperação (Fase 3, Etapa 2, D-073).
//
// Se o LibreOffice cai, ele leva o app junto (o motor roda no processo). Para
// não perder o que não foi salvo, o DocumentController pede ao motor, a cada
// 60 s com alterações e numa pausa da digitação, uma cópia em ODT do
// documento (a cópia do D-044: sem mudar o documento, o caminho nem o
// "modificado"). Ela fica aqui, no perfil do Quill, nunca ao lado do arquivo:
//
//   ~/.config/psito-quill/recuperacao/
//     <sessão>-<aba>.odt    a última cópia daquela aba
//     <sessão>-<aba>.json   de onde veio (o arquivo e o nome) e quando
//
// Salvar ou fechar a aba apaga a cópia dela; sair normalmente apaga as da
// sessão. O que sobra é de uma sessão que caiu, e a tela inicial oferece
// recuperar ou descartar. Uma cópia nunca sai sem o usuário escolher.
import 'dart:convert';
import 'dart:io';

import '../settings/config_dir.dart';

/// Uma cópia de uma sessão que caiu.
class RecoveryEntry {
  const RecoveryEntry({required this.id, required this.copy, required this.savedAt, this.original, this.title});

  final String id;

  /// O ODT da cópia.
  final String copy;

  /// O arquivo de onde veio; null: um documento que nunca foi salvo.
  final String? original;

  /// O nome que a aba mostrava ("Dustland — A poeira"); null: o do arquivo.
  final String? title;
  final DateTime savedAt;

  /// O nome para mostrar, sem a pasta; null: sem título.
  String? get name => title ?? original?.split('/').last;

  @override
  bool operator ==(Object other) => other is RecoveryEntry && other.id == id;
  @override
  int get hashCode => id.hashCode;
}

class RecoveryStore {
  RecoveryStore(this.dir, {String? session}) : session = session ?? _newSession();

  /// `~/.config/psito-quill/recuperacao`.
  factory RecoveryStore.standard() => RecoveryStore(Directory('${quillConfigDir().path}/recuperacao'));

  final Directory dir;

  /// Único por sessão (o pid se repete depois de reiniciar o computador).
  final String session;

  static String _newSession() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  String idFor(int tab) => '$session-$tab';

  /// Onde o motor grava: ao lado, para a cópia boa não ser trocada por uma
  /// pela metade (a troca é o `rename`, em [commit]).
  String writingPath(String id) => '${dir.path}/$id.gravando.odt';
  String _copy(String id) => '${dir.path}/$id.odt';

  /// A última cópia gravada da aba [id] (pode não existir).
  String copyPath(String id) => _copy(id);
  String _meta(String id) => '${dir.path}/$id.json';

  /// O caminho é de uma cópia de recuperação (o controlador não a apaga
  /// como uma cópia do D-044).
  bool owns(String path) => path.startsWith('${dir.path}/');

  /// Prepara a pasta (só do usuário: as cópias têm o texto do livro).
  bool ensureDir() {
    try {
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
        Process.runSync('chmod', ['700', dir.path]);
      }
      return true;
    } on Object {
      return false;
    }
  }

  /// A cópia em [writingPath] ficou pronta: vira a cópia de [id].
  void commit(String id, {String? original, String? title, DateTime? at}) {
    try {
      File(writingPath(id)).renameSync(_copy(id));
      final meta = File('${_meta(id)}.tmp')
        ..writeAsStringSync(jsonEncode({
          'arquivo': original,
          'titulo': title,
          'em': (at ?? DateTime.now()).toIso8601String(),
        }));
      meta.renameSync(_meta(id));
    } on FileSystemException {
      // Sem gravar: a cópia anterior, se houver, continua.
    }
    _dropLock(writingPath(id));
  }

  /// A gravação falhou ou não serve mais (a aba fechou no meio).
  void dropWriting(String id) {
    _delete(writingPath(id));
    _dropLock(writingPath(id));
  }

  /// Tira a cópia [id] (a aba salvou ou fechou, ou o usuário descartou).
  void delete(String id) {
    for (final p in [_copy(id), _meta(id), writingPath(id)]) {
      _delete(p);
      _dropLock(p);
    }
  }

  /// As cópias desta sessão (sair normalmente apaga).
  void deleteSession() {
    for (final id in _ids()) {
      if (id.startsWith('$session-')) delete(id);
    }
  }

  /// As cópias de outras sessões (as que caíram), a mais nova primeiro.
  List<RecoveryEntry> pending() {
    final out = <RecoveryEntry>[];
    for (final id in _ids()) {
      if (id.startsWith('$session-')) continue;
      final copy = File(_copy(id));
      if (!copy.existsSync()) {
        delete(id);
        continue;
      }
      Map<String, Object?> meta;
      try {
        meta = jsonDecode(File(_meta(id)).readAsStringSync()) as Map<String, Object?>;
      } on Object {
        meta = const {};
      }
      out.add(RecoveryEntry(
        id: id,
        copy: copy.path,
        original: meta['arquivo'] as String?,
        title: meta['titulo'] as String?,
        savedAt: DateTime.tryParse(meta['em'] as String? ?? '') ?? copy.lastModifiedSync(),
      ));
    }
    out.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return out;
  }

  /// Os ids que têm uma cópia, um registro ou uma gravação pela metade.
  Set<String> _ids() {
    final ids = <String>{};
    try {
      for (final f in dir.listSync().whereType<File>()) {
        final name = f.uri.pathSegments.last;
        if (name.startsWith('.~lock.')) continue;
        final m = RegExp(r'^([0-9a-z]+-\d+)\.').firstMatch(name);
        if (m != null) ids.add(m.group(1)!);
      }
    } on FileSystemException {
      // Sem a pasta: nada.
    }
    return ids;
  }

  static void _delete(String path) {
    try {
      final f = File(path);
      if (f.existsSync()) f.deleteSync();
    } on FileSystemException {
      // Já foi.
    }
  }

  /// A trava que o LibreOffice deixa ao lado de um arquivo aberto.
  static void _dropLock(String path) {
    final slash = path.lastIndexOf('/');
    _delete('${path.substring(0, slash)}/.~lock.${path.substring(slash + 1)}#');
  }
}
