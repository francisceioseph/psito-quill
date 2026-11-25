// A janela Compilar (Fase 4, Etapa 1, D-086): os capítulos que entram (a
// árvore do fichário com caixas de marcar), a folha de rosto, o sumário, as
// quebras, o separador de cena e o formato. "Compilar…" pergunta onde gravar
// e mostra o andamento; cancelar para no próximo passo.
//
// Os modelos (Etapa 2, D-087): o Manuscrito, o Livro 6×9 e o E-book, e os
// de quem escreve, no `compilar.json` do livro, com a aparência (a página,
// o corpo, os cabeçalhos) e a capa. A janela abre como ficou da última vez.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../book/book.dart';
import '../../book/compile.dart';
import '../../book/compile_models.dart';
import '../../book/compile_style.dart';
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
  final _font = TextEditingController();
  bool _titlePage = true, _toc = true, _pageBreaks = true, _partTitles = true, _chapterTitles = true;
  bool _figures = false, _index = false;
  SceneBreakMode _scenes = SceneBreakMode.keep;
  CompileFormat _format = CompileFormat.pdf;
  OutputStyle _style = const OutputStyle();
  String _cover = '';

  /// O `compilar.json` do livro e o modelo escolhido (null: nenhum).
  late final CompileStore _store;
  String? _model;

  CompileJob? _job;
  CompileStage? _stage;
  int _done = 0, _total = 0;

  String? get _bookDir => widget.workspace.book.dir;

  @override
  void initState() {
    super.initState();
    final dir = _bookDir;
    _store = dir == null ? CompileStore() : CompileStore.read(dir);
    if (_store.last != null && _store.settingsOf(_store.last!) != null) _model = _store.last;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_tocTitle != null) return;
    _tocTitle = TextEditingController(text: AppLocalizations.of(context).compileTocDefault);
    // A janela como ficou da última vez; os capítulos que já não existem
    // saem da lista dos de fora.
    final last = _store.choices;
    if (last != null) {
      final ids = {for (final c in _book.chapters) c.id};
      _apply(last.copyWith(
        excluded: last.excluded.intersection(ids),
        title: last.title.isEmpty ? _book.title : last.title,
        author: last.author.isEmpty ? _book.author : last.author,
      ));
    }
  }

  /// Põe [s] na janela.
  void _apply(CompileSettings s) {
    _excluded
      ..clear()
      ..addAll(s.excluded);
    _title.text = s.title;
    _subtitle.text = s.subtitle;
    _author.text = s.author;
    _tocTitle!.text = s.tocTitle;
    _titlePage = s.titlePage;
    _toc = s.toc;
    _figures = s.figures;
    _index = s.index;
    _pageBreaks = s.pageBreaks;
    _partTitles = s.partTitles;
    _chapterTitles = s.chapterTitles;
    _scenes = s.scenes;
    _format = s.format;
    _style = s.style;
    _font.text = s.style.font;
    _cover = s.cover;
  }

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    _author.dispose();
    _tocTitle?.dispose();
    _font.dispose();
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
        figures: _figures,
        figuresTitle: AppLocalizations.of(context).figureTableTitle,
        index: _index,
        indexTitle: AppLocalizations.of(context).indexTitle,
        pageBreaks: _pageBreaks,
        partTitles: _partTitles,
        chapterTitles: _chapterTitles,
        scenes: _scenes,
        format: _format,
        style: _style.copyWith(font: _font.text.trim()),
        cover: _cover,
      );

  /// Grava o `compilar.json`; false se não deu.
  bool _writeStore() {
    final dir = _bookDir;
    if (dir == null) return false;
    try {
      _store.write(dir);
      return true;
    } on FileSystemException {
      widget.onNotice(AppLocalizations.of(context).compileModelWriteFailed);
      return false;
    }
  }

  String _modelLabel(AppLocalizations l10n, String? id) {
    if (id == null) return l10n.compileModelNone;
    return switch (BuiltInModel.values.where((b) => b.id == id).firstOrNull) {
      BuiltInModel.manuscript => l10n.compileModelManuscript,
      BuiltInModel.sixByNine => l10n.compileModelSixByNine,
      BuiltInModel.ebook => l10n.compileModelEbook,
      null => id,
    };
  }

  void _chooseModel(String? id) {
    final model = id == null ? null : _store.settingsOf(id);
    setState(() {
      _model = id;
      if (model != null) _apply(_settings.withModel(model));
    });
  }

  Future<String?> _askName(String title, String initial) => showDialog<String>(
        context: context,
        builder: (_) => _NameDialog(title: title, initial: initial),
      );

  Future<void> _saveModel() async {
    final l10n = AppLocalizations.of(context);
    final current = _model != null && _store.named(_model!) != null ? _model! : '';
    final name = (await _askName(l10n.compileModelSaveTitle, current))?.trim();
    if (name == null || name.isEmpty || !mounted) return;
    setState(() => _store.save(name, _settings));
    if (_writeStore()) {
      setState(() => _model = name);
      widget.onNotice(l10n.compileModelSaved(name));
    }
  }

  Future<void> _renameModel() async {
    final l10n = AppLocalizations.of(context);
    final from = _model;
    if (from == null || _store.named(from) == null) return;
    final to = (await _askName(l10n.compileModelRenameTitle, from))?.trim();
    if (to == null || to.isEmpty || to == from || !mounted) return;
    setState(() {
      _store.delete(to);
      _store.rename(from, to);
      _model = to;
    });
    _writeStore();
  }

  void _deleteModel() {
    final l10n = AppLocalizations.of(context);
    final name = _model;
    if (name == null || _store.named(name) == null) return;
    setState(() {
      _store.delete(name);
      _model = null;
    });
    if (_writeStore()) widget.onNotice(l10n.compileModelDeleted(name));
  }

  Future<void> _pickCover() async {
    final l10n = AppLocalizations.of(context);
    final path = await widget.workspace.dialogs.pickImage(label: l10n.compileCover);
    if (path == null || !mounted) return;
    setState(() => _cover = path);
  }

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
    // A janela da próxima vez começa como esta.
    _store
      ..last = _model
      ..choices = settings;
    _writeStore();
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

  String _pageLabel(AppLocalizations l10n, PageChoice p) => switch (p) {
        PageChoice.keep => l10n.compileKeep,
        PageChoice.a4 => l10n.compilePageA4,
        PageChoice.letter => l10n.compilePageLetter,
        PageChoice.a5 => l10n.compilePageA5,
        PageChoice.sixByNine => l10n.compilePageSixByNine,
      };

  String _spacingLabel(AppLocalizations l10n, LineSpacing v) => switch (v) {
        LineSpacing.keep => l10n.compileKeep,
        LineSpacing.single => l10n.compileSpacingSingle,
        LineSpacing.oneHalf => l10n.compileSpacingOneHalf,
        LineSpacing.double => l10n.compileSpacingDouble,
      };

  String _indentLabel(AppLocalizations l10n, IndentChoice v) => switch (v) {
        IndentChoice.keep => l10n.compileKeep,
        IndentChoice.on => l10n.compileIndentOn,
        IndentChoice.off => l10n.compileIndentOff,
      };

  String _headersLabel(AppLocalizations l10n, HeaderMode v) => switch (v) {
        HeaderMode.keep => l10n.compileKeep,
        HeaderMode.none => l10n.compileHeadersNone,
        HeaderMode.manuscript => l10n.compileHeadersManuscript,
        HeaderMode.book => l10n.compileHeadersBook,
      };

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

    Widget toggle(String label, bool value, ValueChanged<bool>? onChanged) => Padding(
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

    Widget drop<T>(String label, String text, List<WDropdownItem<T>> items, ValueChanged<T> onSelected) => Padding(
          padding: EdgeInsets.only(bottom: t.space.sm),
          child: Row(children: [
            SizedBox(width: 160, child: WLabel(label)),
            WDropdown<T>(label: label, width: 300, text: text, items: items, onSelected: running ? null : onSelected),
          ]),
        );

    final modelSettings = _model == null ? null : _store.settingsOf(_model!);
    final modelText = modelSettings != null && !_settings.sameModel(modelSettings)
        ? l10n.compileModelChanged(_modelLabel(l10n, _model))
        : _modelLabel(l10n, _model);
    final ownModel = _model != null && _store.named(_model!) != null;
    String keepOr(bool keep, String text) => keep ? l10n.compileKeep : text;
    final st = _style;

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
            SizedBox(width: 160, child: WLabel(l10n.compileModel)),
            WDropdown<String?>(
              label: l10n.compileModel,
              width: 220,
              text: modelText,
              items: [
                WDropdownItem(null, l10n.compileModelNone),
                for (final b in BuiltInModel.values) WDropdownItem(b.id, _modelLabel(l10n, b.id)),
                for (final m in _store.models) WDropdownItem(m.name, m.name),
              ],
              onSelected: _chooseModel,
            ),
          ]),
          Wrap(alignment: WrapAlignment.end, children: [
            TextButton(onPressed: () => unawaited(_saveModel()), child: Text(l10n.compileModelSave)),
            if (ownModel) ...[
              TextButton(onPressed: () => unawaited(_renameModel()), child: Text(l10n.compileModelRename)),
              TextButton(onPressed: _deleteModel, child: Text(l10n.compileModelDelete)),
            ],
          ]),
          SizedBox(height: t.space.md),
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
          toggle(l10n.compileFigures, _figures, (v) => setState(() => _figures = v)),
          // O EPUB não tem páginas para o índice remissivo.
          toggle(l10n.compileIndex, _index && _format != CompileFormat.epub,
              _format == CompileFormat.epub ? null : (v) => setState(() => _index = v)),
          if (_figures || _index) WLabel(l10n.compileReferencesNote, small: true, tone: WLabelTone.muted),
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
          SizedBox(height: t.space.lg),
          Semantics(header: true, child: WLabel(l10n.compileLook, heading: true)),
          SizedBox(height: t.space.sm),
          drop<PageChoice>(
            l10n.compilePage,
            _pageLabel(l10n, st.page),
            [for (final p in PageChoice.values) WDropdownItem(p, _pageLabel(l10n, p))],
            (v) => setState(() => _style = _style.copyWith(page: v)),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: t.space.sm),
            child: Row(children: [
              SizedBox(width: 160, child: WLabel(l10n.compileFont)),
              SizedBox(
                width: 300,
                child: IgnorePointer(
                  ignoring: running,
                  child: WTextField(label: l10n.compileFont, hint: l10n.compileKeep, controller: _font, onChanged: (_) => setState(() {})),
                ),
              ),
            ]),
          ),
          drop<int>(
            l10n.compileFontSize,
            keepOr(st.fontSize == 0, l10n.compileFontSizePt(st.fontSize)),
            [for (final n in const [0, 10, 11, 12, 13, 14]) WDropdownItem(n, keepOr(n == 0, l10n.compileFontSizePt(n)))],
            (v) => setState(() => _style = _style.copyWith(fontSize: v)),
          ),
          drop<LineSpacing>(
            l10n.compileSpacing,
            _spacingLabel(l10n, st.spacing),
            [for (final v in LineSpacing.values) WDropdownItem(v, _spacingLabel(l10n, v))],
            (v) => setState(() => _style = _style.copyWith(spacing: v)),
          ),
          drop<IndentChoice>(
            l10n.compileIndent,
            _indentLabel(l10n, st.indent),
            [for (final v in IndentChoice.values) WDropdownItem(v, _indentLabel(l10n, v))],
            (v) => setState(() => _style = _style.copyWith(indent: v)),
          ),
          drop<HeaderMode>(
            l10n.compileHeaders,
            _headersLabel(l10n, st.headers),
            [for (final v in HeaderMode.values) WDropdownItem(v, _headersLabel(l10n, v))],
            (v) => setState(() => _style = _style.copyWith(headers: v)),
          ),
          toggle(l10n.compileRightPage, st.rightPage, (v) => setState(() => _style = _style.copyWith(rightPage: v))),
          Row(children: [
            SizedBox(width: 160, child: WLabel(l10n.compileCover)),
            Expanded(
              child: WLabel(
                _cover.isEmpty ? l10n.compileCoverNone : _cover.split('/').last,
                tone: _cover.isEmpty ? WLabelTone.muted : WLabelTone.normal,
              ),
            ),
            TextButton(onPressed: running ? null : () => unawaited(_pickCover()), child: Text(l10n.compileCoverPick)),
            if (_cover.isNotEmpty)
              TextButton(onPressed: running ? null : () => setState(() => _cover = ''), child: Text(l10n.compileCoverRemove)),
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

/// O nome de um modelo, para salvar ou renomear.
class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.title, required this.initial});
  final String title, initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _name = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _ok() {
    final name = _name.text.trim();
    if (name.isNotEmpty) Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 360,
        child: WTextField(label: l10n.compileModelName, controller: _name, autofocus: true, onSubmitted: (_) => _ok()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.dialogCancel)),
        FilledButton(onPressed: _ok, child: Text(l10n.compileModelOk)),
      ],
    );
  }
}
