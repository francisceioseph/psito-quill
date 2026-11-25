// A janela de escolher o atalho de um comando (Fase 4, Etapa 8, D-093): a
// próxima combinação de teclas vira o atalho, com o aviso quando ela já é de
// outro comando (atribuir tira dele).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../commands/command_registry.dart';
import '../atoms/w_label.dart';
import '../tokens/tokens.dart';

/// O que a janela devolve.
sealed class ShortcutChoice {
  const ShortcutChoice();
}

/// [shortcut] para o comando; [takenFrom], o comando que perde.
class AssignShortcut extends ShortcutChoice {
  const AssignShortcut(this.shortcut, {this.takenFrom});
  final SingleActivator shortcut;
  final String? takenFrom;
}

/// Sem atalho nenhum.
class RemoveShortcut extends ShortcutChoice {
  const RemoveShortcut();
}

/// O do jogo de atalhos de novo.
class ResetShortcut extends ShortcutChoice {
  const ResetShortcut();
}

Future<ShortcutChoice?> showShortcutDialog(BuildContext context, {required CommandRegistry commands, required String id}) =>
    showDialog<ShortcutChoice>(context: context, builder: (_) => _ShortcutDialog(commands: commands, id: id));

/// As teclas que sozinhas não fazem um atalho.
final _modifiers = {
  LogicalKeyboardKey.controlLeft,
  LogicalKeyboardKey.controlRight,
  LogicalKeyboardKey.shiftLeft,
  LogicalKeyboardKey.shiftRight,
  LogicalKeyboardKey.altLeft,
  LogicalKeyboardKey.altRight,
  LogicalKeyboardKey.metaLeft,
  LogicalKeyboardKey.metaRight,
  LogicalKeyboardKey.capsLock,
};

/// Uma combinação que serve de atalho: com Ctrl ou Alt, ou uma tecla F. Uma
/// letra sozinha (ou com Shift) é texto.
bool usableShortcut(SingleActivator a) {
  final k = a.trigger;
  final fKey = k.keyId >= LogicalKeyboardKey.f1.keyId && k.keyId <= LogicalKeyboardKey.f24.keyId;
  return a.control || a.alt || fKey;
}

class _ShortcutDialog extends StatefulWidget {
  const _ShortcutDialog({required this.commands, required this.id});
  final CommandRegistry commands;
  final String id;

  @override
  State<_ShortcutDialog> createState() => _ShortcutDialogState();
}

class _ShortcutDialogState extends State<_ShortcutDialog> {
  SingleActivator? _pressed;
  bool _unusable = false;
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.handled;
    if (_modifiers.contains(e.logicalKey)) return KeyEventResult.handled;
    // Esc sem nada fecha, como em toda janela; Tab segue para os botões.
    if (e.logicalKey == LogicalKeyboardKey.escape && !HardwareKeyboard.instance.isControlPressed) {
      return KeyEventResult.ignored;
    }
    if (e.logicalKey == LogicalKeyboardKey.tab && !HardwareKeyboard.instance.isControlPressed) return KeyEventResult.ignored;
    final k = HardwareKeyboard.instance;
    final a = SingleActivator(e.logicalKey, control: k.isControlPressed, alt: k.isAltPressed, shift: k.isShiftPressed);
    setState(() {
      _unusable = !usableShortcut(a);
      _pressed = _unusable ? null : a;
    });
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = QuillTokens.of(context);
    final c = widget.commands[widget.id];
    final current = widget.commands.shortcutOf(widget.id);
    final standard = widget.commands.defaultShortcutOf(widget.id);
    final pressed = _pressed;
    final taken = pressed == null ? null : widget.commands.commandWithShortcut(pressed, except: widget.id);
    return AlertDialog(
      title: Text(l10n.shortcutDialogTitle(c?.label ?? widget.id)),
      content: SizedBox(
        width: 420,
        child: Focus(
          focusNode: _focus,
          autofocus: true,
          onKeyEvent: _onKey,
          child: Semantics(
            liveRegion: true,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              WLabel(
                current == null ? l10n.shortcutNone : l10n.shortcutCurrent(activatorLabel(current)),
                small: true,
                tone: WLabelTone.muted,
              ),
              SizedBox(height: t.space.md),
              WLabel(pressed == null ? l10n.shortcutPress : activatorLabel(pressed), heading: pressed != null),
              if (_unusable) ...[
                SizedBox(height: t.space.sm),
                WLabel(l10n.shortcutUnusable, small: true, tone: WLabelTone.danger, maxLines: 3),
              ],
              if (taken != null) ...[
                SizedBox(height: t.space.sm),
                WLabel(l10n.shortcutTaken(taken.label), small: true, tone: WLabelTone.danger, maxLines: 3),
              ],
            ]),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.dialogCancel)),
        TextButton(
          onPressed: current == null ? null : () => Navigator.pop(context, const RemoveShortcut()),
          child: Text(l10n.shortcutRemove),
        ),
        TextButton(
          onPressed: sameActivator(current, standard) || (current == null && standard == null)
              ? null
              : () => Navigator.pop(context, const ResetShortcut()),
          child: Text(l10n.shortcutReset),
        ),
        FilledButton(
          onPressed: pressed == null ? null : () => Navigator.pop(context, AssignShortcut(pressed, takenFrom: taken?.id)),
          child: Text(l10n.shortcutAssign),
        ),
      ],
    );
  }
}

/// Os atalhos escolhidos depois de [choice] para [id] (o que vai nas
/// preferências). Um atalho igual ao do jogo não fica guardado.
Map<String, String> applyShortcutChoice(CommandRegistry commands, Map<String, String> custom, String id, ShortcutChoice choice) {
  final out = {...custom};
  void set(String cmd, SingleActivator? a) {
    if (sameActivator(a, commands.defaultShortcutOf(cmd)) || (a == null && commands.defaultShortcutOf(cmd) == null)) {
      out.remove(cmd);
    } else {
      out[cmd] = encodeActivator(a);
    }
  }

  switch (choice) {
    case AssignShortcut(:final shortcut, :final takenFrom):
      set(id, shortcut);
      if (takenFrom != null) set(takenFrom, null);
    case RemoveShortcut():
      set(id, null);
    case ResetShortcut():
      out.remove(id);
      // O do jogo pode estar com outro agora: aquele perde.
      if (commands.defaultShortcutOf(id) case final a?) {
        if (commands.commandWithShortcut(a, except: id) case final other?) set(other.id, null);
      }
  }
  return out;
}
