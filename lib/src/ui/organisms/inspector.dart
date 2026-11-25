// O painel Formatar, à direita (F10 mostra e esconde). Muda com o que está
// selecionado: o texto (caractere e parágrafo), a imagem, a tabela; a
// página fica sempre embaixo. Com "Revelar formatação" (Shift+F1), mostra
// em cima o que vale no cursor, como o WordPerfect.
//
// Tudo o que mostra vem do motor (os estados); tudo o que muda vai por um
// comando.
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../commands/command_registry.dart';
import '../../commands/commands_document.dart';
import '../../document/doc_colors.dart';
import '../../document/document_controller.dart';
import '../../document/format_origin.dart';
import '../../commands/commands_view.dart';
import '../../commands/commands_page.dart';
import '../atoms/w_chip.dart';
import '../atoms/w_dropdown.dart';
import '../atoms/w_label.dart';
import '../atoms/w_segmented.dart';
import '../molecules/command_button.dart';
import '../molecules/inspector_section.dart';
import '../molecules/measure_field.dart';
import '../molecules/panel_action.dart';
import '../molecules/swatch_row.dart';
import '../molecules/side_panel.dart';
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

/// As seções do painel Formatar. Imagem e Tabela só aparecem com a seleção.
enum InspectorPart { text, paragraph, page, image, table }

/// A seção que aparece: Imagem e Tabela voltam para Texto quando a seleção
/// sai delas.
InspectorPart shownInspectorPart(InspectorPart part, DocumentController doc) => switch (part) {
      InspectorPart.image when doc.graphic == null => InspectorPart.text,
      InspectorPart.table when !doc.inTable => InspectorPart.text,
      final p => p,
    };

/// O ícone de cada seção, no trilho da direita (D-062).
IconData inspectorPartIcon(InspectorPart p) => switch (p) {
      InspectorPart.text => Symbols.text_fields_rounded,
      InspectorPart.paragraph => Symbols.format_paragraph_rounded,
      InspectorPart.page => Symbols.article_rounded,
      InspectorPart.image => Symbols.image_rounded,
      InspectorPart.table => Symbols.table_rounded,
    };

String inspectorPartLabel(AppLocalizations l10n, InspectorPart p) => switch (p) {
      InspectorPart.text => l10n.sectionText,
      InspectorPart.paragraph => l10n.sectionParagraph,
      InspectorPart.page => l10n.sectionPage,
      InspectorPart.image => l10n.sectionImage,
      InspectorPart.table => l10n.sectionTable,
    };

class Inspector extends StatelessWidget {
  const Inspector({
    super.key,
    required this.doc,
    required this.commands,
    required this.reveal,
    this.part = InspectorPart.text,
    this.onPart,
    this.onClose,
    this.onRan,
    this.sectionsInRail = false,
  });

  final DocumentController doc;

  /// As seções ficam no trilho da direita (D-062): sem o seletor no painel.
  /// No Clássico 97, sem trilhos, o seletor continua.
  final bool sectionsInRail;
  final CommandRegistry commands;

  /// Mostra a seção "Revelar formatação".
  final bool reveal;

  /// A seção escolhida. Só ela é construída (D-038: o painel inteiro custava
  /// uns 3,5 MB).
  final InspectorPart part;
  final ValueChanged<InspectorPart>? onPart;
  final VoidCallback? onClose;
  final VoidCallback? onRan;

  /// A seção que aparece: Imagem e Tabela voltam para Texto quando a seleção
  /// sai delas.
  InspectorPart get shownPart => shownInspectorPart(part, doc);

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    Widget cmd(String id) => CommandButton(commands: commands, id: id, onRan: onRan);
    Widget row(List<String> ids) => Wrap(spacing: t.space.sm, runSpacing: t.space.sm, children: [for (final id in ids) cmd(id)]);
    final editable = doc.canEdit;
    final unit = l10n.unitCm;
    final shown = shownPart;

