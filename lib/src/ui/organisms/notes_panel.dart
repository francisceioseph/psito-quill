// O painel Notas (Fase 3, Etapa 8, D-082): as notas do livro, à esquerda.
//
// Duas vistas no mesmo painel: a lista (a busca, os tipos e as notas, que
// monta só as linhas visíveis) e a nota aberta (o nome, o tipo, os apelidos
// e o texto). O texto é Markdown simples num campo do Flutter, sem o motor:
// os `[[Nome]]` ficam destacados, e embaixo vêm as ligações (o clique abre a
// nota ou o capítulo; uma que não existe, cria) e as notas que mencionam
// esta. Uma linha do tempo mostra também os eventos, em ordem.
//
// Grava sozinho, 1 s depois da última tecla, e ao voltar à lista ou fechar
// o painel. A lista é lida quando o painel abre e solta quando ele fecha.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../book/book.dart';
import '../../book/notes.dart';
import '../atoms/w_button.dart';
import '../atoms/w_chip.dart';
import '../atoms/w_dropdown.dart';
import '../atoms/w_label.dart';
import '../atoms/w_segmented.dart';
import '../atoms/w_text_field.dart';
import '../molecules/side_panel.dart';
import '../tokens/tokens.dart';

String noteKindLabel(AppLocalizations l10n, NoteKind k) => switch (k) {
      NoteKind.character => l10n.noteKindCharacter,
      NoteKind.place => l10n.noteKindPlace,
      NoteKind.faction => l10n.noteKindFaction,
      NoteKind.term => l10n.noteKindTerm,
      NoteKind.timeline => l10n.noteKindTimeline,
    };

/// O plural, para os filtros ("Personagens").
String noteKindPlural(AppLocalizations l10n, NoteKind k) => switch (k) {
      NoteKind.character => l10n.noteKindCharacters,
      NoteKind.place => l10n.noteKindPlaces,
      NoteKind.faction => l10n.noteKindFactions,
      NoteKind.term => l10n.noteKindTerms,
      NoteKind.timeline => l10n.noteKindTimeline,
    };

IconData noteKindIcon(NoteKind k) => switch (k) {
      NoteKind.character => Symbols.person_rounded,
      NoteKind.place => Symbols.location_on_rounded,
      NoteKind.faction => Symbols.groups_rounded,
      NoteKind.term => Symbols.menu_book_rounded,
      NoteKind.timeline => Symbols.timeline_rounded,
    };

/// O campo do texto de uma nota: os `[[...]]` em destaque.
class NoteTextController extends TextEditingController {
  NoteTextController();

  TextStyle? linkStyle;

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    final link = linkStyle;
    // Durante a pré-edição do IME, o desenho de sempre (o sublinhado dela).
    if (link == null || (withComposing && value.isComposingRangeValid)) {
      return super.buildTextSpan(context: context, style: style, withComposing: withComposing);
    }
    final spans = <TextSpan>[];
    var at = 0;
    for (final (s, e) in noteLinkRanges(text)) {
      if (s > at) spans.add(TextSpan(text: text.substring(at, s)));
      spans.add(TextSpan(text: text.substring(s, e), style: link));
      at = e;
    }
    if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
    return TextSpan(style: style, children: spans);
  }
}

class NotesPanel extends StatefulWidget {
  const NotesPanel({
    super.key,
    required this.bookDir,
    required this.chapters,
    required this.onOpenChapter,
    required this.onClose,
    required this.closeLabel,
  });

  final String bookDir;

  /// Os capítulos do livro: um `[[Título]]` também liga a eles.
  final List<BookNode> Function() chapters;
  final ValueChanged<BookNode> onOpenChapter;
  final VoidCallback onClose;
  final String closeLabel;

  @override
  State<NotesPanel> createState() => NotesPanelState();
}

class NotesPanelState extends State<NotesPanel> {
  late List<Note> _notes = listNotes(widget.bookDir);
  final _query = TextEditingController();
  NoteKind? _filter;

