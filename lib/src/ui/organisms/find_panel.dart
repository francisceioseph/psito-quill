// O painel Localizar e substituir, à esquerda da página (Etapa 7, D-062),
// como o do OnlyOffice: os campos em cima e, embaixo, a lista das
// ocorrências com a página e o trecho. Antes era uma barra em cima da
// página, sem a lista.
//
// Enter acha a próxima; Shift+Enter, a anterior; Esc fecha e devolve o foco
// ao documento. O motor seleciona a ocorrência e diz quantas há. A lista sai
// da cópia do documento (a mesma da busca única, D-050), refeita quando o
// texto mudou, e só as linhas visíveis são construídas.
//
// Com um livro aberto, "No livro" troca a lista pela do livro inteiro
// (Fase 3, Etapa 6, D-080), agrupada por capítulo; o clique abre o capítulo
// e seleciona a ocorrência. As setas, "Todas" e Substituir continuam no
// capítulo da tela.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../document/document_controller.dart';
import '../../book/book_search.dart';
import '../../document/fodt.dart' show TextHit, TextSearchResult;
import '../../document/search.dart';
import '../atoms/w_button.dart';
import '../atoms/w_label.dart';
import '../atoms/w_segmented.dart';
import '../atoms/w_text_field.dart';
import '../molecules/side_panel.dart';
import '../tokens/tokens.dart';

class FindPanel extends StatefulWidget {
  const FindPanel({
    super.key,
    required this.doc,
    required this.onClose,
    required this.closeLabel,
    this.initialText = '',
    this.searchBook,
    this.onOpenBookHit,
  });

  final DocumentController doc;
  final VoidCallback onClose;

  /// A busca no livro inteiro; null: não há livro aberto (sem "No livro").
  final Future<BookSearchResult> Function(SearchQuery q)? searchBook;

  /// Abre o capítulo e seleciona a ocorrência.
  final void Function(String chapterId, TextHit hit)? onOpenBookHit;

  /// "Fechar a busca (Ctrl+H)".
  final String closeLabel;

  /// O que já vem no campo (a seleção, se for curta, ou o da busca única).
  final String initialText;

  @override
  State<FindPanel> createState() => FindPanelState();
}

class FindPanelState extends State<FindPanel> {
  final _find = TextEditingController();
  final _replace = TextEditingController();
  final _findFocus = FocusNode(debugLabel: 'localizar');
  bool _matchCase = false, _wholeWord = false, _regex = false;
  Timer? _debounce;

  /// A lista e a pergunta que a gerou.
  TextSearchResult _result = TextSearchResult.empty;
  BookSearchResult _bookResult = BookSearchResult.empty;
  SearchQuery? _asked;
  bool _askedInBook = false;
  bool _searching = false;
  String? _picked;

  /// "No livro" (só com [FindPanel.searchBook]).
  bool _inBook = false;

  /// Uma busca no livro já roda: a próxima espera por ela (um isolate de
  /// cada vez, para a memória não dobrar enquanto se digita).
  bool _bookRunning = false;
  bool _bookAgain = false;

  bool get _bookScope => _inBook && widget.searchBook != null;

  SearchQuery get query => SearchQuery(_find.text, matchCase: _matchCase, wholeWord: _wholeWord, regex: _regex);

  /// A lista mostrada é a desta pergunta, neste lugar.
  bool get _current => _asked == query && _askedInBook == _bookScope && !_searching;

  @override
  void initState() {
    super.initState();
    _find.text = widget.initialText;
    _find.selection = TextSelection(baseOffset: 0, extentOffset: _find.text.length);
    _list();
  }

  /// Volta o foco ao campo e seleciona o texto (Ctrl+H com o painel aberto).
  void focusField() {
    _findFocus.requestFocus();
    _find.selection = TextSelection(baseOffset: 0, extentOffset: _find.text.length);
  }

