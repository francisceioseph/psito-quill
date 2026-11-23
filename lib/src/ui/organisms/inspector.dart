// O painel Formatar, à direita (F10 mostra e esconde). Muda com o que está
// selecionado: o texto (caractere e parágrafo), a imagem, a tabela; a
// página fica sempre embaixo. Com "Revelar formatação" (Shift+F1), mostra
// em cima o que vale no cursor, como o WordPerfect.
//
// Tudo o que mostra vem do motor (os estados); tudo o que muda vai por um
// comando.
import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../commands/command_registry.dart';
import '../../commands/commands_document.dart';
import '../../document/doc_colors.dart';
import '../../document/document_controller.dart';
import '../atoms/w_button.dart';
import '../atoms/w_color_swatch.dart';
import '../atoms/w_label.dart';
import '../molecules/command_button.dart';
import '../molecules/inspector_section.dart';
import '../molecules/measure_field.dart';
import '../style_labels.dart';
import '../tokens/tokens.dart';
import 'ribbon.dart' show formatPoints;

String colorName(AppLocalizations l10n, DocColorName n) => switch (n) {
      DocColorName.black => l10n.colorBlack,
      DocColorName.gray => l10n.colorGray,
      DocColorName.red => l10n.colorRed,
      DocColorName.orange => l10n.colorOrange,
      DocColorName.yellow => l10n.colorYellow,
      DocColorName.green => l10n.colorGreen,
      DocColorName.blue => l10n.colorBlue,
      DocColorName.purple => l10n.colorPurple,
    };

/// As margens prontas da faixa Layout e do painel.
List<(String, PageMargins)> marginPresets(AppLocalizations l10n) => [
      (l10n.marginsNormal, (left: 2.5, right: 2.5, top: 2.5, bottom: 2.5)),
      (l10n.marginsNarrow, (left: 1.27, right: 1.27, top: 1.27, bottom: 1.27)),
      (l10n.marginsAbnt, (left: 3.0, right: 2.0, top: 3.0, bottom: 2.0)),
      (l10n.marginsWide, (left: 5.08, right: 5.08, top: 2.54, bottom: 2.54)),
    ];

String pageSizeLabel(AppLocalizations l10n, PageSize s) => switch (s.id) {
      'a4' => l10n.pageSizeA4,
      'a5' => l10n.pageSizeA5,
      'carta' => l10n.pageSizeLetter,
      'livro6x9' => l10n.pageSizeBook6x9,
      'livro55x85' => l10n.pageSizeBook55x85,
      _ => s.id,
    };

class Inspector extends StatelessWidget {
  const Inspector({super.key, required this.doc, required this.commands, required this.reveal, this.onRan});

  final DocumentController doc;
  final CommandRegistry commands;

  /// Mostra a seção "Revelar formatação".
  final bool reveal;
  final VoidCallback? onRan;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    Widget cmd(String id) => CommandButton(commands: commands, id: id, onRan: onRan);
    Widget row(List<String> ids) => Wrap(spacing: t.space.xs, runSpacing: t.space.xs, children: [for (final id in ids) cmd(id)]);
    final editable = doc.canEdit;
    final indents = doc.paragraphIndents;
    final unit = l10n.unitCm;

