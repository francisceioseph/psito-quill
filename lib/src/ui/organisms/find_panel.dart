// O painel Localizar e substituir, à esquerda da página (Etapa 7, D-062),
// como o do OnlyOffice: os campos em cima e, embaixo, a lista das
// ocorrências com a página e o trecho. Antes era uma barra em cima da
// página, sem a lista.
//
// Enter acha a próxima; Shift+Enter, a anterior; Esc fecha e devolve o foco
// ao documento. O motor seleciona a ocorrência e diz quantas há. A lista sai
// da cópia do documento (a mesma da busca única, D-050), refeita quando o
// texto mudou, e só as linhas visíveis são construídas.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../document/document_controller.dart';
import '../../document/fodt.dart' show TextHit, TextSearchResult;
import '../../document/search.dart';
import '../atoms/w_button.dart';
import '../atoms/w_label.dart';
import '../atoms/w_text_field.dart';
import '../molecules/side_panel.dart';
import '../tokens/tokens.dart';

class FindPanel extends StatefulWidget {
  const FindPanel({super.key, required this.doc, required this.onClose, required this.closeLabel, this.initialText = ''});

  final DocumentController doc;
  final VoidCallback onClose;

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
  String? _asked;
  bool _searching = false;
  int? _picked;

  SearchQuery get query => SearchQuery(_find.text, matchCase: _matchCase, wholeWord: _wholeWord, regex: _regex);

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
    final q = _find.text;
    if (q.trim().length < 2) {
      if (_asked != null || _result.total > 0) {
        setState(() {
          _result = TextSearchResult.empty;
          _asked = null;
          _picked = null;
        });
      }
      return;
    }
    _debounce = Timer(now ? Duration.zero : const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      setState(() => _searching = true);
      final r = await widget.doc.searchText(q, fresh: true);
      // Só a resposta da última pergunta vale.
      if (!mounted || _find.text != q) return;
      setState(() {
        _result = r;
        _asked = q;
        _searching = false;
        _picked = null;
      });
    });
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
            final status = s.query != query
                ? (_asked == _find.text && !_searching ? l10n.searchHitsCount(_result.total) : '')
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
                          onPressed: () => setState(() => _matchCase = !_matchCase),
                        ),
                        WToggle(
                          icon: Symbols.space_bar_rounded,
                          label: l10n.findWholeWord,
                          value: _wholeWord,
                          onPressed: () => setState(() => _wholeWord = !_wholeWord),
                        ),
                        WToggle(
                          icon: Symbols.data_object_rounded,
                          label: l10n.findRegex,
                          value: _regex,
                          onPressed: () => setState(() => _regex = !_regex),
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
                              _list(now: true);
                            }
                          : null,
                    ),
                  ],
                ),
                SizedBox(height: t.space.md),
                Semantics(
                  liveRegion: true,
                  child: WLabel(status, small: true, tone: s.notFound && s.query == query ? WLabelTone.danger : WLabelTone.muted),
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

  Widget _hits(BuildContext context, AppLocalizations l10n, QuillTokens t) {
    final q = _find.text;
    if (q.trim().length < 2) return const SizedBox.shrink();
    if (_searching || _asked != q) {
      return Padding(
        padding: EdgeInsets.only(top: t.space.md),
        child: WLabel(l10n.searchSearching, small: true, tone: WLabelTone.muted),
      );
    }
    if (_result.hits.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: t.space.md),
        child: WLabel(l10n.searchNoHits, small: true, tone: WLabelTone.muted),
      );
    }
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
            selected: _picked == i,
            onPressed: () {
              setState(() => _picked = i);
              widget.doc.goToHit(hit);
            },
          );
        },
      ),
    );
  }
}

/// Uma ocorrência: a página em cima e o trecho com o achado em negrito.
class _HitTile extends StatefulWidget {
  const _HitTile({required this.hit, required this.selected, required this.onPressed});
  final TextHit hit;
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
    final text = '${hit.before}${hit.match}${hit.after}';
    return Semantics(
      button: true,
      selected: widget.selected,
      label: l10n.searchHitLabel(text.trim(), hit.page),
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
