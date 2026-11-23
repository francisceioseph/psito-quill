// A faixa (tema moderno): as abas e a aba Início. As outras abas (Inserir,
// Layout, Revisão, Livro…) entram nas próximas fases.
//
// Tudo sai do CommandRegistry; as listas (estilo, fonte, tamanho) mostram o
// estado que vem do motor.
import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../commands/command_registry.dart';
import '../../commands/commands_document.dart';
import '../../document/document_controller.dart';
import '../atoms/w_button.dart';
import '../atoms/w_dropdown.dart';
import '../atoms/w_separator.dart';
import '../molecules/command_button.dart';
import '../molecules/ribbon_group.dart';
import '../tokens/tokens.dart';

/// Os tamanhos de fonte da lista, como no Word.
const fontSizes = [8.0, 9, 10, 10.5, 11, 12, 14, 16, 18, 20, 22, 24, 28, 32, 36, 48, 72];

String formatPoints(double v, String locale) {
  final s = v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  return locale.startsWith('pt') ? s.replaceAll('.', ',') : s;
}

class Ribbon extends StatelessWidget {
  const Ribbon({
    super.key,
    required this.commands,
    required this.doc,
    required this.fileOpen,
    required this.onFile,
    required this.onHome,
    required this.onRan,
    this.trailing = const [],
  });

  final CommandRegistry commands;
  final DocumentController doc;

  /// O painel Arquivo está aberto (a aba Arquivo fica marcada).
  final bool fileOpen;
  final VoidCallback onFile, onHome;

  /// Depois de um comando ou de fechar uma lista: o foco volta ao documento.
  final VoidCallback onRan;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: commands,
      builder: (context, _) => Container(
        decoration: BoxDecoration(
          color: t.colors.frame,
          border: Border(bottom: BorderSide(color: t.colors.border)),
        ),
        padding: EdgeInsets.symmetric(horizontal: t.space.md, vertical: t.space.xs),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            WTextButton(label: l10n.ribbonFile, selected: fileOpen, onPressed: onFile),
            SizedBox(width: t.space.xs),
            WTextButton(label: l10n.ribbonHome, selected: !fileOpen, onPressed: onHome),
            const Spacer(),
            // Acesso rápido, como no Word: salvar, desfazer, refazer.
            for (final id in [CommandIds.save, CommandIds.undo, CommandIds.redo])
              CommandButton(commands: commands, id: id, onRan: onRan),
            if (trailing.isNotEmpty) const WSeparator(),
            ...trailing,
          ]),
          if (!fileOpen) ...[
            SizedBox(height: t.space.xs),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _HomeTab(commands: commands, doc: doc, onRan: onRan),
            ),
          ],
        ]),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.commands, required this.doc, required this.onRan});

  final CommandRegistry commands;
  final DocumentController doc;
  final VoidCallback onRan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    Widget cmd(String id) => CommandButton(commands: commands, id: id, onRan: onRan);
    final editable = doc.canEdit;
    final size = doc.fontSize;

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      RibbonGroup(
        title: l10n.groupClipboard,
        children: [cmd(CommandIds.paste), cmd(CommandIds.cut), cmd(CommandIds.copy)],
      ),
      const WSeparator(),
      RibbonGroup(title: l10n.groupStyles, children: [
        WDropdown<String>(
          label: l10n.fieldStyle,
          text: doc.paragraphStyle ?? '',
          width: 170,
          items: [for (final (name, label) in quickStyles(l10n)) WDropdownItem(name, label)],
          onSelected: editable ? doc.applyParagraphStyle : null,
          onClosed: onRan,
        ),
      ]),
      const WSeparator(),
      RibbonGroup(title: l10n.groupFont, children: [
        WDropdown<String>(
          label: l10n.fieldFont,
          text: doc.fontName ?? '',
          width: 170,
          items: [for (final f in doc.fonts) WDropdownItem(f, f)],
          onSelected: editable && doc.fonts.isNotEmpty ? doc.setFontName : null,
          onClosed: onRan,
        ),
        WDropdown<double>(
          label: l10n.fieldFontSize,
          text: size == null ? '' : formatPoints(size, locale),
          width: 76,
          items: [for (final s in fontSizes) WDropdownItem(s.toDouble(), formatPoints(s.toDouble(), locale))],
          onSelected: editable ? doc.setFontSize : null,
          onClosed: onRan,
        ),
        cmd(CommandIds.bold),
        cmd(CommandIds.italic),
        cmd(CommandIds.underline),
        cmd(CommandIds.strikeout),
      ]),
      const WSeparator(),
      RibbonGroup(title: l10n.groupParagraph, children: [
        cmd(CommandIds.alignLeft),
        cmd(CommandIds.alignCenter),
        cmd(CommandIds.alignRight),
        cmd(CommandIds.justify),
        cmd(CommandIds.bullets),
        cmd(CommandIds.numbering),
      ]),
    ]);
  }
}
