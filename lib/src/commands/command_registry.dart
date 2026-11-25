// Command: cada ação do editor existe uma vez só, aqui.
//
// A faixa, os menus do tema 97, a paleta (Ctrl+K), os atalhos e os plugins
// leem deste registro.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Os dois jogos de atalhos do plano (seção 5.4).
enum ShortcutScheme { wordPt, wordEn }

class Command {
  const Command({
    required this.id,
    required this.label,
    required this.icon,
    required this.run,
    this.shortcuts = const {},
    this.isActive,
    this.canRun,
  });

  final String id;

  /// Rótulo já traduzido (vem da l10n de quem registra).
  final String label;
  final IconData icon;
  final VoidCallback run;
  final Map<ShortcutScheme, SingleActivator> shortcuts;

  /// Para comandos que ligam e desligam (negrito): o estado vem do motor.
  final bool Function()? isActive;
  final bool Function()? canRun;

  bool get enabled => canRun?.call() ?? true;
  bool get active => isActive?.call() ?? false;
}

class CommandRegistry extends ChangeNotifier {
  // O campo é privado (o setter avisa os ouvintes); o parâmetro, não.
  // ignore: prefer_initializing_formals
  CommandRegistry({ShortcutScheme scheme = ShortcutScheme.wordPt}) : _scheme = scheme;

  ShortcutScheme _scheme;
  ShortcutScheme get scheme => _scheme;
  set scheme(ShortcutScheme value) {
    if (value == _scheme) return;
    _scheme = value;
    notifyListeners();
  }
  final Map<String, Command> _commands = {};

  /// Os atalhos que a pessoa escolheu (D-093), por cima do jogo: o id e o
  /// atalho; null tira o do jogo.
  Map<String, SingleActivator?> _overrides = const {};
  Map<String, SingleActivator?> get overrides => _overrides;
  set overrides(Map<String, SingleActivator?> value) {
    _overrides = Map.unmodifiable(value);
    notifyListeners();
  }

  void register(Command command) {
    if (_commands.containsKey(command.id)) {
      throw ArgumentError('comando repetido: ${command.id}');
    }
    _commands[command.id] = command;
    notifyListeners();
  }

  Command? operator [](String id) => _commands[id];
  Iterable<Command> get all => _commands.values;

  /// O atalho de agora: o escolhido pela pessoa, ou o do jogo.
  SingleActivator? shortcutOf(String id) =>
      _overrides.containsKey(id) ? _overrides[id] : _commands[id]?.shortcuts[scheme];

  /// O do jogo, sem o escolhido.
  SingleActivator? defaultShortcutOf(String id) => _commands[id]?.shortcuts[scheme];

  /// O atalho para mostrar: "Ctrl+Shift+N", "F12". null se não tem.
  String? shortcutLabelOf(String id) => switch (shortcutOf(id)) {
        null => null,
        final a => activatorLabel(a),
      };

  /// O comando (outro que [except]) que já usa [a] agora.
  Command? commandWithShortcut(SingleActivator a, {String? except}) {
    for (final c in _commands.values) {
      if (c.id == except) continue;
      if (sameActivator(shortcutOf(c.id), a)) return c;
    }
    return null;
  }

  /// "Negrito (Ctrl+N)", para a dica dos botões.
  String tooltipOf(String id) {
    final c = _commands[id];
    if (c == null) return id;
    final s = shortcutLabelOf(id);
    return s == null ? c.label : '${c.label} ($s)';
  }

  /// O comando cujo atalho (no jogo atual) é esta tecla.
  Command? match(KeyEvent event, HardwareKeyboard keyboard) {
    if (event is KeyUpEvent) return null;
    for (final c in _commands.values) {
      final a = shortcutOf(c.id);
      if (a != null && a.accepts(event, keyboard)) return c;
    }
    return null;
  }

  /// Roda pelo id. Devolve false se não existe ou não pode agora.
  bool run(String id) {
    final c = _commands[id];
    if (c == null || !c.enabled) return false;
    c.run();
    return true;
  }
}

/// "Ctrl+Shift+N", "F12".
String activatorLabel(SingleActivator a) {
  final key = switch (a.trigger) {
    LogicalKeyboardKey.equal => '+',
    LogicalKeyboardKey.minus => '-',
    final k => k.keyLabel.length == 1 ? k.keyLabel.toUpperCase() : k.keyLabel,
  };
  return [
    if (a.control) 'Ctrl',
    if (a.alt) 'Alt',
    if (a.shift) 'Shift',
    key,
  ].join('+');
}

bool sameActivator(SingleActivator? a, SingleActivator? b) =>
    a != null &&
    b != null &&
    a.trigger == b.trigger &&
    a.control == b.control &&
    a.alt == b.alt &&
    a.shift == b.shift &&
    a.meta == b.meta;

/// Como o atalho escolhido fica nas preferências: `ctrl,alt,shift,keyId`
/// (os três em 0 ou 1); "" é sem atalho.
String encodeActivator(SingleActivator? a) =>
    a == null ? '' : '${a.control ? 1 : 0},${a.alt ? 1 : 0},${a.shift ? 1 : 0},${a.trigger.keyId}';

/// O inverso; null para "" ou um texto que não serve.
SingleActivator? decodeActivator(String text) {
  final p = text.split(',');
  if (p.length != 4) return null;
  final id = int.tryParse(p[3]);
  if (id == null) return null;
  final key = LogicalKeyboardKey.findKeyByKeyId(id) ?? LogicalKeyboardKey(id);
  return SingleActivator(key, control: p[0] == '1', alt: p[1] == '1', shift: p[2] == '1');
}
