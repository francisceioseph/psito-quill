// Ocupado sem janelas (Etapa 8, D-066): enquanto o motor abre ou salva, os
// cliques param, o cursor do mouse vira o de espera e um véu leve cobre a
// área de edição. O progresso fica no rodapé, que não é coberto.
//
// A árvore é a mesma com e sem o véu: o filho não é remontado (a página
// guardaria a rolagem e o foco de outro jeito).
import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

class BusyScope extends StatelessWidget {
  const BusyScope({super.key, required this.busy, required this.child});

  final bool busy;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        AbsorbPointer(absorbing: busy, child: child),
        if (busy)
          Positioned.fill(
            child: MouseRegion(
              cursor: SystemMouseCursors.wait,
              opaque: true,
              child: ExcludeSemantics(child: ColoredBox(color: t.colors.frame.withValues(alpha: 0.35))),
            ),
          ),
      ],
    );
  }
}
