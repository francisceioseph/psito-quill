// A janela do parágrafo (Fase 4, Etapa 6, D-091): a cor de fundo, "não
// adicionar intervalo entre parágrafos do mesmo estilo", as bordas e as
// tabulações. O motor não diz tudo do parágrafo do cursor (a largura e a cor
// da borda, o intervalo, o preenchimento das tabulações), então a janela
// devolve só o que a pessoa mudou nela ([ParagraphChanges]).
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../document/doc_colors.dart';
import '../../document/paragraph_format.dart';
import '../atoms/w_button.dart';
import '../atoms/w_checkbox.dart';
import '../atoms/w_chip.dart';
import '../atoms/w_dropdown.dart';
import '../atoms/w_label.dart';
import '../atoms/w_segmented.dart';
import '../atoms/w_text_field.dart';
import '../molecules/measure_field.dart';
import '../molecules/swatch_row.dart';
import '../tokens/tokens.dart';
import 'inspector.dart' show colorName;

/// [borderSides]: os lados com borda que o motor diz (null: não disse).
Future<ParagraphChanges?> showParagraphDialog(
  BuildContext context, {
  required bool noSpaceSameStyle,
  required int? borderSides,
  required List<TabStopSpec> tabs,
}) =>
    showDialog<ParagraphChanges>(
      context: context,
      builder: (_) => _ParagraphDialog(noSpaceSameStyle: noSpaceSameStyle, borderSides: borderSides, tabs: tabs),
    );

enum _Part { background, spacing, borders, tabs }

class _ParagraphDialog extends StatefulWidget {
  const _ParagraphDialog({required this.noSpaceSameStyle, required this.borderSides, required this.tabs});
  final bool noSpaceSameStyle;
  final int? borderSides;
  final List<TabStopSpec> tabs;

  @override
  State<_ParagraphDialog> createState() => _ParagraphDialogState();
}

class _ParagraphDialogState extends State<_ParagraphDialog> {
  _Part _part = _Part.background;

  // O fundo: null fica como está; -1 é sem cor.
  int? _background;
  late bool _noSpace = widget.noSpaceSameStyle;
  late BorderPreset? _preset = widget.borderSides == null ? null : BorderPreset.of(widget.borderSides!);
  BorderWeight _weight = BorderWeight.thin;
  int _borderColor = 0x000000;
  bool _bordersTouched = false;
  late final _tabs = [...widget.tabs];
  bool _tabsTouched = false;
  final _tabPosition = TextEditingController();
  TabAlign _tabAlign = TabAlign.left;
  TabLeader _tabLeader = TabLeader.none;

  @override
  void dispose() {
    _tabPosition.dispose();
    super.dispose();
  }

  ParagraphChanges get _changes => ParagraphChanges(
        background: _background == null || _background! < 0 ? null : _background,
        clearBackground: _background == -1,
        noSpaceSameStyle: _noSpace == widget.noSpaceSameStyle ? null : _noSpace,
        borders: _bordersTouched && _preset != null
            ? BorderSpec(sides: _preset!.sides, weight: _weight, color: _borderColor)
            : null,
        tabs: _tabsTouched ? _tabs : null,
      );

  double? get _newTabCm => parseCm(_tabPosition.text);

  void _addTab() {
    final cm = _newTabCm;
    if (cm == null || cm < 0 || cm > 100) return;
    final pos = (cm * 1000).round();
    setState(() {
      _tabs
        ..removeWhere((t) => (t.positionMm100 - pos).abs() < 10)
        ..add(TabStopSpec(positionMm100: pos, align: _tabAlign, leader: _tabLeader))
        ..sort((a, b) => a.positionMm100.compareTo(b.positionMm100));
      _tabsTouched = true;
      _tabPosition.clear();
    });
  }

  String _alignLabel(AppLocalizations l10n, TabAlign a) => switch (a) {
        TabAlign.left => l10n.tabAlignLeft,
        TabAlign.center => l10n.tabAlignCenter,
        TabAlign.right => l10n.tabAlignRight,
        TabAlign.decimal => l10n.tabAlignDecimal,
      };

  String _leaderLabel(AppLocalizations l10n, TabLeader f) => switch (f) {
        TabLeader.none => l10n.tabLeaderNone,
        TabLeader.dots => l10n.tabLeaderDots,
        TabLeader.dashes => l10n.tabLeaderDashes,
        TabLeader.line => l10n.tabLeaderLine,
      };

  String _presetLabel(AppLocalizations l10n, BorderPreset p) => switch (p) {
        BorderPreset.none => l10n.borderNone,
        BorderPreset.box => l10n.borderBox,
        BorderPreset.top => l10n.borderTop,
        BorderPreset.bottom => l10n.borderBottom,
        BorderPreset.topBottom => l10n.borderTopBottom,
        BorderPreset.left => l10n.borderLeft,
      };

