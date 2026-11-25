// Os bastidores do Arquivo (o "backstage" do Word e do OnlyOffice, D-064):
// a lista grande à esquerda e, à direita, só a seção aberta (Recentes,
// Informações ou Preferências). Os comandos da lista (Novo, Abrir, Salvar,
// Fechar) rodam e voltam ao documento.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../commands/command_registry.dart';
import '../../commands/commands_book.dart';
import '../../commands/commands_document.dart';
import '../../commands/commands_layout.dart';
import '../../commands/commands_view.dart';
import '../../document/document_controller.dart';
import '../../document/paragraph_format.dart';
import '../../document/workspace.dart';
import '../../files/open_folder.dart';
import '../../files/recent_files.dart';
import '../../settings/settings.dart';
import '../atoms/w_button.dart';
import '../atoms/w_label.dart';
import '../atoms/w_text_field.dart';
import '../tokens/tokens.dart';
import 'preferences_view.dart';
import 'recent_list.dart';

enum FileSection { recent, info, preferences }

class FilePanel extends StatefulWidget {
  const FilePanel({
    super.key,
    required this.commands,
    required this.workspace,
    required this.recents,
    required this.settings,
    required this.onClose,
    this.section,
  });

  final CommandRegistry commands;
  final Workspace workspace;
  final RecentFiles recents;
  final Settings settings;
  final VoidCallback onClose;

  /// A seção aberta ao entrar; null: Informações com um arquivo salvo, e
  /// Recentes sem.
  final FileSection? section;

  @override
  State<FilePanel> createState() => _FilePanelState();
}

class _FilePanelState extends State<FilePanel> {
  late FileSection _section =
      widget.section ?? (widget.workspace.doc.path != null ? FileSection.info : FileSection.recent);

  @override
  void didUpdateWidget(FilePanel old) {
    super.didUpdateWidget(old);
    if (widget.section != null && widget.section != old.section) _section = widget.section!;
  }

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final doc = widget.workspace.doc;

    Widget command(String id) {
      final c = widget.commands[id];
      if (c == null) return const SizedBox.shrink();
      return _BackstageItem(
        icon: c.icon,
        label: c.label,
        tooltip: widget.commands.tooltipOf(id),
        onPressed: c.enabled
            ? () {
                widget.onClose();
                widget.commands.run(id);
              }
            : null,
      );
    }

    Widget section(FileSection s, IconData icon, String label, {bool enabled = true}) => _BackstageItem(
          icon: icon,
          label: label,
          selected: _section == s,
          onPressed: enabled ? () => setState(() => _section = s) : null,
        );

    Widget divider() => Padding(
          padding: EdgeInsets.symmetric(vertical: t.space.sm),
          child: Divider(height: 1, color: t.colors.border),
        );

