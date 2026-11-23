// Os estilos: gerenciar (aplicar, criar e atualizar a partir da seleção) e
// o nome de um estilo novo.
//
// Apagar estilo fica de fora: o `.uno:StyleDelete` não faz nada no 24.2
// (D-030).
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../commands/command_registry.dart';
import '../../commands/commands_document.dart';
import '../../document/document_controller.dart';
import '../../kit/lok/lo_styles.dart';
import '../atoms/w_button.dart';
import '../atoms/w_chip.dart';
import '../atoms/w_label.dart';
import '../atoms/w_segmented.dart';
import '../atoms/w_text_field.dart';
import '../molecules/style_card.dart';
import '../style_labels.dart';
import '../tokens/tokens.dart';
import 'ribbon.dart' show styleSample;

/// Pede o nome de um estilo novo; null se cancelou.
Future<String?> showNewStyleDialog(BuildContext context, DocumentController doc) => showDialog<String>(
  context: context,
  builder: (_) => NewStyleDialog(taken: doc.paragraphStyles.toSet()),
);

class NewStyleDialog extends StatefulWidget {
  const NewStyleDialog({super.key, required this.taken});

  /// Os nomes que já existem.
  final Set<String> taken;

  @override
  State<NewStyleDialog> createState() => _NewStyleDialogState();
}

class _NewStyleDialogState extends State<NewStyleDialog> {
  final _name = TextEditingController();

