// O modo Leitura (D-089): só a página, com uma barrinha em cima (o título,
// a página e o sair). Nada se edita: o controlador está em `reading`, e as
// setas e o Page Down folheiam (o DocumentView manda a página ao motor).
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../atoms/w_button.dart';
import '../atoms/w_label.dart';
import '../tokens/tokens.dart';

class ReadingView extends StatelessWidget {
  const ReadingView({super.key, required this.title, required this.page, required this.onExit, required this.child});

  final String title;

  /// "Página 3 de 12"; null enquanto o motor não diz.
  final String? page;
  final VoidCallback onExit;

  /// A página (o DocumentView).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final c = t.colors;
    return ColoredBox(
      color: c.backdrop,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Semantics(
          container: true,
          explicitChildNodes: true,
          label: l10n.modeReading,
          child: Container(
            color: c.frame,
            padding: EdgeInsets.symmetric(horizontal: t.space.lg, vertical: t.space.xs),
            child: Row(children: [
              Icon(Symbols.chrome_reader_mode_rounded, size: t.density.icon, color: c.onFrameMuted),
              SizedBox(width: t.space.sm),
              Expanded(child: WLabel(title, maxLines: 1)),
              if (page case final p?) ...[WLabel(p, small: true, tone: WLabelTone.muted), SizedBox(width: t.space.lg)],
              WLabel(l10n.modeReadingHint, small: true, tone: WLabelTone.muted),
              SizedBox(width: t.space.md),
              WTextButton(label: l10n.modeReadingExit, icon: Symbols.close_rounded, onPressed: onExit),
            ]),
          ),
        ),
        Expanded(child: child),
      ]),
    );
  }
}
