// O painel Estrutura, à esquerda: os títulos do documento, recuados pelo
// nível, com o atual marcado. Clicar leva até o título.
//
// Uma lista preguiçosa (ListView.builder): um livro tem centenas de títulos,
// e só os visíveis são construídos.
import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../document/outline.dart';
import '../atoms/w_label.dart';
import '../molecules/side_panel.dart';
import '../tokens/tokens.dart';

class OutlinePanel extends StatelessWidget {
  const OutlinePanel({super.key, required this.entries, required this.current, required this.onJump, required this.onClose});

  final List<OutlineEntry> entries;

  /// O título onde está o cursor; null: antes do primeiro.
  final int? current;
  final ValueChanged<int> onJump;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = QuillTokens.of(context);
    return SidePanel(
      title: l10n.outlineTitle,
      closeLabel: l10n.outlineClose,
      onClose: onClose,
      side: AxisDirection.left,
      width: 280,
      child: entries.isEmpty
          ? Padding(
              padding: EdgeInsets.only(top: t.space.md),
              child: WLabel(l10n.outlineEmpty, tone: WLabelTone.muted, maxLines: 4),
            )
          : ListView.builder(
              itemCount: entries.length,
              itemExtent: t.density.control + t.space.xs,
              padding: EdgeInsets.only(bottom: t.space.md),
              itemBuilder: (context, i) => PanelListItem(
                text: entries[i].text,
                level: entries[i].level,
                selected: i == current,
                onPressed: () => onJump(i),
              ),
            ),
    );
  }
}

/// Um item das listas dos painéis (Estrutura, Estilos): uma pílula que fica
/// tonal quando escolhida, recuada pelo nível.
class PanelListItem extends StatefulWidget {
  const PanelListItem({super.key, required this.text, required this.selected, this.onPressed, this.level = 1});
  final String text;
  final bool selected;
  final VoidCallback? onPressed;

  /// 1 sem recuo; cada nível a mais recua 14 px.
  final int level;

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
            padding: EdgeInsets.only(left: t.space.md + (widget.level - 1).clamp(0, 5) * 14.0, right: t.space.md),
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
