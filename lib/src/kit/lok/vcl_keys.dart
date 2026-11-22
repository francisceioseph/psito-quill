// Teclas do Flutter → códigos do VCL, que o postKeyEvent do LOK espera.
//
// Os números vêm de include/vcl/keycodes.hxx (com::sun::star::awt::Key) do
// LibreOffice. Não estão no LibreOfficeKitEnums.h, por isso ficam aqui.
import 'package:flutter/services.dart';

abstract final class VclKey {
  static const num0 = 256;
  static const a = 512;
  static const f1 = 768;
  static const down = 1024, up = 1025, left = 1026, right = 1027;
  static const home = 1028, end = 1029, pageUp = 1030, pageDown = 1031;
  static const enter = 1280, escape = 1281, tab = 1282, backspace = 1283;
  static const space = 1284, insert = 1285, delete = 1286;

  static const shift = 0x1000, mod1 = 0x2000, mod2 = 0x4000;
}

/// O que mandar ao LOK para uma tecla: o caractere e o código.
class VclKeyStroke {
  const VclKeyStroke(this.charCode, this.keyCode);
  final int charCode, keyCode;

  @override
  bool operator ==(Object other) =>
      other is VclKeyStroke && other.charCode == charCode && other.keyCode == keyCode;

  @override
  int get hashCode => Object.hash(charCode, keyCode);

  @override
  String toString() => 'VclKeyStroke(char: $charCode, key: $keyCode)';
}

final Map<LogicalKeyboardKey, (int, int)> _special = {
  LogicalKeyboardKey.arrowDown: (0, VclKey.down),
  LogicalKeyboardKey.arrowUp: (0, VclKey.up),
  LogicalKeyboardKey.arrowLeft: (0, VclKey.left),
  LogicalKeyboardKey.arrowRight: (0, VclKey.right),
  LogicalKeyboardKey.home: (0, VclKey.home),
  LogicalKeyboardKey.end: (0, VclKey.end),
  LogicalKeyboardKey.pageUp: (0, VclKey.pageUp),
  LogicalKeyboardKey.pageDown: (0, VclKey.pageDown),
  LogicalKeyboardKey.enter: (13, VclKey.enter),
  LogicalKeyboardKey.numpadEnter: (13, VclKey.enter),
  LogicalKeyboardKey.escape: (27, VclKey.escape),
  LogicalKeyboardKey.tab: (9, VclKey.tab),
  LogicalKeyboardKey.backspace: (8, VclKey.backspace),
  LogicalKeyboardKey.insert: (0, VclKey.insert),
  LogicalKeyboardKey.delete: (127, VclKey.delete),
};

/// Converte uma tecla. null quando não é para o motor (só um modificador,
/// por exemplo).
VclKeyStroke? vclKeyFor(KeyEvent event, {required bool shift, required bool control, required bool alt}) {
  final mods = (shift ? VclKey.shift : 0) | (control ? VclKey.mod1 : 0) | (alt ? VclKey.mod2 : 0);
  final key = event.logicalKey;

  final special = _special[key];
  if (special != null) return VclKeyStroke(special.$1, special.$2 | mods);

  final fIndex = _functionKeys.indexOf(key);
  if (fIndex >= 0) return VclKeyStroke(0, (VclKey.f1 + fIndex) | mods);

  // Com Ctrl ou Alt, é um atalho: vai o código da letra/número, sem caractere.
  if (control || alt) {
    final label = key.keyLabel.toLowerCase();
    if (label.length == 1) {
      final c = label.codeUnitAt(0);
      if (c >= 0x61 && c <= 0x7a) return VclKeyStroke(0, (VclKey.a + c - 0x61) | mods);
      if (c >= 0x30 && c <= 0x39) return VclKeyStroke(0, (VclKey.num0 + c - 0x30) | mods);
    }
    return null;
  }

  // Texto: o caractere já vem com o layout (ABNT2) e o Shift aplicados.
  final ch = event.character;
  if (ch != null && ch.isNotEmpty) {
    final rune = ch.runes.first;
    if (rune >= 0x20 && rune != 0x7f) {
      return VclKeyStroke(rune, rune == 0x20 ? VclKey.space : 0);
    }
  }
  return null;
}

final List<LogicalKeyboardKey> _functionKeys = [
  LogicalKeyboardKey.f1, LogicalKeyboardKey.f2, LogicalKeyboardKey.f3, LogicalKeyboardKey.f4,
  LogicalKeyboardKey.f5, LogicalKeyboardKey.f6, LogicalKeyboardKey.f7, LogicalKeyboardKey.f8,
  LogicalKeyboardKey.f9, LogicalKeyboardKey.f10, LogicalKeyboardKey.f11, LogicalKeyboardKey.f12,
];
