// A busca única (D-050): uma palavra do texto ou um comando, num campo só.
// Ctrl+F, Ctrl+L e Ctrl+K abrem; o campo da ponta direita das abas também.
//
// Duas seções: "No documento" (as ocorrências, com a página e o trecho, da
// cópia temporária lida num isolate) e "Comandos" (os do registro, como a
// antiga paleta). Setas escolhem, Enter vai, Esc fecha. Substituir continua
// no painel Localizar (Ctrl+H), que o último item abre.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../commands/command_registry.dart';
import '../../commands/commands_view.dart';
import '../../commands/menus.dart';
import '../../commands/palette_search.dart';
import '../../document/document_controller.dart';
import '../../document/fodt.dart';
import '../atoms/w_label.dart';
import '../atoms/w_text_field.dart';
import '../tokens/tokens.dart';

/// O que a busca escolheu.
sealed class SearchChoice {
  const SearchChoice();
}

class RunCommand extends SearchChoice {
  const RunCommand(this.id);
  final String id;
}

class GoToHit extends SearchChoice {
  const GoToHit(this.hit);
  final TextHit hit;
}

/// Abrir o painel Localizar e substituir com o que foi digitado.
class OpenFindOptions extends SearchChoice {
  const OpenFindOptions(this.query);
  final String query;
}

/// Abre a busca. Devolve a escolha (já feita: o comando rodou, o cursor foi
/// à ocorrência), ou null se fechou sem escolher.
Future<SearchChoice?> showCommandPalette(BuildContext context, CommandRegistry commands, {DocumentController? doc}) async {
  final choice = await showDialog<SearchChoice>(
    context: context,
    barrierColor: QuillTokens.of(context).colors.frame.withValues(alpha: 0),
    builder: (_) => CommandPalette(commands: commands, doc: doc),
  );
  doc?.endTextSearch();
  return choice;
}

/// Um item da lista: um título de seção (não se escolhe) ou uma escolha.
sealed class _Item {
  const _Item();
}

class _Header extends _Item {
  const _Header(this.text, [this.trailing]);
  final String text;
  final String? trailing;
}

class _Note extends _Item {
  const _Note(this.text);
  final String text;
}

class _Choice extends _Item {
  const _Choice(this.choice, {this.entry});
  final SearchChoice choice;
  final PaletteEntry? entry;
}

class CommandPalette extends StatefulWidget {
  const CommandPalette({super.key, required this.commands, this.doc});
  final CommandRegistry commands;

  /// Sem documento aberto, só os comandos.
  final DocumentController? doc;

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  final _query = TextEditingController();
  int _index = 0;

  /// A busca no texto espera uma pausa de 250 ms na digitação. [_asked] é a
  /// pergunta da última resposta; [_result], a resposta.
  Timer? _debounce;
  String _asked = '';
  bool _searching = false;
  TextSearchResult _result = TextSearchResult.empty;

  bool get _textSearch => widget.doc?.isOpen ?? false;

