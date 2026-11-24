// A cortiça (Fase 3, Etapa 10, D-084): os capítulos como cartões, no lugar
// da página. É a mesma árvore do fichário: arrastar um cartão (ou Alt+setas)
// reordena o livro, e a sinopse se edita no cartão (F2, ou o lápis).
//
// Os cartões são os capítulos do livro inteiro, na ordem dele, ou só os de
// uma parte. A grade monta só os cartões visíveis (`GridView.builder`), e
// nada passa pelo motor enquanto a cortiça está na tela. O painel se refaz
// pela `revision` do livro, como o fichário (D-037).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../book/book.dart';
import '../../book/book_controller.dart';
import '../atoms/w_button.dart';
import '../atoms/w_dropdown.dart';
import '../atoms/w_label.dart';
import '../atoms/w_text_field.dart';
import '../tokens/tokens.dart';
import 'binder_panel.dart' show chapterStatusLabel;

/// Os cartões: os capítulos de [partId] ou, sem parte, do livro inteiro.
List<BookNode> corkCards(Book book, String? partId) {
  if (partId != null) {
    final part = book.find(partId)?.$1;
    if (part != null && part.isPart) return List.of(part.children);
  }
  return book.chapters.toList();
}

/// Onde o cartão [from] cai, solto no lugar do cartão [to]: a parte do
/// cartão de destino (null, o primeiro nível) e o índice nela, contado antes
/// de tirar o cartão (como o `BookController.move`). Indo para a frente, ele
/// fica depois do destino; para trás, antes.
({String? partId, int index}) corkDrop(Book book, List<BookNode> cards, int from, int to) {
  final target = cards[to];
  final (_, list) = book.find(target.id)!;
  final at = list.indexOf(target);
  return (partId: book.parentOf(target.id)?.id, index: from < to ? at + 1 : at);
}

class Corkboard extends StatefulWidget {
  const Corkboard({
    super.key,
    required this.books,
    required this.onOpen,
    required this.onClose,
    this.currentId,
  });

  final BookController books;

  /// Abre o capítulo (o duplo clique ou Enter); a página volta à tela.
  final void Function(BookNode chapter) onOpen;

  /// Volta à página (Esc ou o botão).
  final VoidCallback onClose;

  /// O capítulo da tela, destacado.
  final String? currentId;

  @override
  State<Corkboard> createState() => _CorkboardState();
}

class _CorkboardState extends State<Corkboard> {
  final _scroll = ScrollController();
  final _nodes = <String, FocusNode>{};
  String? _part;
  String? _focusId;
  String? _editing;
  TextEditingController? _synopsis;
  int _columns = 1;
  double _rowExtent = 0;

  static const _spacing = 16.0;
  static const _minWidth = 240.0;
  static const _aspect = 1.35;

  @override
  void dispose() {
    _scroll.dispose();
    for (final f in _nodes.values) {
      f.dispose();
    }
    _synopsis?.dispose();
    super.dispose();
  }

  FocusNode _nodeOf(String id) => _nodes.putIfAbsent(id, () => FocusNode(debugLabel: 'cartão $id'));

  /// Solta os nós de foco dos capítulos que saíram da lista.
  void _prune(List<BookNode> cards) {
    final ids = {for (final c in cards) c.id};
    _nodes.removeWhere((id, f) {
      if (ids.contains(id)) return false;
      f.dispose();
      return true;
    });
  }

  /// Leva o foco ao cartão [i], rolando até ele se não está montado.
  void _focus(List<BookNode> cards, int i) {
    if (cards.isEmpty) return;
    final index = i.clamp(0, cards.length - 1);
    final id = cards[index].id;
    setState(() => _focusId = id);
    if (_scroll.hasClients && _rowExtent > 0) {
      final row = index ~/ _columns;
      final top = row * _rowExtent, bottom = top + _rowExtent;
      final p = _scroll.position;
      if (top < p.pixels) {
        _scroll.jumpTo(top.clamp(0, p.maxScrollExtent));
      } else if (bottom > p.pixels + p.viewportDimension) {
        _scroll.jumpTo((bottom - p.viewportDimension).clamp(0, p.maxScrollExtent));
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nodes[id]?.requestFocus();
    });
  }

  void _move(List<BookNode> cards, int from, int to) {
    if (to < 0 || to >= cards.length || to == from) return;
    final id = cards[from].id;
    final drop = corkDrop(widget.books.book!, cards, from, to);
    widget.books.move(id, partId: drop.partId, index: drop.index);
    final after = corkCards(widget.books.book!, _part);
    _focus(after, after.indexWhere((c) => c.id == id));
  }

  void _edit(BookNode n) {
    _synopsis?.dispose();
    _synopsis = TextEditingController(text: n.synopsis);
    setState(() => _editing = n.id);
  }

  void _endEdit({required bool save}) {
    final id = _editing, c = _synopsis;
    if (id == null || c == null) return;
    if (save) widget.books.setSynopsis(id, c.text.trim());
    setState(() {
      _editing = null;
      _synopsis = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      c.dispose();
      if (mounted) _nodes[id]?.requestFocus();
    });
  }

