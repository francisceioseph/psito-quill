// O botão de cor da faixa (cor da fonte, realce): o ícone com uma barrinha
// da cor atual embaixo; clicar abre as amostras. A cor é do documento (RGB
// do motor), não do tema.
import 'package:flutter/material.dart';

import '../atoms/w_button.dart';
import '../atoms/w_color_swatch.dart';
import '../tokens/tokens.dart';

const _opaque = 0xFF000000;

class ColorMenuButton extends StatelessWidget {
  const ColorMenuButton({
    super.key,
    required this.icon,
    required this.label,
    required this.current,
    required this.currentName,
    required this.noneLabel,
    required this.choices,
    required this.onSelected,
    this.onClosed,
  });

  final IconData icon;

  /// "Cor da fonte".
  final String label;

  /// O RGB atual; null: automática (ou sem realce).
  final int? current;

  /// O nome da cor atual, para o leitor de tela ("vermelho").
  final String currentName;
  final String noneLabel;

  /// O nome e o RGB de cada amostra.
  final List<(String, int)> choices;

  /// null: desligado (só leitura).
  final ValueChanged<int?>? onSelected;
  final VoidCallback? onClosed;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final c = t.colors;
    final rgb = current;
    return MenuAnchor(
      onClose: onClosed,
      menuChildren: [
        Padding(
          padding: EdgeInsets.all(t.space.sm),
          child: Builder(
            builder: (menuContext) {
              void pick(int? v) {
                onSelected?.call(v);
                MenuController.maybeOf(menuContext)?.close();
              }

              return Row(mainAxisSize: MainAxisSize.min, children: [
                WColorSwatch(rgb: null, label: noneLabel, selected: rgb == null, onPressed: () => pick(null)),
                for (final (name, value) in choices)
                  WColorSwatch(rgb: value, label: name, selected: rgb == value, onPressed: () => pick(value)),
              ]);
            },
          ),
        ),
      ],
      builder: (context, controller, _) => WControlSurface(
        tooltip: label,
        selected: false,
        onPressed: onSelected == null ? null : () => controller.isOpen ? controller.close() : controller.open(),
        semantics: (child) => Semantics(
          container: true,
          button: true,
          enabled: onSelected != null,
          label: label,
          value: currentName,
          child: child,
        ),
        width: t.density.control,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: t.density.icon - 2, color: onSelected == null ? c.onFrame.withValues(alpha: 0.38) : c.onFrameMuted),
          Container(
            width: 16,
            height: 3,
            decoration: BoxDecoration(
              color: rgb == null ? c.onFrameMuted : Color(rgb | _opaque),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ]),
      ),
    );
  }
}
