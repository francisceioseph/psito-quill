// O trilho de navegação, à esquerda (Fase 2B, Etapa 2): os painéis que se
// abrem ao lado da página (o fichário e as Notas do livro, Estrutura,
// Localizar, Estilos). O Assistente entra quando existir.
//
// Cada item é um bloco de 76 px com o ícone e o nome embaixo (até duas
// linhas, sem cortar "Comentários"). O aberto fica com o bloco inteiro tonal
// e o ícone preenchido; o realce do mouse e do foco também vão no bloco
// todo. Clicar no aberto fecha o painel.
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

  /// A largura do trilho; o bloco de cada item tem 4 px de folga de cada lado.
  /// O nome tem 72 px: "Comentários", o maior, mede uns 68 na Noto Sans de
  /// 11 px.
  static const width = 84.0;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: label,
      child: SizedBox(
        width: width,
        // Numa janela baixa (ou com a interface ampliada), o trilho rola.
        child: SingleChildScrollView(
          child: Column(children: [
          SizedBox(height: t.space.sm),
          for (final item in items) ...[
            _RailButton<T>(
              item: item,
              selected: item.value == selected,
              onPressed: () => onSelected(item.value == selected ? null : item.value),
            ),
            SizedBox(height: t.space.xs),
          ],
        ]),
        ),
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
    final icon = Icon(widget.item.icon, size: t.density.icon, color: fg, fill: on && modern ? 1 : 0, weight: on ? 500 : 400);
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
              child: AnimatedContainer(
                duration: t.motion.fast,
                width: NavRail.width - 8,
                padding: EdgeInsets.symmetric(horizontal: 2, vertical: t.space.sm),
                decoration: BoxDecoration(
                  color: on
                      ? c.accentSoft
                      : _hover
                          ? c.surfaceHigh
                          : null,
                  borderRadius: BorderRadius.circular(modern ? t.radius.control : 0),
                  border: _focused ? Border.all(color: c.focusRing, width: 2) : null,
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  icon,
                  SizedBox(height: t.space.xs),
                  Text(
                    widget.item.label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: fg, fontSize: 11, height: 1.15, fontWeight: FontWeight.w500, fontFamily: t.font.family),
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
