// Átomos de botão: WButton (ação), WToggle (liga/desliga) e WTextButton
// (só texto: abas da faixa, itens do painel Arquivo). Todos sobre a mesma
// superfície, WControlSurface, que o WDropdown também usa.
//
// Leem só os tokens. O desenho muda com o ComponentStyle do tema
// (Strategy): moderno com raio e realce suave, ou bisel 3D do tema 97.
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../tokens/tokens.dart';

class WButton extends StatelessWidget {
  const WButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.showLabel = false,
    this.tooltip,
  });

  final IconData icon;

  /// Também é o nome para o leitor de tela e a dica.
  final String label;
  final VoidCallback? onPressed;
  final bool showLabel;

  /// A dica, se for diferente do rótulo ("Salvar (Ctrl+B)").
  final String? tooltip;

  @override
  Widget build(BuildContext context) => WControlSurface(
        icon: icon,
        text: showLabel ? label : null,
        tooltip: tooltip ?? label,
        onPressed: onPressed,
        selected: false,
        semantics: (child) => Semantics(container: true, button: true, enabled: onPressed != null, label: label, child: child),
      );
}

/// Um botão grande, com o ícone em cima do nome (o Colar da faixa, os de
/// Inserir). Ocupa as duas linhas de um grupo.
class WBigButton extends StatelessWidget {
  const WBigButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.tooltip,
    this.width,
    this.dropdown = false,
  });

  final IconData icon;
  final String label;
  final String? tooltip;
  final VoidCallback? onPressed;

  /// Largura fixa (a faixa adaptável calcula com ela); o nome quebra em até
  /// duas linhas. null: a do conteúdo.
  final double? width;

  /// Abre um menu: uma setinha embaixo do nome.
  final bool dropdown;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final h = t.density.control * 2 + t.space.sm;
    return WControlSurface(
      tooltip: tooltip ?? label,
      onPressed: onPressed,
      selected: false,
      height: h,
      width: width,
      semantics: (child) => Semantics(container: true, button: true, enabled: onPressed != null, label: label, child: child),
      child: Builder(builder: (context) {
        final fg = onPressed == null ? t.colors.onFrame.withValues(alpha: 0.38) : t.colors.onFrame;
        final text = Text(
          label,
          maxLines: dropdown ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(color: fg, fontSize: t.font.small, height: 1.1, fontWeight: FontWeight.w500, fontFamily: t.font.family),
        );
        return Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: t.density.icon + 4, color: fg),
          SizedBox(height: t.space.xs),
          if (width == null) text else Flexible(child: text),
          if (dropdown) Icon(Symbols.expand_more_rounded, size: t.font.small, color: fg),
        ]);
      }),
    );
  }
}

/// Um botão só de texto. [selected] marca a aba atual.
class WTextButton extends StatelessWidget {
  const WTextButton({
    super.key,
    required this.label,
    this.onPressed,
    this.selected = false,
    this.icon,
    this.autofocus = false,
    this.pill = true,
    this.tone = WTone.normal,
    this.tab = false,
  });

  /// Uma aba da faixa: o texto no tamanho das abas (`font.tab`).
  final bool tab;

  /// Cantos redondos inteiros, como as abas do desenho.
  final bool pill;

  /// As cores: normal, preenchido (o Arquivo) ou de contexto (Tabela, Imagem).
  final WTone tone;

  final String label;
  final bool autofocus;
  final VoidCallback? onPressed;
  final bool selected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => WControlSurface(
        icon: icon,
        text: label,
        tooltip: null,
        pill: pill,
        tone: tone,
        autofocus: autofocus,
        onPressed: onPressed,
        selected: selected,
        fontSize: tab ? QuillTokens.of(context).font.tab : null,
        semantics: (child) =>
            Semantics(container: true, button: true, selected: selected, enabled: onPressed != null, label: label, child: child),
      );
}

/// As cores de um controle no desenho moderno.
/// - normal: transparente, tonal quando ligado;
/// - filled: a cor da marca sempre (o botão Arquivo);
/// - context: o terciário (as abas Tabela e Imagem, que aparecem com a seleção).
enum WTone { normal, filled, context }

class WToggle extends StatelessWidget {
  const WToggle({super.key, required this.icon, required this.label, required this.value, this.onPressed, this.tooltip});

  final IconData icon;
  final String label;
  final String? tooltip;

  /// Ligado? O valor vem do estado do motor, não do clique.
  final bool value;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => WControlSurface(
        icon: icon,
        tooltip: tooltip ?? label,
        onPressed: onPressed,
        selected: value,
        semantics: (child) =>
            Semantics(container: true, button: true, toggled: value, enabled: onPressed != null, label: label, child: child),
      );
}

/// A superfície comum dos controles: ícone e/ou texto, realce de mouse e de
/// foco, Enter/Espaço pelo teclado, e o desenho moderno ou bisel.
///
/// Clicar não tira o foco do documento (como na faixa do Word): só o Tab
/// foca um controle.
class WControlSurface extends StatefulWidget {
  const WControlSurface({
    super.key,
    this.icon,
    this.text,
    this.trailingIcon,
    this.width,
    this.outlined = false,
    this.pill = false,
    this.tone = WTone.normal,
    this.height,
    this.autofocus = false,
    this.child,
    this.fontSize,
    required this.tooltip,
    required this.onPressed,
    required this.selected,
    required this.semantics,
  });

  /// O tamanho do texto; null: o da interface (as abas usam o `font.tab`).
  final double? fontSize;

  /// Um conteúdo próprio no lugar do ícone e do texto (a amostra de cor).
  final Widget? child;

