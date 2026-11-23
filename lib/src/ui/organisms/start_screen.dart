// A tela inicial (D-064): o editor sem documento. Dois cartões grandes
// (Documento em branco e Abrir) e os recentes numa tabela.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../document/workspace.dart';
import '../atoms/w_button.dart';
import '../atoms/w_label.dart';
import '../tokens/tokens.dart';
import 'recent_list.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key, required this.workspace});

  final Workspace workspace;

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
