// As réguas (Fase 2B, Etapa 4, D-046): a horizontal, em cima da página, e a
// vertical, à esquerda.
//
// A horizontal mostra as margens da página (em cinza), a medida com o zero
// na margem esquerda, os recuos (primeira linha, esquerdo e direito) e as
// tabulações do parágrafo do cursor. Os recuos se arrastam (com a linha
// tracejada na página e a medida) e também andam pelo teclado: cada marca
// recebe o foco pelo Tab, e as setas andam 1 mm (Shift: 1 cm).
//
// Memória e redesenho: cada régua é um CustomPaint que se repinta com a
// rolagem e o zoom (o DocViewport) e com os dados do parágrafo, e nada se
// reconstrói com a rolagem vertical. As marcas focáveis só se refazem quando
// a posição horizontal muda (zoom, rolagem para os lados, outro parágrafo).
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../kit/quill_kit.dart' show RulerInfo;
import '../molecules/measure_field.dart' show formatCm;
import '../tokens/tokens.dart';
import 'document_view.dart' show DocViewport;

/// A unidade da régua (Exibir › Régua, nas preferências).
enum RulerUnit { cm, mm, inch, pt }

/// As marcas que se arrastam.
enum RulerMark { firstLine, left, right }

/// O que a régua horizontal mostra, sem a posição na tela.
@immutable
class RulerData {
  const RulerData({required this.info, required this.leftCm, required this.firstLineCm, required this.rightCm});

  final RulerInfo info;

  /// Os recuos do parágrafo, em cm. A primeira linha é relativa ao esquerdo.
  final double leftCm, firstLineCm, rightCm;

  @override
  bool operator ==(Object other) =>
      other is RulerData &&
      other.info == info &&
      other.leftCm == leftCm &&
      other.firstLineCm == firstLineCm &&
      other.rightCm == rightCm;

  @override
  int get hashCode => Object.hash(info, leftCm, firstLineCm, rightCm);
}

/// O tamanho de uma régua (a horizontal é desta altura; a vertical, desta
/// largura).
const double rulerThickness = 24;

/// Os twips de um centésimo de milímetro.
const double _twipsPerMm100 = 1440 / 2540;

/// Meia largura das marcas dos recuos (14 px; a área de clique, 20).
const double _markHalfWidth = 7;

/// O vão em volta das páginas, em 1/100 mm (os 284 twips).
const double _gapMm100 = pageGapTwips / _twipsPerMm100;

/// A geometria da régua horizontal numa posição de tela: tudo em pixels da
/// área da página.
@immutable
class HRulerGeometry {
  const HRulerGeometry(this.view, this.data);
  final DocViewport view;
  final RulerData data;

  double get pxPerMm100 => view.pxPerTwip * _twipsPerMm100;
  double get pxPerCm => pxPerMm100 * 1000;
  /// A página do cursor, pelo `pageOffset` do motor, que é onde ela começa
  /// no documento (sondado na 24.2): com uma página por linha, o vão (501);
  /// no modo Livro, com a primeira página sozinha à direita, o vão mais uma
  /// página (21502), porque as duas de um par se encostam.
  double get pageLeft => view.left + (data.info.pageOffset ?? _gapMm100) * pxPerMm100;
  double get pageRight => pageLeft + data.info.pageWidth * pxPerMm100;
  double get marginLeft => pageLeft + data.info.leftMargin * pxPerMm100;
  double get marginRight => marginLeft + data.info.textWidth * pxPerMm100;

  double xOf(RulerMark m) => switch (m) {
        RulerMark.left => marginLeft + data.leftCm * pxPerCm,
        RulerMark.firstLine => marginLeft + (data.leftCm + data.firstLineCm) * pxPerCm,
        RulerMark.right => marginRight - data.rightCm * pxPerCm,
      };

  /// A posição [x] em cm da margem esquerda (o zero da régua).
  double cmAt(double x) => (x - marginLeft) / pxPerCm;
}