    final segments = [
      WSegment(InspectorPart.text, l10n.sectionText),
      WSegment(InspectorPart.paragraph, l10n.sectionParagraph),
      WSegment(InspectorPart.page, l10n.sectionPage),
      if (doc.graphic != null) WSegment(InspectorPart.image, l10n.sectionImage),
      if (doc.inTable) WSegment(InspectorPart.table, l10n.sectionTable),
    ];

    final Widget section = switch (shown) {
      InspectorPart.text => _textSection(context, l10n, t, row, editable),
      InspectorPart.paragraph => InspectorSection(title: l10n.sectionParagraph, children: [
          row([CommandIds.alignLeft, CommandIds.alignCenter, CommandIds.alignRight, CommandIds.justify]),
          row([CommandIds.bullets, CommandIds.numbering, CommandIds.indentLess, CommandIds.indentMore]),
          LabeledRow(
            label: l10n.fieldLineSpacing,
            child: row([CommandIds.lineSpacing1, CommandIds.lineSpacing15, CommandIds.lineSpacing2]),
          ),
          // Os três recuos lado a lado, cada um com o rótulo em cima (D-062).
          WLabel(l10n.fieldIndents, small: true, tone: WLabelTone.muted),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: MeasureField(
                label: l10n.fieldIndentLeft,
                caption: l10n.fieldIndentLeftShort,
                value: doc.paragraphIndents['left'],
                unit: unit,
                onDone: onRan,
                onChanged: editable ? (v) => doc.setIndents(left: v) : null,
              ),
            ),
            SizedBox(width: t.space.md),
            Expanded(
              child: MeasureField(
                label: l10n.fieldIndentFirst,
                caption: l10n.fieldIndentFirstShort,
                value: doc.paragraphIndents['firstline'],
                unit: unit,
                onDone: onRan,
                onChanged: editable ? (v) => doc.setIndents(firstLine: v) : null,
              ),
            ),
            SizedBox(width: t.space.md),
            Expanded(
              child: MeasureField(
                label: l10n.fieldIndentRight,
                caption: l10n.fieldIndentRightShort,
                value: doc.paragraphIndents['right'],
                unit: unit,
                onDone: onRan,
                onChanged: editable ? (v) => doc.setIndents(right: v) : null,
              ),
            ),
          ]),
          LabeledRow(label: l10n.fieldSpacing, child: row([CommandIds.spaceLess, CommandIds.spaceMore])),
          // O fundo do parágrafo (D-091): o motor não diz a cor atual.
          WLabel(l10n.paragraphBackground, small: true, tone: WLabelTone.muted),
          SwatchRow(swatches: [
            (rgb: null, label: l10n.paragraphBackgroundNone, selected: false, onPressed: editable ? () => doc.setParagraphBackground(null) : null),
            for (final (name, rgb) in highlightChoices)
              (rgb: rgb, label: colorName(l10n, name), selected: false, onPressed: editable ? () => doc.setParagraphBackground(rgb) : null),
          ]),
          PanelAction(commands: commands, id: PageCommandIds.paragraph, onRan: onRan),
        ]),
      InspectorPart.page => InspectorSection(title: l10n.sectionPage, children: [
          row([CommandIds.portrait, CommandIds.landscape]),
          WLabel(l10n.fieldPageSize, small: true, tone: WLabelTone.muted),
          Wrap(spacing: t.space.sm, runSpacing: t.space.sm, children: [
            for (final s in pageSizes)
              WChip(label: pageSizeLabel(l10n, s), onPressed: editable ? () => doc.setPageSize(s) : null),
          ]),
          WLabel(l10n.fieldMargins, small: true, tone: WLabelTone.muted),
          Wrap(spacing: t.space.sm, runSpacing: t.space.sm, children: [
            for (final (label, m) in marginPresets(l10n))
              WChip(label: label, onPressed: editable ? () => doc.setPageMargins(m) : null),
          ]),
        ]),
      InspectorPart.image => InspectorSection(title: l10n.sectionImage, children: [
          if (doc.graphicSizeCm case final s?)
            WLabel(l10n.imageSizeCm(formatCm(s.width, locale), formatCm(s.height, locale)), small: true),
          row([CommandIds.wrapOff, CommandIds.wrapIdeal, CommandIds.wrapThrough]),
          row([CommandIds.imageLeft, CommandIds.imageCenter, CommandIds.imageRight]),
        ]),
      InspectorPart.table => InspectorSection(title: l10n.sectionTable, children: [
          row([CommandIds.rowAbove, CommandIds.rowBelow, CommandIds.columnLeft, CommandIds.columnRight]),
          row([CommandIds.deleteRow, CommandIds.deleteColumn, CommandIds.deleteTable, CommandIds.mergeCells]),
        ]),
    };

    return SidePanel(
      title: l10n.inspectorTitle,
      closeLabel: commands.tooltipOf(ViewCommandIds.inspector).replaceFirst(l10n.commandInspector, l10n.inspectorClose),
      onClose: onClose ?? () => commands.run(ViewCommandIds.inspector),
      width: 300,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (!sectionsInRail) ...[
          WSegmented<InspectorPart>(
            label: l10n.inspectorSections,
            segments: segments,
            selected: shown,
            onChanged: onPart,
            expanded: true,
          ),
          SizedBox(height: t.space.sm),
        ],
        Expanded(
          child: ListView(
            padding: EdgeInsets.only(bottom: t.space.md),
            children: [
              if (reveal) _RevealSection(doc: doc, commands: commands, onRan: onRan),
              section,
            ],
          ),
        ),
      ]),
    );
  }

  Widget _textSection(BuildContext context, AppLocalizations l10n, QuillTokens t, Widget Function(List<String>) row, bool editable) {
    final styles = doc.paragraphStyles;
    return InspectorSection(title: l10n.sectionText, children: [
      WLabel(l10n.fieldStyle, small: true, tone: WLabelTone.muted),
      LayoutBuilder(
        builder: (context, box) => WDropdown<String>(
          label: l10n.fieldStyle,
          text: doc.paragraphStyleId == null ? '' : styleLabel(l10n, doc.paragraphStyleId!),
          width: box.maxWidth,
          items: [for (final s in styles) WDropdownItem(s, styleLabel(l10n, s))],
          onSelected: editable && styles.isNotEmpty ? doc.applyParagraphStyle : null,
          onClosed: onRan,
        ),
      ),
      PanelAction(commands: commands, id: ViewCommandIds.updateStyle, onRan: onRan),
      PanelAction(commands: commands, id: ViewCommandIds.newStyle, onRan: onRan),
      row([
        CommandIds.bold,
        CommandIds.italic,
        CommandIds.underline,
        CommandIds.strikeout,
        CommandIds.superscript,
        CommandIds.subscript,
      ]),
      WLabel(l10n.fieldFontColor, small: true, tone: WLabelTone.muted),
      SwatchRow(swatches: [
        (rgb: null, label: l10n.colorAutomatic, selected: doc.fontColor == null, onPressed: editable ? () => doc.setFontColor(null) : null),
        for (final (name, rgb) in fontColorChoices)
          (rgb: rgb, label: colorName(l10n, name), selected: doc.fontColor == rgb, onPressed: editable ? () => doc.setFontColor(rgb) : null),
      ]),
      WLabel(l10n.fieldHighlight, small: true, tone: WLabelTone.muted),
      SwatchRow(swatches: [
        (rgb: null, label: l10n.highlightNone, selected: doc.highlightColor == null, onPressed: editable ? () => doc.setHighlight(null) : null),
        for (final (name, rgb) in highlightChoices)
          (rgb: rgb, label: colorName(l10n, name), selected: doc.highlightColor == rgb, onPressed: editable ? () => doc.setHighlight(rgb) : null),
      ]),
      PanelAction(commands: commands, id: CommandIds.clearFormatting, onRan: onRan),
    ]);
  }
}

