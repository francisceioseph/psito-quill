// O painel Estrutura, à esquerda: os títulos do documento, recuados pelo
// nível, com o atual marcado. Clicar leva até o título. Em cima, "Início do
// documento", o nível até onde mostrar e recolher ou expandir (D-091).
//
// Uma lista preguiçosa (ListView.builder): um livro tem centenas de títulos,
// e só os visíveis são construídos.
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../document/outline.dart';
import '../atoms/w_button.dart';
import '../atoms/w_dropdown.dart';
import '../atoms/w_label.dart';
import '../molecules/side_panel.dart';
import '../tokens/tokens.dart';

class OutlinePanel extends StatefulWidget {
  const OutlinePanel({
    super.key,
    required this.entries,
    required this.current,
    required this.onJump,
    required this.onStart,
    required this.onClose,
  });

  final List<OutlineEntry> entries;

  /// O título onde está o cursor; null: antes do primeiro.
  final int? current;
  final ValueChanged<int> onJump;

  /// "Início do documento", o primeiro item (D-091).
  final VoidCallback onStart;
  final VoidCallback onClose;

  @override
  State<OutlinePanel> createState() => _OutlinePanelState();
}

/// Até o nível 9; 10 mostra todos.
const _allLevels = 10;

class _OutlinePanelState extends State<OutlinePanel> {
  int _maxLevel = _allLevels;

  /// Os títulos recolhidos, pelo índice. Só vale para a mesma lista: muda o
  /// número de títulos, volta tudo aberto.
  final _collapsed = <int>{};

  @override
  void didUpdateWidget(OutlinePanel old) {
    super.didUpdateWidget(old);
    if (old.entries.length != widget.entries.length) _collapsed.clear();
  }

  bool _hasChildren(int i) {
    final e = widget.entries;
    return i + 1 < e.length && e[i + 1].level > e[i].level && e[i + 1].level <= _maxLevel;
  }

  /// Os índices que aparecem: até o nível escolhido, sem os de dentro de um
  /// recolhido.
  List<int> _visible() {
    final out = <int>[];
    int? hideAbove;
    for (final (i, e) in widget.entries.indexed) {
      if (e.level > _maxLevel) continue;
      if (hideAbove != null) {
        if (e.level > hideAbove) continue;
        hideAbove = null;
      }
      out.add(i);
      if (_collapsed.contains(i) && _hasChildren(i)) hideAbove = e.level;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = QuillTokens.of(context);
    final entries = widget.entries;
    final visible = _visible();
    final current = widget.current;
    // O atual escondido num recolhido: marca o de fora que o contém.
    int? shown = current;
    if (current != null && !visible.contains(current)) {
      shown = visible.lastWhere((i) => i < current, orElse: () => -1);
      if (shown < 0) shown = null;
    }
    final toggleWidth = t.density.control;
    return SidePanel(
      title: l10n.outlineTitle,
      closeLabel: l10n.outlineClose,
      onClose: widget.onClose,
      side: AxisDirection.left,
      width: 280,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (entries.isNotEmpty) ...[
          Row(children: [
            Expanded(
              child: LayoutBuilder(builder: (context, box) => WDropdown<int>(
                label: l10n.outlineLevels,
                text: _maxLevel == _allLevels ? l10n.outlineAllLevels : l10n.outlineLevelN(_maxLevel),
                items: [
                  for (var n = 1; n <= 9; n++) WDropdownItem(n, l10n.outlineLevelN(n)),
                  WDropdownItem(_allLevels, l10n.outlineAllLevels),
                ],
                onSelected: (n) => setState(() {
                  _maxLevel = n;
                  _collapsed.clear();
                }),
                width: box.maxWidth,
              )),
            ),
            WButton(
              icon: Symbols.unfold_more_rounded,
              label: l10n.outlineExpandAll,
              onPressed: _collapsed.isEmpty ? null : () => setState(_collapsed.clear),
            ),
            WButton(
              icon: Symbols.unfold_less_rounded,
              label: l10n.outlineCollapseAll,
              onPressed: () => setState(() {
                _collapsed
                  ..clear()
                  ..addAll([for (var i = 0; i < entries.length; i++) if (_hasChildren(i)) i]);
              }),
            ),
          ]),
          SizedBox(height: t.space.sm),
        ],
        PanelListItem(text: l10n.outlineStart, selected: current == null, onPressed: widget.onStart),
        Expanded(
          child: entries.isEmpty
              ? Padding(
                  padding: EdgeInsets.only(top: t.space.md),
                  child: WLabel(l10n.outlineEmpty, tone: WLabelTone.muted, maxLines: 4),
                )
              : ListView.builder(
                  itemCount: visible.length,
                  itemExtent: t.density.control + t.space.xs,
                  padding: EdgeInsets.only(bottom: t.space.md),
                  itemBuilder: (context, k) {
                    final i = visible[k];
                    final e = entries[i];
                    final open = !_collapsed.contains(i);
                    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      SizedBox(width: (e.level - 1).clamp(0, 5) * 14.0),
                      if (_hasChildren(i))
                        WButton(
                          icon: open ? Symbols.expand_more_rounded : Symbols.chevron_right_rounded,
                          label: open ? l10n.outlineCollapse(e.text) : l10n.outlineExpand(e.text),
                          onPressed: () => setState(() => open ? _collapsed.add(i) : _collapsed.remove(i)),
                        )
                      else
                        SizedBox(width: toggleWidth),
                      Expanded(
                        child: PanelListItem(
                          text: e.text,
                          level: e.level,
                          indent: false,
                          selected: i == shown,
                          onPressed: () => widget.onJump(i),
                        ),
                      ),
                    ]);
                  },
                ),
        ),
      ]),
    );
  }
}

