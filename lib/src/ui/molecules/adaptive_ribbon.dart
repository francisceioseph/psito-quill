// A faixa que se adapta à largura (Fase 2B, Etapa 7, D-049), como a do
// Office desde 2007: cada grupo tem tamanhos, do maior ao menor, e a faixa
// escolhe o maior que cabe, encolhendo primeiro os grupos de prioridade
// menor. Um grupo "elástico" (a galeria de estilos) fica com a sobra.
//
// As larguras de cada tamanho são calculadas pelos tokens, não medidas: um
// LayoutBuilder só, sem IntrinsicWidth nem layout duplo, e nenhum tamanho
// que não aparece é construído.
import 'package:flutter/widgets.dart';

import '../tokens/tokens.dart';
import 'ribbon_group.dart';

/// Um tamanho de um grupo: a largura do conteúdo (sem a moldura do grupo) e
/// como desenhá-lo.
class RibbonLevel {
  const RibbonLevel(this.width, this.build);
  final double width;
  final WidgetBuilder build;
}

/// Um grupo da faixa adaptável.
class RibbonGroupSpec {
  const RibbonGroupSpec({required this.title, this.levels = const [], this.priority = 0, this.fill, this.minFill = 0});

  final String title;

  /// Do maior ao menor.
  final List<RibbonLevel> levels;

  /// Os de prioridade menor encolhem primeiro.
  final int priority;

  /// O grupo elástico: recebe a largura que sobrou (pelo menos [minFill]).
  final Widget Function(BuildContext context, double width)? fill;
  final double minFill;

  bool get elastic => fill != null;
}

/// As medidas comuns para calcular as larguras dos tamanhos.
class RibbonMetrics {
  RibbonMetrics(QuillTokens t)
      : button = t.density.control,
        gap = RibbonGroup.gapOf(t),
        big = RibbonGroup.bigWidthOf(t),
        chrome = RibbonGroup.chromeOf(t);

  /// Um botão de ícone, o espaço entre dois, um botão grande e a moldura de
  /// um grupo (as margens e a divisória).
  final double button, gap, big, chrome;

  /// [n] botões de ícone numa linha.
  double row(int n) => n <= 0 ? 0 : n * button + (n - 1) * gap;

  /// Várias peças de larguras conhecidas numa linha.
  double sum(List<double> widths) => widths.isEmpty ? 0 : widths.reduce((a, b) => a + b) + (widths.length - 1) * gap;
}

/// A largura do nome de cada grupo (embaixo dos controles), medida uma vez
/// por nome e tamanho de letra: um grupo nunca fica mais estreito que o nome.
/// O estilo é o do rótulo (`WLabel`) sobre o padrão do tema, que traz o
/// espaçamento entre as letras.
final _titleWidths = <(String, double, String?, double?), double>{};

double ribbonTitleWidth(String title, QuillTokens t, TextStyle base) =>
    _titleWidths.putIfAbsent((title, t.font.small, t.font.family, base.letterSpacing), () {
      final p = TextPainter(
        text: TextSpan(text: title, style: base.merge(TextStyle(fontSize: t.font.small, fontFamily: t.font.family))),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      final w = p.width.ceilToDouble() + 1;
      p.dispose();
      return w;
    });

/// Escolhe o tamanho de cada grupo para caber em [available]. Devolve o
/// índice do tamanho de cada um (0 é o maior; os elásticos ficam em 0).
/// [titles] é a largura do nome de cada grupo (o mínimo de cada um).
List<int> chooseRibbonLevels(List<RibbonGroupSpec> groups, double available, double chrome, [List<double>? titles]) {
  final level = List<int>.filled(groups.length, 0);
  double total() {
    var w = 0.0;
    for (final (i, g) in groups.indexed) {
      final content = g.elastic ? g.minFill : g.levels[level[i]].width;
      final title = titles?[i] ?? 0;
      w += chrome + (content > title ? content : title);
    }
    return w;
  }

  final order = [for (var i = 0; i < groups.length; i++) i]
    ..sort((a, b) {
      final p = groups[a].priority.compareTo(groups[b].priority);
      return p != 0 ? p : b.compareTo(a); // na mesma prioridade, o da direita primeiro
    });
  while (total() > available) {
    final i = order.where((i) => !groups[i].elastic && level[i] < groups[i].levels.length - 1).firstOrNull;
    if (i == null) break;
    level[i]++;
  }
  return level;
}

/// A fileira de grupos. Se nem o menor de cada um couber, rola de lado.
class AdaptiveRibbon extends StatelessWidget {
  const AdaptiveRibbon({super.key, required this.groups});
  final List<RibbonGroupSpec> groups;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final chrome = RibbonGroup.chromeOf(t);
    return LayoutBuilder(builder: (context, box) {
      final available = box.maxWidth;
      final base = DefaultTextStyle.of(context).style;
      final titles = [for (final g in groups) ribbonTitleWidth(g.title, t, base)];
      final level = chooseRibbonLevels(groups, available, chrome, titles);
      double widthOf(int i) {
        final w = groups[i].levels[level[i]].width;
        return w > titles[i] ? w : titles[i];
      }

      var used = 0.0;
      for (final (i, g) in groups.indexed) {
        used += chrome + (g.elastic ? 0 : widthOf(i));
      }
      final elastic = groups.where((g) => g.elastic).length;
      final share = elastic == 0 ? 0.0 : ((available - used) / elastic).floorToDouble();
      final row = IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final (i, g) in groups.indexed)
            RibbonGroup(
              title: g.title,
              last: i == groups.length - 1,
              firstRow: [
                if (g.fill case final fill?)
                  SizedBox(width: share < g.minFill ? g.minFill : share, child: fill(context, share < g.minFill ? g.minFill : share))
                else
                  SizedBox(width: widthOf(i), child: Center(child: g.levels[level[i]].build(context))),
              ],
            ),
        ]),
      );
      final fits = used + (elastic == 0 ? 0 : groups.where((g) => g.elastic).fold(0.0, (a, g) => a + g.minFill)) <= available;
      return fits ? row : SingleChildScrollView(scrollDirection: Axis.horizontal, child: row);
    });
  }
}
