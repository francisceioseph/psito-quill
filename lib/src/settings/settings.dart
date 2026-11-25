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
  double _uiScale = 1;
  bool _comfortable = false;
  int _caretWidth = 2;
  bool _caretBlink = true;
  bool _reduceMotion = false;
  String _spellColor = 'vermelho';
  String _zoomOnOpen = '100';
  bool _screenReaderDoc = false;
  bool _autosave = true;
  bool _autoSnapshots = true;
  String _authorName = '';

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

  /// O salvamento automático numa cópia de recuperação (D-073).
  bool get autosave => _autosave;
  set autosave(bool v) => _set(() => _autosave = v);

  /// Um instantâneo automático por dia de cada capítulo do livro (D-081).
  bool get autoSnapshots => _autoSnapshots;
  set autoSnapshots(bool v) => _set(() => _autoSnapshots = v);

  /// O nome nos comentários (D-088). Vazio: o nome da conta do sistema.
  String get authorName => _authorName;
  set authorName(String v) => _set(() => _authorName = v.trim());

  // ------------------------------------------ acessibilidade (D-067) --

  /// O tamanho do texto da interface, por cima do do sistema (1, 1,25, 1,5
  /// ou 2).
  double get uiScale => _uiScale;
  set uiScale(double v) => _set(() => _uiScale = v);

  /// Botões maiores (a densidade confortável, 44 px).
  bool get comfortable => _comfortable;
  set comfortable(bool v) => _set(() => _comfortable = v);

  /// A espessura do cursor do texto (1, 2 ou 3 px) e se ele pisca.
  int get caretWidth => _caretWidth;
  set caretWidth(int v) => _set(() => _caretWidth = v);
  bool get caretBlink => _caretBlink;
  set caretBlink(bool v) => _set(() => _caretBlink = v);

  /// Sem animações (também segue o do sistema).
  bool get reduceMotion => _reduceMotion;
  set reduceMotion(bool v) => _set(() => _reduceMotion = v);

  /// A cor do ondulado da ortografia: "vermelho", "azul" ou "laranja". Vale
  /// ao abrir o Quill de novo (o motor lê ao ligar, D-067).
  String get spellColor => _spellColor;
  set spellColor(String v) => _set(() => _spellColor = v);

  /// O zoom de um documento ao abrir: "100", "largura" ou "pagina".
  String get zoomOnOpen => _zoomOnOpen;
  set zoomOnOpen(String v) => _set(() => _zoomOnOpen = v);

  /// O texto do documento para o leitor de tela, mesmo sem ele ativo.
  bool get screenReaderDoc => _screenReaderDoc;
  set screenReaderDoc(bool v) => _set(() => _screenReaderDoc = v);

  /// A ortografia (D-093): não verificar as palavras em MAIÚSCULAS, nem as
  /// com números. Vão no perfil do motor ao ligar: valem na próxima vez.
  bool _spellIgnoreUpper = false, _spellIgnoreDigits = false;
  bool get spellIgnoreUpper => _spellIgnoreUpper;
  set spellIgnoreUpper(bool v) => _set(() => _spellIgnoreUpper = v);
  bool get spellIgnoreDigits => _spellIgnoreDigits;
  set spellIgnoreDigits(bool v) => _set(() => _spellIgnoreDigits = v);

  /// Os comandos do acesso rápido, na ordem (os ids do `CommandRegistry`).
  static const defaultQuickAccess = ['arquivo.salvar', 'editar.desfazer', 'editar.refazer'];
  List<String> _quickAccess = defaultQuickAccess;
  List<String> get quickAccess => _quickAccess;
  set quickAccess(List<String> v) => _set(() => _quickAccess = List.unmodifiable(v));

  /// Os atalhos escolhidos, por cima do jogo: o id e o atalho
  /// (`encodeActivator`; "" tira o do jogo).
  Map<String, String> _customShortcuts = const {};
  Map<String, String> get customShortcuts => _customShortcuts;
  set customShortcuts(Map<String, String> v) => _set(() => _customShortcuts = Map.unmodifiable(v));

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
      _uiScale = (json['escalaInterface'] as num?)?.toDouble() ?? _uiScale;
      _comfortable = json['botoesMaiores'] as bool? ?? _comfortable;
      _caretWidth = (json['cursorLargura'] as num?)?.toInt() ?? _caretWidth;
      _caretBlink = json['cursorPisca'] as bool? ?? _caretBlink;
      _reduceMotion = json['reduzirMovimento'] as bool? ?? _reduceMotion;
      _spellColor = json['corOrtografia'] as String? ?? _spellColor;
      _zoomOnOpen = json['zoomAoAbrir'] as String? ?? _zoomOnOpen;
      _screenReaderDoc = json['documentoLeitorTela'] as bool? ?? _screenReaderDoc;
      _autosave = json['salvamentoAutomatico'] as bool? ?? _autosave;
      _autoSnapshots = json['instantaneosAutomaticos'] as bool? ?? _autoSnapshots;
      _authorName = json['nome'] as String? ?? _authorName;
      _recentFonts = (json['fontesRecentes'] as List?)?.whereType<String>().take(5).toList() ?? _recentFonts;
      _spellIgnoreUpper = json['ortografiaSemMaiusculas'] as bool? ?? _spellIgnoreUpper;
      _spellIgnoreDigits = json['ortografiaSemNumeros'] as bool? ?? _spellIgnoreDigits;
      _quickAccess = List.unmodifiable((json['acessoRapido'] as List?)?.whereType<String>().take(12) ?? _quickAccess);
      _customShortcuts = Map.unmodifiable({
        for (final MapEntry(:key, :value) in ((json['atalhosProprios'] as Map?) ?? const {}).entries)
          if (key is String && value is String) key: value,
      });
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
            'escalaInterface': _uiScale,
            'botoesMaiores': _comfortable,
            'cursorLargura': _caretWidth,
            'cursorPisca': _caretBlink,
            'reduzirMovimento': _reduceMotion,
            'corOrtografia': _spellColor,
            'zoomAoAbrir': _zoomOnOpen,
            'documentoLeitorTela': _screenReaderDoc,
            'salvamentoAutomatico': _autosave,
            'instantaneosAutomaticos': _autoSnapshots,
            'nome': _authorName,
            'ortografiaSemMaiusculas': _spellIgnoreUpper,
            'ortografiaSemNumeros': _spellIgnoreDigits,
            'acessoRapido': _quickAccess,
            'atalhosProprios': _customShortcuts,
          }));
    } on FileSystemException {
      // Sem onde gravar: vale só para esta sessão.
    }
  }
}

/// O nome completo da conta (o primeiro campo do GECOS no /etc/passwd), ou o
/// login. Lido do disco, nada sai do computador.
String systemUserName() {
  final user = Platform.environment['USER'] ?? '';
  try {
    for (final line in File('/etc/passwd').readAsLinesSync()) {
      final f = line.split(':');
      if (f.length > 4 && f[0] == user) {
        final full = f[4].split(',').first.trim();
        return full.isEmpty ? user : full;
      }
    }
  } on FileSystemException {
    // Sem o arquivo: o login.
  }
  return user;
}
