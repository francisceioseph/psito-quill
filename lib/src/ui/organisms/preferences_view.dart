// As preferências, nos bastidores do Arquivo (D-064, D-067): Geral,
// Aparência, Acessibilidade, Privacidade, Acesso rápido e Atalhos (D-093:
// escolher os do acesso rápido e o atalho de cada comando). Só a seção aberta
// é construída.
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../commands/command_registry.dart';
import '../../settings/settings.dart';
import '../atoms/w_button.dart';
import '../atoms/w_dropdown.dart';
import '../atoms/w_label.dart';
import '../atoms/w_segmented.dart';
import '../atoms/w_switch.dart';
import '../atoms/w_text_field.dart';
import '../theme_labels.dart';
import '../tokens/tokens.dart';
import 'shortcut_dialog.dart';

enum PreferencesSection { general, appearance, accessibility, privacy, quickAccess, shortcuts }

class PreferencesView extends StatefulWidget {
  const PreferencesView({super.key, required this.settings, this.commands, this.initial = PreferencesSection.general});

  final Settings settings;

  /// Os comandos, para o acesso rápido e os atalhos; sem eles, só o jogo.
  final CommandRegistry? commands;
  final PreferencesSection initial;

  @override
  State<PreferencesView> createState() => _PreferencesViewState();
}

class _PreferencesViewState extends State<PreferencesView> {
  late PreferencesSection _section = widget.initial;
  late final _author = TextEditingController(text: widget.settings.authorName);
  late final _systemName = systemUserName();
  final _filter = TextEditingController();

