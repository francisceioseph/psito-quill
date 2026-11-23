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
  bool _keepRecents = true;
  bool _ribbonCollapsed = false;
  List<String> _recentFonts = const [];
  bool _ruler = true;
  String _pageLayout = 'uma';
  bool _zen = false;
  bool _zenFocus = true;
  bool _zenTypewriter = true;
  String _zenPaper = 'sepia';
  String _rulerUnit = 'cm';
  bool _startScreen = true;
  bool _statusBar = true;

  /// O id do tema (os de `builtInThemes`).
  String get theme => _theme;
  set theme(String v) => _set(() => _theme = v);

  ShortcutScheme get shortcuts => _shortcuts;
  set shortcuts(ShortcutScheme v) => _set(() => _shortcuts = v);

  /// O painel Formatar aberto (F10).
  bool get inspector => _inspector;
  set inspector(bool v) => _set(() => _inspector = v);

  /// Guardar a lista de arquivos recentes no disco (D-041).
  bool get keepRecents => _keepRecents;
  set keepRecents(bool v) => _set(() => _keepRecents = v);

  /// A faixa só com as abas (Ctrl+F1).
  bool get ribbonCollapsed => _ribbonCollapsed;
  set ribbonCollapsed(bool v) => _set(() => _ribbonCollapsed = v);

  /// As fontes escolhidas por último, a mais recente primeiro (no máximo 5).
  List<String> get recentFonts => _recentFonts;

  void useFont(String name) => _set(() => _recentFonts = [name, ..._recentFonts.where((f) => f != name)].take(5).toList());

  /// Exibir › Régua (as duas réguas).
  bool get ruler => _ruler;
  set ruler(bool v) => _set(() => _ruler = v);

  /// A disposição das páginas: "uma", "varias" ou "livro" (D-047).
  String get pageLayout => _pageLayout;
  set pageLayout(String v) => _set(() => _pageLayout = v);

  /// O modo zen está aberto. Não é guardado: o Quill abre sempre fora dele.
  bool get zen => _zen;
  set zen(bool v) {
    if (v == _zen) return;
    _zen = v;
    notifyListeners();
  }

  /// No modo zen: o foco no parágrafo, a máquina de escrever e o papel
  /// ("sepia", "claro" ou "escuro").
  bool get zenFocus => _zenFocus;
  set zenFocus(bool v) => _set(() => _zenFocus = v);
  bool get zenTypewriter => _zenTypewriter;
  set zenTypewriter(bool v) => _set(() => _zenTypewriter = v);
  String get zenPaper => _zenPaper;
  set zenPaper(String v) => _set(() => _zenPaper = v);

  /// "cm", "mm", "inch" ou "pt".
  String get rulerUnit => _rulerUnit;
  set rulerUnit(String v) => _set(() => _rulerUnit = v);

  /// Sem arquivo para abrir, o Quill abre na tela inicial (os recentes);
  /// desligado, num documento em branco (D-064).
  bool get startScreen => _startScreen;
  set startScreen(bool v) => _set(() => _startScreen = v);

  /// Exibir › Barra de status.
  bool get statusBar => _statusBar;
  set statusBar(bool v) => _set(() => _statusBar = v);

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
      _keepRecents = json['guardarRecentes'] as bool? ?? _keepRecents;
      _ribbonCollapsed = json['faixaRecolhida'] as bool? ?? _ribbonCollapsed;
      _ruler = json['regua'] as bool? ?? _ruler;
      _pageLayout = json['paginas'] as String? ?? _pageLayout;
      _zenFocus = json['zenFoco'] as bool? ?? _zenFocus;
      _zenTypewriter = json['zenMaquina'] as bool? ?? _zenTypewriter;
      _zenPaper = json['zenPapel'] as String? ?? _zenPaper;
      _rulerUnit = json['unidadeRegua'] as String? ?? _rulerUnit;
      _startScreen = json['telaInicial'] as bool? ?? _startScreen;
      _statusBar = json['barraStatus'] as bool? ?? _statusBar;
      _recentFonts = (json['fontesRecentes'] as List?)?.whereType<String>().take(5).toList() ?? _recentFonts;
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
            'guardarRecentes': _keepRecents,
            'faixaRecolhida': _ribbonCollapsed,
            'fontesRecentes': _recentFonts,
            'regua': _ruler,
            'paginas': _pageLayout,
            'zenFoco': _zenFocus,
            'zenMaquina': _zenTypewriter,
            'zenPapel': _zenPaper,
            'unidadeRegua': _rulerUnit,
            'telaInicial': _startScreen,
            'barraStatus': _statusBar,
          }));
    } on FileSystemException {
      // Sem onde gravar: vale só para esta sessão.
    }
  }
}