  KeyEventResult _onKey(List<BookNode> cards, int i, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    final alt = HardwareKeyboard.instance.isAltPressed;
    final step = switch (k) {
      LogicalKeyboardKey.arrowLeft => -1,
      LogicalKeyboardKey.arrowRight => 1,
      LogicalKeyboardKey.arrowUp => -_columns,
      LogicalKeyboardKey.arrowDown => _columns,
      _ => 0,
    };
    if (step != 0) {
      if (alt) {
        _move(cards, i, (i + step).clamp(0, cards.length - 1));
      } else {
        _focus(cards, i + step);
      }
      return KeyEventResult.handled;
    }
    if (alt) return KeyEventResult.ignored;
    switch (k) {
      case LogicalKeyboardKey.home:
        _focus(cards, 0);
      case LogicalKeyboardKey.end:
        _focus(cards, cards.length - 1);
      case LogicalKeyboardKey.enter || LogicalKeyboardKey.numpadEnter:
        widget.onOpen(cards[i]);
      case LogicalKeyboardKey.f2:
        _edit(cards[i]);
      case LogicalKeyboardKey.escape:
        widget.onClose();
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = QuillTokens.of(context);
    final c = t.colors;
    final book = widget.books.book;
    if (book == null) return const SizedBox.shrink();
    if (_part != null && book.find(_part!)?.$1.isPart != true) _part = null;
    final cards = corkCards(book, _part);
    _prune(cards);
    final parts = [for (final n in book.nodes) if (n.isPart) n];
    final scopeName = _part == null ? l10n.corkAll : book.find(_part!)!.$1.title;

    final header = Padding(
      padding: EdgeInsets.fromLTRB(t.space.xl, t.space.lg, t.space.xl, t.space.md),
      child: Row(children: [
        Icon(Symbols.dashboard_rounded, size: 20, color: c.onFrameMuted),
        SizedBox(width: t.space.sm),
        Expanded(
          child: Semantics(
            header: true,
            child: WLabel(l10n.corkTitle(book.title), heading: true),
          ),
        ),
        if (parts.isNotEmpty) ...[
          WDropdown<String?>(
            label: l10n.corkScope,
            text: scopeName,
            width: 220,
            items: [
              WDropdownItem(null, l10n.corkAll),
              for (final p in parts) WDropdownItem(p.id, p.title),
            ],
            onSelected: (v) => setState(() {
              _part = v;
              _focusId = null;
            }),
          ),
          SizedBox(width: t.space.md),
        ],
        WTextButton(label: l10n.corkBack, icon: Symbols.description_rounded, onPressed: widget.onClose),
      ]),
    );

    final grid = cards.isEmpty
        ? Center(child: WLabel(l10n.corkEmpty, tone: WLabelTone.muted))
        : LayoutBuilder(builder: (context, box) {
            final width = box.maxWidth - 2 * t.space.xl;
            _columns = math.max(1, ((width + _spacing) / (_minWidth + _spacing)).floor());
            final cardWidth = (width - (_columns - 1) * _spacing) / _columns;
            _rowExtent = cardWidth / _aspect + _spacing;
            return GridView.builder(
              controller: _scroll,
              padding: EdgeInsets.fromLTRB(t.space.xl, t.space.sm, t.space.xl, t.space.xl),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _columns,
                mainAxisSpacing: _spacing,
                crossAxisSpacing: _spacing,
                childAspectRatio: _aspect,
              ),
              itemCount: cards.length,
              itemBuilder: (context, i) {
                final n = cards[i];
                return _DropSlot(
                  index: i,
                  onAccept: (from) => _move(cards, from, i),
                  child: _CorkCard(
                    key: ValueKey(n.id),
                    node: n,
                    index: i,
                    width: cardWidth,
                    open: n.id == widget.currentId,
                    focusNode: _nodeOf(n.id),
                    autofocus: n.id == _focusId || (_focusId == null && i == 0),
                    editing: _editing == n.id ? _synopsis : null,
                    onKey: (e) => _onKey(cards, i, e),
                    onFocus: () => _focusId = n.id,
                    onOpen: () => widget.onOpen(n),
                    onEdit: () => _edit(n),
                    onEditDone: (save) => _endEdit(save: save),
                  ),
                );
              },
            );
          });

    return ColoredBox(
      color: c.frame,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [header, Expanded(child: grid)],
      ),
    );
  }
}

/// O lugar de um cartão, que aceita outro cartão solto em cima.
class _DropSlot extends StatelessWidget {
  const _DropSlot({required this.index, required this.onAccept, required this.child});
  final int index;
  final void Function(int from) onAccept;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = QuillTokens.of(context).colors;
    final radius = QuillTokens.of(context).radius.panel;
    return DragTarget<int>(
      onWillAcceptWithDetails: (d) => d.data != index,
      onAcceptWithDetails: (d) => onAccept(d.data),
      builder: (context, candidates, _) => DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: candidates.isEmpty
            ? const BoxDecoration()
            : BoxDecoration(border: Border.all(color: c.accent, width: 2), borderRadius: BorderRadius.circular(radius)),
        child: child,
      ),
    );
  }
}

