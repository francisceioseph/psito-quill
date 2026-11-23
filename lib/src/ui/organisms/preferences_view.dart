// As preferências, nos bastidores do Arquivo (D-064): o tema, os atalhos, a
// abertura e a privacidade.
import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../commands/command_registry.dart';
import '../../settings/settings.dart';
import '../atoms/w_button.dart';
import '../atoms/w_label.dart';
import '../tokens/tokens.dart';

class PreferencesView extends StatelessWidget {
  const PreferencesView({super.key, required this.settings});

  final Settings settings;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final l10n = AppLocalizations.of(context);
    Widget caption(String text) => Padding(
          padding: EdgeInsets.only(top: t.space.lg, bottom: t.space.sm),
          child: WLabel(text, tone: WLabelTone.muted),
        );
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        caption(l10n.prefTheme),
        Wrap(spacing: t.space.sm, children: [
          for (final (id, label) in [('claro', l10n.themeClaro), ('escuro', l10n.themeEscuro), ('sepia', l10n.themeSepia), ('classico97', l10n.themeClassico)])
            WTextButton(label: label, selected: settings.theme == id, onPressed: () => settings.theme = id),
        ]),
        caption(l10n.prefShortcuts),
        Wrap(spacing: t.space.sm, runSpacing: t.space.sm, children: [
          for (final (scheme, label) in [(ShortcutScheme.wordPt, l10n.schemeWordPt), (ShortcutScheme.wordEn, l10n.schemeWordEn)])
            WTextButton(label: label, selected: settings.shortcuts == scheme, onPressed: () => settings.shortcuts = scheme),
        ]),
        caption(l10n.prefStart),
        Wrap(spacing: t.space.sm, children: [
          WTextButton(label: l10n.prefStartScreen, selected: settings.startScreen, onPressed: () => settings.startScreen = true),
          WTextButton(label: l10n.prefStartBlank, selected: !settings.startScreen, onPressed: () => settings.startScreen = false),
        ]),
        caption(l10n.prefPrivacy),
        WTextButton(
          label: l10n.prefKeepRecents,
          selected: settings.keepRecents,
          onPressed: () => settings.keepRecents = !settings.keepRecents,
        ),
        SizedBox(height: t.space.sm),
        WLabel(l10n.prefPrivacyNote, tone: WLabelTone.muted, maxLines: 3),
      ]),
    );
  }
}