/// "Revelar formatação": o que vale no cursor, lido dos estados do motor.
class _RevealSection extends StatelessWidget {
  const _RevealSection({required this.doc, required this.commands, this.onRan});
  final DocumentController doc;
  final CommandRegistry commands;
  final VoidCallback? onRan;

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
    final alignId = doc.isOn('.uno:CenterPara')
        ? 'center'
        : doc.isOn('.uno:RightPara')
            ? 'end'
            : doc.isOn('.uno:JustifyPara')
                ? 'justify'
                : 'start';
    // De onde vem cada coisa: do estilo ou direta (a cópia, D-044).
    final origin = formatOrigins(
      style: doc.paragraphStyleId == null ? null : doc.snapshot.styles[doc.paragraphStyleId],
      fontName: doc.fontName,
      fontSize: size,
      bold: doc.isOn('.uno:Bold'),
      italic: doc.isOn('.uno:Italic'),
      color: colorRgb,
      alignment: alignId,
      firstLineCm: indents['firstline'],
    );
    bool? direct(List<FormatAspect> aspects) {
      final known = [for (final a in aspects) ?origin[a]];
      return known.isEmpty ? null : known.any((d) => d);
    }

    final rows = <(String, String, bool?)>[
      (l10n.revealParagraphStyle, doc.paragraphStyleId == null ? '—' : styleLabel(l10n, doc.paragraphStyleId!), null),
      (
        l10n.revealFont,
        [doc.fontName ?? '—', if (size != null) '${formatPoints(size, locale)} pt'].join(', '),
        direct([FormatAspect.font, FormatAspect.size])
      ),
      (l10n.revealEffects, effects.isEmpty ? l10n.revealNone : effects.join(', '), direct([FormatAspect.bold, FormatAspect.italic])),
      (l10n.revealColor, color, direct([FormatAspect.color])),
      (l10n.revealAlignment, align, direct([FormatAspect.alignment])),
      (
        l10n.revealIndents,
        '${l10n.fieldIndentLeft} ${cm(indents['left'])} · ${l10n.fieldIndentFirst} ${cm(indents['firstline'])}',
        direct([FormatAspect.firstLine])
      ),
      (l10n.revealSpacing, '${cm(spacing['upper'])} · ${cm(spacing['lower'])}', null),
      (
        l10n.revealLineSpacing,
        switch (doc.lineSpacing) {
          final p? => l10n.percentValue(p),
          null => l10n.revealOther,
        },
        null
      ),
      (l10n.revealLanguage, (s['.uno:LanguageStatus'] ?? '—').split(';').first, null),
      (l10n.revealPageStyle, s['.uno:PageStyleName'] ?? '—', null),
    ];
    final t = QuillTokens.of(context);
    return InspectorSection(title: l10n.sectionReveal, children: [
      for (final (label, value, isDirect) in rows)
        Semantics(
          label: isDirect == null
              ? '$label: $value'
              : '$label: $value, ${isDirect ? l10n.revealDirect : l10n.revealFromStyle}',
          child: ExcludeSemantics(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              WLabel(label, small: true, tone: WLabelTone.muted),
              Row(children: [
                Flexible(child: WLabel(value, maxLines: 2)),
                if (isDirect != null) ...[SizedBox(width: t.space.sm), _OriginTag(direct: isDirect)],
              ]),
            ]),
          ),
        ),
      if (commands[CommandIds.clearFormatting] case final c?)
        Align(
          alignment: Alignment.centerLeft,
          child: WChip(
            label: l10n.revealClearDirect,
            icon: c.icon,
            onPressed: c.enabled
                ? () {
                    commands.run(CommandIds.clearFormatting);
                    onRan?.call();
                  }
                : null,
          ),
        ),
    ]);
  }
}

/// A etiqueta "estilo" ou "direto" ao lado do valor.
class _OriginTag extends StatelessWidget {
  const _OriginTag({required this.direct});
  final bool direct;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final c = t.colors;
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: direct ? c.accentContainer : c.surfaceHigh,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        direct ? l10n.revealDirect : l10n.revealFromStyle,
        style: TextStyle(
          color: direct ? c.onAccentContainer : c.onFrameMuted,
          fontSize: 10,
          fontWeight: FontWeight.w500,
          fontFamily: t.font.family,
        ),
      ),
    );
  }
}