class _CorkCard extends StatefulWidget {
  const _CorkCard({
    super.key,
    required this.node,
    required this.index,
    required this.width,
    required this.open,
    required this.focusNode,
    required this.autofocus,
    required this.editing,
    required this.onKey,
    required this.onFocus,
    required this.onOpen,
    required this.onEdit,
    required this.onEditDone,
  });

  final BookNode node;
  final int index;
  final double width;
  final bool open, autofocus;
  final FocusNode focusNode;

  /// O campo da sinopse, quando ela está em edição.
  final TextEditingController? editing;
  final KeyEventResult Function(KeyEvent e) onKey;
  final VoidCallback onFocus, onOpen, onEdit;
  final void Function(bool save) onEditDone;

  @override
  State<_CorkCard> createState() => _CorkCardState();
}

class _CorkCardState extends State<_CorkCard> {
  bool _focused = false, _hover = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = QuillTokens.of(context);
    final c = t.colors;
    final n = widget.node;
    final label = n.label == null || n.label! >= c.labels.length ? null : c.labels[n.label!];
    final m = MaterialLocalizations.of(context);
    final status = '${chapterStatusLabel(l10n, n.status)} · ${l10n.corkWords(m.formatDecimal(n.words))}';
    final text = TextStyle(color: c.onFrame, fontSize: t.font.ui, fontFamily: t.font.family);
    final muted = text.copyWith(color: c.onFrameMuted, fontSize: t.font.small);
    final editing = widget.editing;

    final card = Container(
      decoration: BoxDecoration(
        color: _hover && editing == null ? c.surfaceHigh : c.surfaceContainer,
        borderRadius: BorderRadius.circular(t.radius.panel),
        border: Border.all(
          color: _focused ? c.focusRing : (widget.open ? c.accent : c.border),
          width: _focused || widget.open ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // O rótulo de cor, numa faixa em cima.
          Container(height: 6, color: label),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(t.space.md, t.space.sm, t.space.sm, t.space.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(n.title,
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: text.copyWith(fontWeight: FontWeight.w600)),
                    ),
                    if (editing == null)
                      WButton(icon: Symbols.edit_rounded, label: l10n.corkEditSynopsis, onPressed: widget.onEdit),
                  ]),
                  Text(status, style: muted, maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(height: t.space.sm),
                  Expanded(
                    child: editing != null
                        ? _SynopsisField(controller: editing, label: l10n.corkSynopsis, onDone: widget.onEditDone)
                        : Text(
                            n.synopsis.isEmpty ? l10n.corkNoSynopsis : n.synopsis,
                            style: n.synopsis.isEmpty ? muted.copyWith(fontStyle: FontStyle.italic) : text,
                            overflow: TextOverflow.fade,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    final body = Semantics(
      container: true,
      button: true,
      selected: widget.open,
      label: '${n.title}, $status, ${n.synopsis.isEmpty ? l10n.corkNoSynopsis : n.synopsis}',
      hint: l10n.corkKeysHint,
      child: Focus(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        onKeyEvent: (_, e) => editing != null ? KeyEventResult.ignored : widget.onKey(e),
        onFocusChange: (v) {
          setState(() => _focused = v);
          if (v) widget.onFocus();
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            onTap: widget.focusNode.requestFocus,
            onDoubleTap: editing == null ? widget.onOpen : null,
            child: ExcludeSemantics(excluding: editing == null, child: card),
          ),
        ),
      ),
    );
    if (editing != null) return body;
    return Draggable<int>(
      data: widget.index,
      feedback: Material(
        type: MaterialType.transparency,
        child: Opacity(opacity: 0.85, child: SizedBox(width: widget.width, height: widget.width / 1.35, child: card)),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: card),
      child: body,
    );
  }
}

/// A sinopse em edição: sair do campo grava, Esc desiste, Ctrl+Enter grava.
class _SynopsisField extends StatefulWidget {
  const _SynopsisField({required this.controller, required this.label, required this.onDone});
  final TextEditingController controller;
  final String label;
  final void Function(bool save) onDone;

  @override
  State<_SynopsisField> createState() => _SynopsisFieldState();
}

class _SynopsisFieldState extends State<_SynopsisField> {
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

  void _finish(bool save) {
    if (_done) return;
    _done = true;
    widget.onDone(save);
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Focus(
        onKeyEvent: (_, e) {
          if (e is! KeyDownEvent) return KeyEventResult.ignored;
          if (e.logicalKey == LogicalKeyboardKey.escape) {
            _finish(false);
            return KeyEventResult.handled;
          }
          if ((e.logicalKey == LogicalKeyboardKey.enter || e.logicalKey == LogicalKeyboardKey.numpadEnter) &&
              HardwareKeyboard.instance.isControlPressed) {
            _finish(true);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: WTextField(label: widget.label, controller: widget.controller, focusNode: _focus, expands: true),
      );
}
