// A janela da marca d'água (Fase 4, Etapa 7, D-092): o texto, a cor e a
// direção. O motor a põe no cabeçalho de cada página (o `.uno:Watermark`).
import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../document/doc_colors.dart';
import '../../document/document_controller.dart' show WatermarkSpec;
import '../atoms/w_label.dart';
import '../atoms/w_segmented.dart';
import '../atoms/w_text_field.dart';
import '../molecules/swatch_row.dart';
import '../tokens/tokens.dart';

/// [current]: o texto da marca d'água de agora (null: sem ela).
Future<WatermarkSpec?> showWatermarkDialog(BuildContext context, {String? current}) =>
    showDialog<WatermarkSpec>(context: context, builder: (_) => _WatermarkDialog(current: current));

class _WatermarkDialog extends StatefulWidget {
  const _WatermarkDialog({this.current});
  final String? current;

  @override
  State<_WatermarkDialog> createState() => _WatermarkDialogState();
}

class _WatermarkDialogState extends State<_WatermarkDialog> {
  late final _text = TextEditingController(text: widget.current ?? '');
  int _color = watermarkColorValues.first;
  bool _diagonal = true;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _apply() {
    if (_text.text.trim().isEmpty) return;
    Navigator.pop(context, WatermarkSpec(text: _text.text.trim(), color: _color, diagonal: _diagonal));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = QuillTokens.of(context);
    Widget caption(String text) => Padding(
          padding: EdgeInsets.only(top: t.space.md, bottom: t.space.xs),
          child: WLabel(text, small: true, tone: WLabelTone.muted),
        );
    return AlertDialog(
      title: Text(l10n.watermarkTitle),
      content: SizedBox(
        width: 420,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          caption(l10n.watermarkText),
          WTextField(
            label: l10n.watermarkText,
            hint: l10n.watermarkHint,
            controller: _text,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _apply(),
          ),
          caption(l10n.watermarkColor),
          SwatchRow(swatches: [
            for (final (i, rgb) in watermarkColorValues.indexed)
              (rgb: rgb, label: l10n.watermarkColorN(i + 1), selected: _color == rgb, onPressed: () => setState(() => _color = rgb)),
          ]),
          caption(l10n.watermarkLayout),
          WSegmented<bool>(
            label: l10n.watermarkLayout,
            expanded: true,
            segments: [WSegment(true, l10n.watermarkDiagonal), WSegment(false, l10n.watermarkHorizontal)],
            selected: _diagonal,
            onChanged: (v) => setState(() => _diagonal = v),
          ),
          SizedBox(height: t.space.sm),
          WLabel(l10n.watermarkNote, small: true, tone: WLabelTone.muted, maxLines: 3),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.dialogCancel)),
        FilledButton(onPressed: _text.text.trim().isEmpty ? null : _apply, child: Text(l10n.watermarkApply)),
      ],
    );
  }
}