  void _changed(String q) {
    setState(() => _index = 0);
    _debounce?.cancel();
    if (!_textSearch || q.trim().length < 2) {
      setState(() {
        _result = TextSearchResult.empty;
        _searching = false;
        _asked = q;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      final r = await widget.doc!.searchText(SearchQuery(q));
      // Só a resposta da última pergunta vale.
      if (!mounted || _query.text != q) return;
      setState(() {
        _result = r;
        _asked = q;
        _searching = false;
      });
    });
  }

  List<_Item> _items(AppLocalizations l10n) {
    final q = _query.text;
    final commands = searchCommands(widget.commands, editorMenus(l10n), q);
    final text = _textSearch && q.trim().length >= 2;
    return [
      if (text) ...[
        _Header(l10n.searchSectionDocument, _asked == q && !_searching ? l10n.searchHitsCount(_result.total) : null),
        if (_searching || _asked != q)
          _Note(l10n.searchSearching)
        else if (_result.hits.isEmpty)
          _Note(l10n.searchNoHits)
        else ...[
          for (final h in _result.hits) _Choice(GoToHit(h)),
          if (_result.total > _result.hits.length) _Note(l10n.searchMoreHits(_result.total - _result.hits.length)),
        ],
      ],
      if (commands.isNotEmpty) ...[
        if (text) _Header(l10n.searchSectionCommands),
        for (final e in commands) _Choice(RunCommand(e.command.id), entry: e),
      ],
      if (text) _Choice(OpenFindOptions(q)),
    ];
  }

  void _pick(SearchChoice c) {
    Navigator.of(context).pop(c);
    // Depois de fechar: o comando pode abrir outra tela.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (c) {
        case RunCommand(:final id):
          widget.commands.run(id);
        case GoToHit(:final hit):
          widget.doc?.goToHit(hit);
        case OpenFindOptions():
          break; // quem abriu a busca abre o painel
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final items = _items(l10n);
    final choices = [for (final (i, it) in items.indexed) if (it is _Choice) i];
    _index = choices.isEmpty ? 0 : _index.clamp(0, choices.length - 1);
    final selected = choices.isEmpty ? -1 : choices[_index];
    return Align(
      alignment: const Alignment(0, -0.7),
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: 640,
          constraints: const BoxConstraints(maxHeight: 520),
          decoration: BoxDecoration(
            color: t.colors.frameRaised,
            borderRadius: BorderRadius.circular(t.radius.panel),
            border: Border.all(color: t.colors.border),
            boxShadow: [BoxShadow(color: t.colors.onFrame.withValues(alpha: 0.18), blurRadius: 24)],
          ),
          padding: EdgeInsets.all(t.space.md),
          child: Focus(
            onKeyEvent: (_, e) {
              if (e is KeyUpEvent || choices.isEmpty) return KeyEventResult.ignored;
              if (e.logicalKey == LogicalKeyboardKey.arrowDown) {
                setState(() => _index = (_index + 1) % choices.length);
                return KeyEventResult.handled;
              }
              if (e.logicalKey == LogicalKeyboardKey.arrowUp) {
                setState(() => _index = (_index - 1) % choices.length);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              WTextField(
                label: l10n.searchCommands,
                hint: l10n.paletteHint,
                controller: _query,
                autofocus: true,
                onChanged: _changed,
                onSubmitted: (_) {
                  if (selected >= 0) _pick((items[selected] as _Choice).choice);
                },
              ),
              SizedBox(height: t.space.sm),
              if (items.isEmpty)
                Padding(
                  padding: EdgeInsets.all(t.space.md),
                  child: WLabel(l10n.paletteEmpty, tone: WLabelTone.muted),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, i) => switch (items[i]) {
                      _Header(:final text, :final trailing) => Padding(
                          padding: EdgeInsets.fromLTRB(t.space.md, t.space.md, t.space.md, t.space.xs),
                          child: Semantics(
                            header: true,
                            child: Row(children: [
                              Expanded(child: WLabel(text, small: true, tone: WLabelTone.muted)),
                              if (trailing != null) WLabel(trailing, small: true, tone: WLabelTone.muted),
                            ]),
                          ),
                        ),
                      _Note(:final text) => Padding(
                          padding: EdgeInsets.symmetric(horizontal: t.space.md, vertical: t.space.sm),
                          child: Semantics(liveRegion: true, child: WLabel(text, tone: WLabelTone.muted)),
                        ),
                      _Choice(:final choice, :final entry) => _Row(
                          selected: i == selected,
                          onTap: () => _pick(choice),
                          child: switch (choice) {
                            RunCommand(:final id) => _CommandRow(
                                entry: entry!,
                                shortcut: widget.commands.shortcutLabelOf(id),
                              ),
                            GoToHit(:final hit) => _HitRow(hit: hit),
                            OpenFindOptions() => _IconRow(
                                icon: Symbols.find_replace_rounded,
                                label: l10n.searchFindOptions,
                                shortcut: widget.commands.shortcutLabelOf(ViewCommandIds.replace),
                              ),
                          },
                        ),
                    },
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Uma linha escolhível: marcada pelas setas, clicável.
class _Row extends StatelessWidget {
  const _Row({required this.selected, required this.onTap, required this.child});
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(minHeight: t.density.control),
          decoration: BoxDecoration(
            color: selected ? t.colors.accentSoft : null,
            borderRadius: BorderRadius.circular(t.radius.control),
          ),
          padding: EdgeInsets.symmetric(horizontal: t.space.md, vertical: t.space.sm),
          child: child,
        ),
      ),
    );
  }
}

class _CommandRow extends StatelessWidget {
  const _CommandRow({required this.entry, required this.shortcut});
  final PaletteEntry entry;
  final String? shortcut;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final c = entry.command;
    return Semantics(
      button: true,
      label: c.label,
      child: ExcludeSemantics(
        child: Row(children: [
          Icon(c.icon, size: t.density.icon - 2, color: t.colors.onFrame),
          SizedBox(width: t.space.md),
          Expanded(child: WLabel(c.label)),
          if (entry.menu case final m?) ...[
            WLabel(m, small: true, tone: WLabelTone.muted),
            SizedBox(width: t.space.md),
          ],
          if (shortcut case final s?) WLabel(s, small: true, tone: WLabelTone.muted),
        ]),
      ),
    );
  }
}

/// Uma ocorrência: o trecho com o achado em negrito, e a página.
class _HitRow extends StatelessWidget {
  const _HitRow({required this.hit});
  final TextHit hit;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final style = TextStyle(color: t.colors.onFrame, fontSize: t.font.ui, fontFamily: t.font.family);
    final text = '${hit.before}${hit.match}${hit.after}';
    return Semantics(
      button: true,
      label: l10n.searchHitLabel(text.trim(), hit.page),
      child: ExcludeSemantics(
        child: Row(children: [
          Icon(Symbols.description_rounded, size: t.density.icon - 2, color: t.colors.onFrameMuted),
          SizedBox(width: t.space.md),
          Expanded(
            child: Text.rich(
              TextSpan(style: style, children: [
                TextSpan(text: hit.before.isEmpty ? '' : '…${hit.before}'),
                TextSpan(text: hit.match, style: const TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: hit.after.isEmpty ? '' : '${hit.after}…'),
              ]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: t.space.md),
          WLabel(l10n.searchPage(hit.page), small: true, tone: WLabelTone.muted),
        ]),
      ),
    );
  }
}

class _IconRow extends StatelessWidget {
  const _IconRow({required this.icon, required this.label, this.shortcut});
  final IconData icon;
  final String label;
  final String? shortcut;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    return Semantics(
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: Row(children: [
          Icon(icon, size: t.density.icon - 2, color: t.colors.onFrame),
          SizedBox(width: t.space.md),
          Expanded(child: WLabel(label)),
          if (shortcut case final s?) WLabel(s, small: true, tone: WLabelTone.muted),
        ]),
      ),
    );
  }
}
