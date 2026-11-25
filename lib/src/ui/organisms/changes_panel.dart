// O painel Alterações (D-089), no trilho: a Revisão, mostrar na página, a
// anterior e a próxima, e a lista na ordem do texto, com o autor, o tipo e o
// trecho; aceitar e rejeitar uma ou todas. O clique leva ao trecho.
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../document/document_controller.dart';
import '../../kit/quill_kit.dart';
import '../atoms/w_button.dart';
import '../atoms/w_checkbox.dart';
import '../atoms/w_label.dart';
import '../atoms/w_switch.dart';
import '../molecules/side_panel.dart';
import '../tokens/tokens.dart';
import 'snapshots_dialog.dart' show snapshotWhen;

/// As alterações na ordem do texto (o motor manda na dele).
List<TrackedChange> changesInTextOrder(List<TrackedChange> changes) {
  final out = [...changes];
  out.sort((a, b) {
    final pa = a.range.firstOrNull?.topLeft, pb = b.range.firstOrNull?.topLeft;
    if (pa == null || pb == null) return (pa == null ? 1 : 0) - (pb == null ? 1 : 0);
    if ((pa.dy - pb.dy).abs() > 20) return pa.dy.compareTo(pb.dy);
    return pa.dx.compareTo(pb.dx);
  });
  return out;
}

String changeKindLabel(AppLocalizations l10n, TrackedChangeKind k) => switch (k) {
      TrackedChangeKind.insert => l10n.changeInsert,
      TrackedChangeKind.delete => l10n.changeDelete,
      TrackedChangeKind.format => l10n.changeFormat,
      TrackedChangeKind.other => l10n.changeOther,
    };

IconData changeKindIcon(TrackedChangeKind k) => switch (k) {
      TrackedChangeKind.insert => Symbols.add_rounded,
      TrackedChangeKind.delete => Symbols.remove_rounded,
      TrackedChangeKind.format => Symbols.format_paint_rounded,
      TrackedChangeKind.other => Symbols.edit_rounded,
    };

class ChangesPanel extends StatelessWidget {
  const ChangesPanel({super.key, required this.doc, required this.onClose, required this.closeLabel, this.onRan});

  final DocumentController doc;
  final VoidCallback onClose;
  final String closeLabel;
  final VoidCallback? onRan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = QuillTokens.of(context);
    final list = changesInTextOrder(doc.changes);
    final editable = doc.canEdit;
    return SidePanel(
      title: l10n.changesTitle,
      closeLabel: closeLabel,
      onClose: onClose,
      side: AxisDirection.left,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          WSwitch(
            value: doc.tracking,
            label: l10n.changesTracking,
            onChanged: doc.isOpen && !doc.readOnly ? (v) => doc.setTracking(v) : null,
          ),
          SizedBox(width: t.space.sm),
          Flexible(child: ExcludeSemantics(child: WLabel(l10n.changesTracking, maxLines: 2))),
        ]),
        SizedBox(height: t.space.xs),
        WCheckbox(value: doc.showChanges, label: l10n.changesShow, onChanged: (_) => doc.toggleShowChanges()),
        SizedBox(height: t.space.sm),
        Wrap(spacing: t.space.xs, runSpacing: t.space.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [
          WButton(
            icon: Symbols.arrow_upward_rounded,
            label: l10n.commandPreviousChange,
            onPressed: list.isEmpty ? null : () => doc.nextChange(back: true),
          ),
          WButton(
            icon: Symbols.arrow_downward_rounded,
            label: l10n.commandNextChange,
            onPressed: list.isEmpty ? null : doc.nextChange,
          ),
          if (editable) ...[
            WTextButton(
              label: l10n.commandAcceptAll,
              icon: Symbols.done_all_rounded,
              onPressed: list.isEmpty ? null : doc.acceptAllChanges,
            ),
            WTextButton(
              label: l10n.commandRejectAll,
              icon: Symbols.remove_done_rounded,
              onPressed: list.isEmpty ? null : doc.rejectAllChanges,
            ),
          ],
        ]),
        SizedBox(height: t.space.sm),
        if (list.isNotEmpty) ...[
          WLabel(l10n.changesCount(list.length), small: true, tone: WLabelTone.muted),
          SizedBox(height: t.space.xs),
        ],
        Expanded(
          child: list.isEmpty
              ? WLabel(l10n.changesEmpty, tone: WLabelTone.muted, maxLines: 4)
              : Semantics(
                  container: true,
                  label: l10n.changesTitle,
                  child: ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, _) => SizedBox(height: t.space.sm),
                    itemBuilder: (context, i) => _ChangeCard(
                      change: list[i],
                      editable: editable,
                      onTap: () {
                        doc.goToChange(list[i]);
                        onRan?.call();
                      },
                      onAccept: () => doc.acceptChange(list[i].index),
                      onReject: () => doc.rejectChange(list[i].index),
                    ),
                  ),
                ),
        ),
      ]),
    );
  }
}

class _ChangeCard extends StatefulWidget {
  const _ChangeCard({
    required this.change,
    required this.editable,
    required this.onTap,
    required this.onAccept,
    required this.onReject,
  });

  final TrackedChange change;
  final bool editable;
  final VoidCallback onTap, onAccept, onReject;

  @override
  State<_ChangeCard> createState() => _ChangeCardState();
}

class _ChangeCardState extends State<_ChangeCard> {
  bool _hover = false, _focused = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = QuillTokens.of(context);
    final c = t.colors;
    final ch = widget.change;
    final kind = changeKindLabel(l10n, ch.kind);
    final who = ch.author.isEmpty ? l10n.commentsNoAuthor : ch.author;
    final byline = [kind, who, if (ch.date case final d?) snapshotWhen(context, d)].join(' · ');
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Container(
        padding: EdgeInsets.all(t.space.sm),
        decoration: BoxDecoration(
          color: _hover ? c.surfaceHigh : c.surfaceContainer,
          borderRadius: BorderRadius.circular(t.radius.control),
          border: Border.all(color: _focused ? c.focusRing : c.border, width: _focused ? 2 : 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Semantics(
            button: true,
            label: '$byline. ${ch.description}',
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
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(changeKindIcon(ch.kind), size: t.density.icon, color: c.onFrameMuted),
                    SizedBox(width: t.space.sm),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        WLabel(byline, small: true, tone: WLabelTone.muted, maxLines: 2),
                        SizedBox(height: t.space.xs),
                        WLabel(ch.description, maxLines: 6),
                        if (ch.comment.isNotEmpty) WLabel(ch.comment, small: true, maxLines: 4),
                      ]),
                    ),
                  ]),
                ),
              ),
            ),
          ),
          if (widget.editable)
            Wrap(alignment: WrapAlignment.end, children: [
              WButton(icon: Symbols.check_rounded, label: l10n.changesAccept, onPressed: widget.onAccept),
              WButton(icon: Symbols.close_rounded, label: l10n.changesReject, onPressed: widget.onReject),
            ]),
        ]),
      ),
    );
  }
}