/// Um item das listas dos painéis (Estrutura, Estilos): uma pílula que fica
/// tonal quando escolhida, recuada pelo nível.
class PanelListItem extends StatefulWidget {
  const PanelListItem({super.key, required this.text, required this.selected, this.onPressed, this.level = 1, this.indent = true});
  final String text;
  final bool selected;
  final VoidCallback? onPressed;

  /// 1 sem recuo; cada nível a mais recua 14 px.
  final int level;

  /// false: quem monta a lista recua (a Estrutura, com o botão de recolher).
  final bool indent;

  @override
  State<PanelListItem> createState() => _PanelListItemState();
}

class _PanelListItemState extends State<PanelListItem> {
  bool _hover = false, _focused = false;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final c = t.colors;
    final on = widget.selected;
    final modern = t.component == ComponentStyle.modern;
    return Semantics(
      container: true,
      button: true,
      selected: on,
      label: widget.text,
      enabled: widget.onPressed != null,
      child: FocusableActionDetector(
        enabled: widget.onPressed != null,
        mouseCursor: widget.onPressed != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
            widget.onPressed?.call();
            return null;
          }),
        },
        child: GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            margin: EdgeInsets.only(bottom: t.space.xs),
            padding: EdgeInsets.only(
              left: t.space.md + (widget.indent ? (widget.level - 1).clamp(0, 5) * 14.0 : 0),
              right: t.space.md,
            ),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: on
                  ? c.accentSoft
                  : _hover
                      ? c.surfaceHigh
                      : null,
              borderRadius: BorderRadius.circular(modern ? 16 : 0),
              border: _focused ? Border.all(color: c.focusRing, width: 2) : null,
            ),
            child: ExcludeSemantics(
              child: Text(
                widget.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: on && modern ? c.onAccentSoft : c.onFrameMuted,
                  fontSize: t.font.ui,
                  fontWeight: on || widget.level == 1 ? FontWeight.w500 : FontWeight.w400,
                  fontFamily: t.font.family,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
