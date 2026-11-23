// Uma fileira de amostras de cor que cabe na largura que tem (D-056): cada
// botão encolhe até 28 px para todas caberem numa linha. Abaixo disso, quebra
// a linha como antes.
import 'package:flutter/material.dart';

import '../atoms/w_color_swatch.dart';
import '../tokens/tokens.dart';

/// Os dados de uma amostra (sem o tamanho, que a fileira escolhe).
typedef SwatchSpec = ({int? rgb, String label, bool selected, VoidCallback? onPressed});

class SwatchRow extends StatelessWidget {
  const SwatchRow({super.key, required this.swatches});

  final List<SwatchSpec> swatches;

  /// O menor botão que ainda dá para acertar com o mouse.
  static const minSize = 28.0;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final gap = t.space.sm;
    return LayoutBuilder(builder: (context, box) {
      final n = swatches.length;
      final fit = n == 0 ? t.density.control : (box.maxWidth - gap * (n - 1)) / n;
      final size = fit.clamp(minSize, t.density.control);
      return Wrap(spacing: gap, runSpacing: gap, children: [
        for (final s in swatches)
          WColorSwatch(rgb: s.rgb, label: s.label, selected: s.selected, onPressed: s.onPressed, size: size),
      ]);
    });
  }
}
