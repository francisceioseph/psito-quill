// Os arquivos abertos por último, em ~/.config/psito-quill/recentes.json.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

//
// Com "Guardar os arquivos recentes" desligado (D-041), a lista vale só
// enquanto o Quill está aberto, e o arquivo é apagado.
class RecentFiles extends ChangeNotifier {
  RecentFiles(this.store, {this.max = 10, bool keep = true}) : _keep = keep {
    if (keep) {
      _load();
    } else {
      _forget();
    }
  }

  final File store;
  final int max;
  final List<String> _paths = [];
  bool _keep;

  /// Grava no disco. Desligar apaga o arquivo; religar grava o que há.
  bool get keep => _keep;
  set keep(bool v) {
    if (v == _keep) return;
    _keep = v;
    if (v) {
      _save();
    } else {
      _forget();
    }
  }

  void _forget() {
    try {
      if (store.existsSync()) store.deleteSync();
    } on FileSystemException {
      // Sem permissão: não há o que fazer.
    }
  }

  /// Do mais recente para o mais antigo.
  List<String> get paths => List.unmodifiable(_paths);

  void _load() {
    try {
      final json = jsonDecode(store.readAsStringSync());
      if (json is List) _paths.addAll(json.whereType<String>().take(max));
    } on Object {
      // Sem arquivo, ou estragado: começa vazio.
    }
  }

  void add(String path) {
    _paths
      ..remove(path)
      ..insert(0, path);
    if (_paths.length > max) _paths.removeRange(max, _paths.length);
    _save();
  }

  void remove(String path) {
    if (_paths.remove(path)) _save();
  }

  void _save() {
    if (!_keep) {
      notifyListeners();
      return;
    }
    try {
      store.parent.createSync(recursive: true);
      store.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(_paths));
    } on FileSystemException {
      // Sem onde gravar: os recentes valem só para esta sessão.
    }
    notifyListeners();
  }
}
