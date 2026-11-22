import 'package:flutter/material.dart';

import '../tokens.dart';

/// Escuro: moldura grafite e papel escuro (o motor deixa, pelo esquema de cor
/// registrado no perfil do LibreOffice).
const escuro = QuillTokens(
  id: 'escuro',
  brightness: Brightness.dark,
  component: ComponentStyle.modern,
  paperScheme: 'PsitoQuillEscuro',
  radius: QuillRadius(control: 8, panel: 12),
  font: QuillFont(family: null),
  colors: QuillColors(
    frame: Color(0xFF1C1D20),
    frameRaised: Color(0xFF26282C),
    onFrame: Color(0xFFE8E4DC),
    onFrameMuted: Color(0xFFA29D94),
    border: Color(0xFF3A3C41),
    accent: Color(0xFF8DB4DC),
    onAccent: Color(0xFF0F1A26),
    accentSoft: Color(0xFF2B3A4A),
    backdrop: Color(0xFF141517),
    paper: Color(0xFF232427),
    paperInk: Color(0xFFE6E1D8),
    cursor: Color(0xFFE6E1D8),
    selection: Color(0x668DB4DC),
    focusRing: Color(0xFF8DB4DC),
    bevelLight: Color(0xFF4A4C52),
    bevelDark: Color(0xFF0A0A0B),
    danger: Color(0xFFF2B8B5),
  ),
);
