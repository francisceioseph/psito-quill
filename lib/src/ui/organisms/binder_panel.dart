// O fichário (Fase 3, Etapa 1, D-071): a árvore do livro, à esquerda.
//
// Partes e capítulos numa lista só, recuada pela parte, que monta só as
// linhas visíveis (um livro tem dezenas de capítulos). O clique abre o
// capítulo numa aba; arrastar reordena; pelo teclado, as setas andam,
// Alt+setas movem, Enter abre, F2 renomeia e Delete manda para a lixeira.
// Embaixo, o item escolhido: o status, o rótulo e a sinopse.
//
// O painel é memoizado pela `revision` do livro (D-037): ele só se refaz
// quando o livro muda, nunca a cada tecla no capítulo.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../book/book.dart';
import '../../book/book_controller.dart';
import '../atoms/w_button.dart';
import '../atoms/w_color_swatch.dart';
import '../atoms/w_label.dart';
import '../atoms/w_segmented.dart';
import '../atoms/w_text_field.dart';
import '../molecules/side_panel.dart';
import '../tokens/tokens.dart';

/// Os nomes dos rótulos, na ordem dos `labels` do tema.
List<String> labelNames(AppLocalizations l10n) =>
    [l10n.labelRed, l10n.labelOrange, l10n.labelGreen, l10n.labelBlue, l10n.labelPurple];

String chapterStatusLabel(AppLocalizations l10n, ChapterStatus s) => switch (s) {
      ChapterStatus.draft => l10n.chapterStatusDraft,
      ChapterStatus.revision => l10n.chapterStatusRevision,
      ChapterStatus.done => l10n.chapterStatusDone,
    };

/// Uma linha do fichário: o nó e a parte em que está.
typedef BinderRow = ({BookNode node, BookNode? part});

/// A árvore como lista, na ordem do livro.
List<BinderRow> binderRows(Book book) => [
      for (final n in book.nodes) ...[
        (node: n, part: null),
        for (final c in n.children) (node: c, part: n),
      ],
    ];

/// Onde cai o item [from] solto na posição [to] da lista (a do
/// `ReorderableListView`, contada antes de tirar o item): a parte (null, o
/// primeiro nível) e o índice nela, também contado antes de tirar o item
/// (como o `BookController.move`). Um capítulo solto logo abaixo de uma
/// parte entra nela; uma parte vai sempre para o primeiro nível.
({String? partId, int index}) binderDrop(Book book, List<BinderRow> rows, int from, int to) {
  final moving = rows[from].node;
  bool skip(int i) => i == from || (moving.isPart && rows[i].part == moving);
  // A linha logo acima de onde o item cai, sem ele (nem os filhos dele).
  BinderRow? above;
  for (var i = to - 1; i >= 0; i--) {
    if (i < rows.length && !skip(i)) {
      above = rows[i];
      break;
    }
  }
  if (above == null) return (partId: null, index: 0);
  if (moving.isPart) return (partId: null, index: book.nodes.indexOf(above.part ?? above.node) + 1);
  if (above.node.isPart) return (partId: above.node.id, index: 0);
  if (above.part != null) return (partId: above.part!.id, index: above.part!.children.indexOf(above.node) + 1);
  return (partId: null, index: book.nodes.indexOf(above.node) + 1);
}

class BinderPanel extends StatefulWidget {
  const BinderPanel({
    super.key,
    required this.books,
    required this.currentPath,
    required this.onOpen,
    required this.onNewChapter,
    required this.onNewPart,
    required this.onClose,
    required this.closeLabel,
  });

  final BookController books;

  /// O arquivo do documento da tela (o capítulo marcado).
  final String? currentPath;
  final ValueChanged<BookNode> onOpen;
  final VoidCallback onNewChapter, onNewPart, onClose;
  final String closeLabel;

  @override
  State<BinderPanel> createState() => _BinderPanelState();
}

class _BinderPanelState extends State<BinderPanel> {
  String? _selected;
  String? _renaming;
  final _renameText = TextEditingController();
  final _synopsis = TextEditingController();
  String? _synopsisFor;
  Timer? _synopsisSave;

  BookController get books => widget.books;

