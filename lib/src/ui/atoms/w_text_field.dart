// Átomo de campo de texto: busca, paleta, nome de estilo, medidas.
//
// Um TextField do Flutter (o IME, a seleção e o leitor de tela de graça),
// com as cores, o tipo e o desenho (moderno ou bisel afundado) dos tokens.
import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

class WTextField extends StatelessWidget {
  const WTextField({
    super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.hint,
    this.width,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.error = false,
    this.textAlign = TextAlign.start,
  });

  /// O nome para o leitor de tela ("Localizar").
  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  /// O texto de fundo, com o campo vazio (o rótulo, se null).
  final String? hint;
  final double? width;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;

  /// Contorno de erro (nada encontrado, nome repetido).
  final bool error;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final t = QuillTokens.of(context);
    final c = t.colors;
    final bevel = t.component == ComponentStyle.bevel;
    final edge = error ? c.danger : c.border;
    InputBorder border(Color color, double w) => bevel
        // Afundado: escuro em cima e à esquerda.
        ? OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: c.bevelDark, width: 2))
        : OutlineInputBorder(
            borderRadius: BorderRadius.circular(t.radius.control),
            borderSide: BorderSide(color: color, width: w),
          );
    return SizedBox(
      width: width,
      height: t.density.control,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        onEditingComplete: onEditingComplete,
        textAlign: textAlign,
        cursorColor: c.onFrame,
        style: TextStyle(color: c.onFrame, fontSize: t.font.ui, fontFamily: t.font.family),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: bevel ? c.paper : c.surfaceLowest,
          hintText: hint ?? label,
          hintStyle: TextStyle(color: c.onFrameMuted, fontSize: t.font.ui, fontFamily: t.font.family),
          semanticCounterText: '',
          contentPadding: EdgeInsets.symmetric(horizontal: t.space.md, vertical: t.space.sm + 2),
          enabledBorder: border(edge, 1),
          focusedBorder: border(error ? c.danger : c.focusRing, 2),
          border: border(edge, 1),
        ),
      ),
    );
  }
}
