// WSegmented: botões segmentados, uma escolha entre poucas (as seções do
// painel Formatar, a disposição das páginas, o tipo de tabulação).
//
// Um contorno só, com divisórias; o escolhido fica tonal. Cada segmento
// recebe o foco pelo Tab e diz ao leitor de tela se está escolhido. No
// Clássico 97 (bisel), o escolhido fica afundado.
import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

/// Um segmento: o valor, o rótulo (também o nome para o leitor de tela) e,
/// se houver, o ícone. Com [iconOnly], o rótulo vira só a dica.
class WSegment<T> {
  const WSegment(this.value, this.label, {this.icon, this.iconOnly = false});
  final T value;
  final String label;
  final IconData? icon;
  final bool iconOnly;
}

class WSegmented<T> extends StatelessWidget {
  const WSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    required this.label,
    this.compact = false,
    this.expanded = false,
  });

  /// Mais baixo e estreito, para caber na barra de status.
  final bool compact;

  /// Estica os segmentos para ocupar toda a largura disponível.
  final bool expanded;

  final List<WSegment<T>> segments;
  final T selected;
  final ValueChanged<T>? onChanged;

  /// O nome do grupo para o leitor de tela ("Seção do painel").
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final c = t.colors;
    final modern = t.component == ComponentStyle.modern;
    final h = compact ? t.density.statusBar - t.space.xs : t.density.control;
    final side = BorderSide(color: modern ? c.outline : c.bevelDark);
    return Semantics(
      container: true,
      label: label,
      explicitChildNodes: true,
      child: Container(
        height: h,
        decoration: BoxDecoration(
          border: Border.fromBorderSide(side),
          borderRadius: BorderRadius.circular(modern ? h / 2 : 0),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
          children: [
            for (var i = 0; i < segments.length; i++) ...[
              if (i > 0) Container(width: 1, color: side.color),
              if (expanded)
                Expanded(
                  child: _Segment<T>(
                    compact: compact,
                    segment: segments[i],
                    selected: segments[i].value == selected,
                    onPressed: onChanged == null ? null : () => onChanged!(segments[i].value),
                  ),
                )
              else
                Flexible(
                  child: _Segment<T>(
                    compact: compact,
                    segment: segments[i],
                    selected: segments[i].value == selected,
                    onPressed: onChanged == null ? null : () => onChanged!(segments[i].value),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Segment<T> extends StatefulWidget {
  const _Segment({required this.segment, required this.selected, required this.onPressed, this.compact = false});
  final WSegment<T> segment;
  final bool compact;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  State<_Segment<T>> createState() => _SegmentState<T>();
}

class _SegmentState<T> extends State<_Segment<T>> {
  bool _hover = false, _focused = false;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final c = t.colors;
    final s = widget.segment;
    final modern = t.component == ComponentStyle.modern;
    final enabled = widget.onPressed != null;
    final fg = !enabled
        ? c.onFrame.withValues(alpha: 0.38)
        : widget.selected && modern
            ? c.onAccentSoft
            : c.onFrame;
    final bg = widget.selected
        ? (modern ? c.accentSoft : c.surfaceHighest)
        : _hover
            ? c.surfaceHigh
            : null;
    final showText = !s.iconOnly || s.icon == null;
    final child = Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
      if (s.icon case final icon?)
        Icon(icon, size: t.density.icon - 2, color: fg, fill: widget.selected && modern ? 1 : 0),
      if (s.icon != null && showText) SizedBox(width: t.space.sm),
      if (showText)
        Flexible(
          child: Text(s.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: fg, fontSize: t.font.small, fontWeight: FontWeight.w500, fontFamily: t.font.family)),
        ),
    ]);
    final body = FocusableActionDetector(
      enabled: enabled,
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
        onTap: widget.onPressed,
        child: Container(
          constraints: BoxConstraints(minWidth: widget.compact ? t.density.control : t.density.control + t.space.md),
          padding: EdgeInsets.symmetric(horizontal: widget.compact ? t.space.sm : t.space.lg),
          decoration: BoxDecoration(
            color: bg,
            border: _focused ? Border.all(color: c.focusRing, width: 2) : null,
          ),
          child: Center(widthFactor: 1, child: ExcludeSemantics(child: child)),
        ),
      ),
    );
    return Semantics(
      container: true,
      button: true,
      inMutuallyExclusiveGroup: true,
      selected: widget.selected,
      enabled: enabled,
      label: s.label,
      child: s.iconOnly ? Tooltip(message: s.label, waitDuration: const Duration(milliseconds: 600), child: body) : body,
    );
  }
}
