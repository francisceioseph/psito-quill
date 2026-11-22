import 'package:flutter/material.dart';

import '../tokens.dart';

/// Claro: neutro quente, papel branco.
const claro = QuillTokens(
  id: 'claro',
  brightness: Brightness.light,
  component: ComponentStyle.modern,
  paperScheme: 'PsitoQuillClaro',
  radius: QuillRadius(control: 8, panel: 12),
  font: QuillFont(family: null),
  colors: QuillColors(
    frame: Color(0xFFF4F1EC),
    frameRaised: Color(0xFFFBFAF7),
    onFrame: Color(0xFF26231F),
    onFrameMuted: Color(0xFF6B655C),
    border: Color(0xFFDCD6CC),
    accent: Color(0xFF2F5D8A),
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFDCE6F0),
    backdrop: Color(0xFFE6E1D8),
    paper: Color(0xFFFFFFFF),
    paperInk: Color(0xFF1A1A1A),
    cursor: Color(0xFF1A1A1A),
    selection: Color(0x553C78B4),
    focusRing: Color(0xFF2F5D8A),
    bevelLight: Color(0xFFFFFFFF),
    bevelDark: Color(0xFF8A8478),
    danger: Color(0xFFB3261E),
  ),
);
