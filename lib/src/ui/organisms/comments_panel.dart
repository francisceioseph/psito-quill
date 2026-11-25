// O painel Comentários (D-088), no trilho: as conversas na ordem do texto,
// com o autor, a data e as respostas; comentar a seleção, responder,
// resolver e excluir. O clique numa conversa leva ao trecho.
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../document/comments.dart';
import '../../document/document_controller.dart';
import '../../kit/quill_kit.dart';
import '../atoms/w_button.dart';
import '../atoms/w_checkbox.dart';
import '../atoms/w_label.dart';
import '../atoms/w_text_field.dart';
import '../molecules/side_panel.dart';
import '../tokens/tokens.dart';
import 'snapshots_dialog.dart' show snapshotWhen;

class CommentsPanel extends StatefulWidget {
  const CommentsPanel({super.key, required this.doc, required this.onClose, required this.closeLabel, this.onRan});

  final DocumentController doc;
  final VoidCallback onClose;
  final String closeLabel;

  /// Depois de ir ao trecho: o foco volta à página.
  final VoidCallback? onRan;

  @override
  State<CommentsPanel> createState() => CommentsPanelState();
}

class CommentsPanelState extends State<CommentsPanel> {
  final _newText = TextEditingController();
  final _newFocus = FocusNode();
  final _replyText = TextEditingController();
  bool _showResolved = false;
  String? _replyTo;

  /// O "Novo comentário" (Ctrl+Alt+C): o foco no campo.
  void focusNew() => _newFocus.requestFocus();

  @override
  void dispose() {
    _newText.dispose();
    _newFocus.dispose();
    _replyText.dispose();
    super.dispose();
  }

  void _add() {
    final text = _newText.text.trim();
    if (text.isEmpty) return;
    widget.doc.insertComment(text);
    _newText.clear();
    widget.onRan?.call();
  }

  void _reply(String id) {
    final text = _replyText.text.trim();
    if (text.isEmpty) return;
    widget.doc.replyComment(id, text);
    _replyText.clear();
    setState(() => _replyTo = null);
  }

