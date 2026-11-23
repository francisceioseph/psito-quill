// Átomo de lista: um campo que abre um menu (estilo, fonte, tamanho).
//
// O menu é o MenuAnchor do Flutter (teclado e leitor de tela de graça), com
// as cores dos tokens.
import 'package:flutter/material.dart';

import '../tokens/tokens.dart';
import 'w_button.dart';

class WDropdownItem<T> {
  const WDropdownItem(this.value, this.label);
  final T value;
  final String label;
}

class WDropdown<T> extends StatelessWidget {
  const WDropdown({
    super.key,
    required this.label,
    required this.text,
    required this.items,
    required this.onSelected,
    this.width = 160,
    this.onClosed,
  });

  /// Nome para o leitor de tela e a dica ("Fonte").
  final String label;

  /// O que o campo mostra agora (o valor atual, vindo do motor).
  final String text;
  final List<WDropdownItem<T>> items;

  /// null: desabilitado.
  final ValueChanged<T>? onSelected;
  final double width;

  /// Ao fechar o menu, escolhendo ou não (para devolver o foco ao documento).
  final VoidCallback? onClosed;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final c = t.colors;
    final style = TextStyle(color: c.onFrame, fontSize: t.font.ui, fontFamily: t.font.family);
    return MenuAnchor(
      onClose: onClosed,
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(c.frameRaised),
        surfaceTintColor: WidgetStatePropertyAll(c.frameRaised),
        side: WidgetStatePropertyAll(BorderSide(color: c.border)),
        maximumSize: const WidgetStatePropertyAll(Size(double.infinity, 420)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(t.component == ComponentStyle.modern ? t.radius.control : 0),
        )),
      ),
      menuChildren: [
        for (final item in items)
          MenuItemButton(
            onPressed: onSelected == null ? null : () => onSelected!(item.value),
            style: ButtonStyle(
              foregroundColor: WidgetStatePropertyAll(c.onFrame),
              overlayColor: WidgetStatePropertyAll(c.accentSoft),
              minimumSize: WidgetStatePropertyAll(Size(width, t.density.control)),
            ),
            child: Text(item.label, style: style),
          ),
      ],
      builder: (context, controller, _) => WControlSurface(
        text: text,
        trailingIcon: Icons.arrow_drop_down,
        width: width,
        outlined: true,
        tooltip: label,
        selected: false,
        onPressed: onSelected == null ? null : () => controller.isOpen ? controller.close() : controller.open(),
        semantics: (child) => Semantics(
          container: true,
          button: true,
          enabled: onSelected != null,
          label: label,
          value: text,
          child: child,
        ),
      ),
    );
  }
}