  @override
  void dispose() {
    _author.dispose();
    _filter.dispose();
    super.dispose();
  }

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
            if (widget.commands != null) WSegment(PreferencesSection.quickAccess, l10n.prefQuickAccess),
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
          PreferencesSection.quickAccess => _quickAccess(l10n, s),
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
        _Row(
          label: l10n.prefAuthorName,
          note: l10n.prefAuthorNameNote(_systemName),
          child: WTextField(
            label: l10n.prefAuthorName,
            hint: _systemName,
            controller: _author,
            width: 320,
            onChanged: (v) => s.authorName = v,
          ),
        ),
        _switch(l10n.prefAutosave, s.autosave, (v) => s.autosave = v, note: l10n.prefAutosaveNote),
        _switch(l10n.prefAutoSnapshots, s.autoSnapshots, (v) => s.autoSnapshots = v, note: l10n.prefAutoSnapshotsNote),
        // A ortografia (D-093): vai no perfil do motor, que só lê ao ligar.
        _switch(l10n.prefSpellIgnoreUpper, s.spellIgnoreUpper, (v) => s.spellIgnoreUpper = v),
        _switch(l10n.prefSpellIgnoreDigits, s.spellIgnoreDigits, (v) => s.spellIgnoreDigits = v, note: l10n.prefSpellRulesNote),
        // Os sons da máquina de escrever (D-095).
        _switch(l10n.prefTypewriterSound, s.typewriterSound, (v) => s.typewriterSound = v, note: l10n.prefTypewriterSoundNote),
        if (s.typewriterSound)
          _Row(
            label: l10n.prefTypewriterVolume,
            child: _choices(l10n.prefTypewriterVolume,
                [(0.3, l10n.prefVolumeLow), (0.6, l10n.prefVolumeMedium), (1.0, l10n.prefVolumeHigh)], s.typewriterVolume,
                (v) => s.typewriterVolume = v),
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

  /// Os comandos que dá para pôr no acesso rápido e nos atalhos, pelo nome.
  List<Command> _sorted(CommandRegistry commands) => [...commands.all]..sort((a, b) => a.label.compareTo(b.label));

  List<Widget> _quickAccess(AppLocalizations l10n, Settings s) {
    final commands = widget.commands!;
    final t = QuillTokens.of(context);
    final list = [for (final id in s.quickAccess) if (commands[id] != null) id];
    void save(List<String> v) => s.quickAccess = v;
    return [
      WLabel(l10n.prefQuickAccessNote, small: true, tone: WLabelTone.muted, maxLines: 3),
      SizedBox(height: t.space.md),
      for (final (i, id) in list.indexed)
        Padding(
          padding: EdgeInsets.only(bottom: t.space.xs),
          child: Row(children: [
            Icon(commands[id]!.icon, size: t.density.icon, color: t.colors.onFrameMuted),
            SizedBox(width: t.space.sm),
            Expanded(child: WLabel(commands[id]!.label, maxLines: 1)),
            WButton(
              icon: Symbols.arrow_upward_rounded,
              label: l10n.prefQuickAccessUp(commands[id]!.label),
              onPressed: i == 0 ? null : () => save([...list]..removeAt(i)..insert(i - 1, id)),
            ),
            WButton(
              icon: Symbols.arrow_downward_rounded,
              label: l10n.prefQuickAccessDown(commands[id]!.label),
              onPressed: i == list.length - 1 ? null : () => save([...list]..removeAt(i)..insert(i + 1, id)),
            ),
            WButton(
              icon: Symbols.close_rounded,
              label: l10n.prefQuickAccessRemove(commands[id]!.label),
              onPressed: () => save([...list]..removeAt(i)),
            ),
          ]),
        ),
      SizedBox(height: t.space.md),
      Row(children: [
        WDropdown<String>(
          label: l10n.prefQuickAccessAdd,
          text: l10n.prefQuickAccessAdd,
          width: 320,
          items: [
            for (final c in _sorted(commands))
              if (!list.contains(c.id)) WDropdownItem(c.id, c.label),
          ],
          onSelected: list.length >= 12 ? null : (id) => save([...list, id]),
        ),
        SizedBox(width: t.space.sm),
        WTextButton(
          label: l10n.prefQuickAccessDefault,
          pill: false,
          onPressed: listEquals(list, Settings.defaultQuickAccess) ? null : () => save(Settings.defaultQuickAccess),
        ),
      ]),
    ];
  }

  List<Widget> _shortcuts(AppLocalizations l10n, Settings s) {
    final commands = widget.commands;
    final t = QuillTokens.of(context);
    final q = _filter.text.trim().toLowerCase();
    final shown = commands == null
        ? const <Command>[]
        : [
            for (final c in _sorted(commands))
              if (q.isEmpty || c.label.toLowerCase().contains(q) || (commands.shortcutLabelOf(c.id) ?? '').toLowerCase().contains(q)) c,
          ];
    Future<void> change(String id) async {
      final choice = await showShortcutDialog(context, commands: commands!, id: id);
      if (choice == null || !mounted) return;
      s.customShortcuts = applyShortcutChoice(commands, s.customShortcuts, id, choice);
    }

    return [
      _Row(
        label: l10n.prefShortcuts,
        child: _choices(l10n.prefShortcuts,
            [(ShortcutScheme.wordPt, l10n.schemeWordPt), (ShortcutScheme.wordEn, l10n.schemeWordEn)], s.shortcuts,
            (v) => s.shortcuts = v),
      ),
      if (commands != null) ...[
        WLabel(l10n.prefShortcutsNote, small: true, tone: WLabelTone.muted, maxLines: 3),
        SizedBox(height: t.space.sm),
        Row(children: [
          WTextField(label: l10n.prefShortcutsFilter, controller: _filter, width: 320, onChanged: (_) => setState(() {})),
          SizedBox(width: t.space.sm),
          WTextButton(
            label: l10n.prefShortcutsResetAll,
            pill: false,
            onPressed: s.customShortcuts.isEmpty ? null : () => s.customShortcuts = const {},
          ),
        ]),
        SizedBox(height: t.space.sm),
        for (final c in shown)
          MergeSemantics(
            child: Row(children: [
              Expanded(child: WLabel(c.label, maxLines: 1)),
              SizedBox(
                width: 160,
                child: WLabel(
                  commands.shortcutLabelOf(c.id) ?? '—',
                  tone: s.customShortcuts.containsKey(c.id) ? WLabelTone.normal : WLabelTone.muted,
                ),
              ),
              WTextButton(label: l10n.prefShortcutChange, pill: false, onPressed: () => change(c.id)),
            ]),
          ),
      ],
    ];
  }

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