  /// A nota aberta (o que está no disco, ou o último gravado).
  Note? _open;
  final _name = TextEditingController();
  final _aliases = TextEditingController();
  final _body = NoteTextController();
  final _nameFocus = FocusNode(debugLabel: 'nome da nota');
  NoteKind _kind = NoteKind.character;
  bool _timelineView = false;
  Timer? _save;

  /// A nota aberta, para os testes.
  Note? get openNote => _open;

  @override
  void didUpdateWidget(NotesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookDir != widget.bookDir) {
      _flush();
      _open = null;
      _notes = listNotes(widget.bookDir);
    }
  }

  @override
  void dispose() {
    _flush();
    _query.dispose();
    _name.dispose();
    _aliases.dispose();
    _body.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _changed() {
    _save?.cancel();
    _save = Timer(const Duration(seconds: 1), () {
      _flush();
      if (mounted) setState(() {});
    });
  }

  /// Grava a nota aberta, se mudou.
  void _flush() {
    _save?.cancel();
    _save = null;
    final open = _open;
    if (open == null) return;
    final name = _name.text.trim();
    final next = open.copyWith(
      name: name.isEmpty ? open.name : name,
      kind: _kind,
      aliases: splitAliases(_aliases.text),
      body: _body.text,
    );
    if (formatNote(next) == formatNote(open)) return;
    try {
      writeNote(widget.bookDir, next);
    } on FileSystemException {
      return;
    }
    _open = next;
    final i = _notes.indexWhere((n) => n.file == next.file);
    _notes = [..._notes];
    if (i >= 0) {
      _notes[i] = next;
    } else {
      _notes.add(next);
    }
    _notes.sort((a, b) => foldName(a.name).compareTo(foldName(b.name)));
  }

  void _show(Note n, {bool focusName = false}) {
    _flush();
    setState(() {
      _open = n;
      _name.text = n.name;
      _aliases.text = n.aliases.join(', ');
      _body.text = n.body;
      _kind = n.kind;
      _timelineView = n.kind == NoteKind.timeline && timelineEvents(n.body).isNotEmpty;
    });
    if (focusName) {
      _name.selection = TextSelection(baseOffset: 0, extentOffset: _name.text.length);
      _nameFocus.requestFocus();
    }
  }

  /// Abre a nota chamada [name] (pelo nome ou apelido), se existe.
  bool openByName(String name) {
    final n = findNote(_notes, name);
    if (n == null) return false;
    _show(n);
    return true;
  }

  void _back() {
    _flush();
    setState(() => _open = null);
  }

  void _create(String name, NoteKind kind, {bool focusName = false}) {
    _flush();
    final Note n;
    try {
      n = createNote(widget.bookDir, name, kind);
    } on FileSystemException {
      return;
    }
    _notes = listNotes(widget.bookDir);
    _show(n, focusName: focusName);
  }

  /// Uma nota nova: com o nome da busca, ou "Nova nota", e o tipo do filtro.
  void newNote() {
    final l10n = AppLocalizations.of(context);
    final q = _query.text.trim();
    _create(q.isEmpty ? l10n.noteNewName : q, _filter ?? NoteKind.character, focusName: true);
  }

  Future<void> _delete() async {
    final open = _open;
    if (open == null) return;
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.noteDeleteTitle),
        content: SizedBox(width: 420, child: Text(l10n.noteDeleteBody(open.name))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.dialogCancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.binderDelete)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    _save?.cancel();
    _save = null;
    try {
      removeNote(widget.bookDir, open.file);
    } on FileSystemException {
      // Some da lista mesmo assim, na próxima leitura.
    }
    setState(() {
      _open = null;
      _notes = listNotes(widget.bookDir);
    });
  }

  BookNode? _chapterNamed(String name) {
    final key = foldName(name);
    for (final c in widget.chapters()) {
      if (foldName(c.title) == key) return c;
    }
    return null;
  }

  void _follow(String link) {
    _flush();
    if (openByName(link)) return;
    final chapter = _chapterNamed(link);
    if (chapter != null) {
      widget.onOpenChapter(chapter);
      return;
    }
    _create(link, NoteKind.character);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final open = _open;
    return SidePanel(
      title: l10n.notesTitle,
      closeLabel: widget.closeLabel,
      onClose: widget.onClose,
      side: AxisDirection.left,
      width: 320,
      child: open == null ? _list(context) : _editor(context, open),
    );
  }

  Widget _list(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = QuillTokens.of(context);
    final q = _query.text;
    final shown = [
      for (final n in _notes)
        if ((_filter == null || n.kind == _filter) && noteMatches(n, q)) n,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Expanded(
            child: WTextField(
              label: l10n.notesSearch,
              controller: _query,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) {
                if (shown.isNotEmpty) _show(shown.first);
              },
            ),
          ),
          WButton(icon: Symbols.note_stack_add_rounded, label: l10n.commandNewNote, onPressed: newNote),
        ]),
        SizedBox(height: t.space.sm),
        Wrap(
          spacing: t.space.xs,
          runSpacing: t.space.xs,
          children: [
            WChip(label: l10n.notesAll, selected: _filter == null, onPressed: () => setState(() => _filter = null)),
            for (final k in NoteKind.values)
              WChip(
                label: noteKindPlural(l10n, k),
                icon: noteKindIcon(k),
                selected: _filter == k,
                onPressed: () => setState(() => _filter = _filter == k ? null : k),
              ),
          ],
        ),
        SizedBox(height: t.space.md),
        Expanded(
          child: shown.isEmpty
              ? WLabel(_notes.isEmpty ? l10n.notesEmpty : l10n.notesNoMatch, tone: WLabelTone.muted, maxLines: 4)
              : Semantics(
                  container: true,
                  label: l10n.notesTitle,
                  child: ListView.builder(
                    itemCount: shown.length,
                    itemExtent: t.density.control * 1.5 + t.space.xs,
                    itemBuilder: (context, i) => _NoteRow(note: shown[i], onTap: () => _show(shown[i])),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _editor(BuildContext context, Note open) {
    final l10n = AppLocalizations.of(context);
    final t = QuillTokens.of(context);
    _body.linkStyle = TextStyle(color: t.colors.accent, fontWeight: FontWeight.w600);
    final links = noteLinks(_body.text);
    final mentions = mentionsOf(_notes, open.copyWith(name: _name.text.trim(), aliases: splitAliases(_aliases.text)));
    final timeline = _kind == NoteKind.timeline;
    final events = timeline && _timelineView ? timelineEvents(_body.text) : const <TimelineEvent>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          WButton(icon: Symbols.arrow_back_rounded, label: l10n.notesBack, onPressed: _back),
          Expanded(child: WLabel(noteKindLabel(l10n, _kind), tone: WLabelTone.muted, small: true)),
          WButton(icon: Symbols.delete_rounded, label: l10n.noteDelete, onPressed: () => unawaited(_delete())),
        ]),
        SizedBox(height: t.space.sm),
        WTextField(label: l10n.noteName, controller: _name, focusNode: _nameFocus, onChanged: (_) => _changed()),
        SizedBox(height: t.space.sm),
        Row(children: [
          WDropdown<NoteKind>(
            label: l10n.noteKind,
            text: noteKindLabel(l10n, _kind),
            width: 140,
            items: [for (final k in NoteKind.values) WDropdownItem(k, noteKindLabel(l10n, k))],
            onSelected: (k) {
              setState(() => _kind = k);
              _changed();
            },
          ),
          SizedBox(width: t.space.sm),
          Expanded(
            child: WTextField(
              label: l10n.noteAliases,
              hint: l10n.noteAliasesHint,
              controller: _aliases,
              onChanged: (_) => _changed(),
            ),
          ),
        ]),
        if (timeline) ...[
          SizedBox(height: t.space.sm),
          WSegmented<bool>(
            label: l10n.noteKindTimeline,
            expanded: true,
            segments: [WSegment(false, l10n.noteText), WSegment(true, l10n.noteKindTimeline)],
            selected: _timelineView,
            onChanged: (v) => setState(() => _timelineView = v),
          ),
        ],
        SizedBox(height: t.space.sm),
        Expanded(
          child: timeline && _timelineView
              ? _timeline(context, events)
              : WTextField(
                  label: l10n.noteText,
                  hint: l10n.noteTextHint,
                  controller: _body,
                  expands: true,
                  onChanged: (_) {
                    _changed();
                    // As ligações embaixo seguem o texto.
                    setState(() {});
                  },
                ),
        ),
        if (links.isNotEmpty || mentions.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 160),
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (links.isNotEmpty) ...[
                  SizedBox(height: t.space.md),
                  WLabel(l10n.noteLinks, small: true, tone: WLabelTone.muted),
                  SizedBox(height: t.space.xs),
                  Wrap(spacing: t.space.xs, runSpacing: t.space.xs, children: [
                    for (final l in links) _linkChip(l10n, l),
                  ]),
                ],
                if (mentions.isNotEmpty) ...[
                  SizedBox(height: t.space.md),
                  WLabel(l10n.noteMentions, small: true, tone: WLabelTone.muted),
                  SizedBox(height: t.space.xs),
                  Wrap(spacing: t.space.xs, runSpacing: t.space.xs, children: [
                    for (final m in mentions)
                      WChip(label: m.name, icon: noteKindIcon(m.kind), onPressed: () => _show(m)),
                  ]),
                ],
              ]),
            ),
          ),
      ],
    );
  }

  Widget _linkChip(AppLocalizations l10n, String link) {
    final note = findNote(_notes, link);
    if (note != null) return WChip(label: link, icon: noteKindIcon(note.kind), onPressed: () => _follow(link));
    if (_chapterNamed(link) != null) return WChip(label: link, icon: Symbols.article_rounded, onPressed: () => _follow(link));
    return WChip(label: l10n.noteCreateLink(link), icon: Symbols.add_rounded, onPressed: () => _follow(link));
  }

  Widget _timeline(BuildContext context, List<TimelineEvent> events) {
    final l10n = AppLocalizations.of(context);
    final t = QuillTokens.of(context);
    if (events.isEmpty) return WLabel(l10n.noteTimelineEmpty, tone: WLabelTone.muted, maxLines: 5);
    return Semantics(
      container: true,
      label: l10n.noteKindTimeline,
      child: ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, i) {
          final e = events[i];
          return Padding(
            padding: EdgeInsets.symmetric(vertical: t.space.xs),
            child: MergeSemantics(
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: EdgeInsets.only(top: t.space.xs, right: t.space.sm),
                  child: Icon(Symbols.circle, size: 10, fill: 1, color: t.colors.accent),
                ),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    WLabel(e.when, small: true, tone: WLabelTone.muted),
                    WLabel(e.text, maxLines: 4),
                  ]),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class _NoteRow extends StatefulWidget {
  const _NoteRow({required this.note, required this.onTap});
  final Note note;
  final VoidCallback onTap;

  @override
  State<_NoteRow> createState() => _NoteRowState();
}

class _NoteRowState extends State<_NoteRow> {
  bool _hover = false, _focused = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = QuillTokens.of(context);
    final c = t.colors;
    final n = widget.note;
    final aliases = n.aliases.join(', ');
    return Semantics(
      container: true,
      button: true,
      label: '${n.name}, ${noteKindLabel(l10n, n.kind)}${aliases.isEmpty ? '' : ', $aliases'}',
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
            widget.onTap();
            return null;
          }),
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: ExcludeSemantics(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: t.space.sm),
              decoration: BoxDecoration(
                color: _hover ? c.surfaceHigh : null,
                borderRadius: BorderRadius.circular(t.radius.control),
                border: _focused ? Border.all(color: c.focusRing, width: 2) : null,
              ),
              child: Row(children: [
                Icon(noteKindIcon(n.kind), size: t.density.icon, color: c.onFrameMuted),
                SizedBox(width: t.space.sm),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      WLabel(n.name),
                      if (aliases.isNotEmpty) WLabel(aliases, small: true, tone: WLabelTone.muted),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
