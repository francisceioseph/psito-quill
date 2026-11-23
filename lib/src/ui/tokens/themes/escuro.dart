import 'package:flutter/material.dart';

import '../tokens.dart';

/// Escuro: o Material 3 escuro da mesma semente. O papel fica escuro também
/// (o esquema de cor registrado no perfil do LibreOffice), e atrás dele o tom
/// mais fundo, para a página se destacar.
const escuro = QuillTokens(
  id: 'escuro',
  brightness: Brightness.dark,
  component: ComponentStyle.modern,
  paperScheme: 'PsitoQuillEscuro',
  radius: QuillRadius(control: 8, panel: 16),
  font: QuillFont(family: null),
  colors: QuillColors(
    frame: Color(0xFF111318),
    frameRaised: Color(0xFF191C20),
    onFrame: Color(0xFFE2E2E9),
    onFrameMuted: Color(0xFFC4C6D0),
    border: Color(0xFF44474E),
    accent: Color(0xFFAAC7FF),
    onAccent: Color(0xFF0A305F),
    accentSoft: Color(0xFF3E4759),
    onAccentSoft: Color(0xFFDAE2F9),
    accentContainer: Color(0xFF284777),
    onAccentContainer: Color(0xFFD6E3FF),
    tertiary: Color(0xFFDDBCE0),
    tertiaryContainer: Color(0xFF573E5C),
    onTertiaryContainer: Color(0xFFFAD8FD),
    surfaceLowest: Color(0xFF0C0E13),
    surfaceContainer: Color(0xFF1D2024),
    surfaceHigh: Color(0xFF282A2F),
    surfaceHighest: Color(0xFF33353A),
    outline: Color(0xFF8E9099),
    backdrop: Color(0xFF0C0E13),
    paper: Color(0xFF1E2025),
    paperInk: Color(0xFFE2E2E9),
    cursor: Color(0xFFE2E2E9),
    selection: Color(0x66AAC7FF),
    focusRing: Color(0xFFAAC7FF),
    bevelLight: Color(0xFF44474E),
    bevelDark: Color(0xFF0C0E13),
    danger: Color(0xFFFFB4AB),
    dangerContainer: Color(0xFF93000A),
    onDangerContainer: Color(0xFFFFDAD6),
  ),
);
