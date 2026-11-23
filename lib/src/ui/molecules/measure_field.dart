// Um campo de medida em centímetros (recuos, margens): mostra o valor do
// motor e manda o novo ao confirmar (Enter ou ao sair do campo).
import 'package:flutter/material.dart';

import '../atoms/w_label.dart';
import '../atoms/w_text_field.dart';
import '../tokens/tokens.dart';

/// "1,25" em português, "1.25" em inglês; duas casas, sem zeros sobrando.
String formatCm(double v, String locale) {
  var s = v.toStringAsFixed(2);
  s = s.replaceFirst(RegExp(r'\.?0+$'), '');
  if (s == '-0') s = '0';
  return locale.startsWith('pt') ? s.replaceAll('.', ',') : s;
}

/// Lê "1,5", "1.5" ou "1,5 cm". null se não é um número.
double? parseCm(String text) =>
    double.tryParse(text.replaceAll(RegExp(r'[^\d,.\-]'), '').replaceAll(',', '.'));

class MeasureField extends StatefulWidget {
  const MeasureField({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.onChanged,
    this.onDone,
  });

  final String label;

  /// O valor atual em cm (do motor); null se não se sabe.
  final double? value;

  /// "cm", já traduzido.
  final String unit;

  /// null: só leitura.
  final ValueChanged<double>? onChanged;

  /// Depois do Enter (a página devolve o foco ao documento; sem isso, o
  /// foco fica solto e os atalhos param).
  final VoidCallback? onDone;

  @override
  State<MeasureField> createState() => _MeasureFieldState();
}

class _MeasureFieldState extends State<MeasureField> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _commit();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(MeasureField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && !_focus.hasFocus) _sync();
  }

  void _sync() {
    final v = widget.value;
    _controller.text = v == null ? '' : formatCm(v, Localizations.localeOf(context).toLanguageTag());
  }

  void _commit() {
    final v = parseCm(_controller.text);
    if (v == null || widget.onChanged == null) {
      _sync();
      return;
    }
    if (widget.value == null || (v - widget.value!).abs() > 0.005) widget.onChanged!(v);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    return Row(children: [
      Expanded(child: WLabel(widget.label, small: true, tone: WLabelTone.muted)),
      WTextField(
        label: widget.label,
        hint: '',
        controller: _controller,
        focusNode: _focus,
        width: 64,
        textAlign: TextAlign.end,
        onSubmitted: (_) {
          _commit();
          widget.onDone?.call();
        },
      ),
      SizedBox(width: t.space.sm),
      WLabel(widget.unit, small: true, tone: WLabelTone.muted),
    ]);
  }
}
