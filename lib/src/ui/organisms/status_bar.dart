import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../atoms/w_label.dart';
import '../atoms/w_slider.dart';
import '../tokens/tokens.dart';

/// Um campo de texto da barra de status.
class StatusField {
  const StatusField(
    this.text, {
    this.tone = WLabelTone.muted,
    this.flex = false,
    this.icon,
    this.onTap,
    this.menu,
    this.tooltip,
    this.priority = 1,
  });

  final String text;
  final WLabelTone tone;

  /// Um ícone antes do texto (o da ortografia, no idioma).
  final IconData? icon;

  /// Ocupa o espaço que sobra (a mensagem).
  final bool flex;

  /// Ação ao clicar (ex: ir para a página, abrir painel de estilos).
  final VoidCallback? onTap;

  /// Um menu que abre no clique (o idioma, as palavras). Construído só ao
  /// abrir.
  final List<Widget> Function(BuildContext context)? menu;

  /// Dica de ferramenta para o leitor de tela e mouse.
  final String? tooltip;

  /// Prioridade de exibição em telas estreitas:
  /// 1 = essencial (página, palavras)
  /// 2 = normal (idioma, somente leitura, modificado)
  /// 3 = detalhe (estilo do parágrafo)
  final int priority;
}

/// Uma linha só de leitura num menu da barra de status ("Caracteres 1.204").
class StatusInfoRow extends StatelessWidget {
  const StatusInfoRow(this.label, this.value, {super.key});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    return MergeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 220),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: t.space.lg, vertical: t.space.sm),
          child: Row(
            children: [
              Expanded(child: WLabel(label, tone: WLabelTone.muted)),
              SizedBox(width: t.space.xl),
              WLabel(value),
            ],
          ),
        ),
      ),
    );
  }
}

/// Um campo clicável da barra de status: o mouse, o Tab e Enter ou Espaço.
/// Com [menu], abre o menu no lugar.
class _StatusButton extends StatefulWidget {
  const _StatusButton({
    required this.child,
    required this.label,
    this.onTap,
    this.menu,
    this.tooltip,
    this.bevel = false,
  });

  final Widget child;

  /// O que o leitor de tela lê (o texto do campo).
  final String label;
  final VoidCallback? onTap;
  final List<Widget> Function(BuildContext context)? menu;
  final String? tooltip;
  final bool bevel;

  @override
  State<_StatusButton> createState() => _StatusButtonState();
}

class _StatusButtonState extends State<_StatusButton> {
  bool _hover = false, _focus = false;

  /// O menu existe só enquanto está aberto.
  bool _open = false;
  final _menu = MenuController();
  final _focusNode = FocusNode(debugLabel: 'status');

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _activate() {
    if (widget.menu == null) {
      widget.onTap?.call();
      return;
    }
    if (_menu.isOpen) {
      _menu.close();
      return;
    }
    // O foco fica no campo: o Esc fecha um menu só de leitura (as
    // estatísticas), que não tem item para receber o foco.
    _focusNode.requestFocus();
    setState(() => _open = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _open) _menu.open();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final clickable = widget.onTap != null || widget.menu != null;
    final lit = clickable && (_hover || _focus || _open);

    Widget content = widget.child;
    if (widget.bevel) {
      content = Container(
        padding: EdgeInsets.symmetric(horizontal: t.space.sm, vertical: t.space.xs),
        decoration: BoxDecoration(
          color: _focus ? t.colors.surfaceHigh : null,
          border: Border(
            top: BorderSide(color: t.colors.bevelDark),
            left: BorderSide(color: t.colors.bevelDark),
            bottom: BorderSide(color: t.colors.bevelLight),
            right: BorderSide(color: t.colors.bevelLight),
          ),
        ),
        child: content,
      );
    } else {
      content = Container(
        height: t.density.statusBar - t.space.xs,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: t.space.sm),
        decoration: BoxDecoration(
          color: lit ? t.colors.surfaceHigh : null,
          borderRadius: BorderRadius.circular(t.radius.control / 2),
          border: _focus ? Border.all(color: t.colors.accent, width: 2) : null,
        ),
        child: content,
      );
    }

