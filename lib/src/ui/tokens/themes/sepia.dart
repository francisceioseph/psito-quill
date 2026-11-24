import 'package:flutter/material.dart';

import '../tokens.dart';

/// Sépia: papel creme e tinta marrom, para escrever horas (o modo zen usa o
/// papel dele por padrão). Os contrastes passam no tokens_test como os
/// outros temas.
const sepia = QuillTokens(
  id: 'sepia',
  brightness: Brightness.light,
  component: ComponentStyle.modern,
  paperScheme: 'PsitoQuillSepia',
  radius: QuillRadius(control: 8, panel: 16),
  font: QuillFont(family: null),
  colors: QuillColors(
    frame: Color(0xFFF4ECD8),
    frameRaised: Color(0xFFEFE5CF),
    onFrame: Color(0xFF3B2F22),
    onFrameMuted: Color(0xFF6A5A46),
    border: Color(0xFFD9CCAF),
    accent: Color(0xFF7A5A2E),
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFE6D6B4),
    onAccentSoft: Color(0xFF3B2F22),
    accentContainer: Color(0xFFE9D3A8),
    onAccentContainer: Color(0xFF2E2210),
    tertiary: Color(0xFF6B4F6B),
    tertiaryContainer: Color(0xFFEBD9E8),
    onTertiaryContainer: Color(0xFF2E1A2E),
    surfaceLowest: Color(0xFFFBF6EA),
    surfaceContainer: Color(0xFFEFE5CF),
    surfaceHigh: Color(0xFFEADFC6),
    surfaceHighest: Color(0xFFE3D6B9),
    outline: Color(0xFF857560),
    backdrop: Color(0xFFE9DFC7),
    paper: Color(0xFFF4ECD8),
    paperInk: Color(0xFF3B2F22),
    cursor: Color(0xFF3B2F22),
    selection: Color(0x557A5A2E),
    focusRing: Color(0xFF7A5A2E),
    bevelLight: Color(0xFFFBF6EA),
    bevelDark: Color(0xFF857560),
    danger: Color(0xFFA1301F),
    dangerContainer: Color(0xFFF6D7CC),
    onDangerContainer: Color(0xFF3D0A00),
    labels: [Color(0xFFB3412F), Color(0xFFB86E1F), Color(0xFF5E7D3A), Color(0xFF3F6A8A), Color(0xFF7A4E7E)],
  ),
);
