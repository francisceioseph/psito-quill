// As janelas das referências (D-090): os marcadores (um novo, ir, apagar) e
// a referência cruzada (a um título, a um marcador, a uma legenda).
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../document/outline.dart';
import '../../document/references.dart';
import '../atoms/w_button.dart';
import '../atoms/w_label.dart';
import '../atoms/w_segmented.dart';
import '../atoms/w_text_field.dart';
import '../tokens/tokens.dart';

/// O que a janela dos marcadores pede: um novo com o nome, ou ir a um.
enum BookmarkVerb { insert, go }

/// [onDelete] apaga na hora (a janela continua aberta, sem ele na lista).
Future<(BookmarkVerb, String)?> showBookmarkDialog(
  BuildContext context, {
  required List<String> bookmarks,
  required ValueChanged<String> onDelete,
  bool canEdit = true,
}) =>
    showDialog<(BookmarkVerb, String)>(
      context: context,
      builder: (_) => _BookmarkDialog(bookmarks: bookmarks, onDelete: onDelete, canEdit: canEdit),
    );

class _BookmarkDialog extends StatefulWidget {
  const _BookmarkDialog({required this.bookmarks, required this.onDelete, required this.canEdit});
  final List<String> bookmarks;
  final ValueChanged<String> onDelete;
  final bool canEdit;

  @override
  State<_BookmarkDialog> createState() => _BookmarkDialogState();
}

class _BookmarkDialogState extends State<_BookmarkDialog> {
  final _name = TextEditingController();
  late final _list = [...widget.bookmarks];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  BookmarkNameProblem? get _problem => bookmarkNameProblem(_name.text, _list);

  void _insert() {
    if (!widget.canEdit || _problem != null) return;
    Navigator.pop(context, (BookmarkVerb.insert, _name.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = QuillTokens.of(context);
    final problem = _name.text.isEmpty ? null : _problem;
    return AlertDialog(
      title: Text(l10n.bookmarkDialogTitle),
      content: SizedBox(
        width: 420,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (widget.canEdit) ...[
            WLabel(l10n.bookmarkName, small: true, tone: WLabelTone.muted),
            SizedBox(height: t.space.xs),
            WTextField(
              label: l10n.bookmarkName,
              controller: _name,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _insert(),
            ),
            if (problem != null) ...[
              SizedBox(height: t.space.xs),
              WLabel(
                switch (problem) {
                  BookmarkNameProblem.empty => l10n.bookmarkName,
                  BookmarkNameProblem.characters => l10n.bookmarkBadName,
                  BookmarkNameProblem.exists => l10n.bookmarkExists,
                },
                small: true,
                tone: WLabelTone.danger,
              ),
            ],
            SizedBox(height: t.space.md),
          ],
          WLabel(l10n.bookmarkListTitle, small: true, tone: WLabelTone.muted),
          SizedBox(height: t.space.xs),
          if (_list.isEmpty)
            WLabel(l10n.bookmarkNone, small: true, tone: WLabelTone.muted)
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView(shrinkWrap: true, children: [
                for (final b in _list)
                  Row(children: [
                    Expanded(child: WLabel(b, maxLines: 1)),
                    WButton(
                      icon: Symbols.arrow_forward_rounded,
                      label: l10n.bookmarkGo(b),
                      onPressed: () => Navigator.pop(context, (BookmarkVerb.go, b)),
                    ),
                    if (widget.canEdit)
                      WButton(
                        icon: Symbols.delete_rounded,
                        label: l10n.bookmarkDelete(b),
                        onPressed: () {
                          widget.onDelete(b);
                          setState(() => _list.remove(b));
                        },
                      ),
                  ]),
              ]),
            ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.dialogCancel)),
        if (widget.canEdit)
          FilledButton(onPressed: _problem == null ? _insert : null, child: Text(l10n.bookmarkInsert)),
      ],
    );
  }
}

/// A que a referência aponta.
sealed class CrossRefTarget {
  const CrossRefTarget();
}

/// O título [index] da Estrutura.
class HeadingTarget extends CrossRefTarget {
  const HeadingTarget(this.index);
  final int index;
}

class BookmarkTarget extends CrossRefTarget {
  const BookmarkTarget(this.name);
  final String name;
}

class CaptionTarget extends CrossRefTarget {
  const CaptionTarget(this.caption);
  final CaptionEntry caption;
}

enum _RefKind { heading, bookmark, caption }

