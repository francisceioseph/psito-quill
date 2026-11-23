// Os tokens do design system `quill_ui`.
//
// Todo widget lê cor, espaço, raio, tipo e movimento daqui
// (`QuillTokens.of(context)`). Nenhum widget tem cor literal: só os arquivos
// de tema, em tokens/themes/, têm números de cor (o design_test confere).
import 'package:flutter/material.dart';

/// Strategy: o mesmo átomo desenhado de dois jeitos.
/// - modern: raio, realce suave (Claro, Escuro, Sépia, Alto contraste);
/// - bevel: bisel 3D e cinza (Clássico 97).
enum ComponentStyle { modern, bevel }

@immutable
class QuillColors {
  const QuillColors({
    required this.frame,
    required this.frameRaised,
    required this.onFrame,
    required this.onFrameMuted,
    required this.border,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.backdrop,
    required this.paper,
    required this.paperInk,
    required this.cursor,
    required this.selection,
    required this.focusRing,
    required this.bevelLight,
    required this.bevelDark,
    required this.danger,
  });

  /// Moldura da janela (fundo das barras).
  final Color frame;

  /// Superfícies sobre a moldura (barra de ferramentas, botões).
  final Color frameRaised;
  final Color onFrame, onFrameMuted, border;
  final Color accent, onAccent, accentSoft;

  /// Atrás das páginas.
  final Color backdrop;

  /// O papel e a tinta. Também viram o esquema de cor do LibreOffice.
  final Color paper, paperInk;
  final Color cursor, selection, focusRing;
  final Color bevelLight, bevelDark;
  final Color danger;

  QuillColors lerp(QuillColors o, double t) => QuillColors(
        frame: Color.lerp(frame, o.frame, t)!,
        frameRaised: Color.lerp(frameRaised, o.frameRaised, t)!,
        onFrame: Color.lerp(onFrame, o.onFrame, t)!,
        onFrameMuted: Color.lerp(onFrameMuted, o.onFrameMuted, t)!,
        border: Color.lerp(border, o.border, t)!,
        accent: Color.lerp(accent, o.accent, t)!,
        onAccent: Color.lerp(onAccent, o.onAccent, t)!,
        accentSoft: Color.lerp(accentSoft, o.accentSoft, t)!,
        backdrop: Color.lerp(backdrop, o.backdrop, t)!,
        paper: Color.lerp(paper, o.paper, t)!,
        paperInk: Color.lerp(paperInk, o.paperInk, t)!,
        cursor: Color.lerp(cursor, o.cursor, t)!,
        selection: Color.lerp(selection, o.selection, t)!,
        focusRing: Color.lerp(focusRing, o.focusRing, t)!,
        bevelLight: Color.lerp(bevelLight, o.bevelLight, t)!,
        bevelDark: Color.lerp(bevelDark, o.bevelDark, t)!,
        danger: Color.lerp(danger, o.danger, t)!,
      );
}

@immutable
class QuillSpace {
  const QuillSpace({this.xs = 2, this.sm = 4, this.md = 8, this.lg = 12, this.xl = 20});
  final double xs, sm, md, lg, xl;
}

@immutable
class QuillRadius {
  const QuillRadius({required this.control, required this.panel});
  final double control, panel;
}

@immutable
class QuillFont {
  const QuillFont({required this.family, this.ui = 13, this.small = 12, this.title = 15});
  final String? family;
  final double ui, small, title;
}

@immutable
class QuillMotion {
  const QuillMotion({this.fast = const Duration(milliseconds: 90), this.normal = const Duration(milliseconds: 180)});
  final Duration fast, normal;

  /// O piscar do cursor (desenhado pelo Flutter, sem tocar no motor).
  Duration get caretBlink => const Duration(milliseconds: 530);
}

@immutable
class QuillDensity {
  const QuillDensity({this.control = 32, this.toolbar = 44, this.statusBar = 26});
  final double control, toolbar, statusBar;
}

class QuillTokens extends ThemeExtension<QuillTokens> {
  const QuillTokens({
    required this.id,
    required this.brightness,
    required this.colors,
    required this.radius,
    required this.font,
    required this.component,
    required this.paperScheme,
    this.space = const QuillSpace(),
    this.motion = const QuillMotion(),
    this.density = const QuillDensity(),
  });

  /// "claro", "escuro"...
  final String id;
  final Brightness brightness;
  final QuillColors colors;
  final QuillSpace space;
  final QuillRadius radius;
  final QuillFont font;
  final QuillMotion motion;
  final QuillDensity density;
  final ComponentStyle component;

  /// Nome do esquema de cor do LibreOffice para este tema.
  final String paperScheme;

  static QuillTokens of(BuildContext context) => Theme.of(context).extension<QuillTokens>()!;

  @override
  QuillTokens copyWith({QuillColors? colors, ComponentStyle? component}) => QuillTokens(
        id: id,
        brightness: brightness,
        colors: colors ?? this.colors,
        radius: radius,
        font: font,
        component: component ?? this.component,
        paperScheme: paperScheme,
        space: space,
        motion: motion,
        density: density,
      );

  @override
  QuillTokens lerp(QuillTokens? other, double t) {
    if (other == null) return this;
    return (t < 0.5 ? this : other).copyWith(colors: colors.lerp(other.colors, t));
  }

  /// O ThemeData do Flutter montado a partir dos tokens, para o que vem do
  /// framework (seleção de texto, barras de rolagem) seguir o tema.
  ThemeData toThemeData() {
    final scheme = ColorScheme.fromSeed(
      seedColor: colors.accent,
      brightness: brightness,
      surface: colors.frame,
      onSurface: colors.onFrame,
      primary: colors.accent,
      onPrimary: colors.onAccent,
      error: colors.danger,
    );
    return ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.frame,
      fontFamily: font.family,
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(colors.onFrameMuted.withValues(alpha: 0.5)),
      ),
      // Os menus (de contexto, do tema 97) e os diálogos seguem o tema.
      popupMenuTheme: PopupMenuThemeData(
        color: colors.frameRaised,
        surfaceTintColor: colors.frameRaised,
        textStyle: TextStyle(color: colors.onFrame, fontSize: font.ui, fontFamily: font.family),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius.control),
          side: BorderSide(color: colors.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.frame,
        surfaceTintColor: colors.frame,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius.panel),
          side: component == ComponentStyle.bevel ? BorderSide(color: colors.bevelDark, width: 2) : BorderSide.none,
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(colors.frameRaised),
          surfaceTintColor: WidgetStatePropertyAll(colors.frameRaised),
          side: WidgetStatePropertyAll(BorderSide(color: colors.border)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius.control))),
        ),
      ),
      menuBarTheme: MenuBarThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(colors.frame),
          surfaceTintColor: WidgetStatePropertyAll(colors.frame),
          elevation: const WidgetStatePropertyAll(0),
          shape: const WidgetStatePropertyAll(RoundedRectangleBorder()),
        ),
      ),
      menuButtonTheme: MenuButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(colors.onFrame),
          overlayColor: WidgetStatePropertyAll(colors.accentSoft),
          textStyle: WidgetStatePropertyAll(TextStyle(fontSize: font.ui, fontFamily: font.family)),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.onFrame,
        selectionColor: colors.selection,
      ),
      extensions: [this],
    );
  }
}