  String _weightLabel(AppLocalizations l10n, BorderWeight w) => switch (w) {
        BorderWeight.thin => l10n.borderThin,
        BorderWeight.medium => l10n.borderMedium,
        BorderWeight.thick => l10n.borderThick,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = QuillTokens.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    Widget caption(String text) => Padding(
          padding: EdgeInsets.only(top: t.space.md, bottom: t.space.xs),
          child: WLabel(text, small: true, tone: WLabelTone.muted),
        );

    final body = switch (_part) {
      _Part.background => [
          caption(l10n.paragraphBackground),
          SwatchRow(swatches: [
            (rgb: null, label: l10n.paragraphBackgroundNone, selected: _background == -1, onPressed: () => setState(() => _background = -1)),
            for (final (name, rgb) in highlightChoices)
              (rgb: rgb, label: colorName(l10n, name), selected: _background == rgb, onPressed: () => setState(() => _background = rgb)),
          ]),
          SizedBox(height: t.space.sm),
          WLabel(l10n.paragraphBackgroundNote, small: true, tone: WLabelTone.muted, maxLines: 3),
        ],
      _Part.spacing => [
          SizedBox(height: t.space.md),
          WCheckbox(value: _noSpace, label: l10n.paragraphNoSpaceSameStyle, onChanged: (v) => setState(() => _noSpace = v)),
          SizedBox(height: t.space.sm),
          WLabel(l10n.paragraphNoSpaceNote, small: true, tone: WLabelTone.muted, maxLines: 3),
        ],
      _Part.borders => [
          caption(l10n.borderSides),
          Wrap(spacing: t.space.sm, runSpacing: t.space.sm, children: [
            for (final p in BorderPreset.values)
              WChip(
                label: _presetLabel(l10n, p),
                selected: _preset == p,
                onPressed: () => setState(() {
                  _preset = p;
                  _bordersTouched = true;
                }),
              ),
          ]),
          caption(l10n.borderWeight),
          WSegmented<BorderWeight>(
            label: l10n.borderWeight,
            expanded: true,
            segments: [for (final w in BorderWeight.values) WSegment(w, _weightLabel(l10n, w))],
            selected: _weight,
            onChanged: (w) => setState(() {
              _weight = w;
              _bordersTouched = true;
            }),
          ),
          caption(l10n.borderColor),
          SwatchRow(swatches: [
            for (final (name, rgb) in fontColorChoices)
              (
                rgb: rgb,
                label: colorName(l10n, name),
                selected: _borderColor == rgb,
                onPressed: () => setState(() {
                  _borderColor = rgb;
                  _bordersTouched = true;
                }),
              ),
          ]),
        ],
      _Part.tabs => [
          caption(l10n.tabsCurrent),
          if (_tabs.isEmpty)
            WLabel(l10n.tabsNone, small: true, tone: WLabelTone.muted)
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView(shrinkWrap: true, children: [
                for (final tab in _tabs)
                  Row(children: [
                    Expanded(
                      child: WLabel(
                        l10n.tabsItem(
                          l10n.measureCm(formatCm(tab.positionMm100 / 1000, locale)),
                          _alignLabel(l10n, tab.align),
                          _leaderLabel(l10n, tab.leader),
                        ),
                        maxLines: 1,
                      ),
                    ),
                    WButton(
                      icon: Symbols.delete_rounded,
                      label: l10n.tabsRemove(l10n.measureCm(formatCm(tab.positionMm100 / 1000, locale))),
                      onPressed: () => setState(() {
                        _tabs.remove(tab);
                        _tabsTouched = true;
                      }),
                    ),
                  ]),
              ]),
            ),
          caption(l10n.tabsNew),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            SizedBox(
              width: 96,
              child: WTextField(
                label: l10n.tabsPosition,
                controller: _tabPosition,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _addTab(),
              ),
            ),
            SizedBox(width: t.space.sm),
            WDropdown<TabAlign>(
              label: l10n.tabsAlign,
              text: _alignLabel(l10n, _tabAlign),
              items: [for (final a in TabAlign.values) WDropdownItem(a, _alignLabel(l10n, a))],
              onSelected: (a) => setState(() => _tabAlign = a),
              width: 120,
            ),
            SizedBox(width: t.space.sm),
            WDropdown<TabLeader>(
              label: l10n.tabsLeader,
              text: _leaderLabel(l10n, _tabLeader),
              items: [for (final f in TabLeader.values) WDropdownItem(f, _leaderLabel(l10n, f))],
              onSelected: (f) => setState(() => _tabLeader = f),
              width: 120,
            ),
          ]),
          SizedBox(height: t.space.sm),
          Row(children: [
            WTextButton(
              label: l10n.tabsAdd,
              icon: Symbols.add_rounded,
              pill: false,
              onPressed: _newTabCm == null ? null : _addTab,
            ),
            SizedBox(width: t.space.sm),
            WTextButton(
              label: l10n.tabsClear,
              icon: Symbols.clear_all_rounded,
              pill: false,
              onPressed: _tabs.isEmpty
                  ? null
                  : () => setState(() {
                        _tabs.clear();
                        _tabsTouched = true;
                      }),
            ),
          ]),
        ],
    };

    return AlertDialog(
      title: Text(l10n.paragraphDialogTitle),
      content: SizedBox(
        width: 460,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          WSegmented<_Part>(
            label: l10n.paragraphDialogParts,
            expanded: true,
            segments: [
              WSegment(_Part.background, l10n.paragraphPartBackground),
              WSegment(_Part.spacing, l10n.paragraphPartSpacing),
              WSegment(_Part.borders, l10n.paragraphPartBorders),
              WSegment(_Part.tabs, l10n.paragraphPartTabs),
            ],
            selected: _part,
            onChanged: (p) => setState(() => _part = p),
          ),
          ...body,
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.dialogCancel)),
        FilledButton(
          onPressed: _changes.isEmpty ? null : () => Navigator.pop(context, _changes),
          child: Text(l10n.paragraphApply),
        ),
      ],
    );
  }
}
