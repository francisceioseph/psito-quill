// As janelas dos modelos (Fase 4, Etapa 8, D-093): escolher um modelo para
// um documento novo (o do livro primeiro), e dar nome a um modelo novo.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../document/templates.dart';
import '../../files/open_folder.dart';
import '../atoms/w_button.dart';
import '../atoms/w_label.dart';
import '../atoms/w_text_field.dart';
import '../tokens/tokens.dart';

/// O caminho do modelo escolhido.
Future<String?> showNewFromTemplateDialog(BuildContext context, {required List<TemplateEntry> templates, required Directory folder}) =>
    showDialog<String>(context: context, builder: (_) => _NewFromTemplate(templates: templates, folder: folder));

class _NewFromTemplate extends StatelessWidget {
  const _NewFromTemplate({required this.templates, required this.folder});
  final List<TemplateEntry> templates;
  final Directory folder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = QuillTokens.of(context);
    return AlertDialog(
      title: Text(l10n.templatesNewTitle),
      content: SizedBox(
        width: 440,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (templates.isEmpty)
            WLabel(l10n.templatesNone(folder.path), small: true, tone: WLabelTone.muted, maxLines: 4)
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView(shrinkWrap: true, children: [
                for (final e in templates)
                  WTextButton(
                    label: e.ofBook ? l10n.templatesOfBook : e.name,
                    icon: e.ofBook ? Symbols.auto_stories_rounded : Symbols.description_rounded,
                    pill: false,
                    onPressed: () => Navigator.pop(context, e.path),
                  ),
              ]),
            ),
          SizedBox(height: t.space.md),
          Align(
            alignment: Alignment.centerLeft,
            child: WTextButton(
              label: l10n.templatesOpenFolder,
              icon: Symbols.folder_open_rounded,
              pill: false,
              onPressed: () {
                try {
                  folder.createSync(recursive: true);
                } on FileSystemException {
                  return;
                }
                openFolder(folder.path);
              },
            ),
          ),
        ]),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.dialogCancel))],
    );
  }
}

/// O nome do arquivo (`Nome.ott`) do modelo novo, na pasta [folder].
Future<String?> showSaveTemplateDialog(BuildContext context, {required Directory folder}) =>
    showDialog<String>(context: context, builder: (_) => _SaveTemplate(folder: folder));

class _SaveTemplate extends StatefulWidget {
  const _SaveTemplate({required this.folder});
  final Directory folder;

  @override
  State<_SaveTemplate> createState() => _SaveTemplateState();
}

class _SaveTemplateState extends State<_SaveTemplate> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String? get _file => templateFileName(_name.text);

  void _save() {
    final f = _file;
    if (f != null) Navigator.pop(context, f);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = QuillTokens.of(context);
    final f = _file;
    final exists = f != null && File('${widget.folder.path}/$f').existsSync();
    return AlertDialog(
      title: Text(l10n.templatesSaveTitle),
      content: SizedBox(
        width: 420,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          WLabel(l10n.templatesSaveNote, small: true, tone: WLabelTone.muted, maxLines: 3),
          SizedBox(height: t.space.md),
          WTextField(
            label: l10n.templatesName,
            controller: _name,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _save(),
          ),
          if (exists) ...[
            SizedBox(height: t.space.xs),
            WLabel(l10n.templatesExists, small: true, tone: WLabelTone.danger),
          ],
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.dialogCancel)),
        FilledButton(onPressed: f == null ? null : _save, child: Text(exists ? l10n.templatesReplace : l10n.templatesSave)),
      ],
    );
  }
}
