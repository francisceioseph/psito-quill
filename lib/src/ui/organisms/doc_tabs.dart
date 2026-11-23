// A fileira das abas de documentos (D-054), acima da faixa. Aparece só com
// duas abas ou mais (quem chama decide).
//
// Cada aba: o nome do arquivo, um ponto se há alterações e o X para fechar.
// O clique troca, o clique do meio fecha, e a dica mostra o caminho inteiro.
// Pelo teclado: Tab chega a cada aba e Enter troca (e Ctrl+Tab de qualquer
// lugar). A aba da tela fica com a cor da faixa, que parece continuar dela.
import 'package:flutter/gestures.dart' show kMiddleMouseButton;
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../document/document_controller.dart';
import '../atoms/w_button.dart';
import '../tokens/tokens.dart';

class DocTabStrip extends StatelessWidget {
  const DocTabStrip({super.key, required this.doc, required this.onClose});

  final DocumentController doc;

  /// Fechar uma aba passa pelo Workspace (que pergunta se há alterações).
  final void Function(DocTab tab) onClose;

  /// O nome que a aba mostra: o do arquivo, sem a pasta.
  static String titleOf(DocumentController doc, DocTab t, AppLocalizations l10n) {
    final p = doc.tabPath(t);
    if (p == null || p.isEmpty) return l10n.untitled;
    final slash = p.lastIndexOf('/');
    return slash < 0 ? p : p.substring(slash + 1);
  }

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final l10n = AppLocalizations.of(context);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: l10n.tabsLabel,
      child: Container(
        height: t.density.control + t.space.xs * 2,
        color: t.colors.frame,
        padding: EdgeInsets.symmetric(horizontal: t.space.sm, vertical: t.space.xs),
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (final tab in doc.tabs)
              Padding(
                padding: EdgeInsets.only(right: t.space.xs),
                child: _Tab(
                  key: ValueKey(tab.serial),
                  title: titleOf(doc, tab, l10n),
                  path: doc.tabPath(tab),
                  modified: doc.tabModified(tab),
                  current: tab == doc.currentTab,
                  onSelect: () => doc.activateTab(tab),
                  onClose: () => onClose(tab),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    super.key,
    required this.title,
    required this.path,
    required this.modified,
    required this.current,
    required this.onSelect,
    required this.onClose,
  });

  final String title;
  final String? path;
  final bool modified, current;
  final VoidCallback onSelect, onClose;

  /// A aba mais larga; o nome corta com reticências.
  static const maxWidth = 240.0;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final c = t.colors;
    final name = modified ? l10n.tabModifiedNamed(title) : title;
    // As cores do WControlSurface (o conteúdo próprio não as recebe dele).
    final fg = t.component == ComponentStyle.modern ? (current ? c.onAccentSoft : c.onFrameMuted) : c.onFrame;
    return Listener(
      onPointerDown: (e) {
        if (e.buttons == kMiddleMouseButton) onClose();
      },
      child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxWidth),
              child: WControlSurface(
                tooltip: path ?? title,
                onPressed: onSelect,
                selected: current,
                semantics: (child) => Semantics(
                  container: true,
                  button: true,
                  selected: current,
                  label: name,
                  child: child,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Symbols.description_rounded, size: t.density.icon - 4, color: fg, fill: current ? 1 : 0),
                    SizedBox(width: t.space.xs),
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: fg,
                          fontFamily: t.font.family,
                          fontSize: t.font.ui,
                          fontWeight: current ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (modified) ...[
                      SizedBox(width: t.space.xs),
                      // O ponto das alterações (o nome para o leitor de tela já diz).
                      ExcludeSemantics(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            WButton(icon: Symbols.close_rounded, label: l10n.tabCloseNamed(title), onPressed: onClose),
          ],
      ),
    );
  }
}