    if (clickable) {
      content = FocusableActionDetector(
        focusNode: _focusNode,
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        onShowFocusHighlight: (v) => setState(() => _focus = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => _activate()),
          if (_open) DismissIntent: CallbackAction<DismissIntent>(onInvoke: (_) => _menu.close()),
        },
        child: GestureDetector(onTap: _activate, behavior: HitTestBehavior.opaque, child: content),
      );
    }

    if (widget.tooltip != null) {
      content = Tooltip(message: widget.tooltip!, child: content);
    }

    content = Semantics(
      button: clickable,
      label: widget.label,
      hint: widget.tooltip,
      excludeSemantics: true,
      child: content,
    );

    if (widget.menu == null) return content;
    return MenuAnchor(
      controller: _menu,
      childFocusNode: _focusNode,
      alignmentOffset: Offset(0, t.space.xs),
      onClose: () {
        if (mounted) setState(() => _open = false);
      },
      menuChildren: _open ? widget.menu!(context) : const [],
      child: content,
    );
  }
}

/// A barra de status: campos de texto e, no fim, controles (o zoom).
class StatusBar extends StatelessWidget {
  const StatusBar({super.key, required this.fields, this.trailing = const []});

  final List<StatusField> fields;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final bevel = t.component == ComponentStyle.bevel;
    final fixed = [for (final f in fields) if (!f.flex) f];
    final message = [for (final f in fields) if (f.flex && f.text.isNotEmpty) f].firstOrNull;

