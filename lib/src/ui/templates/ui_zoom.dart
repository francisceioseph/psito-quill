// O tamanho da interface (Acessibilidade, D-067): tudo cresce junto (o
// texto, os botões, os ícones), como o "deixar tudo maior" dos sistemas. Só
// o texto maior vazaria dos controles de altura fixa da faixa e do painel.
//
// O filho é montado numa área menor (o tamanho da janela dividido pelo
// zoom) e desenhado ampliado. A densidade de pixels sobe junto: os
// ladrilhos do motor são pedidos na resolução da tela, nítidos.
import 'package:flutter/widgets.dart';

class UiZoom extends StatelessWidget {
  const UiZoom({super.key, required this.zoom, required this.child});

  final double zoom;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (zoom == 1) return child;
    final mq = MediaQuery.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        final size = Size(box.maxWidth / zoom, box.maxHeight / zoom);
        return FittedBox(
          fit: BoxFit.fill,
          alignment: Alignment.topLeft,
          child: SizedBox.fromSize(
            size: size,
            child: MediaQuery(
              data: mq.copyWith(
                size: size,
                devicePixelRatio: mq.devicePixelRatio * zoom,
                padding: mq.padding / zoom,
                viewPadding: mq.viewPadding / zoom,
                viewInsets: mq.viewInsets / zoom,
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
