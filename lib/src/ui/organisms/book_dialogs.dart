// As janelas do livro (D-071): o livro novo e a importação de um manuscrito.
//
// As duas perguntam o título e onde guardar; o livro vira a pasta
// "<título>.psitobook" dentro do lugar escolhido. A importação mostra antes
// os capítulos achados, com o nível dos títulos para trocar, e o progresso
// enquanto o motor grava cada capítulo.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../book/book.dart';
import '../../book/book_io.dart';
import '../../book/docx_import.dart';
import '../../book/fodt_split.dart';
import '../../files/file_dialogs.dart';
import '../atoms/w_label.dart';
import '../atoms/w_segmented.dart';
import '../atoms/w_text_field.dart';
import '../tokens/tokens.dart';

/// Onde o livro fica por padrão: a pasta Documentos, se existe; senão a casa.
String defaultBookLocation() {
  final home = Platform.environment['HOME'] ?? Directory.current.path;
  for (final d in ['Documentos', 'Documents']) {
    if (Directory('$home/$d').existsSync()) return '$home/$d';
  }
  return home;
}

/// O livro novo: o título e a pasta (a do livro, já com o `.psitobook`).
Future<(String title, String dir)?> showNewBookDialog(BuildContext context, FileDialogs dialogs) =>
    showDialog<(String, String)>(context: context, builder: (_) => _NewBookDialog(dialogs: dialogs));

class _NewBookDialog extends StatefulWidget {
  const _NewBookDialog({required this.dialogs});
  final FileDialogs dialogs;

  @override
  State<_NewBookDialog> createState() => _NewBookDialogState();
}

class _NewBookDialogState extends State<_NewBookDialog> {
  final _title = TextEditingController();
  String _location = defaultBookLocation();

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  bool get _ready => _title.text.trim().isNotEmpty;

  void _create() {
    if (!_ready) return;
    Navigator.pop(context, (_title.text.trim(), '$_location/${bookFolderName(_title.text)}'));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = QuillTokens.of(context);
    return AlertDialog(
      title: Text(l10n.newBookTitle),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WLabel(l10n.bookTitleLabel, small: true, tone: WLabelTone.muted),
            SizedBox(height: t.space.xs),
            WTextField(
              label: l10n.bookTitleLabel,
              controller: _title,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _create(),
            ),
            SizedBox(height: t.space.md),
            _LocationField(
              location: _location,
              folder: bookFolderName(_title.text),
              dialogs: widget.dialogs,
              onChanged: (v) => setState(() => _location = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.dialogCancel)),
        FilledButton(onPressed: _ready ? _create : null, child: Text(l10n.createButton)),
      ],
    );
  }
}

class _LocationField extends StatelessWidget {
  const _LocationField({required this.location, required this.folder, required this.dialogs, required this.onChanged});
  final String location, folder;
  final FileDialogs dialogs;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = QuillTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        WLabel(l10n.bookLocationLabel, small: true, tone: WLabelTone.muted),
        SizedBox(height: t.space.xs),
        Row(
          children: [
            Expanded(child: WLabel(location, maxLines: 2)),
            SizedBox(width: t.space.sm),
            TextButton(
              onPressed: () async {
                final picked = await dialogs.pickDirectory(label: l10n.chooseFolderButton, initialDirectory: location);
                if (picked != null) onChanged(picked);
              },
              child: Text(l10n.chooseFolder),
            ),
          ],
        ),
        SizedBox(height: t.space.xs),
        WLabel(l10n.bookLocationNote(folder), small: true, tone: WLabelTone.muted, maxLines: 3),
      ],
    );
  }
}

/// A importação de [manuscript]: devolve a pasta e o livro criado, ou null
/// se desistiu.
Future<(String dir, Book book)?> showImportDialog(
  BuildContext context, {
  required String manuscript,
  required DocxImporter importer,
  required FileDialogs dialogs,
}) =>
    showDialog<(String, Book)>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ImportDialog(manuscript: manuscript, importer: importer, dialogs: dialogs),
    );

class _ImportDialog extends StatefulWidget {
  const _ImportDialog({required this.manuscript, required this.importer, required this.dialogs});
  final String manuscript;
  final DocxImporter importer;
  final FileDialogs dialogs;

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  final _title = TextEditingController();
  String _location = defaultBookLocation();
  FodtManuscript? _m;
  int _level = 1;
  List<ChapterDraft> _drafts = const [];

  /// Durante a gravação: quantos capítulos já foram; null fora dela.
  int? _done;
  String? _error;