    return Container(
      height: t.density.statusBar + t.space.sm,
      padding: EdgeInsets.symmetric(
        horizontal: bevel ? t.space.xs : t.space.md,
        vertical: bevel ? t.space.xs : 0,
      ),
      decoration: BoxDecoration(
        color: t.colors.frame,
        border: Border(
          top: BorderSide(
            color: bevel ? t.colors.border : t.colors.border.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final width = box.maxWidth;
          // Em telas estreitas, filtra campos secundários para garantir que os essenciais
          // (página e contagem de palavras) não sejam truncados nem causem overflow.
          final visibleFixed = [
            for (final f in fixed)
              if (f.priority == 1 || (f.priority == 2 && width >= 750) || (f.priority >= 3 && width >= 980))
                f,
          ];

          return _StatusWidth(
            width: width,
            child: Row(
              children: [
                // Os campos do documento e a mensagem ficam numa fileira que
                // ocupa tudo o que sobra; a vista (memória, disposição, zoom)
                // fica colada à direita. Com os campos flexíveis direto na
                // fileira de fora, a parte deles que não usavam sobrava no fim.
                Expanded(
                  child: Row(
                    children: [
                      // À esquerda, os campos do documento.
                      for (final (i, f) in visibleFixed.indexed) ...[
                        if (i > 0) SizedBox(width: t.space.xs),
                        Flexible(
                          child: _StatusButton(
                            bevel: bevel,
                            label: f.text,
                            onTap: f.onTap,
                            menu: f.menu,
                            tooltip: f.tooltip,
                            child: _text(t, f),
                          ),
                        ),
                      ],
                      // Depois, a mensagem ("Salvo"), só quando existe.
                      if (message != null) ...[
                        SizedBox(width: width >= 1050 ? t.space.lg : t.space.sm),
                        Flexible(
                          flex: 3,
                          child: Semantics(
                            liveRegion: true,
                            child: _StatusButton(bevel: bevel, label: message.text, child: _text(t, message)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing.isNotEmpty) SizedBox(width: width >= 1050 ? t.space.md : t.space.sm),
                ...trailing,
              ],
            ),
          );
        },
      ),
    );
  }

  /// A largura da barra de status (0 fora dela).
  static double widthOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_StatusWidth>()?.width ?? 0;

  static Widget _text(QuillTokens t, StatusField f) => f.icon == null
      ? WLabel(f.text, tone: f.tone, small: true)
      : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(f.icon, size: 16, color: t.colors.onFrameMuted),
            SizedBox(width: t.space.xs),
            Flexible(child: WLabel(f.text, tone: f.tone, small: true)),
          ],
        );
}

/// O zoom da barra de status: −, o controle deslizante, + e a porcentagem.
///
/// Arrastar muda só o número (estado local); o motor recebe o zoom ao
/// soltar. Cada zoom no meio do arrasto pediria ladrilhos novos à toa.
class ZoomControl extends StatefulWidget {
  const ZoomControl({
    super.key,
    required this.zoom,
    required this.min,
    required this.max,
    required this.onZoom,
    required this.label,
    required this.percentLabel,
    required this.zoomIn,
    required this.zoomOut,
    this.menu,
    this.menuTooltip,
  });

  /// 1 = 100 %.
  final double zoom, min, max;
  final ValueChanged<double>? onZoom;
  final String label;
  final String Function(int percent) percentLabel;

  /// Os botões − e + (os comandos, com a dica e o atalho).
  final Widget zoomIn, zoomOut;

  /// O menu da porcentagem: 100 %, ajustar à largura, à página, outros.
  final List<Widget> Function(BuildContext context)? menu;
  final String? menuTooltip;

  @override
  State<ZoomControl> createState() => _ZoomControlState();
}

class _ZoomControlState extends State<ZoomControl> {
  double? _dragging;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final shown = _dragging ?? widget.zoom;
    final percent = (shown * 100).round();
    // Janela estreita: só −, + e porcentagem (o controle deslizante sai abaixo de 1050 px).
    final slider = StatusBar.widthOf(context) >= 1050;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        widget.zoomOut,
        if (slider)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: t.space.xs),
            child: WSlider(
              label: widget.label,
              value: shown * 100,
              min: widget.min * 100,
              max: widget.max * 100,
              divisions: ((widget.max - widget.min) * 20).round(),
              valueLabel: widget.percentLabel(percent),
              width: 110,
              onChanged: widget.onZoom == null ? null : (v) => setState(() => _dragging = v / 100),
              onChangeEnd: widget.onZoom == null
                  ? null
                  : (v) {
                      setState(() => _dragging = null);
                      widget.onZoom!(v / 100);
                    },
            ),
          ),
        widget.zoomIn,
        _StatusButton(
          label: widget.percentLabel(percent),
          tooltip: widget.menuTooltip,
          menu: widget.menu,
          bevel: t.component == ComponentStyle.bevel,
          child: SizedBox(
            width: 44,
            child: Align(alignment: Alignment.centerRight, child: WLabel(widget.percentLabel(percent), small: true)),
          ),
        ),
        SizedBox(width: t.space.xs),
      ],
    );
  }
}

/// O RSS do processo, lido a cada 2 s. Só este rótulo se refaz, e só quando
/// o número muda (antes, o relógio refazia a página inteira).
class MemoryLabel extends StatefulWidget {
  const MemoryLabel({super.key, required this.format});
  final String Function(int mb) format;

  @override
  State<MemoryLabel> createState() => _MemoryLabelState();
}

class _MemoryLabelState extends State<MemoryLabel> {
  late int _mb = ProcessInfo.currentRss >> 20;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      final mb = ProcessInfo.currentRss >> 20;
      if (mb != _mb && mounted) setState(() => _mb = mb);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Symbols.memory_rounded, size: 16, color: QuillTokens.of(context).colors.onFrameMuted),
      WLabel(widget.format(_mb), small: true, tone: WLabelTone.muted),
    ],
  );
}

class _StatusWidth extends InheritedWidget {
  const _StatusWidth({required this.width, required super.child});
  final double width;

  @override
  bool updateShouldNotify(_StatusWidth old) => (old.width >= 1050) != (width >= 1050);
}
