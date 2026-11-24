// Os instantâneos de um capítulo (Fase 3, Etapa 7, D-081): guardar um agora
// (com um nome, se quiser), e, em cada um, comparar com o atual, restaurar
// ou apagar. A lista é lida do índice ao abrir a janela e depois de cada
// ação; nada fica na memória quando ela fecha.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../book/book.dart';
import '../../book/snapshots.dart';
import '../../document/workspace.dart';
import '../atoms/w_button.dart';
import '../atoms/w_label.dart';
import '../atoms/w_text_field.dart';
import '../tokens/tokens.dart';

/// A data e a hora de [s], no idioma da interface.
String snapshotWhen(BuildContext context, DateTime at) {
  final m = MaterialLocalizations.of(context);
  return '${m.formatMediumDate(at)}, ${m.formatTimeOfDay(TimeOfDay.fromDateTime(at), alwaysUse24HourFormat: true)}';
}

/// O que a janela pede à página quando fecha: comparar com um instantâneo.
typedef SnapshotCompareRequest = ({Snapshot snapshot, String when});

/// Mostra os instantâneos de [chapter]. Devolve o instantâneo a comparar, se
/// foi pedido (a página compara depois de fechar a janela).
Future<SnapshotCompareRequest?> showSnapshotsDialog(
  BuildContext context, {
  required Workspace workspace,
  required BookNode chapter,
  required void Function(String text) onNotice,
}) =>
    showDialog<SnapshotCompareRequest>(
      context: context,
      builder: (_) => _SnapshotsDialog(workspace: workspace, chapter: chapter, onNotice: onNotice),
    );

class _SnapshotsDialog extends StatefulWidget {
  const _SnapshotsDialog({required this.workspace, required this.chapter, required this.onNotice});
  final Workspace workspace;
  final BookNode chapter;
  final void Function(String text) onNotice;

  @override
  State<_SnapshotsDialog> createState() => _SnapshotsDialogState();
}

class _SnapshotsDialogState extends State<_SnapshotsDialog> {
  final _name = TextEditingController();
  late List<Snapshot> _list = widget.workspace.snapshotsOf(widget.chapter);
  bool _working = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _reload() => setState(() => _list = widget.workspace.snapshotsOf(widget.chapter));

  Future<void> _take() async {
    if (_working) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _working = true);
    final s = await widget.workspace.takeSnapshot(widget.chapter, name: _name.text);
    if (!mounted) return;
    _working = false;
    if (s == null) {
      widget.onNotice(l10n.snapshotFailed);
    } else {
      _name.clear();
    }
    _reload();
  }

  Future<bool> _confirm(String title, String body, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return AlertDialog(
            title: Text(title),
            content: SizedBox(width: 420, child: Text(body)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.dialogCancel)),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(action)),
            ],
          );
        },
      ) ==
      true;

  Future<void> _restore(Snapshot s) async {
    final l10n = AppLocalizations.of(context);
    final when = snapshotWhen(context, s.at);
    if (!await _confirm(l10n.snapshotRestoreTitle, l10n.snapshotRestoreBody(when), l10n.snapshotRestore) || !mounted) return;
    setState(() => _working = true);
    final ok = await widget.workspace.restoreSnapshot(widget.chapter, s, beforeName: l10n.snapshotBeforeRestore);
    if (!mounted) return;
    widget.onNotice(ok ? l10n.snapshotRestored(when) : l10n.snapshotRestoreFailed);
    if (ok) {
      Navigator.pop(context);
      return;
    }
    _working = false;
    _reload();
  }

  Future<void> _delete(Snapshot s) async {
    final l10n = AppLocalizations.of(context);
    if (!await _confirm(l10n.snapshotDeleteTitle, l10n.snapshotDeleteBody(snapshotWhen(context, s.at)), l10n.snapshotDelete) ||
        !mounted) {
      return;
    }
    widget.workspace.deleteSnapshot(widget.chapter, s);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = QuillTokens.of(context);
    return AlertDialog(
      title: Text(l10n.snapshotsTitle(widget.chapter.title)),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Expanded(
                child: WTextField(
                  label: l10n.snapshotName,
                  controller: _name,
                  autofocus: true,
                  onSubmitted: (_) => unawaited(_take()),
                ),
              ),
              SizedBox(width: t.space.sm),
              FilledButton.icon(
                onPressed: _working ? null : () => unawaited(_take()),
                icon: const Icon(Symbols.add_a_photo_rounded, size: 18),
                label: Text(l10n.snapshotTake),
              ),
            ]),
            SizedBox(height: t.space.md),
            if (_list.isEmpty)
              WLabel(l10n.snapshotsEmpty, tone: WLabelTone.muted, maxLines: 3)
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: Semantics(
                  container: true,
                  label: l10n.commandSnapshots,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _list.length,
                    itemBuilder: (context, i) {
                      final s = _list[i];
                      final when = snapshotWhen(context, s.at);
                      final name = s.name.isNotEmpty ? s.name : (s.auto ? l10n.snapshotAuto : l10n.snapshotUnnamed);
                      return _SnapshotRow(
                        title: when,
                        subtitle: '$name · ${l10n.snapshotWords(s.words)}',
                        enabled: !_working,
                        onCompare: () => Navigator.pop(context, (snapshot: s, when: when)),
                        onRestore: () => unawaited(_restore(s)),
                        onDelete: () => unawaited(_delete(s)),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.dialogClose)),
      ],
    );
  }
}

class _SnapshotRow extends StatelessWidget {
  const _SnapshotRow({
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onCompare,
    required this.onRestore,
    required this.onDelete,
  });

  final String title, subtitle;
  final bool enabled;
  final VoidCallback onCompare, onRestore, onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = QuillTokens.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: t.space.xs),
      child: Row(children: [
        Expanded(
          child: MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WLabel(title),
                WLabel(subtitle, small: true, tone: WLabelTone.muted),
              ],
            ),
          ),
        ),
        WButton(icon: Symbols.compare_rounded, label: '${l10n.snapshotCompare}: $title', tooltip: l10n.snapshotCompare, onPressed: enabled ? onCompare : null),
        WButton(icon: Symbols.history_rounded, label: '${l10n.snapshotRestore}: $title', tooltip: l10n.snapshotRestore, onPressed: enabled ? onRestore : null),
        WButton(icon: Symbols.delete_rounded, label: '${l10n.snapshotDelete}: $title', tooltip: l10n.snapshotDelete, onPressed: enabled ? onDelete : null),
      ]),
    );
  }
}
