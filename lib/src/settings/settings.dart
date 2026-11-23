// As preferências, em ~/.config/psito-quill/preferencias.json.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../commands/command_registry.dart';

class Settings extends ChangeNotifier {
  Settings(this.store) {
    _load();
  }

  /// null: só na memória (testes).
  final File? store;

  String _theme = 'claro';
  ShortcutScheme _shortcuts = ShortcutScheme.wordPt;
  bool _inspector = true;

  /// O id do tema (os de `builtInThemes`).
  String get theme => _theme;
  set theme(String v) => _set(() => _theme = v);

  ShortcutScheme get shortcuts => _shortcuts;
  set shortcuts(ShortcutScheme v) => _set(() => _shortcuts = v);

  /// O painel Formatar aberto (F10).
  bool get inspector => _inspector;
  set inspector(bool v) => _set(() => _inspector = v);

  void _set(void Function() change) {
    change();
    _save();
    notifyListeners();
  }

  void _load() {
    final f = store;
    if (f == null) return;
    try {
      final json = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      _theme = json['tema'] as String? ?? _theme;
      _shortcuts = ShortcutScheme.values.asNameMap()[json['atalhos']] ?? _shortcuts;
      _inspector = json['painelFormatar'] as bool? ?? _inspector;
    } on Object {
      // Sem arquivo ou estragado: os padrões.
    }
  }

  void _save() {
    final f = store;
    if (f == null) return;
    try {
      f.parent.createSync(recursive: true);
      f.writeAsStringSync(const JsonEncoder.withIndent('  ').convert({
            'tema': _theme,
            'atalhos': _shortcuts.name,
            'painelFormatar': _inspector,
          }));
    } on FileSystemException {
      // Sem onde gravar: vale só para esta sessão.
    }
  }
}