  final IconData? icon;
  final String? text;

  /// Uma seta, nos campos de lista.
  final IconData? trailingIcon;

  /// Largura fixa (campos de lista); null: a do conteúdo.
  final double? width;

  /// Com contorno, como um campo (no estilo moderno).
  final bool outlined;

  /// Cantos redondos inteiros (abas, botões segmentados).
  final bool pill;
  final WTone tone;

  /// Altura própria (os chips, 28 px); null: a da densidade.
  final double? height;
  final bool autofocus;
  final String? tooltip;
  final VoidCallback? onPressed;
  final bool selected;
  final Widget Function(Widget) semantics;

  @override
  State<WControlSurface> createState() => _ControlSurfaceState();
}

class _ControlSurfaceState extends State<WControlSurface> {
  bool _hover = false, _pressed = false, _focused = false;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final c = t.colors;
    final enabled = widget.onPressed != null;
    final modern = t.component == ComponentStyle.modern;
    // Material 3: o ligado é tonal (secondaryContainer); o resto, onSurfaceVariant.
    final fg = !enabled
        ? c.onFrame.withValues(alpha: 0.38)
        : !modern
            ? c.onFrame
            : switch (widget.tone) {
                WTone.filled => c.onAccent,
                WTone.context => widget.selected ? c.onTertiaryContainer : c.tertiary,
                WTone.normal => widget.selected
                    ? c.onAccentSoft
                    : widget.outlined
                        ? c.onFrame
                        : c.onFrameMuted,
              };

    final text = widget.text;
    final label = text == null
        ? null
        : Text(text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: fg,
                fontSize: widget.fontSize ?? t.font.ui,
                fontFamily: t.font.family,
                fontWeight: modern && !widget.outlined ? FontWeight.w500 : null));
    // O ícone ligado fica preenchido (o eixo FILL do Material Symbols).
    final on = widget.selected && modern;
    final content = Row(mainAxisSize: widget.width == null ? MainAxisSize.min : MainAxisSize.max, children: [
      if (widget.icon case final icon?)
        Icon(icon, size: t.density.icon, color: fg, fill: on ? 1 : 0, weight: on ? 500 : 400),
      if (widget.icon != null && label != null) SizedBox(width: t.space.sm),
      if (label != null) widget.width == null ? Flexible(child: label) : Expanded(child: label),
      if (widget.trailingIcon case final trailing?) ...[
        SizedBox(width: t.space.xs),
        Icon(trailing, size: t.density.icon - 2, color: fg),
      ],
    ]);

    final height = widget.height ?? t.density.control;
    final radius = widget.pill ? height / 2 : t.radius.control;
    final decoration = switch (t.component) {
      ComponentStyle.modern => BoxDecoration(
          color: widget.tone == WTone.filled
              ? (_hover || _pressed ? Color.alphaBlend(c.onAccent.withValues(alpha: 0.12), c.accent) : c.accent)
              : widget.selected
              ? (widget.tone == WTone.context ? c.tertiaryContainer : c.accentSoft)
              : _pressed
                  ? c.surfaceHighest
                  : _hover
                      ? c.surfaceHigh
                      : widget.outlined
                          ? c.surfaceLowest
                          : null,
          borderRadius: BorderRadius.circular(radius),
          border: _focused
              ? Border.all(color: c.focusRing, width: 2)
              : widget.outlined
                  ? Border.all(color: widget.selected ? c.accentSoft : c.border)
                  : null,
        ),
      // Bisel: claro em cima e à esquerda; afundado (invertido) se ligado ou
      // apertado.
      ComponentStyle.bevel => () {
          final down = widget.selected || _pressed;
          final hi = BorderSide(color: down ? c.bevelDark : c.bevelLight, width: 1.5);
          final lo = BorderSide(color: down ? c.bevelLight : c.bevelDark, width: 1.5);
          return BoxDecoration(
            color: c.frameRaised,
            border: Border(top: hi, left: hi, bottom: lo, right: lo),
            boxShadow: _focused ? [BoxShadow(color: c.focusRing, spreadRadius: 1)] : null,
          );
        }(),
    };
    // Só ícone: um quadrado da altura do controle, sem margem.
    final iconOnly = text == null && widget.child == null && widget.trailingIcon == null;
    final padding = iconOnly ? 0.0 : widget.pill ? t.space.lg + 2 : t.space.md;

    final surface = FocusableActionDetector(
          enabled: enabled,
          autofocus: widget.autofocus,
          mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onShowHoverHighlight: (v) => setState(() => _hover = v),
          onShowFocusHighlight: (v) => setState(() => _focused = v),
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
              widget.onPressed?.call();
              return null;
            }),
          },
          child: GestureDetector(
            onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
            onTapCancel: () => setState(() => _pressed = false),
            onTap: enabled
                ? () {
                    setState(() => _pressed = false);
                    widget.onPressed!();
                  }
                : null,
            child: AnimatedContainer(
              duration: t.motion.fast,
              width: widget.width,
              constraints: BoxConstraints(minHeight: height, minWidth: height),
              padding: EdgeInsets.symmetric(horizontal: padding),
              decoration: decoration,
              // Centraliza sem crescer: o tamanho é o do conteúdo (no mínimo
              // o da densidade), mesmo com restrições soltas.
              // O nome para o leitor de tela vem do Semantics de fora.
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: ExcludeSemantics(child: widget.child ?? content),
              ),
            ),
          ),
        );
    final tip = widget.tooltip;
    return widget.semantics(
      tip == null ? surface : Tooltip(message: tip, waitDuration: const Duration(milliseconds: 600), child: surface),
    );
  }
}
