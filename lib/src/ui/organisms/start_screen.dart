// A tela inicial (D-064): o editor sem documento. Os cartões grandes
// (Documento em branco, Abrir, e o livro novo ou importado, D-071) e os
// recentes numa tabela. Depois de uma queda, as cópias de recuperação vêm
// antes de tudo (D-073).
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../document/recovery.dart';
import '../../document/workspace.dart';
import '../atoms/w_button.dart';
import '../atoms/w_label.dart';
import '../tokens/tokens.dart';
import 'recent_list.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key, required this.workspace, this.onNewBook, this.onImport});

  final Workspace workspace;

  /// O livro novo e a importação (D-071) pedem janelas: são da página.
  final VoidCallback? onNewBook, onImport;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final l10n = AppLocalizations.of(context);
    return ColoredBox(
      color: t.colors.frameRaised,
      child: FocusTraversalGroup(
        child: ListView(
          padding: EdgeInsets.symmetric(vertical: t.space.xl * 2, horizontal: t.space.xl),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _RecoveryList(workspace: workspace),
                  Semantics(header: true, child: WLabel(l10n.startTitle, heading: true)),
                  SizedBox(height: t.space.lg),
                  Wrap(spacing: t.space.lg, runSpacing: t.space.lg, children: [
                    _StartCard(
                      icon: Symbols.note_add_rounded,
                      label: l10n.startBlank,
                      autofocus: true,
                      onPressed: () => unawaited(workspace.newDocument()),
                    ),
                    _StartCard(
                      icon: Symbols.folder_open_rounded,
                      label: l10n.startOpen,
                      onPressed: () => unawaited(workspace.openWithDialog()),
                    ),
                    if (onNewBook != null)
                      _StartCard(icon: Symbols.library_add_rounded, label: l10n.startNewBook, onPressed: onNewBook!),
                    if (onImport != null)
                      _StartCard(icon: Symbols.upload_file_rounded, label: l10n.startImport, onPressed: onImport!),
                  ]),
                  SizedBox(height: t.space.xl * 2),
                  Semantics(header: true, child: WLabel(l10n.recentHeading, heading: true)),
                  SizedBox(height: t.space.md),
                  RecentList(recents: workspace.recents, onOpen: (p) => unawaited(workspace.openPath(p))),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartCard extends StatelessWidget {
  const _StartCard({required this.icon, required this.label, required this.onPressed, this.autofocus = false});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    return WControlSurface(
      width: 200,
      height: 132,
      outlined: true,
      autofocus: autofocus,
      tooltip: null,
      selected: false,
      onPressed: onPressed,
      semantics: (child) => Semantics(button: true, label: label, child: child),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 40, color: t.colors.accent),
        SizedBox(height: t.space.md),
        WLabel(label),
      ]),
    );
  }
}

/// As cópias de uma sessão que caiu: Recuperar ou Descartar cada uma.
class _RecoveryList extends StatelessWidget {
  const _RecoveryList({required this.workspace});

  final Workspace workspace;

  Future<void> _discard(BuildContext context, RecoveryEntry e, String name) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.recoverDiscardTitle),
        content: Text(l10n.recoverDiscardBody(name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.dialogCancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.recoverDiscard)),
        ],
      ),
    );
    if (ok == true) workspace.discardRecovery(e);
  }

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final loc = MaterialLocalizations.of(context);
    return ListenableBuilder(
      listenable: workspace,
      builder: (context, _) {
        final entries = workspace.recoverable;
        if (entries.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: EdgeInsets.only(bottom: t.space.xl * 2),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Semantics(header: true, child: WLabel(l10n.recoverHeading, heading: true)),
            SizedBox(height: t.space.sm),
            WLabel(l10n.recoverNote, tone: WLabelTone.muted, maxLines: 3),
            SizedBox(height: t.space.md),
            for (final e in entries)
              Builder(builder: (context) {
                final name = e.name ?? l10n.untitled;
                final when = '${loc.formatShortDate(e.savedAt)} ${loc.formatTimeOfDay(TimeOfDay.fromDateTime(e.savedAt))}';
                final folder = e.original == null ? null : File(e.original!).parent.path;
                return Semantics(
                  container: true,
                  label: l10n.recoverRow(name, when),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: t.space.xs),
                    child: Row(children: [
                      Icon(Symbols.restore_page_rounded, size: t.density.icon, color: t.colors.accent),
                      SizedBox(width: t.space.md),
                      Expanded(
                        child: ExcludeSemantics(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            WLabel(name),
                            WLabel(folder == null ? when : '$folder · $when', small: true, tone: WLabelTone.muted),
                          ]),
                        ),
                      ),
                      WButton(icon: Symbols.restore_page_rounded, label: l10n.recoverOpen, showLabel: true, onPressed: () => workspace.recover(e)),
                      SizedBox(width: t.space.sm),
                      WButton(
                        icon: Symbols.delete_rounded,
                        label: l10n.recoverDiscard,
                        showLabel: true,
                        onPressed: () => unawaited(_discard(context, e, name)),
                      ),
                    ]),
                  ),
                );
              }),
          ]),
        );
      },
    );
  }
}
