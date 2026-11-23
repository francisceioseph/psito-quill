import 'package:flutter/material.dart';

import '../tokens.dart';

/// Clássico 97: cinza #C0C0C0, bisel 3D, destaque azul-marinho. A fonte é a
/// Liberation Sans, livre e instalada junto com o LibreOffice (D-034).
const classico97 = QuillTokens(
  id: 'classico97',
  brightness: Brightness.light,
  component: ComponentStyle.bevel,
  paperScheme: 'PsitoQuillClassico',
  radius: QuillRadius(control: 0, panel: 0),
  font: QuillFont(family: 'Liberation Sans', ui: 12, small: 11, title: 13),
  density: QuillDensity(control: 26, toolbar: 34, statusBar: 24),
  colors: QuillColors(
    frame: Color(0xFFC0C0C0),
    frameRaised: Color(0xFFC0C0C0),
    onFrame: Color(0xFF000000),
    onFrameMuted: Color(0xFF3A3A3A),
    border: Color(0xFF808080),
    accent: Color(0xFF000080),
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFA6CAF0),
    backdrop: Color(0xFF808080),
    paper: Color(0xFFFFFFFF),
    paperInk: Color(0xFF000000),
    cursor: Color(0xFF000000),
    selection: Color(0x66000080),
    focusRing: Color(0xFF000000),
    bevelLight: Color(0xFFFFFFFF),
    bevelDark: Color(0xFF808080),
    danger: Color(0xFF800000),
  ),
);
