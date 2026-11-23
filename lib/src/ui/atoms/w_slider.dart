// WSlider: um valor num intervalo (o zoom na barra de status, o tamanho do
// texto da interface). É o Slider do Flutter, que já traz o teclado (setas)
// e o leitor de tela, com as cores e a altura dos tokens.
import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

class WSlider extends StatelessWidget {
  const WSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.label,
    this.divisions,
    this.valueLabel,
    this.onChanged,
    this.onChangeEnd,
    this.width = 120,
  });

  final double value, min, max;
  final int? divisions;

  /// O nome para o leitor de tela ("Zoom").
  final String label;

  /// O valor falado e na bolha ("150 %").
  final String? valueLabel;
  final ValueChanged<double>? onChanged;

  /// Ao soltar: o que é caro (o zoom do motor) vai aqui, não a cada passo.
  final ValueChanged<double>? onChangeEnd;
  final double width;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final c = t.colors;
    final modern = t.component == ComponentStyle.modern;
    // Um nó só, com o nome e o valor do controle deslizante (sem o
    // container, o nome subia para o nó de cima).
    return MergeSemantics(
      child: Semantics(
        label: label,
        child: SizedBox(
          width: width,
          height: t.density.control,
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: modern ? 4 : 2,
              activeTrackColor: modern ? c.accent : c.onFrame,
              inactiveTrackColor: modern ? c.accentSoft : c.bevelDark,
              thumbColor: modern ? c.accent : c.frameRaised,
              overlayColor: c.accent.withValues(alpha: 0.12),
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: modern ? 7 : 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              valueIndicatorColor: c.onFrame,
              valueIndicatorTextStyle: TextStyle(color: c.frame, fontSize: t.font.small, fontFamily: t.font.family),
              showValueIndicator: ShowValueIndicator.onDrag,
              // Sem marcas: o Material 3 de 2024 tira os pontinhos das divisões.
              tickMarkShape: SliderTickMarkShape.noTickMark,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              label: valueLabel,
              semanticFormatterCallback: valueLabel == null ? null : (_) => valueLabel!,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
        ),
      ),
    );
  }
}