/// Os recuos novos depois de arrastar [mark] até [cm] (da margem esquerda;
/// para o direito, da margem direita). Arrastar o esquerdo leva a primeira
/// linha junto, como no Word: ela fica onde estava na página.
({double? left, double? firstLine, double? right}) indentsAfterDrag(RulerData d, RulerMark mark, double cm) =>
    switch (mark) {
      RulerMark.left => (left: cm, firstLine: d.firstLineCm + d.leftCm - cm, right: null),
      RulerMark.firstLine => (left: null, firstLine: cm - d.leftCm, right: null),
      RulerMark.right => (left: null, firstLine: null, right: cm),
    };

/// Arredonda para o milímetro (a régua "gruda" de 1 em 1 mm).
double snapCm(double cm) => (cm * 10).roundToDouble() / 10;

/// Os números da régua, já medidos, um por texto. Medir um número cria um
/// parágrafo nativo (memória do malloc): fazer isso a cada quadro da rolagem
/// fazia o heap crescer uns 14 MB (D-046). Assim cada número é medido uma vez
/// só e reaproveitado; o cache é da régua e se desfaz com ela.
class RulerLabels {
  RulerLabels();

  final _cache = <String, TextPainter>{};
  Color? _color;

  /// O número [text] medido, na cor [color] (trocar a cor limpa o cache).
  TextPainter get(String text, Color color) {
    if (color != _color) {
      clear();
      _color = color;
    }
    return _cache[text] ??= TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 9)),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  int get length => _cache.length;

  void clear() {
    for (final p in _cache.values) {
      p.dispose();
    }
    _cache.clear();
  }
}

/// A régua horizontal com o canto (à esquerda, onde a vertical começa).
class HorizontalRuler extends StatefulWidget {
  const HorizontalRuler({
    super.key,
    required this.viewport,
    required this.data,
    required this.unit,
    required this.onIndents,
    this.onDoubleTap,
    this.guide,
  });

  final ValueListenable<DocViewport?> viewport;

  /// null: sem documento ou sem a régua do motor ainda.
  final RulerData? data;
  final RulerUnit unit;

  /// Os recuos novos, em cm (os que não mudaram vêm null).
  final void Function({double? left, double? firstLine, double? right})? onIndents;

  /// Duplo clique: o painel Formatar na seção Parágrafo.
  final VoidCallback? onDoubleTap;

  /// Onde desenhar a linha tracejada sobre a página enquanto arrasta (x na
  /// área da página; null: nenhuma).
  final ValueNotifier<double?>? guide;

  @override
  State<HorizontalRuler> createState() => _HorizontalRulerState();
}

class _HorizontalRulerState extends State<HorizontalRuler> {
  /// A marca sendo arrastada e onde ela está agora (x em pixels).
  final _drag = ValueNotifier<(RulerMark, double)?>(null);
  final _focused = ValueNotifier<RulerMark?>(null);

  /// Só a parte horizontal do viewport: as marcas focáveis não se refazem
  /// com a rolagem vertical.
  final _horizontal = ValueNotifier<DocViewport?>(null);
  final _labels = RulerLabels();

  @override
  void initState() {
    super.initState();
    widget.viewport.addListener(_onViewport);
    _onViewport();
  }

  @override
  void didUpdateWidget(HorizontalRuler old) {
    super.didUpdateWidget(old);
    if (old.viewport != widget.viewport) {
      old.viewport.removeListener(_onViewport);
      widget.viewport.addListener(_onViewport);
      _onViewport();
    }
  }

  void _onViewport() {
    final v = widget.viewport.value;
    final h = _horizontal.value;
    if (v == null) {
      _horizontal.value = null;
    } else if (h == null || h.left != v.left || h.pxPerTwip != v.pxPerTwip) {
      _horizontal.value = DocViewport(left: v.left, top: 0, pxPerTwip: v.pxPerTwip, viewSize: v.viewSize);
    }
  }

  @override
  void dispose() {
    widget.viewport.removeListener(_onViewport);
    _drag.dispose();
    _focused.dispose();
    _horizontal.dispose();
    _labels.clear();
    super.dispose();
  }

