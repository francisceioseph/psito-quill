// O painel Estilos, à esquerda (o trilho abre): os estilos de parágrafo do
// documento, com o atual marcado; clicar aplica. Embaixo, Novo a partir da
// seleção e Gerenciar. A galeria com as prévias de verdade é a Etapa 3.
import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../commands/command_registry.dart';
import '../../commands/commands_view.dart';
import '../../document/document_controller.dart';
import '../molecules/panel_action.dart';
import '../molecules/side_panel.dart';
import '../style_labels.dart';
import '../tokens/tokens.dart';
import 'outline_panel.dart' show PanelListItem;

class StylesPanel extends StatelessWidget {
  const StylesPanel({super.key, required this.doc, required this.commands, required this.onClose, required this.onRan});

  final DocumentController doc;
  final CommandRegistry commands;
  final VoidCallback onClose;
  final VoidCallback onRan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = QuillTokens.of(context);
    final current = doc.paragraphStyleId;
    final styles = [
      for (final s in bookStyles)
        if (doc.paragraphStyles.isEmpty || doc.paragraphStyles.contains(s)) s,
      ...doc.customParagraphStyles,
    ];
    return SidePanel(
      title: l10n.ribbonStyles,
      closeLabel: l10n.stylesPanelClose,
      onClose: onClose,
      side: AxisDirection.left,
      width: 280,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          child: ListView.builder(
            itemCount: styles.length,
            itemExtent: t.density.control + t.space.sm,
            padding: EdgeInsets.only(bottom: t.space.sm),
            itemBuilder: (context, i) => PanelListItem(
              text: styleLabel(l10n, styles[i]),
              selected: styles[i] == current,
              onPressed: doc.canEdit
                  ? () {
                      doc.applyParagraphStyle(styles[i]);
                      onRan();
                    }
                  : null,
            ),
          ),
        ),
        // As ações: uma por linha, na largura do painel (D-056).
        Padding(
          padding: EdgeInsets.only(top: t.space.md, bottom: t.space.sm),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            PanelAction(commands: commands, id: ViewCommandIds.newStyle),
            SizedBox(height: t.space.sm),
            PanelAction(commands: commands, id: ViewCommandIds.manageStyles),
          ]),
        ),
      ]),
    );
  }
}
