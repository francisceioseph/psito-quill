// Os arquivos abertos por último, em ~/.config/psito-quill/recentes.json.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class RecentFiles extends ChangeNotifier {
  RecentFiles(this.store, {this.max = 10}) {
    _load();
  }

  final File store;
  final int max;
  final List<String> _paths = [];

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
    try {
      store.parent.createSync(recursive: true);
      store.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(_paths));
    } on FileSystemException {
      // Sem onde gravar: os recentes valem só para esta sessão.
    }
    notifyListeners();
  }
}