/// [otherBookmarks]: os marcadores dos outros capítulos do livro (o nome do
/// capítulo e o do marcador), que chegam depois; null fora de um livro.
Future<(CrossRefTarget, RefFormat)?> showCrossRefDialog(
  BuildContext context, {
  required List<OutlineEntry> headings,
  required List<String> bookmarks,
  required List<CaptionEntry> captions,
  Future<List<(String, String)>>? otherBookmarks,
}) =>
    showDialog<(CrossRefTarget, RefFormat)>(
      context: context,
      builder: (_) => _CrossRefDialog(
        headings: headings,
        bookmarks: bookmarks,
        captions: captions,
        otherBookmarks: otherBookmarks,
      ),
    );

class _CrossRefDialog extends StatefulWidget {
  const _CrossRefDialog({required this.headings, required this.bookmarks, required this.captions, this.otherBookmarks});
  final List<OutlineEntry> headings;
  final List<String> bookmarks;
  final List<CaptionEntry> captions;
  final Future<List<(String, String)>>? otherBookmarks;

  @override
  State<_CrossRefDialog> createState() => _CrossRefDialogState();
}

class _CrossRefDialogState extends State<_CrossRefDialog> {
  _RefKind _kind = _RefKind.heading;
  RefFormat _format = RefFormat.text;
  int? _selected;
  List<(String, String)> _others = const [];

  @override
  void initState() {
    super.initState();
    if (widget.headings.isEmpty) {
      _kind = widget.bookmarks.isNotEmpty ? _RefKind.bookmark : (widget.captions.isNotEmpty ? _RefKind.caption : _kind);
    }
    widget.otherBookmarks?.then((list) {
      if (mounted) setState(() => _others = list);
    });
  }

  /// Os itens da lista: o rótulo e o alvo.
  List<(String, CrossRefTarget)> _items(AppLocalizations l10n) => switch (_kind) {
        _RefKind.heading => [
            for (final (i, h) in widget.headings.indexed) ('${'  ' * (h.level - 1)}${h.text}', HeadingTarget(i)),
          ],
        _RefKind.bookmark => [
            for (final b in widget.bookmarks) (b, BookmarkTarget(b)),
            for (final (chapter, b) in _others)
              if (!widget.bookmarks.contains(b)) (l10n.crossRefOtherChapter(b, chapter), BookmarkTarget(b)),
          ],
        _RefKind.caption => [for (final c in widget.captions) (c.text, CaptionTarget(c))],
      };

  void _insert(List<(String, CrossRefTarget)> items) {
    final i = _selected;
    if (i == null || i >= items.length) return;
    Navigator.pop(context, (items[i].$2, _format));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = QuillTokens.of(context);
    final items = _items(l10n);
    return AlertDialog(
      title: Text(l10n.crossRefTitle),
      content: SizedBox(
        width: 460,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          WSegmented<_RefKind>(
            label: l10n.crossRefKind,
            expanded: true,
            segments: [
              WSegment(_RefKind.heading, l10n.crossRefHeadings),
              WSegment(_RefKind.bookmark, l10n.crossRefBookmarks),
              WSegment(_RefKind.caption, l10n.crossRefCaptions),
            ],
            selected: _kind,
            onChanged: (k) => setState(() {
              _kind = k;
              _selected = null;
            }),
          ),
          SizedBox(height: t.space.md),
          SizedBox(
            height: 240,
            child: items.isEmpty
                ? Align(
                    alignment: Alignment.topLeft,
                    child: WLabel(
                      switch (_kind) {
                        _RefKind.heading => l10n.crossRefNoHeadings,
                        _RefKind.bookmark => l10n.bookmarkNone,
                        _RefKind.caption => l10n.crossRefNoCaptions,
                      },
                      small: true,
                      tone: WLabelTone.muted,
                    ),
                  )
                : ListView(children: [
                    for (final (i, (label, _)) in items.indexed)
                      WTextButton(
                        label: label,
                        pill: false,
                        selected: _selected == i,
                        onPressed: () => setState(() => _selected = i),
                      ),
                  ]),
          ),
          SizedBox(height: t.space.md),
          WLabel(l10n.crossRefInsertAs, small: true, tone: WLabelTone.muted),
          SizedBox(height: t.space.xs),
          WSegmented<RefFormat>(
            label: l10n.crossRefInsertAs,
            expanded: true,
            segments: [
              WSegment(RefFormat.text, _kind == _RefKind.caption ? l10n.crossRefFormatCaption : l10n.crossRefFormatText),
              WSegment(RefFormat.page, l10n.crossRefFormatPage),
              WSegment(RefFormat.aboveBelow, l10n.crossRefFormatAboveBelow),
            ],
            selected: _format,
            onChanged: (f) => setState(() => _format = f),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.dialogCancel)),
        FilledButton(onPressed: _selected == null ? null : () => _insert(items), child: Text(l10n.crossRefInsert)),
      ],
    );
  }
}
