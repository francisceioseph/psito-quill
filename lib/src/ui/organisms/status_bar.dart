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

  /// Dica de ferramenta para o leitor de tela e mouse.
  final String? tooltip;

  /// Prioridade de exibição em telas estreitas:
  /// 1 = essencial (página, palavras)
  /// 2 = normal (idioma, somente leitura, modificado)
  /// 3 = detalhe (estilo do parágrafo)
  final int priority;
}

class _StatusButton extends StatefulWidget {
  const _StatusButton({
    required this.child,
    this.onTap,
    this.tooltip,
    this.bevel = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool bevel;

  @override
  State<_StatusButton> createState() => _StatusButtonState();
}

class _StatusButtonState extends State<_StatusButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final clickable = widget.onTap != null;

    Widget content = widget.child;
    if (widget.bevel) {
      content = Container(
        padding: EdgeInsets.symmetric(horizontal: t.space.sm, vertical: t.space.xs),
        decoration: BoxDecoration(
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
        padding: EdgeInsets.symmetric(horizontal: t.space.sm, vertical: 2),
        decoration: BoxDecoration(
          color: _hover && clickable ? t.colors.surfaceHigh : null,
          borderRadius: BorderRadius.circular(t.radius.control / 2),
        ),
        child: content,
      );
    }

    if (clickable) {
      content = MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: content,
        ),
      );
    }

    if (widget.tooltip != null) {
      content = Tooltip(
        message: widget.tooltip!,
        child: content,
      );
    }

    return Semantics(
      button: clickable,
      enabled: clickable,
      label: widget.tooltip,
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
                            onTap: f.onTap,
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
                          child: _StatusButton(
                            bevel: bevel,
                            child: Semantics(liveRegion: true, child: _text(t, message)),
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
  });

  /// 1 = 100 %.
  final double zoom, min, max;
  final ValueChanged<double>? onZoom;
  final String label;
  final String Function(int percent) percentLabel;

  /// Os botões − e + (os comandos, com a dica e o atalho).
  final Widget zoomIn, zoomOut;

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
        SizedBox(
          width: 48,
          child: Align(
            alignment: Alignment.centerRight,
            child: ExcludeSemantics(child: WLabel(widget.percentLabel(percent), small: true)),
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
