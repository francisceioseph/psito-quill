// A janela Compilar (Fase 4, Etapa 1, D-086): os capítulos que entram (a
// árvore do fichário com caixas de marcar), a folha de rosto, o sumário, as
// quebras, o separador de cena e o formato. "Compilar…" pergunta onde gravar
// e mostra o andamento; cancelar para no próximo passo.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../book/book.dart';
import '../../book/compile.dart';
import '../../book/fodt_join.dart';
import '../../document/workspace.dart';
import '../atoms/w_checkbox.dart';
import '../atoms/w_dropdown.dart';
import '../atoms/w_label.dart';
import '../atoms/w_switch.dart';
import '../atoms/w_text_field.dart';
import '../tokens/tokens.dart';

/// Abre a janela Compilar do livro aberto. [onNotice] mostra o resultado.
Future<void> showCompileDialog(BuildContext context, {required Workspace workspace, required ValueChanged<String> onNotice}) =>
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CompileDialog(workspace: workspace, onNotice: onNotice),
    );

class CompileDialog extends StatefulWidget {
  const CompileDialog({super.key, required this.workspace, required this.onNotice});
  final Workspace workspace;
  final ValueChanged<String> onNotice;

  @override
  State<CompileDialog> createState() => _CompileDialogState();
}

class _CompileDialogState extends State<CompileDialog> {
  Book get _book => widget.workspace.book.book!;

  final _excluded = <String>{};
  late final _title = TextEditingController(text: _book.title);
  final _subtitle = TextEditingController();
  late final _author = TextEditingController(text: _book.author);
  TextEditingController? _tocTitle;
  bool _titlePage = true, _toc = true, _pageBreaks = true, _partTitles = true, _chapterTitles = true;
  SceneBreakMode _scenes = SceneBreakMode.keep;
  CompileFormat _format = CompileFormat.pdf;

