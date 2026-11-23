// Os estilos: gerenciar (aplicar, criar e atualizar a partir da seleção) e
// o nome de um estilo novo.
//
// Apagar estilo fica de fora: o `.uno:StyleDelete` não faz nada no 24.2
// (D-030).
import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../document/document_controller.dart';
import '../../kit/lok/lo_styles.dart';
import '../atoms/w_button.dart';
import '../atoms/w_label.dart';
import '../atoms/w_text_field.dart';
import '../style_labels.dart';
import '../tokens/tokens.dart';

/// Pede o nome de um estilo novo; null se cancelou.
Future<String?> showNewStyleDialog(BuildContext context, DocumentController doc) =>
    showDialog<String>(context: context, builder: (_) => NewStyleDialog(taken: doc.paragraphStyles.toSet()));

class NewStyleDialog extends StatefulWidget {
  const NewStyleDialog({super.key, required this.taken});

  /// Os nomes que já existem.
  final Set<String> taken;

  @override
  State<NewStyleDialog> createState() => _NewStyleDialogState();
}

class _NewStyleDialogState extends State<NewStyleDialog> {
  final _name = TextEditingController();

  String get _value => _name.text.trim();
  bool get _taken => widget.taken.contains(_value);
  bool get _valid => _value.isNotEmpty && !_taken;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _create() {
    if (_valid) Navigator.of(context).pop(_value);
  }

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final l10n = AppLocalizations.of(context);
    return Dialog(
      child: SizedBox(
        width: 380,
        child: Padding(
          padding: EdgeInsets.all(t.space.lg),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            WLabel(l10n.stylesNewTitle, heading: true),
            SizedBox(height: t.space.md),
            WTextField(
              label: l10n.stylesName,
              controller: _name,
              autofocus: true,
              error: _taken,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _create(),
            ),
            if (_taken) ...[
              SizedBox(height: t.space.sm),
              WLabel(l10n.stylesNameTaken, small: true, tone: WLabelTone.danger),
            ],
            SizedBox(height: t.space.md),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              WTextButton(label: l10n.dialogCancel, onPressed: () => Navigator.of(context).pop()),
              SizedBox(width: t.space.sm),
              WTextButton(label: l10n.stylesCreate, selected: true, onPressed: _valid ? _create : null),
            ]),
          ]),
        ),
      ),
    );
  }
}

Future<void> showStylesDialog(BuildContext context, DocumentController doc) =>
    showDialog<void>(context: context, builder: (_) => StylesDialog(doc: doc));

class StylesDialog extends StatefulWidget {
  const StylesDialog({super.key, required this.doc});
  final DocumentController doc;

  @override
  State<StylesDialog> createState() => _StylesDialogState();
}

class _StylesDialogState extends State<StylesDialog> {
  bool _character = false;

  @override
  void initState() {
    super.initState();
    widget.doc.refreshStyles();
  }

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final doc = widget.doc;
    return Dialog(
      child: SizedBox(
        width: 460,
        height: 520,
        child: Padding(
          padding: EdgeInsets.all(t.space.lg),
          child: ListenableBuilder(
            listenable: doc,
            builder: (context, _) {
              final sections = _character
                  ? [
                      (l10n.stylesBuiltIn, doc.characterStyles.where(loBuiltinCharacterStyles.contains).toList()),
                      (
                        l10n.stylesMine,
                        doc.characterStyles.where((s) => !loBuiltinCharacterStyles.contains(s)).toList(),
                      ),
                    ]
                  : [
                      (l10n.stylesMine, doc.customParagraphStyles),
                      (l10n.stylesBuiltIn, [
                        for (final s in bookStyles)
                          if (doc.paragraphStyles.contains(s)) s,
                        for (final s in doc.paragraphStyles)
                          if (!bookStyles.contains(s) && loBuiltinParagraphStyles.contains(s)) s,
                      ]),
                    ];
              final current = _character ? null : doc.paragraphStyleId;
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                WLabel(l10n.stylesTitle, heading: true),
                SizedBox(height: t.space.md),
                Row(children: [
                  WTextButton(
                    label: l10n.stylesParagraph,
                    selected: !_character,
                    onPressed: () => setState(() => _character = false),
                  ),
                  SizedBox(width: t.space.xs),
                  WTextButton(
                    label: l10n.stylesCharacter,
                    selected: _character,
                    onPressed: () => setState(() => _character = true),
                  ),
                ]),
                SizedBox(height: t.space.sm),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(border: Border.all(color: t.colors.border)),
                    child: ListView(padding: EdgeInsets.all(t.space.sm), children: [
                      for (final (title, styles) in sections)
                        if (styles.isNotEmpty) ...[
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: t.space.sm),
                            child: WLabel(title, small: true, tone: WLabelTone.muted),
                          ),
                          for (final s in styles)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: WTextButton(
                                label: styleLabel(l10n, s),
                                selected: s == current,
                                onPressed: doc.canEdit
                                    ? () => _character ? doc.applyCharacterStyle(s) : doc.applyParagraphStyle(s)
                                    : null,
                              ),
                            ),
                        ],
                    ]),
                  ),
                ),
                SizedBox(height: t.space.md),
                Row(children: [
                  if (!_character) ...[
                    WTextButton(
                      label: l10n.commandNewStyle,
                      onPressed: doc.canEdit
                          ? () async {
                              final name = await showNewStyleDialog(context, doc);
                              if (name != null) doc.newStyleFromSelection(name);
                            }
                          : null,
                    ),
                    SizedBox(width: t.space.xs),
                    WTextButton(
                      label: l10n.commandUpdateStyle,
                      onPressed: doc.canEdit && current != null ? () => doc.updateStyleFromSelection(current) : null,
                    ),
                  ],
                  const Spacer(),
                  WTextButton(label: l10n.dialogClose, onPressed: () => Navigator.of(context).pop()),
                ]),
              ]);
            },
          ),
        ),
      ),
    );
  }
}
