// WChip: um filtro ou uma ação curta (as seções da lista de fontes, os
// filtros da galeria de estilos). 28 px de altura, contorno fino; ligado,
// fica tonal como os outros controles.
import 'package:flutter/material.dart';

import 'w_button.dart';

class WChip extends StatelessWidget {
  const WChip({super.key, required this.label, this.icon, this.selected = false, this.onPressed});

  final String label;
  final IconData? icon;

  /// Para filtros: o chip ligado. Uma ação simples deixa falso.
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => WControlSurface(
        icon: icon,
        text: label,
        tooltip: null,
        outlined: true,
        height: 28,
        onPressed: onPressed,
        selected: selected,
        semantics: (child) =>
            Semantics(container: true, button: true, selected: selected, enabled: onPressed != null, label: label, child: child),
      );
}