  HRulerGeometry? get _geometry {
    final v = widget.viewport.value, d = widget.data;
    return v == null || d == null ? null : HRulerGeometry(v, d);
  }

  RulerMark? _hit(Offset p, HRulerGeometry g) {
    // A primeira linha fica em cima; o esquerdo e o direito, embaixo.
    final top = p.dy < rulerThickness / 2;
    RulerMark? best;
    var bestD = _markHalfWidth + 3;
    for (final m in RulerMark.values) {
      if (m == RulerMark.firstLine && !top) continue;
      if (m != RulerMark.firstLine && top && (g.xOf(RulerMark.firstLine) - p.dx).abs() < _markHalfWidth + 3) continue;
      final d = (g.xOf(m) - p.dx).abs();
      if (d < bestD) {
        bestD = d;
        best = m;
      }
    }
    return best;
  }

  void _commit(RulerMark mark, double x, HRulerGeometry g) {
    final raw = mark == RulerMark.right ? (g.marginRight - x) / g.pxPerCm : g.cmAt(x);
    final i = indentsAfterDrag(g.data, mark, snapCm(raw));
    widget.onIndents?.call(left: i.left, firstLine: i.firstLine, right: i.right);
  }

  /// O teclado numa marca: as setas andam 1 mm; com Shift, 1 cm.
  KeyEventResult _onKey(RulerMark mark, KeyEvent e) {
    if (e is KeyUpEvent || widget.onIndents == null) return KeyEventResult.ignored;
    final d = widget.data;
    if (d == null) return KeyEventResult.ignored;
    final step = HardwareKeyboard.instance.isShiftPressed ? 1.0 : 0.1;
    final sign = switch (e.logicalKey) {
      LogicalKeyboardKey.arrowRight => 1,
      LogicalKeyboardKey.arrowLeft => -1,
      _ => 0,
    };
    if (sign == 0) return KeyEventResult.ignored;
    _nudge(mark, sign * step);
    return KeyEventResult.handled;
  }

  void _nudge(RulerMark mark, double deltaCm) {
    final d = widget.data!;
    // O direito anda ao contrário: o valor é da margem direita para dentro.
    final now = switch (mark) {
      RulerMark.left => d.leftCm,
      RulerMark.firstLine => d.leftCm + d.firstLineCm,
      RulerMark.right => d.rightCm,
    };
    final next = snapCm(now + (mark == RulerMark.right ? -deltaCm : deltaCm));
    final i = indentsAfterDrag(d, mark, next);
    widget.onIndents?.call(left: i.left, firstLine: i.firstLine, right: i.right);
  }

  String _markName(AppLocalizations l10n, RulerMark m) => switch (m) {
        RulerMark.firstLine => l10n.rulerFirstLine,
        RulerMark.left => l10n.rulerLeftIndent,
        RulerMark.right => l10n.rulerRightIndent,
      };

