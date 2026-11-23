import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../document/workspace.dart';
import '../atoms/w_button.dart';
import '../atoms/w_label.dart';
import '../tokens/tokens.dart';

/// "Salvar as alterações?" — Salvar, Não salvar, Cancelar. Esc cancela.
Future<UnsavedChoice> showUnsavedDialog(BuildContext context, String name) async {
  final choice = await showDialog<UnsavedChoice>(
    context: context,
    builder: (context) {
      final t = QuillTokens.of(context);
      final l10n = AppLocalizations.of(context);
      return Dialog(
        backgroundColor: t.colors.frameRaised,
        surfaceTintColor: t.colors.frameRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(t.component == ComponentStyle.modern ? t.radius.panel : 0),
          side: BorderSide(color: t.colors.border),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: EdgeInsets.all(t.space.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(header: true, child: WLabel(l10n.unsavedTitle, heading: true)),
                SizedBox(height: t.space.md),
                WLabel(l10n.unsavedBody(name), maxLines: 3),
                SizedBox(height: t.space.xl),
                // Quebra a linha se os três não couberem (textos longos, letra grande).
                OverflowBar(
                  alignment: MainAxisAlignment.end,
                  spacing: t.space.sm,
                  overflowSpacing: t.space.sm,
                  overflowAlignment: OverflowBarAlignment.end,
                  children: [
                    WTextButton(
                      label: l10n.unsavedCancel,
                      onPressed: () => Navigator.pop(context, UnsavedChoice.cancel),
                    ),
                    WTextButton(
                      label: l10n.unsavedDiscard,
                      onPressed: () => Navigator.pop(context, UnsavedChoice.discard),
                    ),
                    WTextButton(
                      label: l10n.unsavedSave,
                      selected: true,
                      autofocus: true,
                      onPressed: () => Navigator.pop(context, UnsavedChoice.save),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  return choice ?? UnsavedChoice.cancel;
}