  CompileJob? _job;
  CompileStage? _stage;
  int _done = 0, _total = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tocTitle ??= TextEditingController(text: AppLocalizations.of(context).compileTocDefault);
  }

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    _author.dispose();
    _tocTitle?.dispose();
    super.dispose();
  }

  CompileSettings get _settings => CompileSettings(
        excluded: {..._excluded},
        titlePage: _titlePage,
        title: _title.text.trim(),
        subtitle: _subtitle.text.trim(),
        author: _author.text.trim(),
        toc: _toc,
        tocTitle: _tocTitle!.text.trim().isEmpty ? AppLocalizations.of(context).compileTocDefault : _tocTitle!.text.trim(),
        pageBreaks: _pageBreaks,
        partTitles: _partTitles,
        chapterTitles: _chapterTitles,
        scenes: _scenes,
        format: _format,
      );

  String _formatLabel(AppLocalizations l10n, CompileFormat f) => switch (f) {
        CompileFormat.pdf => l10n.compileFormatPdf,
        CompileFormat.epub => l10n.compileFormatEpub,
        CompileFormat.docx => l10n.compileFormatDocx,
        CompileFormat.odt => l10n.compileFormatOdt,
      };

  Future<void> _run() async {
    final l10n = AppLocalizations.of(context);
    final settings = _settings;
    if (compiledChapters(_book, settings).isEmpty) {
      widget.onNotice(l10n.compileNoChapters);
      return;
    }
    final dir = widget.workspace.book.dir;
    final name = (settings.title.isEmpty ? _book.title : settings.title).replaceAll(RegExp(r'[/\\]'), '-');
    final target = await widget.workspace.dialogs.pickExport(
      suggestedName: '$name.${_format.extension}',
      initialDirectory: dir == null ? null : File(dir).parent.path,
      label: l10n.compileFileFilter(_format.extension.toUpperCase()),
      extension: _format.extension,
      mime: _format.mime,
    );
    if (target == null || !mounted) return;
    final job = CompileJob(widget.workspace.doc.kit);
    setState(() {
      _job = job;
      _stage = CompileStage.chapters;
    });
    final result = await widget.workspace.compileBook(job, settings, target, onProgress: (stage, done, total) {
      if (!mounted) return;
      setState(() {
        _stage = stage;
        _done = done;
        _total = total;
      });
    });
    if (!mounted) return;
    // A janela só fecha quando o PopScope já deixa (depois do quadro).
    setState(() => _job = null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
    widget.onNotice(switch (result.outcome) {
      CompileOutcome.done => l10n.compileDone(target),
      CompileOutcome.cancelled => l10n.compileCancelled,
      CompileOutcome.noChapters => l10n.compileNoChapters,
      CompileOutcome.chapterFailed => l10n.compileFailedChapter(result.chapter ?? ''),
      CompileOutcome.writeFailed => l10n.compileFailed,
    });
  }

  void _select(bool Function(BookNode c) keep) => setState(() {
        _excluded
          ..clear()
          ..addAll([
            for (final c in _book.chapters)
              if (!keep(c)) c.id,
          ]);
      });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = QuillTokens.of(context);
    final m = MaterialLocalizations.of(context);
    final running = _job != null;
    final chosen = compiledChapters(_book, _settings);
    final words = chosen.fold(0, (s, e) => s + e.$2.words);
    final total = _book.chapters.length;

    Widget toggle(String label, bool value, ValueChanged<bool> onChanged) => Padding(
          padding: EdgeInsets.only(bottom: t.space.sm),
          child: Row(children: [
            WSwitch(value: value, label: label, onChanged: running ? null : onChanged),
            SizedBox(width: t.space.md),
            Expanded(child: WLabel(label, maxLines: 2)),
          ]),
        );
    Widget field(String label, TextEditingController c, {bool enabled = true}) => Padding(
          padding: EdgeInsets.only(left: t.space.xl * 2, bottom: t.space.sm),
          child: Row(children: [
            SizedBox(width: 140, child: WLabel(label, tone: enabled ? WLabelTone.normal : WLabelTone.muted)),
            Expanded(child: IgnorePointer(ignoring: !enabled || running, child: WTextField(label: label, controller: c))),
          ]),
        );

    final rows = <Widget>[];
    for (final n in _book.nodes) {
      if (n.isPart) {
        final all = n.children.isNotEmpty && n.children.every((c) => !_excluded.contains(c.id));
        rows.add(WCheckbox(
          value: all,
          label: n.title,
          muted: true,
          onChanged: running || n.children.isEmpty
              ? null
              : (v) => setState(() {
                    for (final c in n.children) {
                      v ? _excluded.remove(c.id) : _excluded.add(c.id);
                    }
                  }),
        ));
      }
      for (final c in n.isPart ? n.children : [n]) {
        rows.add(Padding(
          padding: EdgeInsets.only(left: n.isPart ? t.space.xl : 0),
          child: WCheckbox(
            value: !_excluded.contains(c.id),
            label: c.title,
            trailing: m.formatDecimal(c.words),
            onChanged: running ? null : (v) => setState(() => v ? _excluded.remove(c.id) : _excluded.add(c.id)),
          ),
        ));
      }
    }

    final Widget body;
    if (running) {
      final stage = _stage ?? CompileStage.chapters;
      body = Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Semantics(
          liveRegion: true,
          child: WLabel(switch (stage) {
            CompileStage.chapters => l10n.compileProgressChapters(_done + 1, _total == 0 ? chosen.length : _total),
            CompileStage.joining => l10n.compileProgressJoining,
            CompileStage.writing => l10n.compileProgressWriting,
          }),
        ),
        SizedBox(height: t.space.md),
        LinearProgressIndicator(
          value: stage == CompileStage.chapters && _total > 0 ? _done / _total : null,
          semanticsLabel: l10n.compileTitle(_book.title),
        ),
      ]);
    } else {
      body = SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Semantics(header: true, child: WLabel(l10n.compileChapters, heading: true))),
            TextButton(onPressed: () => _select((_) => true), child: Text(l10n.compileSelectAll)),
            TextButton(onPressed: () => _select((c) => c.status == ChapterStatus.done), child: Text(l10n.compileSelectDone)),
            TextButton(onPressed: () => _select((_) => false), child: Text(l10n.compileSelectNone)),
          ]),
          Container(
            height: 220,
            decoration: BoxDecoration(
              border: Border.all(color: t.colors.border),
              borderRadius: BorderRadius.circular(t.radius.control),
            ),
            child: ListView.builder(
              padding: EdgeInsets.all(t.space.xs),
              itemCount: rows.length,
              itemBuilder: (_, i) => rows[i],
            ),
          ),
          SizedBox(height: t.space.xs),
          WLabel(l10n.compileChapterCount(chosen.length, total, m.formatDecimal(words)), small: true, tone: WLabelTone.muted),
          SizedBox(height: t.space.lg),
          toggle(l10n.compileTitlePage, _titlePage, (v) => setState(() => _titlePage = v)),
          field(l10n.compileBookTitle, _title, enabled: _titlePage),
          field(l10n.compileSubtitle, _subtitle, enabled: _titlePage),
          field(l10n.compileAuthor, _author),
          toggle(l10n.compileToc, _toc, (v) => setState(() => _toc = v)),
          field(l10n.compileTocTitle, _tocTitle!, enabled: _toc),
          toggle(l10n.compilePageBreaks, _pageBreaks, (v) => setState(() => _pageBreaks = v)),
          toggle(l10n.compilePartTitles, _partTitles, (v) => setState(() => _partTitles = v)),
          toggle(l10n.compileChapterTitles, _chapterTitles, (v) => setState(() => _chapterTitles = v)),
          SizedBox(height: t.space.sm),
          Row(children: [
            SizedBox(width: 160, child: WLabel(l10n.compileScenes)),
            WDropdown<SceneBreakMode>(
              label: l10n.compileScenes,
              width: 240,
              text: switch (_scenes) {
                SceneBreakMode.keep => l10n.compileScenesKeep,
                SceneBreakMode.stars => l10n.compileScenesStars,
                SceneBreakMode.hash => l10n.compileScenesHash,
              },
              items: [
                WDropdownItem(SceneBreakMode.keep, l10n.compileScenesKeep),
                WDropdownItem(SceneBreakMode.stars, l10n.compileScenesStars),
                WDropdownItem(SceneBreakMode.hash, l10n.compileScenesHash),
              ],
              onSelected: (v) => setState(() => _scenes = v),
            ),
          ]),
          SizedBox(height: t.space.sm),
          Row(children: [
            SizedBox(width: 160, child: WLabel(l10n.compileFormat)),
            WDropdown<CompileFormat>(
              label: l10n.compileFormat,
              width: 240,
              text: _formatLabel(l10n, _format),
              items: [for (final f in CompileFormat.values) WDropdownItem(f, _formatLabel(l10n, f))],
              onSelected: (v) => setState(() => _format = v),
            ),
          ]),
        ]),
      );
    }

    return PopScope(
      canPop: !running,
      child: AlertDialog(
        title: Text(l10n.compileTitle(_book.title)),
        content: SizedBox(width: 560, child: body),
        actions: [
          TextButton(
            onPressed: running ? () => _job?.cancel() : () => Navigator.pop(context),
            child: Text(l10n.dialogCancel),
          ),
          if (!running) FilledButton(onPressed: () => unawaited(_run()), child: Text(l10n.compileRun)),
        ],
      ),
    );
  }
}
