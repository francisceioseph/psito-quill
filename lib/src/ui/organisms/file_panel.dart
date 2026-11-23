// O painel Arquivo (como o "backstage" do Word): novo, abrir, salvar, os
// recentes e as preferências (tema e atalhos).
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../commands/command_registry.dart';
import '../../commands/commands_document.dart';
import '../../document/workspace.dart';
import '../../files/recent_files.dart';
import '../../settings/settings.dart';
import '../atoms/w_button.dart';
import '../atoms/w_label.dart';
import '../molecules/command_button.dart';
import '../tokens/tokens.dart';

class FilePanel extends StatelessWidget {
  const FilePanel({
    super.key,
    required this.commands,
    required this.workspace,
    required this.recents,
    required this.settings,
    required this.onClose,
  });

  final CommandRegistry commands;
  final Workspace workspace;
  final RecentFiles recents;
  final Settings settings;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final l10n = AppLocalizations.of(context);
    Widget action(String id) => Padding(
          padding: EdgeInsets.only(bottom: t.space.sm),
          child: Align(
            alignment: Alignment.centerLeft,
            child: CommandButton(commands: commands, id: id, showLabel: true, onRan: onClose),
          ),
        );

    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): onClose},
      child: FocusScope(
        autofocus: true,
        child: ColoredBox(
          color: t.colors.frameRaised,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 220,
              padding: EdgeInsets.all(t.space.xl),
              decoration: BoxDecoration(border: Border(right: BorderSide(color: t.colors.border))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                WTextButton(label: l10n.fileBack, icon: Icons.arrow_back, onPressed: onClose),
                SizedBox(height: t.space.xl),
                action(CommandIds.newDocument),
                action(CommandIds.open),
                action(CommandIds.save),
                action(CommandIds.saveAs),
              ]),
            ),
            Expanded(
              child: ListView(padding: EdgeInsets.all(t.space.xl), children: [
                WLabel(l10n.recentTitle, heading: true),
                SizedBox(height: t.space.md),
                ListenableBuilder(
                  listenable: recents,
                  builder: (context, _) => recents.paths.isEmpty
                      ? WLabel(l10n.recentEmpty, tone: WLabelTone.muted)
                      : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          for (final p in recents.paths)
                            _RecentEntry(
                              path: p,
                              onOpen: () {
                                onClose();
                                unawaited(workspace.openPath(p));
                              },
                            ),
                        ]),
                ),
                SizedBox(height: t.space.xl * 2),
                WLabel(l10n.preferencesTitle, heading: true),
                SizedBox(height: t.space.md),
                ListenableBuilder(
                  listenable: settings,
                  builder: (context, _) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    WLabel(l10n.prefTheme, tone: WLabelTone.muted),
                    SizedBox(height: t.space.sm),
                    Wrap(spacing: t.space.sm, children: [
                      for (final (id, label) in [('claro', l10n.themeClaro), ('escuro', l10n.themeEscuro)])
                        WTextButton(
                          label: label,
                          selected: settings.theme == id,
                          onPressed: () => settings.theme = id,
                        ),
                    ]),
                    SizedBox(height: t.space.lg),
                    WLabel(l10n.prefShortcuts, tone: WLabelTone.muted),
                    SizedBox(height: t.space.sm),
                    for (final (scheme, label) in [
                      (ShortcutScheme.wordPt, l10n.schemeWordPt),
                      (ShortcutScheme.wordEn, l10n.schemeWordEn),
                    ])
                      Padding(
                        padding: EdgeInsets.only(bottom: t.space.sm),
                        child: WTextButton(
                          label: label,
                          selected: settings.shortcuts == scheme,
                          onPressed: () => settings.shortcuts = scheme,
                        ),
                      ),
                  ]),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _RecentEntry extends StatelessWidget {
  const _RecentEntry({required this.path, required this.onOpen});

  final String path;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final file = File(path);
    return Padding(
      padding: EdgeInsets.only(bottom: t.space.xs),
      child: Row(children: [
        WTextButton(label: file.uri.pathSegments.last, icon: Icons.description_outlined, onPressed: onOpen),
        SizedBox(width: t.space.md),
        Flexible(child: WLabel(file.parent.path, small: true, tone: WLabelTone.muted)),
      ]),
    );
  }
}