  @override
  void didUpdateWidget(FindPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // O livro fechou: volta ao capítulo.
    if (oldWidget.searchBook != null && widget.searchBook == null && _inBook) {
      _inBook = false;
      _list(now: true);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _find.dispose();
    _replace.dispose();
    _findFocus.dispose();
    super.dispose();
  }

  /// Refaz a lista depois de uma pausa (ou já, com [now]).
  void _list({bool now = false}) {
    _debounce?.cancel();
    if (_find.text.trim().length < 2) {
      if (_asked != null || _result.total > 0 || _bookResult.total > 0) {
        setState(() {
          _result = TextSearchResult.empty;
          _bookResult = BookSearchResult.empty;
          _asked = null;
          _picked = null;
        });
      }
      return;
    }
    // O livro lê todos os capítulos: espera um pouco mais pela digitação.
    final pause = now ? Duration.zero : Duration(milliseconds: _bookScope ? 500 : 300);
    _debounce = Timer(pause, () {
      if (!mounted) return;
      if (_bookScope) {
        _runBook();
      } else {
        _runChapter();
      }
    });
  }

  Future<void> _runChapter() async {
    final q = query;
    setState(() => _searching = true);
    final r = await widget.doc.searchText(q, fresh: true);
    // Só a resposta da última pergunta vale.
    if (!mounted || query != q || _bookScope) return;
    setState(() {
      _result = r;
      _asked = q;
      _askedInBook = false;
      _searching = false;
      _picked = null;
    });
  }

  Future<void> _runBook() async {
    if (_bookRunning) {
      _bookAgain = true;
      return;
    }
    final search = widget.searchBook;
    if (search == null) return;
    final q = query;
    _bookRunning = true;
    setState(() => _searching = true);
    BookSearchResult r;
    try {
      r = await search(q);
    } on Object {
      r = BookSearchResult.empty;
    } finally {
      _bookRunning = false;
    }
    if (!mounted) return;
    if (_bookAgain || query != q || !_bookScope) {
      _bookAgain = false;
      // A pergunta mudou enquanto buscava: a última vale.
      if (_bookScope) _list(now: true);
      return;
    }
    setState(() {
      _bookResult = r;
      _asked = q;
      _askedInBook = true;
      _searching = false;
      _picked = null;
    });
  }

  void _option(void Function() change) {
    setState(change);
    _list(now: true);
  }

  void _next({bool backward = false}) => widget.doc.find(query, backward: backward);

  void _close() {
    widget.doc.clearSearch();
    widget.onClose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is KeyUpEvent) return KeyEventResult.ignored;
    if (e.logicalKey == LogicalKeyboardKey.escape) {
      _close();
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.enter && _findFocus.hasFocus) {
      _next(backward: HardwareKeyboard.instance.isShiftPressed);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final doc = widget.doc;
    return Focus(
      onKeyEvent: _onKey,
      child: SidePanel(
        title: l10n.findPanelTitle,
        closeLabel: widget.closeLabel,
        onClose: _close,
        side: AxisDirection.left,
        width: 320,
        child: ListenableBuilder(
          listenable: doc,
          builder: (context, _) {
            final s = doc.search;
            final bad = _current && (_bookScope ? _bookResult.badPattern : _result.badPattern);
            final status = bad
                ? l10n.findBadRegex
                : _bookScope
                ? (_current ? l10n.bookHitsCount(_bookResult.total, _bookResult.chapters.length) : '')
                : s.query != query
                ? (_current ? l10n.searchHitsCount(_result.total) : '')
                : s.replaced != null
                ? l10n.findReplaced(s.replaced!)
                : s.notFound
                ? l10n.findNotFound
                : s.count != null
                ? l10n.findCount(s.count!)
                : '';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.searchBook != null) ...[
                  WSegmented<bool>(
                    label: l10n.findScope,
                    expanded: true,
                    segments: [
                      WSegment(false, l10n.findScopeChapter),
                      WSegment(true, l10n.findScopeBook),
                    ],
                    selected: _inBook,
                    onChanged: (v) {
                      if (v == _inBook) return;
                      setState(() {
                        _inBook = v;
                        _picked = null;
                      });
                      _list(now: true);
                    },
                  ),
                  SizedBox(height: t.space.md),
                ],
                WTextField(
                  label: l10n.findField,
                  controller: _find,
                  focusNode: _findFocus,
                  autofocus: true,
                  error: s.notFound && s.query == query,
                  onChanged: (_) {
                    setState(() {});
                    _list();
                  },
                  // O Enter do IME (o do teclado físico vem pelo _onKey).
                  onSubmitted: (_) {
                    _next();
                    _findFocus.requestFocus();
                  },
                ),
                SizedBox(height: t.space.sm),
                // As setas e "Todas" de um lado, as opções do outro; numa tela
                // estreita, as opções descem.
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runSpacing: t.space.xs,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        WButton(
                          icon: Symbols.keyboard_arrow_up_rounded,
                          label: l10n.findPrevious,
                          onPressed: () => _next(backward: true),
                        ),
                        WButton(icon: Symbols.keyboard_arrow_down_rounded, label: l10n.findNext, onPressed: _next),
                        WButton(
                          icon: Symbols.select_all_rounded,
                          label: l10n.findAll,
                          showLabel: true,
                          onPressed: () => doc.findAll(query),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        WToggle(
                          icon: Symbols.text_fields_rounded,
                          label: l10n.findMatchCase,
                          value: _matchCase,
                          onPressed: () => _option(() => _matchCase = !_matchCase),
                        ),
                        WToggle(
                          icon: Symbols.space_bar_rounded,
                          label: l10n.findWholeWord,
                          value: _wholeWord,
                          onPressed: () => _option(() => _wholeWord = !_wholeWord),
                        ),
                        WToggle(
                          icon: Symbols.data_object_rounded,
                          label: l10n.findRegex,
                          value: _regex,
                          onPressed: () => _option(() => _regex = !_regex),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: t.space.lg),
                WTextField(label: l10n.replaceField, controller: _replace),
                SizedBox(height: t.space.sm),
                Wrap(
                  spacing: t.space.sm,
                  runSpacing: t.space.xs,
                  children: [
                    WTextButton(label: l10n.replaceOne, onPressed: doc.canEdit ? () => doc.replace(query, _replace.text) : null),
                    WTextButton(
                      label: l10n.replaceAll,
                      onPressed: doc.canEdit
                          ? () {
                              doc.replaceAll(query, _replace.text);
                              if (!_bookScope) _list(now: true);
                            }
                          : null,
                    ),
                  ],
                ),
                SizedBox(height: t.space.md),
                Semantics(
                  liveRegion: true,
                  child: WLabel(
                    status,
                    small: true,
                    tone: bad || (!_bookScope && s.notFound && s.query == query) ? WLabelTone.danger : WLabelTone.muted,
                  ),
                ),
                SizedBox(height: t.space.sm),
                Divider(height: 1, color: t.colors.border),
                Expanded(child: _hits(context, l10n, t)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _note(String text, QuillTokens t) => Padding(
    padding: EdgeInsets.only(top: t.space.md),
    child: WLabel(text, small: true, tone: WLabelTone.muted),
  );

  Widget _hits(BuildContext context, AppLocalizations l10n, QuillTokens t) {
    if (_find.text.trim().length < 2) return const SizedBox.shrink();
    if (!_current) return _note(l10n.searchSearching, t);
    if (_bookScope) return _bookHits(context, l10n, t);
    if (_result.hits.isEmpty) return _result.badPattern ? const SizedBox.shrink() : _note(l10n.searchNoHits, t);
    final more = _result.total - _result.hits.length;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: l10n.findHitsList,
      child: ListView.builder(
        padding: EdgeInsets.only(top: t.space.sm),
        itemCount: _result.hits.length + (more > 0 ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == _result.hits.length) {
            return Padding(
              padding: EdgeInsets.all(t.space.md),
              child: WLabel(l10n.searchMoreHits(more), small: true, tone: WLabelTone.muted),
            );
          }
          final hit = _result.hits[i];
          return _HitTile(
            hit: hit,
            label: l10n.searchHitLabel('${hit.before}${hit.match}${hit.after}'.trim(), hit.page),
            selected: _picked == '$i',
            onPressed: () {
              setState(() => _picked = '$i');
              widget.doc.goToHit(hit);
            },
          );
        },
      ),
    );
  }

  /// A lista do livro: o nome de cada capítulo, as ocorrências dele e, se
  /// passou do limite, quantas faltam. As linhas são um índice achatado, e
  /// só as visíveis são construídas.
  Widget _bookHits(BuildContext context, AppLocalizations l10n, QuillTokens t) {
    final r = _bookResult;
    if (r.chapters.isEmpty) {
      if (r.badPattern) return const SizedBox.shrink();
      return _note(r.unread > 0 ? '${l10n.searchNoHits}. ${l10n.bookUnread(r.unread)}' : l10n.searchNoHits, t);
    }
    final rows = <(ChapterHits, int)>[]; // -1: o nome; hits.length: "mais"
    for (final c in r.chapters) {
      rows.add((c, -1));
      for (var i = 0; i < c.hits.length; i++) {
        rows.add((c, i));
      }
      if (c.total > c.hits.length) rows.add((c, c.hits.length));
    }
    final unread = r.unread > 0 ? 1 : 0;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: l10n.bookHitsList,
      child: ListView.builder(
        padding: EdgeInsets.only(top: t.space.sm),
        itemCount: rows.length + unread,
        itemBuilder: (context, n) {
          if (n == rows.length) {
            return Padding(
              padding: EdgeInsets.all(t.space.md),
              child: WLabel(l10n.bookUnread(r.unread), small: true, tone: WLabelTone.muted),
            );
          }
          final (c, i) = rows[n];
          if (i < 0) {
            return Semantics(
              header: true,
              label: l10n.bookChapterHits(c.title, c.total),
              child: ExcludeSemantics(
                child: Padding(
                  padding: EdgeInsets.only(top: n == 0 ? 0 : t.space.md, bottom: t.space.xs, left: t.space.xs),
                  child: Row(
                    children: [
                      Expanded(child: WLabel(c.title, heading: true)),
                      WLabel('${c.total}', small: true, tone: WLabelTone.muted),
                    ],
                  ),
                ),
              ),
            );
          }
          if (i == c.hits.length) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: t.space.md, vertical: t.space.xs),
              child: WLabel(l10n.bookMoreHits(c.total - c.hits.length), small: true, tone: WLabelTone.muted),
            );
          }
          final hit = c.hits[i];
          final key = '${c.id}#$i';
          return _HitTile(
            hit: hit,
            label: l10n.bookHitLabel('${hit.before}${hit.match}${hit.after}'.trim(), c.title, hit.page),
            selected: _picked == key,
            onPressed: () {
              setState(() => _picked = key);
              widget.onOpenBookHit?.call(c.id, hit);
            },
          );
        },
      ),
    );
  }
}

/// Uma ocorrência: a página em cima e o trecho com o achado em negrito.
class _HitTile extends StatefulWidget {
  const _HitTile({required this.hit, required this.label, required this.selected, required this.onPressed});
  final TextHit hit;