  void _delete(CommentThread th) {
    // As respostas primeiro: sem o comentário de cima, elas ficariam soltas.
    for (final r in th.replies.reversed) {
      widget.doc.deleteComment(r.id);
    }
    widget.doc.deleteComment(th.root.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = QuillTokens.of(context);
    final doc = widget.doc;
    final threads = commentThreads(doc.comments);
    final resolved = threads.where((th) => th.resolved).length;
    final shown = [for (final th in threads) if (_showResolved || !th.resolved) th];
    return SidePanel(
      title: l10n.commentsTitle,
      closeLabel: widget.closeLabel,
      onClose: widget.onClose,
      side: AxisDirection.left,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (doc.canEdit) ...[
          WTextField(
            label: l10n.commentsNew,
            hint: l10n.commentsNewHint,
            controller: _newText,
            focusNode: _newFocus,
            lines: 3,
          ),
          SizedBox(height: t.space.xs),
          Align(
            alignment: Alignment.centerRight,
            child: WTextButton(
              label: l10n.commentsAdd,
              icon: Symbols.add_comment_rounded,
              tone: WTone.filled,
              onPressed: _add,
            ),
          ),
          SizedBox(height: t.space.sm),
        ],
        if (resolved > 0)
          WCheckbox(
            value: _showResolved,
            label: l10n.commentsShowResolved(resolved),
            onChanged: (v) => setState(() => _showResolved = v),
          ),
        SizedBox(height: t.space.sm),
        Expanded(
          child: shown.isEmpty
              ? WLabel(threads.isEmpty ? l10n.commentsEmpty : l10n.commentsAllResolved,
                  tone: WLabelTone.muted, maxLines: 4)
              : Semantics(
                  container: true,
                  label: l10n.commentsTitle,
                  child: ListView.separated(
                    itemCount: shown.length,
                    separatorBuilder: (_, _) => SizedBox(height: t.space.sm),
                    itemBuilder: (context, i) => _thread(context, shown[i]),
                  ),
                ),
        ),
      ]),
    );
  }

  Widget _thread(BuildContext context, CommentThread th) {
    final l10n = AppLocalizations.of(context);
    final t = QuillTokens.of(context);
    final c = t.colors;
    final editable = widget.doc.canEdit;
    final replying = _replyTo == th.root.id;
    return _ThreadCard(
      label: _spoken(context, th),
      resolved: th.resolved,
      onTap: () {
        widget.doc.goToComment(th.root);
        widget.onRan?.call();
      },
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _entry(context, th.root),
        for (final r in th.replies)
          Container(
            margin: EdgeInsets.only(top: t.space.sm),
            padding: EdgeInsets.only(left: t.space.sm),
            decoration: BoxDecoration(border: Border(left: BorderSide(color: c.border, width: 2))),
            child: _entry(context, r),
          ),
        if (replying) ...[
          SizedBox(height: t.space.sm),
          WTextField(
            label: l10n.commentsReplyField,
            controller: _replyText,
            autofocus: true,
            lines: 2,
          ),
          SizedBox(height: t.space.xs),
          Wrap(alignment: WrapAlignment.end, spacing: t.space.xs, children: [
            WTextButton(label: l10n.commentsCancel, onPressed: () => setState(() => _replyTo = null)),
            WTextButton(label: l10n.commentsSend, tone: WTone.filled, onPressed: () => _reply(th.root.id)),
          ]),
        ] else if (editable)
          Wrap(alignment: WrapAlignment.end, children: [
            WButton(
              icon: Symbols.reply_rounded,
              label: l10n.commentsReply,
              onPressed: () => setState(() {
                _replyText.clear();
                _replyTo = th.root.id;
              }),
            ),
            WButton(
              icon: th.resolved ? Symbols.undo_rounded : Symbols.check_circle_rounded,
              label: th.resolved ? l10n.commentsReopen : l10n.commentsResolve,
              onPressed: () => widget.doc.toggleResolved(th.root.id),
            ),
            WButton(
              icon: Symbols.delete_rounded,
              label: l10n.commentsDelete,
              onPressed: () => _delete(th),
            ),
          ]),
      ]),
    );
  }

  Widget _entry(BuildContext context, DocComment cm) {
    final t = QuillTokens.of(context);
    return ExcludeSemantics(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        WLabel(_byline(context, cm), small: true, tone: WLabelTone.muted),
        SizedBox(height: t.space.xs),
        WLabel(cm.text, maxLines: 12),
      ]),
    );
  }

  String _byline(BuildContext context, DocComment cm) {
    final l10n = AppLocalizations.of(context);
    final who = cm.author.isEmpty ? l10n.commentsNoAuthor : cm.author;
    final when = cm.date;
    return when == null ? who : '$who · ${snapshotWhen(context, when)}';
  }

  String _spoken(BuildContext context, CommentThread th) {
    final l10n = AppLocalizations.of(context);
    final parts = [
      '${_byline(context, th.root)}: ${th.root.text}',
      for (final r in th.replies) '${_byline(context, r)}: ${r.text}',
      if (th.resolved) l10n.commentsResolved,
    ];
    return parts.join('. ');
  }
}

/// A conversa: um cartão que leva ao trecho pelo clique ou pelo Enter.
class _ThreadCard extends StatefulWidget {
  const _ThreadCard({required this.label, required this.resolved, required this.onTap, required this.child});

  final String label;
  final bool resolved;
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_ThreadCard> createState() => _ThreadCardState();
}

class _ThreadCardState extends State<_ThreadCard> {
  bool _hover = false, _focused = false;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final c = t.colors;
    return Semantics(
      container: true,
      button: true,
      label: widget.label,
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
          child: Opacity(
            opacity: widget.resolved ? 0.7 : 1,
            child: Container(
              padding: EdgeInsets.all(t.space.sm),
              decoration: BoxDecoration(
                color: _hover ? c.surfaceHigh : c.surfaceContainer,
                borderRadius: BorderRadius.circular(t.radius.control),
                border: Border.all(color: _focused ? c.focusRing : c.border, width: _focused ? 2 : 1),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