  double _markValue(RulerMark m) {
    final d = widget.data!;
    return switch (m) {
      RulerMark.left => d.leftCm,
      RulerMark.firstLine => d.firstLineCm,
      RulerMark.right => d.rightCm,
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final editable = widget.onIndents != null;
    // A régua horizontal só depende da parte horizontal: a rolagem vertical
    // não a repinta (só a vertical).
    final painter = _HRulerPainter(
      viewport: _horizontal,
      data: widget.data,
      unit: widget.unit,
      drag: _drag,
      focused: _focused,
      colors: t.colors,
      modern: t.component == ComponentStyle.modern,
      unitLabel: l10n.unitCm,
      locale: locale,
      labels: _labels,
    );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: l10n.rulerHorizontal,
      child: SizedBox(
        height: rulerThickness,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          // A marca é a de onde o dedo desceu, não a de depois da folga.
          dragStartBehavior: DragStartBehavior.down,
          onDoubleTap: widget.onDoubleTap,
          onHorizontalDragStart: editable
              ? (e) {
                  final g = _geometry;
                  if (g == null) return;
                  final m = _hit(e.localPosition, g);
                  if (m == null) return;
                  _drag.value = (m, g.xOf(m));
                  widget.guide?.value = g.xOf(m);
                }
              : null,
          onHorizontalDragUpdate: editable
              ? (e) {
                  final d = _drag.value;
                  if (d == null) return;
                  _drag.value = (d.$1, e.localPosition.dx);
                  widget.guide?.value = e.localPosition.dx;
                }
              : null,
          onHorizontalDragEnd: editable
              ? (_) {
                  final d = _drag.value, g = _geometry;
                  _drag.value = null;
                  widget.guide?.value = null;
                  if (d != null && g != null) _commit(d.$1, d.$2, g);
                }
              : null,
          onHorizontalDragCancel: () {
            _drag.value = null;
            widget.guide?.value = null;
          },
          child: CustomPaint(
            painter: painter,
            child: widget.data == null
                ? const SizedBox.expand()
                // As marcas focáveis (o teclado e o leitor de tela), por cima
                // do desenho, sem desenho próprio.
                : ValueListenableBuilder<DocViewport?>(
                    valueListenable: _horizontal,
                    builder: (context, view, _) {
                      if (view == null) return const SizedBox.expand();
                      final g = HRulerGeometry(view, widget.data!);
                      return Stack(clipBehavior: Clip.none, children: [
                        for (final m in RulerMark.values)
                          Positioned(
                            left: g.xOf(m) - 6,
                            top: m == RulerMark.firstLine ? 0 : rulerThickness / 2,
                            width: 12,
                            height: rulerThickness / 2,
                            child: Semantics(
                              label: _markName(l10n, m),
                              // Aumentar e diminuir mexem no valor do recuo (o
                              // direito anda para a esquerda ao aumentar).
                              value: l10n.measureCm(formatCm(_markValue(m), locale)),
                              increasedValue: l10n.measureCm(formatCm(snapCm(_markValue(m) + 0.1), locale)),
                              decreasedValue: l10n.measureCm(formatCm(snapCm(_markValue(m) - 0.1), locale)),
                              onIncrease: editable ? () => _nudge(m, m == RulerMark.right ? -0.1 : 0.1) : null,
                              onDecrease: editable ? () => _nudge(m, m == RulerMark.right ? 0.1 : -0.1) : null,
                              child: Focus(
                                canRequestFocus: editable,
                                onFocusChange: (f) => _focused.value = f ? m : (_focused.value == m ? null : _focused.value),
                                onKeyEvent: (_, e) => _onKey(m, e),
                                child: const SizedBox.expand(),
                              ),
                            ),
                          ),
                      ]);
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class _HRulerPainter extends CustomPainter {
  _HRulerPainter({
    required this.viewport,
    required this.data,
    required this.unit,
    required this.drag,
    required this.focused,
    required this.colors,
    required this.modern,
    required this.unitLabel,
    required this.locale,
    required this.labels,
  }) : super(repaint: Listenable.merge([viewport, drag, focused]));

  final RulerLabels labels;

  final ValueListenable<DocViewport?> viewport;
  final RulerData? data;
  final RulerUnit unit;
  final ValueListenable<(RulerMark, double)?> drag;
  final ValueListenable<RulerMark?> focused;
  final QuillColors colors;
  final bool modern;
  final String unitLabel, locale;

  @override
  void paint(Canvas canvas, Size size) {
    final c = colors;
    canvas.drawRect(Offset.zero & size, Paint()..color = c.frame);
    final v = viewport.value, d = data;
    if (v == null || d == null) return;
    final g = HRulerGeometry(v, d);
    final band = Rect.fromLTRB(g.pageLeft, 3, g.pageRight, size.height - 3);
    // As margens em cinza, o texto em branco.
    canvas.drawRect(band, Paint()..color = c.surfaceHigh);
    canvas.drawRect(Rect.fromLTRB(g.marginLeft, band.top, g.marginRight, band.bottom), Paint()..color = c.surfaceLowest);
    canvas.drawRect(band, Paint()
      ..color = c.border
      ..style = PaintingStyle.stroke);

    _ticks(canvas, g, band);
    _tabs(canvas, g, band);

    final dragging = drag.value;
    for (final m in RulerMark.values) {
      final x = dragging != null && dragging.$1 == m ? dragging.$2 : g.xOf(m);
      _mark(canvas, m, x, band, active: dragging?.$1 == m || focused.value == m);
    }
    if (dragging != null) {
      final cm = dragging.$1 == RulerMark.right ? (g.marginRight - dragging.$2) / g.pxPerCm : g.cmAt(dragging.$2);
      _label(canvas, '${formatCm(snapCm(cm), locale)} $unitLabel', Offset(dragging.$2 + 8, 0), size);
    }
  }

  /// O passo maior (com número) em cm, e quantas divisões ele tem.
  (double, int, double Function(double)) get _scale => switch (unit) {
        RulerUnit.cm => (1, 4, (cm) => cm),
        RulerUnit.mm => (1, 4, (cm) => cm * 10),
        RulerUnit.inch => (2.54, 8, (cm) => cm / 2.54),
        RulerUnit.pt => (2.54, 8, (cm) => cm / 2.54 * 72),
      };

  void _ticks(Canvas canvas, HRulerGeometry g, Rect band) {
    final (majorCm, divisions, label) = _scale;
    final majorPx = majorCm * g.pxPerCm;
    if (majorPx < 8) return;
    // Num zoom pequeno, menos divisões.
    final div = majorPx / divisions >= 5 ? divisions : (majorPx / 2 >= 5 ? 2 : 1);
    final step = majorPx / div;
    final ink = Paint()
      ..color = colors.onFrameMuted
      ..strokeWidth = 1;
    final mid = band.center.dy;
    final first = ((g.pageLeft - g.marginLeft) / step).ceil();
    final last = ((g.pageRight - g.marginLeft) / step).floor();
    // Números um sim, um não, se não couberem.
    final every = majorPx < 26 ? 2 : 1;
    for (var i = first; i <= last; i++) {
      final x = g.marginLeft + i * step;
      if (i % div == 0) {
        final n = (i ~/ div).abs();
        if (n != 0 && n % every == 0) {
          final value = label(n * majorCm);
          final text = value == value.roundToDouble() ? value.round().toString() : value.toStringAsFixed(1);
          _number(canvas, text, Offset(x, mid));
        } else if (n == 0) {
          canvas.drawLine(Offset(x, band.top + 2), Offset(x, band.bottom - 2), ink);
        }
      } else {
        final h = div >= 4 && i % (div ~/ 2) == 0 ? 4.0 : 2.0;
        canvas.drawLine(Offset(x, mid - h), Offset(x, mid + h), ink);
      }
    }
  }

  void _tabs(Canvas canvas, HRulerGeometry g, Rect band) {
    final ink = Paint()
      ..color = colors.onFrameMuted
      ..strokeWidth = 1;
    for (final tab in g.data.info.tabs) {
      final x = g.marginLeft + tab.position * g.pxPerMm100;
      if (x < g.marginLeft || x > g.marginRight) continue;
      // As padrão (tipo 4 na 24.2) são só um tracinho embaixo.
      canvas.drawLine(Offset(x, band.bottom - 3), Offset(x, band.bottom), ink);
      if (tab.style != 4) canvas.drawLine(Offset(x, band.bottom), Offset(x + 4, band.bottom), ink..strokeWidth = 1.5);
    }
  }

  /// As marcas dos recuos, no desenho do Office (D-060): a ampulheta (a
  /// primeira linha em cima; o recuo esquerdo embaixo, com a caixinha que
  /// arrasta os dois) e o triângulo do direito. Com contorno e cantos
  /// suaves, inteiras dentro da régua; na cor de destaque com o foco ou
  /// arrastando.
  void _mark(Canvas canvas, RulerMark m, double x, Rect band, {required bool active}) {
    const w = _markHalfWidth;
    final top = band.top - 2, bottom = band.bottom + 2;
    final path = Path();
    switch (m) {
      case RulerMark.firstLine:
        path
          ..moveTo(x - w, top)
          ..lineTo(x + w, top)
          ..lineTo(x, top + 8)
          ..close();
      case RulerMark.left:
        path
          ..moveTo(x, bottom - 11)
          ..lineTo(x + w, bottom - 5)
          ..lineTo(x - w, bottom - 5)
          ..close()
          ..addRect(Rect.fromLTRB(x - w, bottom - 5, x + w, bottom));
      case RulerMark.right:
        path
          ..moveTo(x, bottom - 8)
          ..lineTo(x + w, bottom)
          ..lineTo(x - w, bottom)
          ..close();
    }
    canvas.drawPath(path, Paint()..color = active ? colors.accentContainer : colors.surfaceLowest);
    canvas.drawPath(
      path,
      Paint()
        ..color = active ? colors.accent : colors.onFrameMuted
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..strokeJoin = modern ? StrokeJoin.round : StrokeJoin.miter,
    );
  }

  void _number(Canvas canvas, String text, Offset center) {
    final tp = labels.get(text, colors.onFrameMuted);
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _label(Canvas canvas, String text, Offset at, Size size) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: colors.onAccent, fontSize: 10, fontWeight: FontWeight.w500)),
      textDirection: TextDirection.ltr,
    )..layout();
    final r = Rect.fromLTWH(math.min(at.dx, size.width - tp.width - 8), 2, tp.width + 8, size.height - 4);
    canvas.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(modern ? 4 : 0)), Paint()..color = colors.accent);
    tp.paint(canvas, Offset(r.left + 4, r.center.dy - tp.height / 2));
    tp.dispose();
  }

  @override
  bool shouldRepaint(_HRulerPainter old) =>
      old.data != data || old.unit != unit || old.colors != colors || old.viewport != viewport;
}

/// A régua vertical: as margens de cima e de baixo de cada página visível,
/// com a medida a partir da margem de cima. Só mostra (as margens mudam pelo
/// painel Formatar ou pela faixa Layout).
class VerticalRuler extends StatefulWidget {
  const VerticalRuler({super.key, required this.viewport, required this.pages, this.margins});

  final ValueListenable<DocViewport?> viewport;

  /// O tamanho de cada página em twips e quantas são (a pilha de páginas do
  /// motor, com 284 twips entre elas).
  final ({Size page, int count})? pages;

  /// Em cima e embaixo, em cm (da cópia temporária); null: só a página.
  final ({double top, double bottom})? margins;

  @override
  State<VerticalRuler> createState() => _VerticalRulerState();
}

class _VerticalRulerState extends State<VerticalRuler> {
  final _labels = RulerLabels();

  @override
  void dispose() {
    _labels.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    // Um nó próprio: sem o container, o nome subia e se juntava ao da
    // janela (o teste do rodapé da Etapa 8 mostrou).
    return Semantics(
      container: true,
      label: AppLocalizations.of(context).rulerVertical,
      child: SizedBox(
        width: rulerThickness,
        child: CustomPaint(
          painter: _VRulerPainter(
            viewport: widget.viewport,
            pages: widget.pages,
            margins: widget.margins,
            colors: t.colors,
            labels: _labels,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// Os twips entre as páginas (e em volta delas) na pilha do motor (D-036).
const double pageGapTwips = 284;

/// Quantas fileiras de páginas o motor empilha: com uma coluna, uma por
/// página; com várias, [columns] por fileira; no modo Livro, a primeira
/// sozinha e depois os pares.
int pageRows(int pages, {int columns = 1, bool book = false}) {
  if (pages <= 0) return 0;
  if (book) return pages ~/ 2 + 1;
  return (pages + columns - 1) ~/ math.max(1, columns);
}

class _VRulerPainter extends CustomPainter {
  _VRulerPainter({required this.viewport, required this.pages, required this.margins, required this.colors, required this.labels})
      : super(repaint: viewport);

  final RulerLabels labels;

  final ValueListenable<DocViewport?> viewport;
  final ({Size page, int count})? pages;
  final ({double top, double bottom})? margins;
  final QuillColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = colors.frame);
    final v = viewport.value, p = pages;
    if (v == null || p == null || p.count <= 0) return;
    final s = v.pxPerTwip;
    final pageH = p.page.height * s;
    final ink = Paint()..color = colors.onFrameMuted;
    final cm = 1440 / 2.54 * s;
    for (var i = 0; i < p.count; i++) {
      final top = v.top + (pageGapTwips + i * (p.page.height + pageGapTwips)) * s;
      if (top > size.height) break;
      if (top + pageH < 0) continue;
      final band = Rect.fromLTRB(3, top, size.width - 3, top + pageH);
      canvas.drawRect(band, Paint()..color = colors.surfaceHigh);
      final m = margins;
      final textTop = m == null ? top : top + m.top * cm;
      final textBottom = m == null ? top + pageH : top + pageH - m.bottom * cm;
      canvas.drawRect(Rect.fromLTRB(band.left, textTop, band.right, textBottom), Paint()..color = colors.surfaceLowest);
      if (cm < 8) continue;
      for (var k = 1; textTop + k * cm < textBottom; k++) {
        final y = textTop + k * cm;
        if (y < -10 || y > size.height + 10) continue;
        final tp = labels.get('$k', colors.onFrameMuted);
        tp.paint(canvas, Offset(size.width / 2 - tp.width / 2, y - tp.height / 2));
        if (cm >= 20) canvas.drawLine(Offset(size.width / 2 - 2, y - cm / 2), Offset(size.width / 2 + 2, y - cm / 2), ink);
      }
    }
  }

  @override
  bool shouldRepaint(_VRulerPainter old) =>
      old.pages != pages || old.margins != margins || old.colors != colors || old.viewport != viewport;
}

/// A página com as réguas: em cima a horizontal (com o canto), à esquerda a
/// vertical, e a linha tracejada por cima da página enquanto um recuo se
/// arrasta.
class RulerFrame extends StatefulWidget {
  const RulerFrame({
    super.key,
    required this.viewport,
    required this.child,
    required this.data,
    required this.unit,
    required this.pages,
    this.margins,
    this.onIndents,
    this.onDoubleTap,
  });

  final ValueListenable<DocViewport?> viewport;
  final Widget child;
  final RulerData? data;
  final RulerUnit unit;
  final ({Size page, int count})? pages;
  final ({double top, double bottom})? margins;
  final void Function({double? left, double? firstLine, double? right})? onIndents;
  final VoidCallback? onDoubleTap;

  @override
  State<RulerFrame> createState() => _RulerFrameState();
}

class _RulerFrameState extends State<RulerFrame> {
  final _guide = ValueNotifier<double?>(null);

  @override
  void dispose() {
    _guide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        SizedBox(width: rulerThickness, height: rulerThickness, child: ColoredBox(color: t.colors.frame)),
        Expanded(
          child: HorizontalRuler(
            viewport: widget.viewport,
            data: widget.data,
            unit: widget.unit,
            onIndents: widget.onIndents,
            onDoubleTap: widget.onDoubleTap,
            guide: _guide,
          ),
        ),
      ]),
      Expanded(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          VerticalRuler(viewport: widget.viewport, pages: widget.pages, margins: widget.margins),
          Expanded(
            child: Stack(fit: StackFit.expand, children: [
              widget.child,
              IgnorePointer(child: CustomPaint(painter: _GuidePainter(_guide, t.colors.accent))),
            ]),
          ),
        ]),
      ),
    ]);
  }
}

/// A linha tracejada sobre a página, onde o recuo vai ficar.
class _GuidePainter extends CustomPainter {
  _GuidePainter(this.guide, this.color) : super(repaint: guide);
  final ValueListenable<double?> guide;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final x = guide.value;
    if (x == null) return;
    final p = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var y = 0.0; y < size.height; y += 8) {
      canvas.drawLine(Offset(x, y), Offset(x, math.min(y + 4, size.height)), p);
    }
  }

  @override
  bool shouldRepaint(_GuidePainter old) => old.color != color || old.guide != guide;
}
