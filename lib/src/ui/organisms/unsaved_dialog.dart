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
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Semantics(header: true, child: WLabel(l10n.unsavedTitle, heading: true)),
              SizedBox(height: t.space.md),
              WLabel(l10n.unsavedBody(name), maxLines: 3),
              SizedBox(height: t.space.xl),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                WTextButton(
                  label: l10n.unsavedCancel,
                  onPressed: () => Navigator.pop(context, UnsavedChoice.cancel),
                ),
                SizedBox(width: t.space.sm),
                WTextButton(
                  label: l10n.unsavedDiscard,
                  onPressed: () => Navigator.pop(context, UnsavedChoice.discard),
                ),
                SizedBox(width: t.space.sm),
                WTextButton(
                  label: l10n.unsavedSave,
                  selected: true,
                  autofocus: true,
                  onPressed: () => Navigator.pop(context, UnsavedChoice.save),
                ),
              ]),
            ]),
          ),
        ),
      );
    },
  );
  return choice ?? UnsavedChoice.cancel;
}
