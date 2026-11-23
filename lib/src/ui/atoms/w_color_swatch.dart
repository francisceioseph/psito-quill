// Átomo de amostra de cor: um quadrado que escolhe a cor da fonte ou do
// realce. A cor é do documento (RGB do LibreOffice), não do tema; o nome vai
// para o leitor de tela.
import 'package:flutter/material.dart';

import '../tokens/tokens.dart';
import 'w_button.dart';

/// Opaco, para virar Color a partir do RGB do motor.
const _opaque = 0xFF000000;

class WColorSwatch extends StatelessWidget {
  const WColorSwatch({super.key, required this.rgb, required this.label, required this.selected, this.onPressed});

  /// null: a automática (ou sem realce), desenhada com um risco.
  final int? rgb;
  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final rgb = this.rgb;
    return WControlSurface(
      tooltip: label,
      onPressed: onPressed,
      selected: selected,
      semantics: (child) => Semantics(
        container: true,
        button: true,
        selected: selected,
        enabled: onPressed != null,
        label: label,
        child: child,
      ),
      icon: null,
      text: null,
      width: t.density.control,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: rgb == null ? t.colors.paper : Color(rgb | _opaque),
          border: Border.all(color: t.colors.border),
        ),
        child: rgb == null ? Icon(Icons.block, size: 14, color: t.colors.onFrameMuted) : null,
      ),
    );
  }
}
