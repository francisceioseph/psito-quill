// O gráfico das metas (Fase 3, Etapa 9, D-083): as palavras de cada um dos
// últimos dias, em barras, com a linha da meta do dia. Um CustomPainter, sem
// pacote de gráficos; o leitor de tela ouve o total e o melhor dia.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

class GoalsChart extends StatelessWidget {
  const GoalsChart({super.key, required this.days, this.goal, required this.semanticLabel, this.height = 96});

  /// As palavras por dia, o mais antigo primeiro (o último é hoje).
  final List<int> days;

  /// A meta do dia (a linha); null sem meta.
  final int? goal;
  final String semanticLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = QuillTokens.of(context).colors;
    return Semantics(
      label: semanticLabel,
      image: true,
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _ChartPainter(
              days: days,
              goal: goal,
              bar: c.accent,
              met: c.tertiary,
              today: c.accentContainer,
              line: c.outline,
              base: c.border,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.days,
    required this.goal,
    required this.bar,
    required this.met,
    required this.today,
    required this.line,
    required this.base,
  });

  final List<int> days;
  final int? goal;
  final Color bar, met, today, line, base;

  @override
  void paint(Canvas canvas, Size size) {
    if (days.isEmpty) return;
    final top = math.max(days.fold(0, math.max), goal ?? 0);
    final slot = size.width / days.length;
    final gap = math.min(2.0, slot * 0.25);
    final paint = Paint();
    if (top > 0) {
      for (var i = 0; i < days.length; i++) {
        final v = days[i];
        if (v <= 0) continue;
        final h = size.height * v / top;
        final isToday = i == days.length - 1;
        paint.color = goal != null && v >= goal! ? met : (isToday ? today : bar);
        canvas.drawRect(Rect.fromLTWH(i * slot + gap / 2, size.height - h, slot - gap, h), paint);
        if (isToday && paint.color == today) {
          // Hoje ainda está em andamento: o contorno da barra na cor das outras.
          canvas.drawRect(
            Rect.fromLTWH(i * slot + gap / 2, size.height - h, slot - gap, h).deflate(0.5),
            Paint()
              ..color = bar
              ..style = PaintingStyle.stroke,
          );
        }
      }
    }
    // A linha de base e a da meta, tracejada.
    canvas.drawLine(Offset(0, size.height - 0.5), Offset(size.width, size.height - 0.5), Paint()..color = base);
    if (goal != null && top > 0) {
      final y = size.height - size.height * goal! / top + 0.5;
      final dash = Paint()
        ..color = line
        ..strokeWidth = 1;
      for (var x = 0.0; x < size.width; x += 6) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + 3, size.width), y), dash);
      }
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      goal != old.goal ||
      bar != old.bar ||
      met != old.met ||
      today != old.today ||
      line != old.line ||
      base != old.base ||
      !_same(days, old.days);

  static bool _same(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
