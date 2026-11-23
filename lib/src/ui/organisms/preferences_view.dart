// As preferências, nos bastidores do Arquivo (D-064, D-067): Geral,
// Aparência, Acessibilidade, Privacidade e Atalhos. Só a seção aberta é
// construída.
import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../commands/command_registry.dart';
import '../../settings/settings.dart';
import '../atoms/w_button.dart';
import '../atoms/w_label.dart';
import '../atoms/w_segmented.dart';
import '../atoms/w_switch.dart';
import '../theme_labels.dart';
import '../tokens/tokens.dart';

enum PreferencesSection { general, appearance, accessibility, privacy, shortcuts }

class PreferencesView extends StatefulWidget {
  const PreferencesView({super.key, required this.settings, this.initial = PreferencesSection.general});

  final Settings settings;
  final PreferencesSection initial;

  @override
  State<PreferencesView> createState() => _PreferencesViewState();
}

class _PreferencesViewState extends State<PreferencesView> {
  late PreferencesSection _section = widget.initial;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final s = widget.settings;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        WSegmented<PreferencesSection>(
          label: l10n.preferencesTitle,
          segments: [
            WSegment(PreferencesSection.general, l10n.prefGeneral),
            WSegment(PreferencesSection.appearance, l10n.prefAppearance),
            WSegment(PreferencesSection.accessibility, l10n.prefAccessibility),
            WSegment(PreferencesSection.privacy, l10n.prefPrivacy),
            WSegment(PreferencesSection.shortcuts, l10n.prefShortcuts),
          ],
          selected: _section,
          onChanged: (v) => setState(() => _section = v),
        ),
        SizedBox(height: t.space.lg),
        ...switch (_section) {
          PreferencesSection.general => _general(l10n, s),
          PreferencesSection.appearance => _appearance(l10n, s),
          PreferencesSection.accessibility => _accessibility(l10n, s),
          PreferencesSection.privacy => _privacy(l10n, s),
          PreferencesSection.shortcuts => _shortcuts(l10n, s),
        },
      ]),
    );
  }

  List<Widget> _general(AppLocalizations l10n, Settings s) => [
        _Row(
          label: l10n.prefStart,
          child: _choices(l10n.prefStart, [(true, l10n.prefStartScreen), (false, l10n.prefStartBlank)], s.startScreen,
              (v) => s.startScreen = v),
        ),
        _Row(
          label: l10n.prefZoomOnOpen,
          child: _choices(l10n.prefZoomOnOpen,
              [('100', l10n.zoomPercent(100)), ('largura', l10n.commandFitWidth), ('pagina', l10n.commandFitPage)],
              s.zoomOnOpen, (v) => s.zoomOnOpen = v),
        ),
      ];

  List<Widget> _appearance(AppLocalizations l10n, Settings s) => [
        _Row(
          label: l10n.prefTheme,
          child: Wrap(
            spacing: QuillTokens.of(context).space.sm,
            runSpacing: QuillTokens.of(context).space.sm,
            children: [
              for (final (id, label) in themeChoices(l10n))
                WTextButton(label: label, selected: s.theme == id, onPressed: () => s.theme = id),
            ],
          ),
        ),
      ];

  List<Widget> _accessibility(AppLocalizations l10n, Settings s) => [
        _Row(
          label: l10n.prefUiScale,
          note: l10n.prefUiScaleNote,
          child: _choices(l10n.prefUiScale, [for (final v in const [1.0, 1.25, 1.5, 2.0]) (v, l10n.zoomPercent((v * 100).round()))],
              s.uiScale, (v) => s.uiScale = v),
        ),
        _switch(l10n.prefComfortable, s.comfortable, (v) => s.comfortable = v),
        _Row(
          label: l10n.prefCaretWidth,
          child: _choices(l10n.prefCaretWidth, [for (final v in const [1, 2, 3]) (v, l10n.prefCaretPx(v))], s.caretWidth,
              (v) => s.caretWidth = v),
        ),
        _switch(l10n.prefCaretBlink, s.caretBlink, (v) => s.caretBlink = v),
        _switch(l10n.prefReduceMotion, s.reduceMotion, (v) => s.reduceMotion = v, note: l10n.prefReduceMotionNote),
        _Row(
          label: l10n.prefSpellColor,
          note: l10n.prefSpellColorNote,
          child: _choices(l10n.prefSpellColor,
              [('vermelho', l10n.colorRed), ('azul', l10n.colorBlue), ('laranja', l10n.colorOrange)], s.spellColor,
              (v) => s.spellColor = v),
        ),
        _switch(l10n.prefScreenReaderDoc, s.screenReaderDoc, (v) => s.screenReaderDoc = v, note: l10n.prefScreenReaderDocNote),
      ];

  List<Widget> _privacy(AppLocalizations l10n, Settings s) => [
        _switch(l10n.prefKeepRecents, s.keepRecents, (v) => s.keepRecents = v),
        WLabel(l10n.prefPrivacyNote, tone: WLabelTone.muted, maxLines: 3),
      ];

  List<Widget> _shortcuts(AppLocalizations l10n, Settings s) => [
        _Row(
          label: l10n.prefShortcuts,
          child: _choices(l10n.prefShortcuts,
              [(ShortcutScheme.wordPt, l10n.schemeWordPt), (ShortcutScheme.wordEn, l10n.schemeWordEn)], s.shortcuts,
              (v) => s.shortcuts = v),
        ),
      ];

  Widget _choices<T>(String label, List<(T, String)> options, T selected, ValueChanged<T> onChanged) => Wrap(
        spacing: QuillTokens.of(context).space.sm,
        runSpacing: QuillTokens.of(context).space.sm,
        children: [
          for (final (v, text) in options)
            Semantics(
              inMutuallyExclusiveGroup: true,
              child: WTextButton(label: text, selected: v == selected, onPressed: () => onChanged(v)),
            ),
        ],
      );

  Widget _switch(String label, bool value, ValueChanged<bool> onChanged, {String? note}) => _Row(
        label: label,
        note: note,
        inline: true,
        child: WSwitch(value: value, label: label, onChanged: onChanged),
      );
}

/// Uma preferência: o nome em cima (ou ao lado de um interruptor), o
/// controle e, se houver, uma nota.
class _Row extends StatelessWidget {
  const _Row({required this.label, required this.child, this.note, this.inline = false});

  final String label;
  final Widget child;
  final String? note;
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: t.space.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (inline)
          Row(children: [child, SizedBox(width: t.space.md), Flexible(child: ExcludeSemantics(child: WLabel(label, maxLines: 2)))])
        else ...[
          ExcludeSemantics(child: WLabel(label, tone: WLabelTone.muted)),
          SizedBox(height: t.space.sm),
          Semantics(label: label, container: true, child: child),
        ],
        if (note case final n?) ...[
          SizedBox(height: t.space.xs),
          WLabel(n, small: true, tone: WLabelTone.muted, maxLines: 3),
        ],
      ]),
    );
  }
}