  @override
  void initState() {
    super.initState();
    final name = widget.manuscript.split('/').last;
    final dot = name.lastIndexOf('.');
    _title.text = dot > 0 ? name.substring(0, dot) : name;
    unawaited(_read());
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  String _message(AppLocalizations l10n, ImportError e) => switch (e) {
        ImportError.unreadable => l10n.importErrorUnreadable,
        ImportError.emptyManuscript => l10n.importErrorEmpty,
        ImportError.bookExists => l10n.bookErrorExists,
        ImportError.writeFailed => l10n.bookErrorWrite,
      };

  Future<void> _read() async {
    try {
      final m = await widget.importer.read(widget.manuscript);
      if (!mounted) return;
      setState(() {
        _m = m;
        _level = m.suggestedLevel;
        _drafts = m.chapters(_level);
      });
    } on ImportException catch (e) {
      if (mounted) setState(() => _error = _message(AppLocalizations.of(context), e.error));
    }
  }

  Future<void> _import() async {
    final m = _m;
    if (m == null || _title.text.trim().isEmpty) return;
    final l10n = AppLocalizations.of(context);
    final dir = '$_location/${bookFolderName(_title.text)}';
    setState(() {
      _done = 0;
      _error = null;
    });
    try {
      final book = await widget.importer.create(
        dir: dir,
        title: _title.text.trim(),
        m: m,
        drafts: _drafts,
        untitled: l10n.importUntitled,
        progress: (n) {
          if (mounted) setState(() => _done = n);
        },
      );
      if (mounted) Navigator.pop(context, (dir, book));
    } on ImportException catch (e) {
      if (mounted) {
        setState(() {
          _done = null;
          _error = _message(l10n, e.error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = QuillTokens.of(context);
    final m = _m;
    final done = _done;
    final busy = done != null;
    return AlertDialog(
      title: Text(l10n.importTitle),
      content: SizedBox(
        width: 480,
        height: 460,
        child: m == null
            ? Center(
                child: _error != null
                    ? WLabel(_error!, maxLines: 4)
                    : Column(mainAxisSize: MainAxisSize.min, children: [
                        const SizedBox(width: 32, height: 32, child: CircularProgressIndicator()),
                        SizedBox(height: t.space.md),
                        Semantics(liveRegion: true, child: WLabel(l10n.importReading)),
                      ]),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  WLabel(l10n.bookTitleLabel, small: true, tone: WLabelTone.muted),
                  SizedBox(height: t.space.xs),
                  WTextField(label: l10n.bookTitleLabel, controller: _title, onChanged: (_) => setState(() {})),
                  SizedBox(height: t.space.md),
                  if (m.headingLevels.length > 1) ...[
                    WLabel(l10n.importLevel, small: true, tone: WLabelTone.muted),
                    SizedBox(height: t.space.xs),
                    WSegmented<int>(
                      label: l10n.importLevel,
                      segments: [for (final l in m.headingLevels.take(4)) WSegment(l, l10n.importLevelN(l))],
                      selected: _level,
                      onChanged: busy
                          ? null
                          : (l) => setState(() {
                                _level = l;
                                _drafts = m.chapters(l);
                              }),
                    ),
                    if (_level > m.headingLevels.first) ...[
                      SizedBox(height: t.space.xs),
                      WLabel(l10n.importPartsNote, small: true, tone: WLabelTone.muted, maxLines: 2),
                    ],
                    SizedBox(height: t.space.md),
                  ],
                  WLabel(l10n.importFound(_drafts.length), small: true, tone: WLabelTone.muted),
                  if (m.sceneSeparators > 0)
                    WLabel(l10n.importScenes(m.sceneSeparators), small: true, tone: WLabelTone.muted, maxLines: 2),
                  SizedBox(height: t.space.xs),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(border: Border.all(color: t.colors.border), borderRadius: BorderRadius.circular(t.radius.control)),
                      child: ListView.builder(
                        itemCount: _drafts.length,
                        itemExtent: t.density.control,
                        padding: EdgeInsets.symmetric(horizontal: t.space.md),
                        itemBuilder: (context, i) {
                          final d = _drafts[i];
                          final newPart = d.part != null && (i == 0 || _drafts[i - 1].part != d.part);
                          final title = d.title?.isNotEmpty == true ? d.title! : l10n.importUntitled;
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: WLabel(
                              '${newPart ? '${d.part} › ' : d.part != null ? '    ' : ''}${l10n.importChapterWords(title, d.words)}',
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: t.space.md),
                  _LocationField(
                    location: _location,
                    folder: bookFolderName(_title.text),
                    dialogs: widget.dialogs,
                    onChanged: (v) => setState(() => _location = v),
                  ),
                  if (busy) ...[
                    SizedBox(height: t.space.md),
                    LinearProgressIndicator(value: _drafts.isEmpty ? null : done / _drafts.length),
                    SizedBox(height: t.space.xs),
                    Semantics(liveRegion: true, child: WLabel(l10n.importProgress(done, _drafts.length), small: true)),
                  ],
                  if (_error != null) ...[
                    SizedBox(height: t.space.sm),
                    WLabel(_error!, maxLines: 3),
                  ],
                ],
              ),
      ),
      actions: [
        TextButton(onPressed: busy ? null : () => Navigator.pop(context), child: Text(l10n.dialogCancel)),
        FilledButton(
          onPressed: m == null || busy || _drafts.isEmpty || _title.text.trim().isEmpty ? null : _import,
          child: Text(l10n.importButton),
        ),
      ],
    );
  }
}
