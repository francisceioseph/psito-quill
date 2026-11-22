// Command: cada ação do editor existe uma vez só, aqui.
//
// A faixa, os menus do tema 97, a paleta (Ctrl+K), os atalhos e os plugins
// leem deste registro. A Fase 0 só tem Negrito e Salvar.
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
  CommandRegistry({this.scheme = ShortcutScheme.wordPt});

  ShortcutScheme scheme;
  final Map<String, Command> _commands = {};

  void register(Command command) {
    if (_commands.containsKey(command.id)) {
      throw ArgumentError('comando repetido: ${command.id}');
    }
    _commands[command.id] = command;
    notifyListeners();
  }

  Command? operator [](String id) => _commands[id];
  Iterable<Command> get all => _commands.values;

  SingleActivator? shortcutOf(String id) => _commands[id]?.shortcuts[scheme];

  /// O comando cujo atalho (no jogo atual) é esta tecla.
  Command? match(KeyEvent event, HardwareKeyboard keyboard) {
    if (event is KeyUpEvent) return null;
    for (final c in _commands.values) {
      final a = c.shortcuts[scheme];
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