    return Semantics(
      container: true,
      label: l10n.inspectorTitle,
      explicitChildNodes: true,
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: t.colors.frame,
          border: Border(left: BorderSide(color: t.colors.border)),
        ),
        child: ListView(children: [
          if (reveal) _RevealSection(doc: doc),
          if (doc.graphic != null)
            InspectorSection(title: l10n.sectionImage, children: [
              if (doc.graphicSizeCm case final s?)
                WLabel(l10n.imageSizeCm(formatCm(s.width, locale), formatCm(s.height, locale)), small: true),
              row([CommandIds.wrapOff, CommandIds.wrapIdeal, CommandIds.wrapThrough]),
              row([CommandIds.imageLeft, CommandIds.imageCenter, CommandIds.imageRight]),
            ]),
          if (doc.inTable)
            InspectorSection(title: l10n.sectionTable, children: [
              row([CommandIds.rowAbove, CommandIds.rowBelow, CommandIds.columnLeft, CommandIds.columnRight]),
              row([CommandIds.deleteRow, CommandIds.deleteColumn, CommandIds.deleteTable, CommandIds.mergeCells]),
            ]),
          InspectorSection(title: l10n.sectionCharacter, children: [
            row([
              CommandIds.bold,
              CommandIds.italic,
              CommandIds.underline,
              CommandIds.strikeout,
              CommandIds.superscript,
              CommandIds.subscript,
            ]),
            WLabel(l10n.fieldFontColor, small: true, tone: WLabelTone.muted),
            Wrap(spacing: t.space.xs, children: [
              WColorSwatch(
                rgb: null,
                label: l10n.colorAutomatic,
                selected: doc.fontColor == null,
                onPressed: editable ? () => doc.setFontColor(null) : null,
              ),
              for (final (name, rgb) in fontColorChoices)
                WColorSwatch(
                  rgb: rgb,
                  label: colorName(l10n, name),
                  selected: doc.fontColor == rgb,
                  onPressed: editable ? () => doc.setFontColor(rgb) : null,
                ),
            ]),
            WLabel(l10n.fieldHighlight, small: true, tone: WLabelTone.muted),
            Wrap(spacing: t.space.xs, children: [
              WColorSwatch(
                rgb: null,
                label: l10n.highlightNone,
                selected: doc.highlightColor == null,
                onPressed: editable ? () => doc.setHighlight(null) : null,
              ),
              for (final (name, rgb) in highlightChoices)
                WColorSwatch(
                  rgb: rgb,
                  label: colorName(l10n, name),
                  selected: doc.highlightColor == rgb,
                  onPressed: editable ? () => doc.setHighlight(rgb) : null,
                ),
            ]),
            row([CommandIds.clearFormatting]),
          ]),
          InspectorSection(title: l10n.sectionParagraph, children: [
            row([CommandIds.alignLeft, CommandIds.alignCenter, CommandIds.alignRight, CommandIds.justify]),
            row([CommandIds.bullets, CommandIds.numbering, CommandIds.indentLess, CommandIds.indentMore]),
            LabeledRow(
              label: l10n.fieldLineSpacing,
              child: row([CommandIds.lineSpacing1, CommandIds.lineSpacing15, CommandIds.lineSpacing2]),
            ),
            MeasureField(
              label: l10n.fieldIndentLeft,
              value: indents['left'],
              unit: unit,
              onDone: onRan,
              onChanged: editable ? (v) => doc.setIndents(left: v) : null,
            ),
            MeasureField(
              label: l10n.fieldIndentFirst,
              value: indents['firstline'],
              unit: unit,
              onDone: onRan,
              onChanged: editable ? (v) => doc.setIndents(firstLine: v) : null,
            ),
            MeasureField(
              label: l10n.fieldIndentRight,
              value: indents['right'],
              unit: unit,
              onDone: onRan,
              onChanged: editable ? (v) => doc.setIndents(right: v) : null,
            ),
            LabeledRow(label: l10n.fieldSpacing, child: row([CommandIds.spaceLess, CommandIds.spaceMore])),
          ]),
          InspectorSection(title: l10n.sectionPage, children: [
            row([CommandIds.portrait, CommandIds.landscape]),
            WLabel(l10n.fieldPageSize, small: true, tone: WLabelTone.muted),
            Wrap(spacing: t.space.xs, runSpacing: t.space.xs, children: [
              for (final s in pageSizes)
                WTextButton(label: pageSizeLabel(l10n, s), onPressed: editable ? () => doc.setPageSize(s) : null),
            ]),
            WLabel(l10n.fieldMargins, small: true, tone: WLabelTone.muted),
            Wrap(spacing: t.space.xs, runSpacing: t.space.xs, children: [
              for (final (label, m) in marginPresets(l10n))
                WTextButton(label: label, onPressed: editable ? () => doc.setPageMargins(m) : null),
            ]),
          ]),
        ]),
      ),
    );
  }
}

/// "Revelar formatação": o que vale no cursor, lido dos estados do motor.
class _RevealSection extends StatelessWidget {
  const _RevealSection({required this.doc});
  final DocumentController doc;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final s = doc.commandStates;
    String cm(double? v) => v == null ? '—' : l10n.measureCm(formatCm(v, locale));
    final effects = [
      if (doc.isOn('.uno:Bold')) l10n.commandBold,
      if (doc.isOn('.uno:Italic')) l10n.commandItalic,
      if (doc.isOn('.uno:Underline')) l10n.commandUnderline,
      if (doc.isOn('.uno:Strikeout')) l10n.commandStrikeout,
      if (doc.isOn('.uno:SuperScript')) l10n.commandSuperscript,
      if (doc.isOn('.uno:SubScript')) l10n.commandSubscript,
    ];
    final align = doc.isOn('.uno:CenterPara')
        ? l10n.commandAlignCenter
        : doc.isOn('.uno:RightPara')
            ? l10n.commandAlignRight
            : doc.isOn('.uno:JustifyPara')
                ? l10n.commandJustify
                : l10n.commandAlignLeft;
    final indents = doc.paragraphIndents;
    final spacing = doc.paragraphSpacing;
    final colorRgb = doc.fontColor;
    final color = colorRgb == null
        ? l10n.colorAutomatic
        : fontColorChoices.where((c) => c.$2 == colorRgb).map((c) => colorName(l10n, c.$1)).firstOrNull ??
            '#${colorRgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
    final size = doc.fontSize;
    final rows = [
      (l10n.revealParagraphStyle, doc.paragraphStyleId == null ? '—' : styleLabel(l10n, doc.paragraphStyleId!)),
      (l10n.revealFont, [doc.fontName ?? '—', if (size != null) '${formatPoints(size, locale)} pt'].join(', ')),
      (l10n.revealEffects, effects.isEmpty ? l10n.revealNone : effects.join(', ')),
      (l10n.revealColor, color),
      (l10n.revealAlignment, align),
      (
        l10n.revealIndents,
        '${l10n.fieldIndentLeft} ${cm(indents['left'])} · ${l10n.fieldIndentFirst} ${cm(indents['firstline'])}'
      ),
      (l10n.revealSpacing, '${cm(spacing['upper'])} · ${cm(spacing['lower'])}'),
      (
        l10n.revealLineSpacing,
        switch (doc.lineSpacing) {
          final p? => l10n.percentValue(p),
          null => l10n.revealOther,
        }
      ),
      (l10n.revealLanguage, (s['.uno:LanguageStatus'] ?? '—').split(';').first),
      (l10n.revealPageStyle, s['.uno:PageStyleName'] ?? '—'),
    ];
    return InspectorSection(title: l10n.sectionReveal, children: [
      for (final (label, value) in rows)
        Semantics(
          label: '$label: $value',
          child: ExcludeSemantics(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              WLabel(label, small: true, tone: WLabelTone.muted),
              WLabel(value, maxLines: 2),
            ]),
          ),
        ),
    ]);
  }
}
