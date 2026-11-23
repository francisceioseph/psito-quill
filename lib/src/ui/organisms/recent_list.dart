// Os arquivos recentes numa tabela (os bastidores e a tela inicial, D-064):
// o nome, a pasta e quando o arquivo mudou. A data vem do disco, lida só
// quando a lista é construída (dez arquivos no máximo).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../files/recent_files.dart';
import '../atoms/w_button.dart';
import '../atoms/w_label.dart';
import '../tokens/tokens.dart';

class RecentList extends StatelessWidget {
  const RecentList({super.key, required this.recents, required this.onOpen});

  final RecentFiles recents;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: recents,
      builder: (context, _) {
        if (recents.paths.isEmpty) return WLabel(l10n.recentEmpty, tone: WLabelTone.muted);
        return Semantics(
          label: l10n.recentTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: t.space.md, vertical: t.space.xs),
                child: ExcludeSemantics(
                  child: Row(children: [
                    SizedBox(width: t.density.icon + t.space.md),
                    Expanded(flex: 3, child: WLabel(l10n.recentName, small: true, tone: WLabelTone.muted)),
                    Expanded(flex: 4, child: WLabel(l10n.recentFolder, small: true, tone: WLabelTone.muted)),
                    SizedBox(width: 150, child: WLabel(l10n.recentModified, small: true, tone: WLabelTone.muted)),
                  ]),
                ),
              ),
              for (final p in recents.paths) _RecentRow(path: p, onOpen: () => onOpen(p)),
            ],
          ),
        );
      },
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.path, required this.onOpen});

  final String path;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final loc = MaterialLocalizations.of(context);
    final file = File(path);
    final name = file.uri.pathSegments.last;
    DateTime? modified;
    try {
      modified = file.statSync().type == FileSystemEntityType.notFound ? null : file.lastModifiedSync();
    } on FileSystemException {
      modified = null;
    }
    final when = modified == null
        ? l10n.recentMissing
        : '${loc.formatShortDate(modified)} ${loc.formatTimeOfDay(TimeOfDay.fromDateTime(modified))}';
    return LayoutBuilder(
      builder: (context, box) => WControlSurface(
        width: box.maxWidth,
        height: t.density.control + t.space.md,
        tooltip: path,
        selected: false,
        onPressed: modified == null ? null : onOpen,
        semantics: (child) => Semantics(button: true, enabled: modified != null, label: '$name, ${file.parent.path}, $when', excludeSemantics: true, child: child),
        child: Row(children: [
          Icon(Symbols.description_rounded, size: t.density.icon, color: t.colors.accent),
          SizedBox(width: t.space.md),
          Expanded(flex: 3, child: WLabel(name)),
          Expanded(flex: 4, child: WLabel(file.parent.path, small: true, tone: WLabelTone.muted)),
          SizedBox(width: 150, child: WLabel(when, small: true, tone: WLabelTone.muted)),
        ]),
      ),
    );
  }
}