  String get _value => _name.text.trim();
  bool get _taken => widget.taken.contains(_value);
  bool get _valid => _value.isNotEmpty && !_taken;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _create() {
    if (_valid) Navigator.of(context).pop(_value);
  }

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final l10n = AppLocalizations.of(context);
    return Dialog(
      child: SizedBox(
        width: 380,
        child: Padding(
          padding: EdgeInsets.all(t.space.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WLabel(l10n.stylesNewTitle, heading: true),
              SizedBox(height: t.space.md),
              WTextField(
                label: l10n.stylesName,
                controller: _name,
                autofocus: true,
                error: _taken,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _create(),
              ),
              if (_taken) ...[
                SizedBox(height: t.space.sm),
                WLabel(l10n.stylesNameTaken, small: true, tone: WLabelTone.danger),
              ],
              SizedBox(height: t.space.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  WTextButton(label: l10n.dialogCancel, onPressed: () => Navigator.of(context).pop()),
                  SizedBox(width: t.space.sm),
                  WTextButton(label: l10n.stylesCreate, selected: true, onPressed: _valid ? _create : null),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A galeria aberta (Fase 2B, Etapa 3): "Mais estilos" e "Gerenciar
/// estilos". Os cartões com as prévias da cópia temporária (D-044), a
/// busca, Parágrafo ou Caractere, "Do livro" (os do autor) e "Do
/// LibreOffice" (os de fábrica), e o atalho de cada estilo.
Future<void> showStylesDialog(BuildContext context, DocumentController doc, {CommandRegistry? commands}) =>
    showDialog<void>(
      context: context,
      builder: (_) => StylesDialog(doc: doc, commands: commands),
    );

/// A galeria aberta como lista que desce (o ▾ da galeria do Início, D-055):
/// por cima da galeria da faixa, a partir do canto de cima dela ([anchor],
/// em coordenadas da tela). Escolher um estilo fecha; Esc e o clique fora
/// também.
Future<void> showStylesDropdown(
  BuildContext context,
  DocumentController doc, {
  required Rect anchor,
  CommandRegistry? commands,
}) {
  final l10n = AppLocalizations.of(context);
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: l10n.dialogClose,
    barrierColor: QuillTokens.of(context).colors.backdrop.withValues(alpha: 0),
    transitionDuration: Duration.zero,
    pageBuilder: (context, _, _) {
      final screen = MediaQuery.sizeOf(context);
      final t = QuillTokens.of(context);
      final width = anchor.width.clamp(560.0, 900.0).clamp(0.0, screen.width - 2 * t.space.md);
      final left = anchor.left.clamp(t.space.md, screen.width - width - t.space.md);
      final height = (screen.height - anchor.top - t.space.lg).clamp(240.0, 480.0);
      return Stack(children: [
        Positioned(
          left: left,
          top: anchor.top,
          width: width,
          height: height,
          child: StylesDialog(doc: doc, commands: commands, dropdown: true),
        ),
      ]);
    },
  );
}

enum _Origin { all, mine, builtIn }

class StylesDialog extends StatefulWidget {
  const StylesDialog({super.key, required this.doc, this.commands, this.dropdown = false});
  final DocumentController doc;

  /// Aberta pelo ▾ da galeria: um painel que desce, sem título nem botão
  /// Fechar, e que fecha ao escolher um estilo.
  final bool dropdown;

  /// Para mostrar o atalho de cada estilo (os de título têm).
  final CommandRegistry? commands;

  @override
  State<StylesDialog> createState() => _StylesDialogState();
}

class _StylesDialogState extends State<StylesDialog> {
  bool _character = false;
  _Origin _origin = _Origin.all;
  final _query = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Depois do primeiro quadro: a resposta pode chegar no meio da construção.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.doc.refreshStyles();
    });
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  /// O atalho do estilo, pelo comando que o aplica.
  String? _shortcutOf(String style) {
    final id = switch (style) {
      'Heading 1' => CommandIds.heading1,
      'Heading 2' => CommandIds.heading2,
      'Heading 3' => CommandIds.heading3,
      'Text body' => CommandIds.bodyText,
      _ => null,
    };
    return id == null ? null : widget.commands?.shortcutLabelOf(id);
  }

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final doc = widget.doc;
    final dropdown = widget.dropdown;
    final body = Padding(
          padding: EdgeInsets.all(dropdown ? t.space.md : t.space.lg),
          child: ListenableBuilder(
            listenable: doc,
            builder: (context, _) {
              final builtIn = _character ? loBuiltinCharacterStyles : loBuiltinParagraphStyles;
              final all = _character
                  ? doc.characterStyles
                  : [
                      for (final s in bookStyles)
                        if (doc.paragraphStyles.contains(s)) s,
                      for (final s in doc.paragraphStyles)
                        if (!bookStyles.contains(s)) s,
                    ];
              final q = _query.text.trim().toLowerCase();
              final styles = [
                for (final s in all)
                  if ((_origin == _Origin.all || (_origin == _Origin.mine) != builtIn.contains(s)) &&
                      (q.isEmpty || styleLabel(l10n, s).toLowerCase().contains(q) || s.toLowerCase().contains(q)))
                    s,
              ];
              final current = _character ? null : doc.paragraphStyleId;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Semantics(header: true, child: WLabel(l10n.stylesTitle, heading: !dropdown))),
                      WTextField(
                        label: l10n.stylesSearch,
                        controller: _query,
                        width: 220,
                        autofocus: true,
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                  SizedBox(height: t.space.md),
                  Wrap(
                    spacing: t.space.md,
                    runSpacing: t.space.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      WSegmented<bool>(
                        label: l10n.stylesKind,
                        segments: [WSegment(false, l10n.stylesParagraph), WSegment(true, l10n.stylesCharacter)],
                        selected: _character,
                        onChanged: (v) => setState(() => _character = v),
                      ),
                      for (final (o, label) in [
                        (_Origin.all, l10n.fontAll),
                        (_Origin.mine, l10n.stylesFromBook),
                        (_Origin.builtIn, l10n.stylesFromLibreOffice),
                      ])
                        WChip(label: label, selected: _origin == o, onPressed: () => setState(() => _origin = o)),
                    ],
                  ),
                  SizedBox(height: t.space.md),
                  Expanded(
                    child: styles.isEmpty
                        ? WLabel(l10n.stylesNone, tone: WLabelTone.muted)
                        : SingleChildScrollView(
                            child: Wrap(
                              spacing: t.space.sm,
                              runSpacing: t.space.sm,
                              children: [
                                for (final s in styles)
                                  StyleCard(
                                    width: 160,
                                    name: styleLabel(l10n, s),
                                    sample: styleSample(l10n, s, doc.snapshot.styles[s]),
                                    shortcut: _shortcutOf(s),
                                    semanticLabel: s == current
                                        ? l10n.styleCardApplied(styleLabel(l10n, s))
                                        : l10n.styleCard(styleLabel(l10n, s)),
                                    selected: s == current,
                                    onPressed: doc.canEdit
                                        ? () {
                                            _character ? doc.applyCharacterStyle(s) : doc.applyParagraphStyle(s);
                                            if (dropdown) Navigator.of(context).pop();
                                          }
                                        : null,
                                  ),
                              ],
                            ),
                          ),
                  ),
                  SizedBox(height: t.space.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // As ações quebram a linha se não couberem (textos longos).
                      Expanded(
                        child: Wrap(
                          spacing: t.space.xs,
                          runSpacing: t.space.xs,
                          children: [
                            if (!_character) ...[
                              WTextButton(
                                label: l10n.commandNewStyle,
                                icon: Symbols.add_rounded,
                                onPressed: doc.canEdit
                                    ? () async {
                                        final name = await showNewStyleDialog(context, doc);
                                        if (name != null) doc.newStyleFromSelection(name);
                                      }
                                    : null,
                              ),
                              WTextButton(
                                label: l10n.commandUpdateStyle,
                                icon: Symbols.sync_rounded,
                                onPressed: doc.canEdit && current != null
                                    ? () => doc.updateStyleFromSelection(current)
                                    : null,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (!dropdown) WTextButton(label: l10n.dialogClose, onPressed: () => Navigator.of(context).pop()),
                    ],
                  ),
                ],
              );
            },
          ),
        );
    if (dropdown) {
      return Material(
        color: t.colors.surfaceContainer,
        elevation: 6,
        borderRadius: BorderRadius.circular(t.radius.control),
        child: Semantics(scopesRoute: true, explicitChildNodes: true, label: l10n.stylesMore, child: body),
      );
    }
    return Dialog(child: SizedBox(width: 720, height: 560, child: body));
  }
}
