// O modo zen (Fase 2B, Etapa 6, D-048): a tela cheia com só a página. Sem
// faixa, sem painéis, sem régua e sem barra de status. A janela inteira fica
// da cor do papel (o tema do zen, Sépia por padrão).
//
// Em cima, uma barrinha de opções aparece ao mexer o mouse e some depois de
// 2 s parado: um Timer só, e só a barrinha se refaz. Embaixo, as palavras e
// o tempo da sessão, que muda uma vez por minuto (outro Timer, e só o rótulo
// se refaz).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../atoms/w_button.dart';
import '../atoms/w_label.dart';
import '../tokens/tokens.dart';

class ZenView extends StatefulWidget {
  const ZenView({
    super.key,
    required this.child,
    required this.words,
    required this.focus,
    required this.typewriter,
    required this.paper,
    required this.onFocus,
    required this.onTypewriter,
    required this.onPaper,
  });

  /// A página (o DocumentView com a máquina de escrever e o foco).
  final Widget child;

  /// "1.240 palavras" (da barra de status); null: ainda não se sabe.
  final String? words;
  final bool focus, typewriter;

  /// "sepia", "claro" ou "escuro".
  final String paper;
  final VoidCallback onFocus, onTypewriter, onPaper;

  @override
  State<ZenView> createState() => _ZenViewState();
}

class _ZenViewState extends State<ZenView> {
  final _barVisible = ValueNotifier<bool>(true);
  Timer? _hide;
  final _started = DateTime.now();
  final _minutes = ValueNotifier<int>(0);
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _showBar();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      _minutes.value = DateTime.now().difference(_started).inMinutes;
    });
  }

  @override
  void dispose() {
    _hide?.cancel();
    _clock?.cancel();
    _barVisible.dispose();
    _minutes.dispose();
    super.dispose();
  }

  /// Mostra a barrinha e a esconde de novo depois de 2 s sem mexer o mouse.
  void _showBar() {
    _barVisible.value = true;
    _hide?.cancel();
    _hide = Timer(const Duration(seconds: 2), () => _barVisible.value = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final c = t.colors;
    return MouseRegion(
      onHover: (_) => _showBar(),
      child: ColoredBox(
        color: c.paper,
        child: Stack(children: [
          Positioned.fill(child: widget.child),
          // A barrinha de opções, por cima da página.
          Positioned(
            top: t.space.md,
            left: 0,
            right: 0,
            child: Center(
              child: ValueListenableBuilder<bool>(
                valueListenable: _barVisible,
                builder: (context, visible, bar) => AnimatedOpacity(
                  opacity: visible ? 1 : 0,
                  duration: t.motion.normal,
                  // Escondida, não recebe clique (nem o leitor de tela a perde:
                  // as opções continuam na paleta Ctrl+K).
                  child: IgnorePointer(ignoring: !visible, child: bar),
                ),
                child: Semantics(
                  container: true,
                  explicitChildNodes: true,
                  label: l10n.zenOptions,
                  child: Container(
                    padding: EdgeInsets.all(t.space.xs),
                    decoration: BoxDecoration(color: c.surfaceHigh, borderRadius: BorderRadius.circular(22)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      WTextButton(label: l10n.zenFocus, icon: Symbols.segment_rounded, selected: widget.focus, onPressed: widget.onFocus),
                      WTextButton(
                        label: l10n.zenTypewriter,
                        icon: Symbols.vertical_align_center_rounded,
                        selected: widget.typewriter,
                        onPressed: widget.onTypewriter,
                      ),
                      WTextButton(label: l10n.zenPaper, icon: Symbols.contrast_rounded, onPressed: widget.onPaper),
                      SizedBox(width: t.space.md),
                      WLabel(l10n.zenExitHint, small: true, tone: WLabelTone.muted),
                      SizedBox(width: t.space.md),
                    ]),
                  ),
                ),
              ),
            ),
          ),
          // Embaixo: as palavras e o tempo da sessão.
          Positioned(
            bottom: t.space.md,
            left: 0,
            right: 0,
            child: Center(
              child: ValueListenableBuilder<int>(
                valueListenable: _minutes,
                builder: (context, minutes, _) => WLabel(
                  [?widget.words, l10n.zenSession(minutes)].join(' · '),
                  small: true,
                  tone: WLabelTone.muted,
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
