// As janelas da Etapa 4 (D-076): o link, abrir um link (com a pergunta) e os
// caracteres especiais.
import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../atoms/w_button.dart';
import '../atoms/w_label.dart';
import '../atoms/w_text_field.dart';
import '../tokens/tokens.dart';
import 'special_characters.dart';

/// O texto e o endereço do link; null se desistiu.
Future<(String text, String url)?> showLinkDialog(BuildContext context, {String text = '', String url = ''}) =>
    showDialog<(String, String)>(context: context, builder: (_) => _LinkDialog(text: text, url: url));

class _LinkDialog extends StatefulWidget {
  const _LinkDialog({required this.text, required this.url});
  final String text, url;

  @override
  State<_LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends State<_LinkDialog> {
  late final _text = TextEditingController(text: widget.text);
  late final _url = TextEditingController(text: widget.url);

  @override
  void dispose() {
    _text.dispose();
    _url.dispose();
    super.dispose();
  }

  bool get _ready => _url.text.trim().isNotEmpty;

  void _apply() {
    if (!_ready) return;
    final url = _url.text.trim();
    final text = _text.text.trim().isEmpty ? url : _text.text.trim();
    Navigator.pop(context, (text, url));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = QuillTokens.of(context);
    return AlertDialog(
      title: Text(l10n.linkDialogTitle),
      content: SizedBox(
        width: 420,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          WLabel(l10n.linkText, small: true, tone: WLabelTone.muted),
          SizedBox(height: t.space.xs),
          WTextField(label: l10n.linkText, controller: _text, onSubmitted: (_) => _apply()),
          SizedBox(height: t.space.md),
          WLabel(l10n.linkUrl, small: true, tone: WLabelTone.muted),
          SizedBox(height: t.space.xs),
          WTextField(
            label: l10n.linkUrl,
            controller: _url,
            autofocus: true,
            hint: 'https://',
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _apply(),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.dialogCancel)),
        FilledButton(onPressed: _ready ? _apply : null, child: Text(l10n.linkApply)),
      ],
    );
  }
}

/// Pergunta antes de abrir [url]: o Quill não abre nada sozinho.
Future<bool> confirmOpenLink(BuildContext context, String url) async {
  final l10n = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.openLinkTitle),
      content: SizedBox(width: 420, child: Text(l10n.openLinkBody(url))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.dialogCancel)),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.openLinkButton)),
      ],
    ),
  );
  return ok == true;
}

/// O caractere escolhido; null se desistiu.
Future<String?> showSpecialCharacters(BuildContext context) =>
    showDialog<String>(context: context, builder: (_) => const _SpecialCharsDialog());

class _SpecialCharsDialog extends StatefulWidget {
  const _SpecialCharsDialog();

  @override
  State<_SpecialCharsDialog> createState() => _SpecialCharsDialogState();
}

class _SpecialCharsDialogState extends State<_SpecialCharsDialog> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  /// Sem acento e sem maiúsculas, para "reticencias" achar "reticências".
  static String _fold(String s) {
    const from = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const to = 'aaaaaeeeeiiiiooooouuuuc';
    final b = StringBuffer();
    for (final ch in s.toLowerCase().split('')) {
      final i = from.indexOf(ch);
      b.write(i < 0 ? ch : to[i]);
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = QuillTokens.of(context);
    final q = _fold(_query.text.trim());
    final all = specialCharacters(l10n);
    final shown = [for (final c in all) if (q.isEmpty || _fold(c.$2).contains(q)) c];
    return AlertDialog(
      title: Text(l10n.specialCharsTitle),
      content: SizedBox(
        width: 520,
        height: 380,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          WTextField(
            label: l10n.specialCharsSearch,
            hint: l10n.specialCharsSearch,
            controller: _query,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              if (shown.isNotEmpty) Navigator.pop(context, shown.first.$1);
            },
          ),
          SizedBox(height: t.space.md),
          Expanded(
            child: shown.isEmpty
                ? Center(child: WLabel(l10n.specialCharsEmpty, tone: WLabelTone.muted))
                : SingleChildScrollView(
                    child: Wrap(spacing: t.space.xs, runSpacing: t.space.xs, children: [
                      for (final (char, name) in shown)
                        WControlSurface(
                          width: t.density.control * 1.4,
                          height: t.density.control * 1.4,
                          outlined: true,
                          tooltip: name,
                          selected: false,
                          onPressed: () => Navigator.pop(context, char),
                          semantics: (child) =>
                              Semantics(button: true, label: l10n.specialCharInsert(name, char), excludeSemantics: true, child: child),
                          // Os invisíveis (o espaço sem quebra, o hífen
                          // opcional) aparecem pelo nome curto.
                          child: Center(
                            child: Text(
                              char.trim().isEmpty || char == '­' ? '⍽' : char,
                              style: TextStyle(fontSize: 20, color: t.colors.onFrame, fontFamily: t.font.family),
                            ),
                          ),
                        ),
                    ]),
                  ),
          ),
        ]),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.dialogCancel))],
    );
  }
}
