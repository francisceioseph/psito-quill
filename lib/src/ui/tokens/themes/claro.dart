import 'package:flutter/material.dart';

import '../tokens.dart';

/// Claro: o Material 3 da semente #415F91 (o azul do desenho), com a
/// superfície levemente azulada e o papel branco (D-042).
const claro = QuillTokens(
  id: 'claro',
  brightness: Brightness.light,
  component: ComponentStyle.modern,
  paperScheme: 'PsitoQuillClaro',
  radius: QuillRadius(control: 8, panel: 16),
  font: QuillFont(family: null),
  colors: QuillColors(
    frame: Color(0xFFF9F9FF),
    frameRaised: Color(0xFFF3F3FA),
    onFrame: Color(0xFF191C20),
    onFrameMuted: Color(0xFF44474E),
    border: Color(0xFFC4C6D0),
    accent: Color(0xFF415F91),
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFDAE2F9),
    onAccentSoft: Color(0xFF3E4759),
    accentContainer: Color(0xFFD6E3FF),
    onAccentContainer: Color(0xFF284777),
    tertiary: Color(0xFF705575),
    tertiaryContainer: Color(0xFFFAD8FD),
    onTertiaryContainer: Color(0xFF29132E),
    surfaceLowest: Color(0xFFFFFFFF),
    surfaceContainer: Color(0xFFEDEDF4),
    surfaceHigh: Color(0xFFE7E8EE),
    surfaceHighest: Color(0xFFE2E2E9),
    outline: Color(0xFF74777F),
    backdrop: Color(0xFFEDEDF4),
    paper: Color(0xFFFFFFFF),
    paperInk: Color(0xFF1B1B1F),
    cursor: Color(0xFF1B1B1F),
    selection: Color(0x55415F91),
    focusRing: Color(0xFF415F91),
    bevelLight: Color(0xFFFFFFFF),
    bevelDark: Color(0xFF74777F),
    danger: Color(0xFFBA1A1A),
    dangerContainer: Color(0xFFFFDAD6),
    onDangerContainer: Color(0xFF410002),
  ),
);
