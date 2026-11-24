// O trilho de navegação, à esquerda (Fase 2B, Etapa 2): os painéis que se
// abrem ao lado da página (o fichário e as Notas do livro, Estrutura,
// Localizar, Estilos). O Assistente entra quando existir.
//
// Cada item é um botão de 56 px com o ícone numa pílula e o nome embaixo,
// como o NavigationRail do Material 3. O aberto fica com a pílula tonal e o
// ícone preenchido. Clicar no aberto fecha o painel.
import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

class NavRailItem<T> {
  const NavRailItem(this.value, this.icon, this.label, {this.tooltip});
  final T value;
  final IconData icon;
  final String label;

  /// A dica com o atalho ("Estrutura (Ctrl+F2)"); null: o nome.
  final String? tooltip;
}

class NavRail<T> extends StatelessWidget {
  const NavRail({super.key, required this.items, required this.selected, required this.onSelected, required this.label});

  final List<NavRailItem<T>> items;

  /// O painel aberto; null: nenhum.
  final T? selected;

  /// Escolher o aberto manda null (fecha).
  final ValueChanged<T?> onSelected;

  /// O nome do trilho para o leitor de tela ("Painéis").
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: label,
      child: SizedBox(
        width: 64,
        child: Column(children: [
          SizedBox(height: t.space.sm),
          for (final item in items) ...[
            _RailButton<T>(
              item: item,
              selected: item.value == selected,
              onPressed: () => onSelected(item.value == selected ? null : item.value),
            ),
            SizedBox(height: t.space.md),
          ],
        ]),
      ),
    );
  }
}

class _RailButton<T> extends StatefulWidget {
  const _RailButton({required this.item, required this.selected, required this.onPressed});
  final NavRailItem<T> item;
  final bool selected;
  final VoidCallback onPressed;

  @override
  State<_RailButton<T>> createState() => _RailButtonState<T>();
}

class _RailButtonState<T> extends State<_RailButton<T>> {
  bool _hover = false, _focused = false;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final c = t.colors;
    final modern = t.component == ComponentStyle.modern;
    final on = widget.selected;
    final fg = on && modern ? c.onAccentSoft : c.onFrameMuted;
    final pill = Container(
      width: 48,
      height: 28,
      decoration: BoxDecoration(
        color: on
            ? c.accentSoft
            : _hover
                ? c.surfaceHigh
                : null,
        borderRadius: BorderRadius.circular(modern ? 14 : 0),
        border: _focused ? Border.all(color: c.focusRing, width: 2) : null,
      ),
      child: Icon(widget.item.icon, size: t.density.icon, color: fg, fill: on && modern ? 1 : 0, weight: on ? 500 : 400),
    );
    return Semantics(
      container: true,
      button: true,
      selected: on,
      label: widget.item.label,
      child: Tooltip(
        message: widget.item.tooltip ?? widget.item.label,
        waitDuration: const Duration(milliseconds: 600),
        child: FocusableActionDetector(
          mouseCursor: SystemMouseCursors.click,
          onShowHoverHighlight: (v) => setState(() => _hover = v),
          onShowFocusHighlight: (v) => setState(() => _focused = v),
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
              widget.onPressed();
              return null;
            }),
          },
          child: GestureDetector(
            onTap: widget.onPressed,
            child: ExcludeSemantics(
              child: SizedBox(
                width: 56,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  pill,
                  SizedBox(height: t.space.xs),
                  Text(
                    widget.item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w500, fontFamily: t.font.family),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