  @override
  void dispose() {
    _flushSynopsis();
    for (final f in _focusNodes.values) {
      f.dispose();
    }
    _renameText.dispose();
    _synopsis.dispose();
    super.dispose();
  }

  void _flushSynopsis() {
    _synopsisSave?.cancel();
    _synopsisSave = null;
    final id = _synopsisFor;
    if (id != null) books.setSynopsis(id, _synopsis.text);
  }

  void _select(BookNode n) {
    if (_selected == n.id) return;
    _flushSynopsis();
    setState(() => _selected = n.id);
  }

  void _activate(BookNode n) {
    _select(n);
    if (!n.isPart) widget.onOpen(n);
  }

  void _startRename(BookNode n) {
    _renameText.text = n.title;
    _renameText.selection = TextSelection(baseOffset: 0, extentOffset: n.title.length);
    setState(() {
      _selected = n.id;
      _renaming = n.id;
    });
  }

  void _endRename({required bool keep}) {
    final id = _renaming;
    if (id == null) return;
    if (keep) books.rename(id, _renameText.text);
    setState(() => _renaming = null);
  }

  Future<void> _remove(BookNode n) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.binderDeleteTitle),
        content: Text(n.isPart ? l10n.binderDeletePart(n.title) : l10n.binderDeleteChapter(n.title)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.dialogCancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.binderDelete)),
        ],
      ),
    );
    if (ok == true) {
      if (_selected == n.id) _selected = null;
      books.remove(n.id);
    }
  }

  Future<void> _menu(BookNode n, Offset at) async {
    final l10n = AppLocalizations.of(context);
    _select(n);
    final box = Overlay.of(context).context.findRenderObject() as RenderBox;
    final choice = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(at & const Size(1, 1), Offset.zero & box.size),
      items: [
        if (!n.isPart) PopupMenuItem(value: 'open', child: Text(l10n.binderOpen)),
        PopupMenuItem(value: 'rename', child: Text(l10n.binderRename)),
        PopupMenuItem(value: 'delete', child: Text(l10n.binderDelete)),
      ],
    );
    switch (choice) {
      case 'open':
        widget.onOpen(n);
      case 'rename':
        _startRename(n);
      case 'delete':
        await _remove(n);
    }
  }

  KeyEventResult _onRowKey(BookNode n, FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    if (_renaming == n.id) return KeyEventResult.ignored;
    final alt = HardwareKeyboard.instance.isAltPressed;
    final key = e.logicalKey;
    if (alt && (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.arrowDown)) {
      books.nudge(n.id, up: key == LogicalKeyboardKey.arrowUp);
      // A linha muda de lugar: o foco vai com ela no próximo quadro.
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusOf(n.id)?.requestFocus());
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.arrowDown) {
      node.focusInDirection(key == LogicalKeyboardKey.arrowUp ? TraversalDirection.up : TraversalDirection.down);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      _activate(n);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.f2) {
      _startRename(n);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.delete) {
      unawaited(_remove(n));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.contextMenu || (key == LogicalKeyboardKey.f10 && HardwareKeyboard.instance.isShiftPressed)) {
      final box = node.context?.findRenderObject() as RenderBox?;
      unawaited(_menu(n, box == null ? Offset.zero : box.localToGlobal(box.size.centerLeft(Offset.zero))));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  final _focusNodes = <String, FocusNode>{};
  FocusNode? _focusOf(String id) => _focusNodes[id];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = QuillTokens.of(context);
    final book = books.book;
    if (book == null) return const SizedBox.shrink();
    final rows = binderRows(book);
    // Os nós de foco só das linhas que existem.
    final ids = {for (final r in rows) r.node.id};
    _focusNodes.removeWhere((id, f) {
      if (ids.contains(id)) return false;
      f.dispose();
      return true;
    });
    final selected = _selected == null ? null : book.find(_selected!)?.$1;
    if (selected?.id != _synopsisFor) {
      _synopsisFor = selected?.id;
      _synopsis.text = selected?.synopsis ?? '';
    }
    return SidePanel(
      title: book.title.isEmpty ? l10n.binderTitle : book.title,
      closeLabel: widget.closeLabel,
      onClose: widget.onClose,
      side: AxisDirection.left,
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: WLabel(l10n.binderWords(book.words), tone: WLabelTone.muted, small: true)),
              WButton(icon: Symbols.note_add_rounded, label: l10n.commandNewChapter, onPressed: widget.onNewChapter),
              WButton(icon: Symbols.create_new_folder_rounded, label: l10n.commandNewPart, onPressed: widget.onNewPart),
            ],
          ),
          SizedBox(height: t.space.sm),
          Expanded(
            child: rows.isEmpty
                ? WLabel(l10n.binderEmpty, tone: WLabelTone.muted, maxLines: 3)
                : Semantics(
                    container: true,
                    label: l10n.binderTitle,
                    child: ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      itemCount: rows.length,
                      itemExtent: t.density.control + t.space.xs,
                      // O índice novo já desconta o item tirado; o binderDrop
                      // conta antes de tirar.
                      onReorderItem: (from, after) {
                        final drop = binderDrop(book, rows, from, after >= from ? after + 1 : after);
                        books.move(rows[from].node.id, partId: drop.partId, index: drop.index);
                      },
                      itemBuilder: (context, i) {
                        final r = rows[i];
                        final n = r.node;
                        return ReorderableDragStartListener(
                          key: ValueKey(n.id),
                          index: i,
                          child: _BinderRowView(
                            node: n,
                            inPart: r.part != null,
                            open: !n.isPart && books.pathOf(n) == widget.currentPath,
                            selected: n.id == _selected,
                            focusNode: _focusNodes.putIfAbsent(n.id, () => FocusNode(debugLabel: 'fichário ${n.id}')),
                            renaming: n.id == _renaming ? _renameText : null,
                            onTap: () => _activate(n),
                            onFocus: () => _select(n),
                            onMenu: (at) => unawaited(_menu(n, at)),
                            onKey: (node, e) => _onRowKey(n, node, e),
                            onRenamed: (keep) => _endRename(keep: keep),
                          ),
                        );
                      },
                    ),
                  ),
          ),
          if (selected != null) _details(context, selected),
        ],
      ),
    );
  }

  Widget _details(BuildContext context, BookNode n) {
    final l10n = AppLocalizations.of(context);
    final t = QuillTokens.of(context);
    final names = labelNames(l10n);
    final labels = t.colors.labels;
    return Padding(
      padding: EdgeInsets.only(top: t.space.md, bottom: t.space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!n.isPart) ...[
            WLabel(l10n.binderStatus, small: true, tone: WLabelTone.muted),
            SizedBox(height: t.space.xs),
            WSegmented<ChapterStatus>(
              label: l10n.binderStatus,
              expanded: true,
              segments: [for (final s in ChapterStatus.values) WSegment(s, chapterStatusLabel(l10n, s))],
              selected: n.status,
              onChanged: (s) => books.setStatus(n.id, s),
            ),
            SizedBox(height: t.space.md),
          ],
          WLabel(l10n.binderLabel, small: true, tone: WLabelTone.muted),
          SizedBox(height: t.space.xs),
          Wrap(
            spacing: t.space.xs,
            runSpacing: t.space.xs,
            children: [
              WColorSwatch(rgb: null, label: l10n.labelNone, selected: n.label == null, onPressed: () => books.setLabel(n.id, null)),
              for (var i = 0; i < labels.length && i < names.length; i++)
                WColorSwatch(
                  rgb: labels[i].toARGB32() & 0xFFFFFF,
                  label: names[i],
                  selected: n.label == i,
                  onPressed: () => books.setLabel(n.id, i),
                ),
            ],
          ),
          SizedBox(height: t.space.md),
          WLabel(l10n.binderSynopsis, small: true, tone: WLabelTone.muted),
          SizedBox(height: t.space.xs),
          WTextField(
            label: l10n.binderSynopsis,
            hint: l10n.binderSynopsisHint,
            controller: _synopsis,
            lines: 3,
            onChanged: (_) {
              _synopsisSave?.cancel();
              _synopsisSave = Timer(const Duration(milliseconds: 600), _flushSynopsis);
            },
          ),
        ],
      ),
    );
  }
}