  /// O nome para o leitor de tela (o trecho e a página; no livro, também o
  /// capítulo).
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  State<_HitTile> createState() => _HitTileState();
}

class _HitTileState extends State<_HitTile> {
  bool _hover = false, _focused = false;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final c = t.colors;
    final hit = widget.hit;
    final modern = t.component == ComponentStyle.modern;
    final fg = widget.selected && modern ? c.onAccentSoft : c.onFrame;
    final style = TextStyle(color: fg, fontSize: t.font.ui, fontFamily: t.font.family, height: 1.35);
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: widget.onPressed,
          child: ExcludeSemantics(
            child: Container(
              margin: EdgeInsets.only(bottom: t.space.xs),
              padding: EdgeInsets.symmetric(horizontal: t.space.md, vertical: t.space.sm),
              decoration: BoxDecoration(
                color: widget.selected
                    ? c.accentSoft
                    : _hover
                    ? c.surfaceHigh
                    : null,
                borderRadius: BorderRadius.circular(modern ? t.radius.control : 0),
                border: _focused ? Border.all(color: c.focusRing, width: 2) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WLabel(l10n.searchPage(hit.page), small: true, tone: WLabelTone.muted),
                  SizedBox(height: t.space.xs),
                  Text.rich(
                    TextSpan(
                      style: style,
                      children: [
                        TextSpan(text: hit.before.isEmpty ? '' : '…${hit.before}'),
                        TextSpan(
                          text: hit.match,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: hit.after.isEmpty ? '' : '${hit.after}…'),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
