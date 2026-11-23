// A busca da paleta de comandos (Ctrl+K): sem acento, sem maiúsculas, cada
// palavra digitada tem de aparecer no nome do comando ou do menu dele.
import 'command_registry.dart';
import 'menus.dart';

const _accents = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', //
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', 'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', //
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ç': 'c', 'ñ': 'n',
};

/// "Ação…" → "acao".
String foldForSearch(String s) {
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    if (ch == '…') continue;
    b.write(_accents[ch] ?? ch);
  }
  return b.toString();
}

class PaletteEntry {
  const PaletteEntry(this.command, this.menu);
  final Command command;

  /// O menu onde o comando está ("Formatar"), ou null.
  final String? menu;
}

/// Os comandos que casam com [query], os que começam com ela primeiro. Só
/// os que podem rodar agora.
List<PaletteEntry> searchCommands(CommandRegistry registry, List<MenuSpec> menus, String query) {
  final menuOf = <String, String>{};
  for (final m in menus) {
    for (final id in m.items.whereType<String>()) {
      menuOf.putIfAbsent(id, () => m.title);
    }
  }
  final words = foldForSearch(query).split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  final scored = <(int, PaletteEntry)>[];
  for (final c in registry.all) {
    if (!c.enabled) continue;
    final label = foldForSearch(c.label);
    final menu = menuOf[c.id];
    final hay = '$label ${foldForSearch(menu ?? '')}';
    if (!words.every(hay.contains)) continue;
    final score = words.isEmpty
        ? 2
        : label.startsWith(words.first)
            ? 0
            : label.contains(words.first)
                ? 1
                : 2;
    scored.add((score, PaletteEntry(c, menu)));
  }
  scored.sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2.command.label.compareTo(b.$2.command.label));
  return [for (final s in scored) s.$2];
}