class _BinderRowView extends StatefulWidget {
  const _BinderRowView({
    required this.node,
    required this.inPart,
    required this.open,
    required this.selected,
    required this.focusNode,
    required this.renaming,
    required this.onTap,
    required this.onFocus,
    required this.onMenu,
    required this.onKey,
    required this.onRenamed,
  });

  final BookNode node;
  final bool inPart, open, selected;
  final FocusNode focusNode;

  /// O campo do nome, enquanto renomeia; null fora disso.
  final TextEditingController? renaming;
  final VoidCallback onTap, onFocus;
  final ValueChanged<Offset> onMenu;
  final FocusOnKeyEventCallback onKey;
  final ValueChanged<bool> onRenamed;

  @override
  State<_BinderRowView> createState() => _BinderRowViewState();
}

class _BinderRowViewState extends State<_BinderRowView> {
  bool _hover = false, _focused = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = QuillTokens.of(context);
    final c = t.colors;
    final n = widget.node;
    final modern = t.component == ComponentStyle.modern;
    final label = n.label == null || n.label! >= c.labels.length ? null : c.labels[n.label!];
    final status = n.isPart ? '' : ', ${chapterStatusLabel(l10n, n.status)}, ${l10n.binderWords(n.words)}';
    final text = TextStyle(
      color: widget.open && modern ? c.onAccentSoft : c.onFrame,
      fontSize: t.font.ui,
      fontWeight: n.isPart || widget.open ? FontWeight.w600 : FontWeight.w400,
      fontFamily: t.font.family,
    );
    final renaming = widget.renaming;
    final row = Container(
      margin: EdgeInsets.only(bottom: t.space.xs),
      padding: EdgeInsets.only(left: t.space.sm + (widget.inPart ? 18 : 0), right: t.space.sm),
      decoration: BoxDecoration(
        color: widget.open
            ? c.accentSoft
            : widget.selected || _hover
                ? c.surfaceHigh
                : null,
        borderRadius: BorderRadius.circular(modern ? 16 : 0),
        border: _focused ? Border.all(color: c.focusRing, width: 2) : null,
      ),
      child: Row(
        children: [
          Icon(n.isPart ? Symbols.folder_rounded : Symbols.description_rounded, size: 18, color: c.onFrameMuted),
          SizedBox(width: t.space.sm),
          Expanded(
            child: renaming != null
                ? _RenameField(controller: renaming, label: l10n.binderRename, onDone: widget.onRenamed)
                : Text(n.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: text),
          ),
          if (label != null) ...[
            SizedBox(width: t.space.xs),
            Container(width: 10, height: 10, decoration: BoxDecoration(color: label, shape: BoxShape.circle)),
          ],
          if (!n.isPart && renaming == null) ...[
            SizedBox(width: t.space.sm),
            Text('${n.words}', style: text.copyWith(color: c.onFrameMuted, fontWeight: FontWeight.w400, fontSize: t.font.small)),
          ],
        ],
      ),
    );
    return Semantics(
      container: true,
      button: true,
      selected: widget.open,
      label: '${n.title}$status',
      hint: l10n.binderKeysHint,
      child: Focus(
        focusNode: widget.focusNode,
        onKeyEvent: widget.onKey,
        onFocusChange: (v) {
          setState(() => _focused = v);
          if (v) widget.onFocus();
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            onTap: () {
              widget.focusNode.requestFocus();
              widget.onTap();
            },
            onSecondaryTapDown: (d) => widget.onMenu(d.globalPosition),
            child: ExcludeSemantics(excluding: renaming == null, child: row),
          ),
        ),
      ),
    );
  }
}

/// O nome em edição: Enter grava, Esc desiste, e sair do campo grava.
class _RenameField extends StatefulWidget {
  const _RenameField({required this.controller, required this.label, required this.onDone});
  final TextEditingController controller;
  final String label;
  final ValueChanged<bool> onDone;

  @override
  State<_RenameField> createState() => _RenameFieldState();
}

class _RenameFieldState extends State<_RenameField> {
  final _focus = FocusNode();
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _finish(true);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  void _finish(bool keep) {
    if (_done) return;
    _done = true;
    widget.onDone(keep);
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Focus(
        onKeyEvent: (node, e) {
          if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
            _finish(false);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: WTextField(
          label: widget.label,
          controller: widget.controller,
          focusNode: _focus,
          onSubmitted: (_) => _finish(true),
        ),
      );
}