    final (title, body) = switch (_section) {
      FileSection.recent => (
          l10n.recentHeading,
          RecentList(
            recents: widget.recents,
            onOpen: (p) {
              widget.onClose();
              unawaited(widget.workspace.openPath(p));
            },
          ),
        ),
      FileSection.info => (l10n.fileInfo, _InfoView(workspace: widget.workspace)),
      FileSection.preferences => (l10n.preferencesTitle, PreferencesView(settings: widget.settings, commands: widget.commands)),
    };

    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): widget.onClose},
      child: FocusScope(
        autofocus: true,
        child: ColoredBox(
          color: t.colors.frameRaised,
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              width: 260,
              decoration: BoxDecoration(
                color: t.colors.frame,
                border: Border(right: BorderSide(color: t.colors.border)),
              ),
              child: FocusTraversalGroup(
                child: ListView(padding: EdgeInsets.all(t.space.md), children: [
                  _BackstageItem(icon: Symbols.arrow_back_rounded, label: l10n.fileBack, onPressed: widget.onClose, autofocus: true),
                  divider(),
                  command(CommandIds.newDocument),
                  command(LayoutCommandIds.newFromTemplate),
                  command(CommandIds.open),
                  divider(),
                  command(BookCommandIds.newBook),
                  command(BookCommandIds.openBook),
                  command(BookCommandIds.importManuscript),
                  command(BookCommandIds.compile),
                  divider(),
                  section(FileSection.recent, Symbols.history_rounded, l10n.recentTitle),
                  divider(),
                  section(FileSection.info, Symbols.info_rounded, l10n.fileInfo, enabled: doc.isOpen),
                  command(CommandIds.save),
                  command(CommandIds.saveAs),
                  command(LayoutCommandIds.saveAsTemplate),
                  command(CommandIds.closeTab),
                  divider(),
                  section(FileSection.preferences, Symbols.settings_rounded, l10n.preferencesTitle),
                  command(ViewCommandIds.about),
                ]),
              ),
            ),
            Expanded(
              child: FocusTraversalGroup(
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: t.space.xl * 2, vertical: t.space.xl),
                  children: [
                    Semantics(header: true, child: WLabel(title, heading: true)),
                    SizedBox(height: t.space.lg),
                    Align(
                      alignment: Alignment.topLeft,
                      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 960), child: body),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Um item da lista dos bastidores: alto, com o ícone e o nome.
class _BackstageItem extends StatelessWidget {
  const _BackstageItem({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.tooltip,
    this.autofocus = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool selected, autofocus;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: t.space.xs),
      child: LayoutBuilder(
        builder: (context, box) => WControlSurface(
          width: box.maxWidth,
          height: t.density.control + t.space.sm,
          icon: icon,
          text: label,
          tooltip: tooltip,
          selected: selected,
          autofocus: autofocus,
          onPressed: onPressed,
          semantics: (child) => Semantics(
            button: true,
            selected: selected,
            enabled: onPressed != null,
            label: label,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Informações: onde está o arquivo, o tamanho, quando mudou, e as
/// estatísticas do motor (páginas, palavras, caracteres).
class _InfoView extends StatelessWidget {
  const _InfoView({required this.workspace});

  final Workspace workspace;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final loc = MaterialLocalizations.of(context);
    final doc = workspace.doc;
    final path = doc.path;
    final file = path == null ? null : File(path);
    String? size, when;
    if (file != null) {
      try {
        final st = file.statSync();
        if (st.type != FileSystemEntityType.notFound) {
          size = formatFileSize(st.size, l10n);
          when = '${loc.formatMediumDate(st.modified)} ${loc.formatTimeOfDay(TimeOfDay.fromDateTime(st.modified))}';
        }
      } on FileSystemException {
        size = null;
      }
    }
    final w = doc.wordCount;
    Widget row(String label, String value) => Padding(
          padding: EdgeInsets.symmetric(vertical: t.space.sm),
          child: MergeSemantics(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 180, child: WLabel(label, tone: WLabelTone.muted)),
              Expanded(child: WLabel(value, maxLines: 3)),
            ]),
          ),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      WLabel(file?.uri.pathSegments.last ?? l10n.untitled, heading: true),
      SizedBox(height: t.space.md),
      if (file != null) row(l10n.infoFolder, file.parent.path),
      if (size != null) row(l10n.infoSize, size),
      if (when != null) row(l10n.infoModified, when),
      if (file == null) row(l10n.infoFolder, l10n.infoNotSaved),
      if (doc.page case (_, final pages)) row(l10n.statusInfoPages, '$pages'),
      if (w != null && !w.selection) ...[
        row(l10n.statusInfoWords, '${w.words}'),
        row(l10n.infoCharactersWithSpaces, '${w.characters}'),
      ],
      // Da cópia, que o LibreOffice conta ao gravar (D-091).
      if (doc.snapshot.charactersNoSpaces case final n?) row(l10n.infoCharactersNoSpaces, '$n'),
      if (doc.snapshot.paragraphs case final n?) row(l10n.infoParagraphs, '$n'),
      SizedBox(height: t.space.lg),
      WLabel(l10n.infoProperties, heading: true),
      SizedBox(height: t.space.sm),
      _PropertiesForm(doc: doc),
      if (file != null) ...[
        SizedBox(height: t.space.lg),
        WTextButton(
          label: l10n.infoOpenFolder,
          icon: Symbols.folder_open_rounded,
          pill: false,
          onPressed: () => openFolder(file.parent.path),
        ),
      ],
    ]);
  }
}

/// As propriedades do documento (D-091): o título, o assunto, o autor, as
/// etiquetas e o comentário, da cópia; "Aplicar" as manda ao motor (uma
/// macro), e o documento fica modificado.
class _PropertiesForm extends StatefulWidget {
  const _PropertiesForm({required this.doc});
  final DocumentController doc;

  @override
  State<_PropertiesForm> createState() => _PropertiesFormState();
}

class _PropertiesFormState extends State<_PropertiesForm> {
  final _title = TextEditingController(), _subject = TextEditingController(), _author = TextEditingController();
  final _keywords = TextEditingController(), _comment = TextEditingController();
  late DocProperties _shown = widget.doc.snapshot.properties;

  List<TextEditingController> get _all => [_title, _subject, _author, _keywords, _comment];

  @override
  void initState() {
    super.initState();
    _fill(_shown);
  }

  void _fill(DocProperties p) {
    _title.text = p.title;
    _subject.text = p.subject;
    _author.text = p.author;
    _keywords.text = p.keywords.join(', ');
    _comment.text = p.comment;
  }

  DocProperties get _edited => DocProperties(
        title: _title.text.trim(),
        subject: _subject.text.trim(),
        author: _author.text.trim(),
        keywords: parseKeywords(_keywords.text),
        comment: _comment.text.trim(),
      );

  @override
  void didUpdateWidget(_PropertiesForm old) {
    super.didUpdateWidget(old);
    // Uma cópia nova: o que a pessoa não mexeu acompanha.
    final now = widget.doc.snapshot.properties;
    if (now != _shown && _edited == _shown) {
      _shown = now;
      _fill(now);
    }
  }

  @override
  void dispose() {
    for (final c in _all) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = QuillTokens.of(context);
    final editable = widget.doc.canEdit;
    final changed = _edited != _shown;
    Widget field(String label, TextEditingController c) => Padding(
          padding: EdgeInsets.symmetric(vertical: t.space.xs),
          child: Row(children: [
            SizedBox(width: 180, child: WLabel(label, tone: WLabelTone.muted)),
            Expanded(
              child: WTextField(label: label, controller: c, enabled: editable, onChanged: (_) => setState(() {})),
            ),
          ]),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      field(l10n.infoTitle, _title),
      field(l10n.infoSubject, _subject),
      field(l10n.infoAuthor, _author),
      field(l10n.infoKeywords, _keywords),
      field(l10n.infoComment, _comment),
      SizedBox(height: t.space.sm),
      Row(children: [
        WTextButton(
          label: l10n.infoApplyProperties,
          icon: Symbols.check_rounded,
          pill: false,
          onPressed: editable && changed
              ? () {
                  final p = _edited;
                  widget.doc.setDocumentProperties(p);
                  setState(() => _shown = p);
                }
              : null,
        ),
        SizedBox(width: t.space.sm),
        WTextButton(
          label: l10n.infoUndoProperties,
          icon: Symbols.undo_rounded,
          pill: false,
          onPressed: changed ? () => setState(() => _fill(_shown)) : null,
        ),
      ]),
    ]);
  }
}

/// "12 KB", "1,4 MB".
String formatFileSize(int bytes, AppLocalizations l10n) {
  if (bytes < 1024) return l10n.sizeBytes(bytes);
  if (bytes < 1024 * 1024) return l10n.sizeKb((bytes / 1024).round());
  return l10n.sizeMb((bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', l10n.decimalSeparator));
}
