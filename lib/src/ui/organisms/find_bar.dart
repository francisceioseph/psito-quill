// A barra de localizar e substituir, em cima da página (como no Word e no
// LibreOffice, sem janela por cima do texto).
//
// Enter acha a próxima; Shift+Enter, a anterior; Esc fecha e devolve o foco
// ao documento. O motor seleciona a ocorrência e diz quantas há.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../document/document_controller.dart';
import '../../document/search.dart';
import '../atoms/w_button.dart';
import '../atoms/w_label.dart';
import '../atoms/w_text_field.dart';
import '../tokens/tokens.dart';

class FindBar extends StatefulWidget {
  const FindBar({super.key, required this.doc, required this.replace, required this.onClose, this.initialText = ''});

  final DocumentController doc;

  /// Mostra a linha de substituir.
  final bool replace;
  final VoidCallback onClose;

  /// O que já vem no campo (a seleção, se for curta).
  final String initialText;

  @override
  State<FindBar> createState() => FindBarState();
}

class FindBarState extends State<FindBar> {
  final _find = TextEditingController();
  final _replace = TextEditingController();
  final _findFocus = FocusNode(debugLabel: 'localizar');
  bool _matchCase = false, _wholeWord = false, _regex = false;

  SearchQuery get query => SearchQuery(_find.text, matchCase: _matchCase, wholeWord: _wholeWord, regex: _regex);

  @override
  void initState() {
    super.initState();
    _find.text = widget.initialText;
    _find.selection = TextSelection(baseOffset: 0, extentOffset: _find.text.length);
  }

  /// Volta o foco ao campo e seleciona o texto (Ctrl+L com a barra aberta).
  void focusField() {
    _findFocus.requestFocus();
    _find.selection = TextSelection(baseOffset: 0, extentOffset: _find.text.length);
  }

  @override
  void dispose() {
    _find.dispose();
    _replace.dispose();
    _findFocus.dispose();
    super.dispose();
  }

  void _next({bool backward = false}) => widget.doc.find(query, backward: backward);

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is KeyUpEvent) return KeyEventResult.ignored;
    if (e.logicalKey == LogicalKeyboardKey.escape) {
      widget.doc.clearSearch();
      widget.onClose();
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
      child: ListenableBuilder(
        listenable: doc,
        builder: (context, _) {
          final s = doc.search;
          final status = s.query != query
              ? ''
              : s.replaced != null
                  ? l10n.findReplaced(s.replaced!)
                  : s.notFound
                      ? l10n.findNotFound
                      : s.count != null
                          ? l10n.findCount(s.count!)
                          : '';
          return Container(
            decoration: BoxDecoration(
              color: t.colors.frame,
              border: Border(bottom: BorderSide(color: t.colors.border)),
            ),
            padding: EdgeInsets.symmetric(horizontal: t.space.md, vertical: t.space.sm),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                WTextField(
                  label: l10n.findField,
                  controller: _find,
                  focusNode: _findFocus,
                  autofocus: true,
                  width: 260,
                  error: s.notFound && s.query == query,
                  onChanged: (_) => setState(() {}),
                  // O Enter do IME (o do teclado físico vem pelo _onKey).
                  onSubmitted: (_) {
                    _next();
                    _findFocus.requestFocus();
                  },
                ),
                SizedBox(width: t.space.sm),
                WButton(icon: Icons.keyboard_arrow_up, label: l10n.findPrevious, onPressed: () => _next(backward: true)),
                WButton(icon: Icons.keyboard_arrow_down, label: l10n.findNext, onPressed: _next),
                WButton(
                  icon: Icons.select_all,
                  label: l10n.findAll,
                  showLabel: true,
                  onPressed: () => doc.findAll(query),
                ),
                SizedBox(width: t.space.sm),
                WToggle(
                  icon: Icons.text_fields,
                  label: l10n.findMatchCase,
                  value: _matchCase,
                  onPressed: () => setState(() => _matchCase = !_matchCase),
                ),
                WToggle(
                  icon: Icons.space_bar,
                  label: l10n.findWholeWord,
                  value: _wholeWord,
                  onPressed: () => setState(() => _wholeWord = !_wholeWord),
                ),
                WToggle(
                  icon: Icons.data_object,
                  label: l10n.findRegex,
                  value: _regex,
                  onPressed: () => setState(() => _regex = !_regex),
                ),
                SizedBox(width: t.space.md),
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: WLabel(status, small: true, tone: s.notFound ? WLabelTone.danger : WLabelTone.muted),
                  ),
                ),
                WButton(
                  icon: Icons.close,
                  label: l10n.findClose,
                  onPressed: () {
                    doc.clearSearch();
                    widget.onClose();
                  },
                ),
              ]),
              if (widget.replace) ...[
                SizedBox(height: t.space.sm),
                Row(children: [
                  WTextField(label: l10n.replaceField, controller: _replace, width: 260),
                  SizedBox(width: t.space.sm),
                  WTextButton(
                    label: l10n.replaceOne,
                    onPressed: doc.canEdit ? () => doc.replace(query, _replace.text) : null,
                  ),
                  WTextButton(
                    label: l10n.replaceAll,
                    onPressed: doc.canEdit ? () => doc.replaceAll(query, _replace.text) : null,
                  ),
                ]),
              ],
            ]),
          );
        },
      ),
    );
  }
}
